import 'package:drift/drift.dart';

import '../../../core/core.dart';
import '../../../core/data/database.dart';
import '../../../core/data/mappers.dart';
import '../domain/goal_record.dart';
import '../domain/goal_repository.dart';
import 'goal_extras_store.dart';

/// [GoalRepository] on the existing `goals` table (schema v2).
///
/// The table has title, area, horizon, importance, progress and
/// lastProgressAt; the rest of a goal ([GoalExtras]) goes to [extras].
/// Extras are written before the row, so the row's `watch()` emission
/// already sees them.
class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(
    this._db, {
    GoalExtrasStore? extras,
    Clock clock = const SystemClock(),
  }) : _extras = extras ?? InMemoryGoalExtrasStore(),
       _clock = clock;

  final AppDatabase _db;
  final GoalExtrasStore _extras;
  final Clock _clock;

  $GoalsTable get _t => _db.goals;

  SimpleSelectStatement<$GoalsTable, GoalRow> _live() => _db.select(_t)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt),
      (t) => OrderingTerm(expression: t.id),
    ]);

  GoalRecord _map(GoalRow row) =>
      GoalRecord.fromCore(row.toDomain(), _extras.get(row.id));

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
  Future<void> upsert(GoalRecord goal) async {
    _extras.put(goal.id, goal.extras);
    await _db.into(_t).insertOnConflictUpdate(goal.toCore().toCompanion());
  }

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
