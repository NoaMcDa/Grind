import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/features/goals/presentation/goal_l10n.dart';
import 'package:grind/features/review/review_repository.dart';
import 'package:grind/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(ensureTimeZones);

  final now = DateTime.utc(2026, 11, 3, 8);
  final en = lookupAppLocalizations(const Locale('en'));
  final he = lookupAppLocalizations(const Locale('he'));

  GoalRecord goal(
    String id, {
    GoalHorizon horizon = GoalHorizon.month,
    GoalMetric? metric,
    GoalStatus status = GoalStatus.active,
    DateTime? created,
    DateTime? updated,
    DateTime? lastProgressAt,
    int importance = 3,
  }) => GoalRecord(
    id: id,
    title: id,
    horizon: horizon,
    metric: metric,
    status: status,
    importance: importance,
    lastProgressAt: lastProgressAt,
    createdAt: created ?? now.subtract(const Duration(days: 60)),
    updatedAt: updated ?? now.subtract(const Duration(days: 60)),
  );

  Task done(String id, DateTime at, {String? goalId, String? category}) => Task(
    id: id,
    title: id,
    goalId: goalId,
    category: category,
    status: TaskStatus.done,
    completedAt: at,
    createdAt: at,
    updatedAt: at,
  );

  group('stalled thresholds by horizon', () {
    test('week 3 d, month 10 d, quarter 21 d, year 45 d', () {
      expect(stalledAfterDays(GoalHorizon.week), 3);
      expect(stalledAfterDays(GoalHorizon.month), 10);
      expect(stalledAfterDays(GoalHorizon.quarter), 21);
      expect(stalledAfterDays(GoalHorizon.year), 45);
    });

    for (final (h, n) in [
      (GoalHorizon.week, 3),
      (GoalHorizon.month, 10),
      (GoalHorizon.quarter, 21),
      (GoalHorizon.year, 45),
    ]) {
      test('${h.name}: ${n - 1} quiet days is on track, $n is stalled', () {
        final g = goal('g', horizon: h);
        const p = GoalProgress(
          current: 1,
          target: 10,
          unit: 'x',
          status: GoalProgressStatus.inProgress,
        );
        expect(
          classifyGoal(goal: g, progress: p, quietDays: n - 1),
          HighlightGroup.onTrack,
        );
        expect(
          classifyGoal(goal: g, progress: p, quietDays: n),
          HighlightGroup.stalled,
        );
      });
    }

    test('80 % wins over quiet; paused is never stalled', () {
      final g = goal('g', horizon: GoalHorizon.week);
      const close = GoalProgress(
        current: 8,
        target: 10,
        unit: 'x',
        status: GoalProgressStatus.closeToDone,
      );
      expect(
        classifyGoal(goal: g, progress: close, quietDays: 99),
        HighlightGroup.closeToDone,
      );
      const some = GoalProgress(
        current: 7,
        target: 10,
        unit: 'x',
        status: GoalProgressStatus.inProgress,
      );
      expect(
        classifyGoal(
          goal: goal('p', status: GoalStatus.paused),
          progress: some,
          quietDays: 99,
        ),
        HighlightGroup.onTrack,
      );
    });

    test('groupHighlights: last move from tasks, ticks and lastProgressAt', () {
      final ctx = PeriodContext(
        now: now,
        location: tz.getLocation('Asia/Jerusalem'),
      );
      final goals = [
        goal(
          'done',
          status: GoalStatus.done,
          metric: const FiniteMetric(target: 4, unit: 'x', current: 4),
        ),
        goal(
          'close',
          metric: const FiniteMetric(target: 10, unit: 'x', current: 9),
        ),
        goal(
          'fresh',
          metric: const FiniteMetric(target: 10, unit: 'x', current: 2),
          lastProgressAt: now.subtract(const Duration(days: 2)),
        ),
        goal(
          'quiet',
          metric: const FiniteMetric(target: 10, unit: 'x', current: 2),
          lastProgressAt: now.subtract(const Duration(days: 12)),
        ),
        goal(
          'weekly',
          horizon: GoalHorizon.week,
          metric: const RecurringMetric(quota: 2, unit: 'runs'),
        ),
        goal(
          'gym',
          horizon: GoalHorizon.year,
          metric: const RecurringMetric(quota: 3, unit: 'workouts'),
        ),
      ];
      final tasks = [
        // Two runs this week: the weekly quota is reached.
        done(
          't1',
          DateTime.utc(2026, 11, 2, 6),
          goalId: 'weekly',
          category: metricTickCategory,
        ),
        done('t2', DateTime.utc(2026, 11, 3, 6), goalId: 'weekly'),
        // One workout 20 days ago: quiet, but within a year's 45 days.
        done('t3', now.subtract(const Duration(days: 20)), goalId: 'gym'),
      ];
      final groups = groupHighlights(
        goals: goals,
        tasks: tasks,
        progressOf: (g) => GoalProgress.of(
          g,
          linkedTasks: tasks.where((t) => t.goalId == g.id).toList(),
          period: ctx,
        ),
        now: now,
      );
      List<String> ids(HighlightGroup g) => [
        for (final h in groups[g]!) h.goal.id,
      ];
      expect(ids(HighlightGroup.completed), ['done', 'weekly']);
      expect(ids(HighlightGroup.closeToDone), ['close']);
      expect(ids(HighlightGroup.onTrack), ['fresh', 'gym']);
      expect(ids(HighlightGroup.stalled), ['quiet']);
      expect(groups[HighlightGroup.stalled]!.single.quietDays, 12);
      expect(
        en.highlightsStalledNote(12),
        'Quiet for 12 days. One small step wakes it up.',
      );
    });
  });

  group('weekly recap', () {
    late tz.Location jlm;
    setUpAll(() => jlm = locationFor('Asia/Jerusalem'));

    test('recap week: last week, or this week on its last day', () {
      final tue = recapWeek(PeriodContext(now: now, location: jlm));
      expect(tue.isCurrent, isFalse);
      expect(tue.week.firstDay, DateTime(2026, 10, 25));
      final sat = recapWeek(
        PeriodContext(now: DateTime.utc(2026, 11, 7, 8), location: jlm),
      );
      expect(sat.isCurrent, isTrue);
      expect(sat.week.firstDay, DateTime(2026, 11, 1));
      // Monday weeks end on Sunday.
      final sun = recapWeek(
        PeriodContext(
          now: DateTime.utc(2026, 11, 8, 8),
          location: jlm,
          weekStart: DateTime.monday,
        ),
      );
      expect(sun.isCurrent, isTrue);
      expect(sun.week.firstDay, DateTime(2026, 11, 2));
    });

    WeeklyRecap build() {
      final w = recapWeek(PeriodContext(now: now, location: jlm));
      final inWeek = DateTime.utc(2026, 10, 27, 9);
      return buildWeeklyRecap(
        week: w.week,
        isCurrentWeek: w.isCurrent,
        goals: [
          goal(
            'Workouts',
            metric: const RecurringMetric(quota: 2, unit: 'workouts'),
          ),
          goal(
            'Read',
            metric: const FiniteMetric(
              target: 10,
              unit: 'chapters',
              current: 3,
            ),
            lastProgressAt: inWeek,
          ),
          goal('Run a 10k', status: GoalStatus.done, updated: inWeek),
          goal('Idle'),
          goal(
            'Nutrition',
            metric: const RecurringMetric(
              quota: 2,
              unit: 'days',
              period: MetricPeriod.month,
            ),
          ),
        ],
        tasks: [
          done('a', inWeek, goalId: 'Workouts', category: metricTickCategory),
          done(
            'b',
            inWeek.add(const Duration(days: 1)),
            goalId: 'Workouts',
            category: metricTickCategory,
          ),
          done('real', inWeek),
          // The monthly quota was reached in October's first week, so this
          // week only adds to it: not a hit this week.
          done('n1', DateTime.utc(2026, 10, 2), goalId: 'Nutrition'),
          done('n2', DateTime.utc(2026, 10, 3), goalId: 'Nutrition'),
          done('n3', inWeek, goalId: 'Nutrition'),
          // Next week: not counted.
          done('later', DateTime.utc(2026, 11, 2, 9)),
        ],
        reviews: const [
          ReviewEntry(
            date: '2026-10-27',
            win: 'Sent the thesis outline',
            doneCount: 3,
            movedCount: 2,
          ),
          ReviewEntry(
            date: '2026-10-30',
            win: 'Went to the gym twice',
            doneCount: 2,
            movedCount: 1,
          ),
          ReviewEntry(
            date: '2026-11-01',
            win: 'Next week',
            doneCount: 1,
            movedCount: 4,
          ),
        ],
      );
    }

    test('wins, quotas hit, goals moved, rolled over', () {
      final r = build();
      expect(r.wins, ['Went to the gym twice', 'Sent the thesis outline']);
      expect([for (final h in r.metricHits) h.goal.id], ['Workouts']);
      expect([for (final g in r.completedGoals) g.id], ['Run a 10k']);
      expect(
        [for (final g in r.movedGoals) g.id],
        ['Workouts', 'Read', 'Run a 10k', 'Nutrition'],
      );
      expect(r.doneCount, 2);
      expect(r.rolledOver, 3);
      expect(r.lead, RecapLead.goalCompleted);
    });

    test('a monthly quota crossed during the week is a hit', () {
      final w = recapWeek(PeriodContext(now: now, location: jlm)).week;
      final r = buildWeeklyRecap(
        week: w,
        isCurrentWeek: false,
        goals: [
          goal(
            'Nutrition',
            metric: const RecurringMetric(
              quota: 2,
              unit: 'days',
              period: MetricPeriod.month,
            ),
          ),
        ],
        tasks: [
          done('n1', DateTime.utc(2026, 10, 2), goalId: 'Nutrition'),
          done('n2', DateTime.utc(2026, 10, 28), goalId: 'Nutrition'),
        ],
        reviews: const [],
      );
      expect(r.metricHits.single.count, 2);
      expect(r.lead, RecapLead.metricHit);
      expect(en.recapHeadline(r), '"Nutrition": 2 of 2 days. Right on rhythm.');
    });

    test('share text (EN), leading with the biggest win', () {
      expect(en.recapShareText(build()), '''
My week with Pip (Oct 25 – Oct 31)
You finished "Run a 10k". That's a big one.
Wins: Went to the gym twice · Sent the thesis outline
Quotas hit: Workouts 2/2
Goals that moved: Workouts · Read · Run a 10k · Nutrition
Tasks done: 2
3 tasks moved to another day. That's planning, and it counts.

Sent from Grind''');
    });

    test('share text (HE)', () {
      final text = he.recapShareText(build());
      expect(text, startsWith('השבוע שלי עם פיפ (25 באוק׳ – 31 באוק׳)'));
      expect(text, contains('סיימת את "Run a 10k". זה גדול.'));
      expect(text, contains('3 משימות עברו ליום אחר. זה תכנון, וגם זה נחשב.'));
    });

    test('an empty week is quiet, never "you missed"', () {
      final w = recapWeek(PeriodContext(now: now, location: jlm));
      final r = buildWeeklyRecap(
        week: w.week,
        isCurrentWeek: false,
        goals: const [],
        tasks: const [],
        reviews: const [],
      );
      expect(r.isEmpty, isTrue);
      expect(en.recapHeadline(r), 'A quiet week. Rest counts too.');
      expect(en.recapShareText(r), isNot(contains('miss')));
      expect(en.recapShareText(r), isNot(contains('moved to another day')));
    });
  });
}
