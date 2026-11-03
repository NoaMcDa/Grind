import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/features/goals/data/drift_goal_repository.dart';
import 'package:grind/features/goals/data/drift_milestone_repository.dart';
import 'package:grind/features/goals/goals.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  final clock = FixedClock(now);

  Milestone ms(
    String id, {
    String goalId = 'g1',
    int order = 0,
    Duration age = Duration.zero,
  }) => Milestone(
    id: id,
    goalId: goalId,
    title: 'Step $id',
    dueAt: DateTime.utc(2026, 12, 1, 21, 59),
    sortOrder: order,
    createdAt: now.add(age),
    updatedAt: now.add(age),
  );

  /// [make] returns the repository and a function that adds a task row.
  void contract(
    String name,
    Future<(MilestoneRepository, Future<void> Function(String))> Function()
    make,
  ) {
    group(name, () {
      late MilestoneRepository repo;
      late Future<void> Function(String) addTask;
      setUp(() async => (repo, addTask) = await make());

      test('upsert, order, get, soft delete', () async {
        await repo.upsertAll([
          ms('c', order: 1),
          ms('b', order: 0, age: const Duration(minutes: 1)),
          ms('a', order: 0),
          ms('x', goalId: 'g2'),
        ]);
        expect((await repo.getAll()).map((m) => m.id), ['a', 'b', 'c', 'x']);

        final a = (await repo.getById('a'))!;
        expect(a, ms('a'));
        await repo.upsert(
          a.copyWith(
            status: MilestoneStatus.done,
            completedAt: now,
            dueAt: null,
          ),
        );
        final done = (await repo.getById('a'))!;
        expect((done.isDone, done.completedAt, done.dueAt), (true, now, null));

        await repo.delete('b');
        expect(await repo.getById('b'), isNull);
        expect((await repo.getAll()).map((m) => m.id), ['a', 'c', 'x']);
      });

      test('task links: link, relink, unlink, dropped on delete', () async {
        await repo.upsertAll([ms('a'), ms('b', order: 1)]);
        await addTask('t1');
        await addTask('t2');
        await repo.linkTask('t1', 'a');
        await repo.linkTask('t2', 'a');
        await repo.linkTask('t2', 'b');
        var links = await repo.watchLinks().first;
        expect(
          {for (final l in links) l.taskId: l.milestoneId},
          {'t1': 'a', 't2': 'b'},
        );
        await repo.unlinkTask('t1');
        await repo.delete('b');
        links = await repo.watchLinks().first;
        expect(links, isEmpty);
      });

      test('watchAll emits the current list, then changes', () async {
        await repo.upsert(ms('a'));
        final seen = <List<String>>[];
        final sub = repo.watchAll().listen(
          (all) => seen.add([for (final m in all) m.id]),
        );
        await pumpEventQueue();
        await repo.upsert(ms('b', order: 1));
        await pumpEventQueue();
        await sub.cancel();
        expect(seen.first, ['a']);
        expect(seen.last, ['a', 'b']);
      });
    });
  }

  contract('InMemoryMilestoneRepository', () async {
    return (
      InMemoryMilestoneRepository(clock: clock) as MilestoneRepository,
      (String _) async {},
    );
  });

  contract('DriftMilestoneRepository', () async {
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    final goals = DriftGoalRepository(db, clock: clock);
    for (final id in ['g1', 'g2']) {
      await goals.upsert(
        GoalRecord(id: id, title: id, createdAt: now, updatedAt: now),
      );
    }
    final tasks = DriftTaskRepository(db, clock: clock);
    return (
      DriftMilestoneRepository(db, clock: clock) as MilestoneRepository,
      (String id) =>
          tasks.upsert(Task(id: id, title: id, createdAt: now, updatedAt: now)),
    );
  });

  test('Drift: a hard-deleted task drops its link', () async {
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    await DriftGoalRepository(
      db,
    ).upsert(GoalRecord(id: 'g1', title: 'g', createdAt: now, updatedAt: now));
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 't1',
            title: 't',
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
    final repo = DriftMilestoneRepository(db, clock: clock);
    await repo.upsert(ms('a'));
    await repo.linkTask('t1', 'a');
    await db.delete(db.tasks).go();
    expect(await repo.watchLinks().first, isEmpty);
  });
}
