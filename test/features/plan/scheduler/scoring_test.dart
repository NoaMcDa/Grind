import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

void main() {
  final now = at(0, 8);
  const stats = UserStats();
  const w = SchedulerWeights();
  double s(Task t, [Goal? g]) => score(t, g, now, stats, w, 6);

  group('score', () {
    test('due tomorrow outranks due in a month at equal importance', () {
      expect(
        s(task('soon', due: at(1, 17))),
        greaterThan(s(task('later', due: at(30, 17)))),
      );
    });

    test('a nice-to-have does not beat a must-do due today', () {
      final mustToday = task('must', priority: 1, due: at(0, 17));
      expect(s(mustToday), greaterThan(s(task('nice', priority: 3))));
      // Even with an important, stalled goal in progress behind it.
      final dream = goal(
        'g',
        'Dream',
        importance: 0.9,
        progress: 0.5,
        lastProgressAt: at(-10, 9),
      );
      expect(
        s(mustToday),
        greaterThan(s(task('nice', priority: 3, goalId: 'g'), dream)),
      );
    });

    test('a 15-minute task ranks above a 3-hour task at equal urgency', () {
      // Both undated: urgency 0 for both.
      expect(
        s(task('quick', minutes: 15)),
        greaterThan(s(task('long', minutes: 180))),
      );
      // Both overdue: urgency 1 for both.
      expect(
        s(task('quick', minutes: 15, due: at(0, 7))),
        greaterThan(s(task('long', minutes: 180, due: at(0, 7)))),
      );
    });

    test('terms follow the research pseudocode', () {
      final g = goal(
        'g',
        'G',
        importance: 0.8,
        progress: 0.5,
        lastProgressAt: at(-8, 9),
      );
      final b = scoreBreakdown(
        task('t', minutes: 60, priority: 1, due: at(3, 8), goalId: 'g'),
        g,
        now,
        stats,
        w,
        6,
      );
      // slack = 3 − 1/6; urgency = 1 − slack/7.
      expect(b.urgency, closeTo(1 - (3 - 1 / 6) / 7, 1e-9));
      expect(b.importance, 0.8);
      expect(b.priority, 1.0);
      expect(b.momentum, 0.2);
      expect(b.stalled, 0.15);
      expect(b.perMinute, closeTo((b.urgency + 0.8) / 60, 1e-9));
      expect(
        b.total,
        closeTo(
          0.4 * b.urgency + 0.25 * 0.8 + 0.2 + 0.2 + 0.15 + 0.15 * b.perMinute,
          1e-9,
        ),
      );
    });

    test('no goal means importance 0.5 and no momentum', () {
      final b = scoreBreakdown(task('t'), null, now, stats, w, 6);
      expect(b.importance, 0.5);
      expect(b.momentum, 0);
      expect(b.stalled, 0);
      expect(b.urgency, 0); // undated: 14 days of slack
    });

    test('custom weights change the order, not the scheduler', () {
      final quick = task('quick', minutes: 15);
      final must = task('must', minutes: 120, priority: 1);
      expect(s(must), greaterThan(s(quick)));
      const quickLover = SchedulerWeights(priority: 0, quickWin: 10);
      expect(
        score(quick, null, now, stats, quickLover, 6),
        greaterThan(score(must, null, now, stats, quickLover, 6)),
      );
    });
  });

  group('duration stats gate', () {
    DurationStat stat(double median, int n) =>
        DurationStat(median: median, n: n);

    test('fewer than 5 samples: ratio 1.0', () {
      final st = UserStats(durationRatioByCategory: {'study': stat(2, 4)});
      expect(durationRatio('study', st), 1.0);
      expect(
        adjustedMinutes(task('t', minutes: 60, category: 'study'), st),
        60,
      );
    });

    test('5 or more samples: median applied, clamped to 0.5–3.0', () {
      final st = UserStats(
        durationRatioByCategory: {
          'study': stat(1.5, 5),
          'admin': stat(0.2, 9),
          'thesis': stat(7, 12),
        },
      );
      expect(
        adjustedMinutes(task('a', minutes: 60, category: 'study'), st),
        90,
      );
      expect(
        adjustedMinutes(task('b', minutes: 60, category: 'admin'), st),
        30,
      );
      expect(
        adjustedMinutes(task('c', minutes: 60, category: 'thesis'), st),
        180,
      );
      expect(adjustedMinutes(task('d', minutes: 60), st), 60);
      expect(adjustedMinutes(task('e', minutes: 60, category: 'gym'), st), 60);
    });

    test('one 10x outlier barely moves the median', () {
      final base = [1.1, 1.2, 1.0, 1.3, 1.2, 1.1];
      final before = DurationStat.fromRatios(base);
      final after = DurationStat.fromRatios([...base, 10]);
      expect(before.n, 6);
      expect(after.n, 7);
      expect(before.median, closeTo(1.15, 1e-9));
      expect(after.median, 1.2); // one rank up, nowhere near 10
      final mean = [...base, 10].reduce((a, b) => a + b) / 7;
      expect(mean, greaterThan(2.4));
    });

    test('running median uses the last 10 samples', () {
      final st = DurationStat.fromRatios([
        ...List.filled(10, 3.0),
        ...List.filled(10, 1.0),
      ]);
      expect(st.median, 1.0);
      expect(st.n, 20);
      expect(DurationStat.fromRatios(const []).median, 1.0);
    });

    test('stats feed the plan: a 1.5x category gets a longer block', () {
      final st = UserStats(durationRatioByCategory: {'study': stat(1.5, 6)});
      final p = plan(
        tasks: [task('t', minutes: 60, category: 'study')],
        goals: const {},
        events: const [],
        prefs: prefsFixture,
        now: at(0, 8),
        stats: st,
        horizonEnd: at(1, 0),
      );
      expect(p.placed.single.minutes, 90);
    });
  });
}
