import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/goals/data/drift_goal_repository.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(ensureTimeZones);

  tz.Location jlm() => tz.getLocation('Asia/Jerusalem');
  PeriodContext ctx(DateTime now, {int weekStart = DateTime.sunday}) =>
      PeriodContext(now: now, location: jlm(), weekStart: weekStart);

  group('period bounds in Asia/Jerusalem', () {
    // Tue 3 Nov 2026, 10:00 local (UTC+2 after the October change).
    final tue = DateTime.utc(2026, 11, 3, 8);

    test('a Sunday week starts on Sunday midnight local', () {
      final b = periodOf(MetricPeriod.week, ctx(tue));
      expect(b.start.toUtc(), DateTime.utc(2026, 10, 31, 22));
      expect(b.end.toUtc(), DateTime.utc(2026, 11, 7, 22));
      expect(b.firstDay, DateTime(2026, 11, 1));
      expect(b.lastDay, DateTime(2026, 11, 7));
    });

    test('a Monday week starts on Monday midnight local', () {
      final b = periodOf(
        MetricPeriod.week,
        ctx(tue, weekStart: DateTime.monday),
      );
      expect(b.start.toUtc(), DateTime.utc(2026, 11, 1, 22));
      expect(b.firstDay, DateTime(2026, 11, 2));
      expect(b.lastDay, DateTime(2026, 11, 8));
    });

    test('the boundary is local midnight, not UTC midnight', () {
      // Sat 31 Oct 23:30 local is still last week; 00:30 Sunday is new.
      final sat = periodOf(
        MetricPeriod.week,
        ctx(DateTime.utc(2026, 10, 31, 21, 30)),
      );
      final sun = periodOf(
        MetricPeriod.week,
        ctx(DateTime.utc(2026, 10, 31, 22, 30)),
      );
      expect(sat.firstDay, DateTime(2026, 10, 25));
      expect(sun.firstDay, DateTime(2026, 11, 1));
      expect(sat.shift(1), sun);
      // On Monday start both instants are inside the week of Oct 26.
      expect(
        periodOf(
          MetricPeriod.week,
          ctx(DateTime.utc(2026, 10, 31, 22, 30), weekStart: DateTime.monday),
        ).firstDay,
        DateTime(2026, 10, 26),
      );
    });

    test('a week across the autumn DST change is 169 hours', () {
      // Israel leaves summer time on Sun 25 Oct 2026.
      final b = periodOf(MetricPeriod.week, ctx(DateTime.utc(2026, 10, 27, 9)));
      expect(b.firstDay, DateTime(2026, 10, 25));
      expect(b.start.hour, 0);
      expect(b.end.hour, 0);
      expect(b.end.difference(b.start), const Duration(hours: 169));
    });

    test('a week across the spring DST change is 167 hours', () {
      // Summer time starts on Fri 27 Mar 2026.
      final b = periodOf(
        MetricPeriod.week,
        ctx(DateTime.utc(2026, 3, 25, 9), weekStart: DateTime.monday),
      );
      expect(b.firstDay, DateTime(2026, 3, 23));
      expect(b.end.difference(b.start), const Duration(hours: 167));
      expect(b.shift(1).start.hour, 0);
    });

    test('months start on the 1st and shift across the year', () {
      final b = periodOf(MetricPeriod.month, ctx(tue));
      expect(b.firstDay, DateTime(2026, 11, 1));
      expect(b.lastDay, DateTime(2026, 11, 30));
      expect(b.shift(-1).firstDay, DateTime(2026, 10, 1));
      expect(b.shift(2).firstDay, DateTime(2027, 1, 1));
      expect(b.shift(-10).firstDay, DateTime(2026, 1, 1));
    });
  });

  group('recurring history', () {
    final now = DateTime.utc(2026, 11, 3, 8);
    const metric = RecurringMetric(quota: 3, unit: 'workouts');

    Task done(String id, DateTime at, {String goalId = 'g'}) => Task(
      id: id,
      title: id,
      goalId: goalId,
      status: TaskStatus.done,
      completedAt: at,
      createdAt: at,
      updatedAt: at,
    );

    test('8 periods, oldest first, with gaps kept as data', () {
      final c = ctx(now);
      final cur = periodOf(MetricPeriod.week, c);
      DateTime inWeek(int back) =>
          cur.shift(-back).start.toUtc().add(const Duration(days: 1, hours: 9));
      final tasks = [
        done('a', inWeek(0)),
        done('b', inWeek(0)),
        done('c', inWeek(2)),
        done('d', inWeek(2)),
        done('e', inWeek(2)),
        done('f', inWeek(5)),
        done('x', inWeek(0), goalId: 'other'),
        Task(
          id: 'open',
          title: 'open',
          goalId: 'g',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final h = recurringHistory(
        goalId: 'g',
        metric: metric,
        tasks: tasks,
        ctx: c,
        since: cur.shift(-6).start.toUtc(),
      );
      expect(h, hasLength(8));
      expect(h.last.bounds, cur);
      expect(h.first.bounds, cur.shift(-7));
      expect([for (final p in h) p.count], [0, 0, 1, 0, 0, 3, 0, 2]);
      // Week -7 ended before the goal existed: untracked. Quiet weeks
      // after it are tracked zeros, not breaks.
      expect(
        [for (final p in h) p.tracked],
        [false, true, true, true, true, true, true, true],
      );
      expect(
        [for (final p in h) p.hit],
        [false, false, false, false, false, true, false, false],
      );
    });

    test('progress counts the current period; a new period starts at 0', () {
      final g = GoalRecord(
        id: 'g',
        title: 'Workouts',
        metric: metric,
        createdAt: now,
        updatedAt: now,
      );
      final tasks = [
        done('a', DateTime.utc(2026, 11, 2, 6)),
        done('b', DateTime.utc(2026, 11, 3, 6)),
        done('c', DateTime.utc(2026, 11, 3, 7)),
      ];
      final p = GoalProgress.of(g, linkedTasks: tasks, period: ctx(now));
      expect(p.current, 3);
      expect(p.target, 3);
      expect(p.isRecurring, isTrue);
      expect(p.isCompleted, isTrue);
      final next = GoalProgress.of(
        g,
        linkedTasks: tasks,
        period: ctx(DateTime.utc(2026, 11, 8, 8)),
      );
      expect(next.current, 0);
      expect(next.status, GoalProgressStatus.notStarted);
      // A new period is not a crossing, either way.
      expect(GoalProgress.milestoneBetween(p, next), isNull);
      expect(GoalProgress.milestoneBetween(next, p), isNull);
    });

    test('metricHit fires only when the quota is reached in one period', () {
      final g = GoalRecord(
        id: 'g',
        title: 'Workouts',
        metric: metric,
        createdAt: now,
        updatedAt: now,
      );
      final two = [
        done('a', DateTime.utc(2026, 11, 2, 6)),
        done('b', DateTime.utc(2026, 11, 3, 6)),
      ];
      final three = [...two, done('c', DateTime.utc(2026, 11, 3, 7))];
      final four = [...three, done('d', DateTime.utc(2026, 11, 3, 7, 30))];
      GoalProgress at(List<Task> t) =>
          GoalProgress.of(g, linkedTasks: t, period: ctx(now));
      expect(
        GoalProgress.milestoneBetween(at(two), at(three)),
        GoalMilestone.metricHit,
      );
      expect(GoalProgress.milestoneBetween(at(three), at(four)), isNull);
      expect(GoalProgress.milestoneBetween(at(three), at(two)), isNull);
    });
  });

  group('storage', () {
    test('a recurring metric round-trips through the core row', () {
      final t = DateTime.utc(2026, 11, 3);
      final g = GoalRecord(
        id: 'g',
        title: 'Nutrition plan',
        metric: const RecurringMetric(
          quota: 5,
          unit: 'days',
          period: MetricPeriod.month,
        ),
        createdAt: t,
        updatedAt: t,
      );
      final core = goalRecordToCore(g);
      expect(core.metricKind, 'recurring');
      expect(core.metricTarget, 5);
      expect(core.metricPeriod, 'month');
      expect(goalRecordFromCore(core).metric, g.metric);
      expect(
        GoalMetric.fromJson(g.metric!.toJson()),
        const RecurringMetric(
          quota: 5,
          unit: 'days',
          period: MetricPeriod.month,
        ),
      );
    });
  });

  group('GoalActions on a recurring goal', () {
    final now = DateTime.utc(2026, 11, 3, 8);
    final goal = GoalRecord(
      id: 'g',
      title: 'Workouts',
      metric: const RecurringMetric(quota: 2, unit: 'workouts'),
      createdAt: now,
      updatedAt: now,
    );

    ProviderContainer make(InMemoryTaskRepository tasks) {
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          goalRepositoryProvider.overrideWithValue(
            InMemoryGoalRepository(seed: [goal], clock: FixedClock(now)),
          ),
          taskRepositoryProvider.overrideWithValue(tasks),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      '+1 adds a hidden tick, returns metricHit at the quota, undo',
      () async {
        final tasks = InMemoryTaskRepository();
        final c = make(tasks);
        final actions = c.read(goalActionsProvider);
        expect(await actions.increment(goal), isNull);
        expect(await actions.increment(goal), GoalMilestone.metricHit);
        final all = await tasks.getAll();
        expect(all, hasLength(2));
        expect(all.every(isMetricTick), isTrue);
        expect(all.every((t) => t.isDone && t.goalId == 'g'), isTrue);
        expect(withoutMetricTicks(all), isEmpty);
        expect(await actions.undoTick(goal), isTrue);
        expect((await tasks.getAll()).length, 1);
        expect(await actions.undoTick(goal), isTrue);
        expect(await actions.undoTick(goal), isFalse);
      },
    );

    test('ticks never show in the linked task list', () async {
      final tasks = InMemoryTaskRepository();
      final c = make(tasks);
      final sub = c.listen(goalLinkedTasksProvider('g'), (_, _) {});
      addTearDown(sub.close);
      c.listen(tasksProvider, (_, _) {});
      c.listen(goalProgressProvider('g'), (_, _) {});
      await pumpEventQueue();
      await c.read(goalActionsProvider).increment(goal);
      await pumpEventQueue();
      expect(c.read(goalLinkedTasksProvider('g')), isEmpty);
      expect(c.read(goalTasksProvider('g')), hasLength(1));
      expect(c.read(goalProgressProvider('g')).current, 1);
    });

    test('milestone events: metricHit from a task ticked anywhere', () async {
      final linked = Task(
        id: 'run',
        title: 'Run',
        goalId: 'g',
        createdAt: now,
        updatedAt: now,
      );
      final tasks = InMemoryTaskRepository([linked]);
      final c = make(tasks);
      final events = <GoalMilestoneEvent>[];
      c.listen(goalMilestoneEventsProvider, (_, next) {
        next.whenData(events.add);
      });
      await pumpEventQueue();
      await c.read(goalActionsProvider).increment(goal);
      await pumpEventQueue();
      expect(events, isEmpty);
      // Completed from Today, not from the goal screen.
      unawaited(
        tasks.upsert(
          linked.copyWith(
            status: TaskStatus.done,
            completedAt: now,
            updatedAt: now,
          ),
        ),
      );
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.single.milestone, GoalMilestone.metricHit);
      expect(events.single.title, 'Workouts');
      expect(events.single.progress.current, 2);
    });
  });
}
