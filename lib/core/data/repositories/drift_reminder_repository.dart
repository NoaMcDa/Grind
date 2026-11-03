import 'package:drift/drift.dart';

import '../../domain/domain.dart';
import '../../repositories/reminder_repository.dart';
import '../../services/clock.dart';
import '../database.dart';
import '../mappers.dart';

/// [ReminderRepository] on the local Drift database. Rules reference their
/// task with a foreign key, so the task must be stored first.
class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  $ReminderRulesTable get _t => _db.reminderRules;

  SimpleSelectStatement<$ReminderRulesTable, ReminderRuleRow> _live() =>
      _db.select(_t)
        ..where((r) => r.deletedAt.isNull())
        ..orderBy([
          (r) => OrderingTerm(expression: r.createdAt),
          (r) => OrderingTerm(expression: r.id),
        ]);

  @override
  Future<List<ReminderRule>> getAll() async =>
      (await _live().get()).map((r) => r.toDomain()).toList();

  @override
  Future<ReminderRule?> getForTask(String taskId) async {
    final q = _live()
      ..where((r) => r.taskId.equals(taskId))
      ..limit(1);
    return (await q.getSingleOrNull())?.toDomain();
  }

  @override
  Future<void> upsert(ReminderRule rule) =>
      _db.into(_t).insertOnConflictUpdate(rule.toCompanion());

  @override
  Future<void> delete(String id) async {
    final now = toMillis(_clock.now().toUtc());
    await (_db.update(_t)..where((r) => r.id.equals(id))).write(
      ReminderRulesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Stream<List<ReminderRule>> watchAll() =>
      _live().watch().map((rows) => rows.map((r) => r.toDomain()).toList());
}
