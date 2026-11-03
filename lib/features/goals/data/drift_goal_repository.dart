import 'package:drift/drift.dart';

import '../../../core/core.dart';
import '../../../core/data/database.dart';
import '../../../core/data/mappers.dart';
import '../domain/goal_metric.dart';
import '../domain/goal_record.dart';
import '../domain/goal_repository.dart';

/// [GoalRepository] on the `goals` table (schema v3). Every field of a
/// [GoalRecord] is a column: nothing is kept in memory.
class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  $GoalsTable get _t => _db.goals;

  SimpleSelectStatement<$GoalsTable, GoalRow> _live() => _db.select(_t)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt),
      (t) => OrderingTerm(expression: t.id),
    ]);

  GoalRecord _map(GoalRow row) => goalRecordFromCore(row.toDomain());

  @override
  Future<List<GoalRecord>> getAll() async =>
      (await _live().get()).map(_map).toList();

  @override
  Future<GoalRecord?> getById(String id) async {
    final q = _db.select(_t)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await q.getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<void> upsert(GoalRecord goal) =>
      _db.into(_t).insertOnConflictUpdate(goalRecordToCore(goal).toCompanion());

  @override
  Future<void> delete(String id) async {
    final now = toMillis(_clock.now().toUtc());
    await (_db.update(_t)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Stream<List<GoalRecord>> watchAll() =>
      _live().watch().map((rows) => rows.map(_map).toList());

  @override
  Stream<GoalRecord?> watchById(String id) =>
      watchAll().map((all) => findGoal(all, id)).distinct();
}

/// The full core [Goal] for [goal]: [GoalRecord.toCore] plus the target
/// date, status, notes and the metric flattened into the `metric*` fields.
Goal goalRecordToCore(GoalRecord goal) {
  final core = goal.toCore().copyWith(
    targetDate: goal.targetDate,
    status: goal.status,
    notes: goal.notes,
  );
  return switch (goal.metric) {
    null => core,
    final FiniteMetric m => core.copyWith(
      metricKind: 'finite',
      metricTarget: m.target,
      metricUnit: m.unit,
      metricCurrent: m.current,
      metricSource: m.source.name,
    ),
    final RecurringMetric m => core.copyWith(
      metricKind: 'recurring',
      metricTarget: m.quota,
      metricUnit: m.unit,
      metricPeriod: m.period.name,
    ),
  };
}

/// The [GoalRecord] stored in [g]. An unknown metric kind reads as no
/// metric rather than failing the whole list.
GoalRecord goalRecordFromCore(Goal g) {
  final kind = g.metricKind;
  final target = g.metricTarget;
  final metric = kind == null || target == null || target <= 0
      ? null
      : GoalMetric.fromJson({
          'kind': kind,
          'target': target,
          'unit': g.metricUnit,
          'current': g.metricCurrent,
          'source': g.metricSource,
          'period': g.metricPeriod,
        });
  return GoalRecord.fromCore(
    g,
    GoalExtras(
      targetDate: g.targetDate,
      status: g.status,
      notes: g.notes,
      metric: metric,
    ),
  );
}
