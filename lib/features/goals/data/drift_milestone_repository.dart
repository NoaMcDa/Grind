import 'package:drift/drift.dart';

import '../../../core/core.dart';
import '../../../core/data/database.dart';
import '../../../core/data/mappers.dart';

/// [MilestoneRepository] on the `milestones` and `milestone_tasks` tables
/// (schema v4).
class DriftMilestoneRepository implements MilestoneRepository {
  DriftMilestoneRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  $MilestonesTable get _t => _db.milestones;

  SimpleSelectStatement<$MilestonesTable, MilestoneRow> _live() =>
      _db.select(_t)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm(expression: t.goalId),
          (t) => OrderingTerm(expression: t.sortOrder),
          (t) => OrderingTerm(expression: t.createdAt),
          (t) => OrderingTerm(expression: t.id),
        ]);

  @override
  Future<List<Milestone>> getAll() async => [
    for (final r in await _live().get()) r.toDomain(),
  ];

  @override
  Future<Milestone?> getById(String id) async {
    final row = await (_db.select(
      _t,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(Milestone milestone) =>
      _db.into(_t).insertOnConflictUpdate(milestone.toCompanion());

  @override
  Future<void> upsertAll(Iterable<Milestone> milestones) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(_t, [
      for (final m in milestones) m.toCompanion(),
    ]),
  );

  @override
  Future<void> delete(String id) => _db.transaction(() async {
    final now = toMillis(_clock.now().toUtc());
    await (_db.update(_t)..where((t) => t.id.equals(id))).write(
      MilestonesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await (_db.delete(
      _db.milestoneTasks,
    )..where((l) => l.milestoneId.equals(id))).go();
  });

  @override
  Stream<List<Milestone>> watchAll() =>
      _live().watch().map((rows) => [for (final r in rows) r.toDomain()]);

  @override
  Future<void> linkTask(String taskId, String milestoneId) => _db
      .into(_db.milestoneTasks)
      .insertOnConflictUpdate(
        MilestoneTaskLink(
          taskId: taskId,
          milestoneId: milestoneId,
          createdAt: _clock.now().toUtc(),
        ).toCompanion(),
      );

  @override
  Future<void> unlinkTask(String taskId) => (_db.delete(
    _db.milestoneTasks,
  )..where((l) => l.taskId.equals(taskId))).go();

  @override
  Stream<List<MilestoneTaskLink>> watchLinks() =>
      (_db.select(_db.milestoneTasks)..orderBy([
            (l) => OrderingTerm(expression: l.createdAt),
            (l) => OrderingTerm(expression: l.taskId),
          ]))
          .watch()
          .map((rows) => [for (final r in rows) r.toDomain()]);
}
