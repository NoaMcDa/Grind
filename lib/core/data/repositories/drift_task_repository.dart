import 'package:drift/drift.dart';

import '../../domain/domain.dart';
import '../../repositories/task_repository.dart';
import '../../services/clock.dart';
import '../database.dart';
import '../mappers.dart';

/// [TaskRepository] on the local Drift database. Same semantics as
/// [InMemoryTaskRepository]; lists are ordered by `createdAt`, then `id`.
class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  $TasksTable get _t => _db.tasks;

  SimpleSelectStatement<$TasksTable, TaskRow> _live() => _db.select(_t)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt),
      (t) => OrderingTerm(expression: t.id),
    ]);

  @override
  Future<List<Task>> getAll() async =>
      (await _live().get()).map((r) => r.toDomain()).toList();

  @override
  Future<Task?> getById(String id) async {
    final q = _db.select(_t)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return (await q.getSingleOrNull())?.toDomain();
  }

  @override
  Future<List<Task>> getDueBetween(DateTime from, DateTime to) async {
    final q = _live()
      ..where((t) {
        final when = coalesce([t.remindAt, t.dueAt]);
        return t.status.equalsValue(TaskStatus.open) &
            when.isBiggerOrEqualValue(toMillis(from)) &
            when.isSmallerThanValue(toMillis(to));
      });
    return (await q.get()).map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Task>> getScheduledBetween(DateTime from, DateTime to) async {
    final q = _live()
      ..where(
        (t) =>
            t.scheduledStart.isNotNull() &
            t.scheduledEnd.isNotNull() &
            t.scheduledStart.isSmallerThanValue(toMillis(to)) &
            t.scheduledEnd.isBiggerThanValue(toMillis(from)),
      );
    return (await q.get()).map((r) => r.toDomain()).toList();
  }

  @override
  Future<void> upsert(Task task) =>
      _db.into(_t).insertOnConflictUpdate(task.toCompanion());

  @override
  Future<void> upsertAll(List<Task> tasks) => _db.batch((b) {
    for (final task in tasks) {
      b.insert(
        _t,
        task.toCompanion(),
        onConflict: DoUpdate((_) => task.toCompanion()),
      );
    }
  });

  @override
  Future<void> delete(String id) async {
    final now = toMillis(_clock.now().toUtc());
    await (_db.update(_t)..where((t) => t.id.equals(id))).write(
      TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Stream<List<Task>> watchAll() =>
      _live().watch().map((rows) => rows.map((r) => r.toDomain()).toList());
}
