import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/features/goals/data/drift_goal_repository.dart';
import 'package:grind/features/goals/goals.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);

  GoalRecord goal(String id, {Duration age = Duration.zero}) => GoalRecord(
    id: id,
    title: 'Goal $id',
    area: 'learning',
    horizon: GoalHorizon.quarter,
    importance: 4,
    targetDate: DateTime.utc(2026, 12, 31, 21, 59),
    notes: 'notes $id',
    metric: const FiniteMetric(target: 12, unit: 'lessons', current: 3),
    createdAt: now.add(age),
    updatedAt: now.add(age),
  );

  void contract(String name, GoalRepository Function() make) {
    group(name, () {
      late GoalRepository repo;
      setUp(() => repo = make());

      test('upsert, get, update, soft delete', () async {
        await repo.upsert(goal('b', age: const Duration(minutes: 1)));
        await repo.upsert(goal('a'));
        expect((await repo.getAll()).map((g) => g.id), ['a', 'b']);

        final a = (await repo.getById('a'))!;
        expect(a.title, 'Goal a');
        expect(a.area, 'learning');
        expect(a.horizon, GoalHorizon.quarter);
        expect(a.importance, 4);
        expect(a.targetDate, DateTime.utc(2026, 12, 31, 21, 59));
        expect(a.notes, 'notes a');
        expect(
          a.finite,
          const FiniteMetric(target: 12, unit: 'lessons', current: 3),
        );

        await repo.upsert(
          a.copyWith(
            title: 'Renamed',
            status: GoalStatus.paused,
            metric: const FiniteMetric(target: 12, unit: 'lessons', current: 9),
          ),
        );
        final updated = (await repo.getById('a'))!;
        expect(updated.title, 'Renamed');
        expect(updated.status, GoalStatus.paused);
        expect(updated.finite!.current, 9);

        await repo.delete('a');
        expect(await repo.getById('a'), isNull);
        expect((await repo.getAll()).map((g) => g.id), ['b']);
      });

      test('watchAll emits the current list, then changes', () async {
        await repo.upsert(goal('a'));
        final stream = repo.watchAll();
        expect(
          stream,
          emitsInOrder([
            predicate<List<GoalRecord>>((l) => l.length == 1),
            predicate<List<GoalRecord>>((l) => l.length == 2),
          ]),
        );
        await pumpEventQueue();
        await repo.upsert(goal('b', age: const Duration(minutes: 1)));
      });

      test('watchById follows one goal until it is deleted', () async {
        await repo.upsert(goal('a'));
        final stream = repo.watchById('a');
        expect(
          stream,
          emitsInOrder([
            predicate<GoalRecord?>((g) => g?.title == 'Goal a'),
            predicate<GoalRecord?>((g) => g?.title == 'New'),
            isNull,
          ]),
        );
        await pumpEventQueue();
        await repo.upsert(
          goal('a').copyWith(
            title: 'New',
            updatedAt: now.add(const Duration(seconds: 1)),
          ),
        );
        await pumpEventQueue();
        await repo.delete('a');
      });
    });
  }

  contract(
    'InMemoryGoalRepository',
    () => InMemoryGoalRepository(clock: FixedClock(now)),
  );

  contract('DriftGoalRepository', () {
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    return DriftGoalRepository(db, clock: FixedClock(now));
  });

  test('Drift row holds the core fields the scheduler reads', () async {
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    final repo = DriftGoalRepository(db, clock: FixedClock(now));
    await repo.upsert(goal('a'));
    final row = await db.select(db.goals).getSingle();
    expect(row.title, 'Goal a');
    expect(row.importance, closeTo(0.8, 1e-9));
    expect(row.progress, closeTo(0.25, 1e-9));
    expect(row.horizon, GoalHorizon.quarter);
  });

  test('Drift row holds every goal field: nothing stays in memory', () async {
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    await DriftGoalRepository(db, clock: FixedClock(now)).upsert(
      goal('a').copyWith(
        status: GoalStatus.paused,
        metric: const FiniteMetric(
          target: 12,
          unit: 'lessons',
          current: 3,
          source: MetricSource.linkedTasks,
        ),
      ),
    );
    final row = await db.select(db.goals).getSingle();
    expect(
      row.targetDate,
      DateTime.utc(2026, 12, 31, 21, 59).millisecondsSinceEpoch,
    );
    expect(row.status, GoalStatus.paused);
    expect(row.notes, 'notes a');
    expect(row.metricKind, 'finite');
    expect(row.metricTarget, 12);
    expect(row.metricUnit, 'lessons');
    expect(row.metricCurrent, 3);
    expect(row.metricSource, 'linkedTasks');
    expect(row.metricPeriod, isNull);

    // A second repository on the same database (a cold start) reads it all.
    final back = (await DriftGoalRepository(db).getById('a'))!;
    expect(back.status, GoalStatus.paused);
    expect(back.notes, 'notes a');
    expect(back.targetDate, DateTime.utc(2026, 12, 31, 21, 59));
    expect(
      back.metric,
      const FiniteMetric(
        target: 12,
        unit: 'lessons',
        current: 3,
        source: MetricSource.linkedTasks,
      ),
    );

    // Removing the metric clears the columns.
    await DriftGoalRepository(db).upsert(back.copyWith(metric: null));
    expect((await db.select(db.goals).getSingle()).metricKind, isNull);
    expect((await DriftGoalRepository(db).getById('a'))!.metric, isNull);
  });
}
