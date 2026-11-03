import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Tuesday 3 Nov 2026, 10:00 in Jerusalem (UTC+2). Weeks start on Sunday.
  final now = DateTime.utc(2026, 11, 3, 8);
  late tz.Location jerusalem;
  late PeriodContext ctx;

  setUpAll(() {
    jerusalem = locationFor('Asia/Jerusalem');
    ctx = PeriodContext(now: now, location: jerusalem);
  });

  /// 23:59 Jerusalem on [d] (y/m/d), as UTC.
  DateTime endOf(int y, int m, int d) => DateTime.utc(y, m, d, 21, 59);

  Milestone ms(
    String id, {
    DateTime? due,
    int order = 0,
    MilestoneStatus status = MilestoneStatus.open,
    String goalId = 'g1',
  }) => Milestone(
    id: id,
    goalId: goalId,
    title: 'Step $id',
    dueAt: due,
    sortOrder: order,
    status: status,
    createdAt: now,
    updatedAt: now,
  );

  Task task(
    String id, {
    String? goalId = 'g1',
    DateTime? start,
    bool done = false,
    String? category,
  }) => Task(
    id: id,
    title: 'Task $id',
    goalId: goalId,
    scheduledStart: start,
    scheduledEnd: start?.add(const Duration(minutes: 30)),
    status: done ? TaskStatus.done : TaskStatus.open,
    category: category,
    createdAt: now,
    updatedAt: now,
  );

  group('suggestedMoveDate (rollover)', () {
    test('not due yet, due today, done or undated: no move', () {
      expect(suggestedMoveDate(ms('a', due: endOf(2026, 11, 10)), ctx), isNull);
      expect(suggestedMoveDate(ms('a', due: endOf(2026, 11, 3)), ctx), isNull);
      expect(
        suggestedMoveDate(
          ms('a', due: endOf(2026, 10, 1), status: MilestoneStatus.done),
          ctx,
        ),
        isNull,
      );
      expect(suggestedMoveDate(ms('a'), ctx), isNull);
    });

    test('yesterday moves to the same weekday next week', () {
      // Mon 2 Nov -> Mon 9 Nov.
      expect(
        suggestedMoveDate(ms('a', due: endOf(2026, 11, 2)), ctx),
        endOf(2026, 11, 9),
      );
    });

    test('exactly a week ago lands a week out, never on today', () {
      expect(
        suggestedMoveDate(ms('a', due: endOf(2026, 10, 27)), ctx),
        endOf(2026, 11, 10),
      );
    });

    test('a month ago lands within the next seven days', () {
      // Thu 1 Oct, 23:59 summer time (UTC+3) -> Thu 5 Nov (UTC+2): the
      // weekday survives the clock change.
      final d = suggestedMoveDate(
        ms('a', due: DateTime.utc(2026, 10, 1, 20, 59)),
        ctx,
      )!;
      expect(d, endOf(2026, 11, 5));
    });

    test('just before local midnight still counts as that day', () {
      // 23:30 Jerusalem on Nov 2 is 21:30 UTC: before today.
      expect(
        suggestedMoveDate(ms('a', due: DateTime.utc(2026, 11, 2, 21, 30)), ctx),
        endOf(2026, 11, 9),
      );
    });
  });

  group('nextScheduledTask', () {
    test('the soonest open block that has not ended, for this goal', () {
      final t = nextScheduledTask(
        [
          task('past', start: now.subtract(const Duration(hours: 2))),
          task('running', start: now.subtract(const Duration(minutes: 10))),
          task('later', start: now.add(const Duration(hours: 5))),
          task('done', start: now.add(const Duration(hours: 1)), done: true),
          task('other', goalId: 'g2', start: now.add(const Duration(hours: 1))),
          task('unplanned'),
          task(
            'tick',
            start: now.add(const Duration(minutes: 1)),
            category: metricTickCategory,
          ),
        ],
        'g1',
        now,
      );
      expect(t?.id, 'running');
    });

    test('null when nothing is scheduled', () {
      expect(nextScheduledTask([task('a')], 'g1', now), isNull);
    });
  });

  test('buildMilestonePlan: order, progress, next, tasks', () {
    final plan = buildMilestonePlan(
      milestones: [
        ms('c', order: 2, due: endOf(2026, 12, 1)),
        ms('a', order: 0, status: MilestoneStatus.done),
        ms('b', order: 1, due: endOf(2026, 11, 2)),
        ms('x', goalId: 'g2'),
      ],
      links: [
        MilestoneTaskLink(taskId: 't1', milestoneId: 'b', createdAt: now),
        MilestoneTaskLink(taskId: 't2', milestoneId: 'b', createdAt: now),
        MilestoneTaskLink(taskId: 'gone', milestoneId: 'b', createdAt: now),
      ],
      tasks: [
        task('t1', done: true),
        task('t2', start: now.add(const Duration(days: 1))),
      ],
      goalId: 'g1',
      ctx: ctx,
    );
    expect(plan.items.map((v) => v.milestone.id), ['a', 'b', 'c']);
    expect((plan.done, plan.total), (1, 3));
    expect(plan.fraction, closeTo(1 / 3, 1e-9));
    expect(plan.next!.milestone.id, 'b');
    expect(plan.next!.moved, isTrue);
    expect(plan.next!.suggestedDueAt, endOf(2026, 11, 9));
    expect(plan.next!.tasks.map((t) => t.id), ['t2', 't1']);
    expect(plan.next!.tasksDone, 1);
    expect(plan.items.last.moved, isFalse);
    expect(plan.nextTask?.id, 't2');
  });

  group('MilestoneActions via providers', () {
    late ProviderContainer c;
    late InMemoryTaskRepository tasks;

    setUp(() {
      tasks = InMemoryTaskRepository();
      c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          taskRepositoryProvider.overrideWithValue(tasks),
          goalRepositoryProvider.overrideWithValue(
            InMemoryGoalRepository(
              seed: [
                GoalRecord(
                  id: 'g1',
                  title: 'PM course',
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
    });

    Future<MilestonePlan> plan() async {
      final sub = c.listen(goalMilestonePlanProvider('g1'), (_, _) {});
      addTearDown(sub.close);
      await c.read(milestonesProvider.future);
      await c.read(milestoneLinksProvider.future);
      await c.read(tasksProvider.future);
      await pumpEventQueue();
      return c.read(goalMilestonePlanProvider('g1'));
    }

    test('add appends; reorder renumbers; toggle and delete', () async {
      final a = c.read(milestoneActionsProvider);
      final m1 = await a.add(goalId: 'g1', title: 'One');
      final m2 = await a.add(goalId: 'g1', title: 'Two');
      final m3 = await a.add(goalId: 'g1', title: 'Three');
      expect([m1, m2, m3].map((m) => m.sortOrder), [0, 1, 2]);

      await a.reorder(m3, -1);
      expect((await plan()).items.map((v) => v.milestone.title), [
        'One',
        'Three',
        'Two',
      ]);
      // Past the top stops at the top.
      final three = (await plan()).items[1].milestone;
      await a.reorder(three, -5);
      expect((await plan()).items.map((v) => v.milestone.title), [
        'Three',
        'One',
        'Two',
      ]);

      final done = await a.toggleDone(three);
      expect((done.isDone, done.completedAt), (true, now));
      expect(
        ((await plan()).done, (await plan()).next!.milestone.title),
        (1, 'One'),
      );
      final reopened = await a.toggleDone(done);
      expect((reopened.isDone, reopened.completedAt), (false, null));

      await a.edit(reopened, title: 'Three!', dueAt: endOf(2026, 12, 24));
      final edited = (await plan()).items.first.milestone;
      expect((edited.title, edited.dueAt), ('Three!', endOf(2026, 12, 24)));

      await a.delete(edited);
      expect((await plan()).total, 2);
    });

    test('acceptMove takes the suggested date, once', () async {
      final a = c.read(milestoneActionsProvider);
      final m = await a.add(
        goalId: 'g1',
        title: 'Slipped',
        dueAt: endOf(2026, 11, 2),
      );
      expect((await plan()).items.single.moved, isTrue);
      await a.acceptMove(m);
      final after = (await plan()).items.single;
      expect(after.milestone.dueAt, endOf(2026, 11, 9));
      expect(after.moved, isFalse);
      // Not moved any more: a second accept changes nothing.
      await a.acceptMove(after.milestone);
      expect((await plan()).items.single.milestone.dueAt, endOf(2026, 11, 9));
    });

    test(
      'addTask: this week and next week, linked to goal and milestone',
      () async {
        final a = c.read(milestoneActionsProvider);
        final m = await a.add(goalId: 'g1', title: 'Module 3');
        final t1 = await a.addTask(m, title: 'Lesson 7', estimatedMinutes: 60);
        final t2 = await a.addTask(
          m,
          title: 'Lesson 8',
          week: MilestoneTaskWeek.nextWeek,
        );
        // Week of Sun 1 Nov - Sat 7 Nov in Jerusalem.
        expect((t1.goalId, t1.estimatedMinutes), ('g1', 60));
        expect(t1.dueAt, endOf(2026, 11, 7));
        expect(t1.notBefore, isNull);
        expect(t2.dueAt, endOf(2026, 11, 14));
        // Sun 8 Nov 00:00 Jerusalem.
        expect(t2.notBefore, DateTime.utc(2026, 11, 7, 22));

        final p = await plan();
        expect(p.items.single.tasks.map((t) => t.title), [
          'Lesson 7',
          'Lesson 8',
        ]);
        expect(
          c.read(goalLinkedTasksProvider('g1')).map((t) => t.id),
          containsAll([t1.id, t2.id]),
        );

        await a.unlinkTask(t1);
        expect((await plan()).items.single.tasks.map((t) => t.id), [t2.id]);
        // Still the goal's task.
        expect((await tasks.getById(t1.id))!.goalId, 'g1');
      },
    );

    test('deleting the goal deletes its milestones', () async {
      final a = c.read(milestoneActionsProvider);
      await a.add(goalId: 'g1', title: 'One');
      await a.add(goalId: 'g2', title: 'Elsewhere');
      final goal = (await c.read(goalRepositoryProvider).getById('g1'))!;
      await c.read(goalActionsProvider).delete(goal);
      final left = await c.read(milestoneRepositoryProvider).getAll();
      expect(left.map((m) => m.title), ['Elsewhere']);
    });
  });
}
