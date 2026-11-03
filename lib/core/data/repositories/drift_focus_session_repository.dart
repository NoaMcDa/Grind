import 'package:drift/drift.dart';

import '../../domain/domain.dart';
import '../database.dart';
import '../focus_session_repository.dart';
import '../mappers.dart';

/// [FocusSessionRepository] on the local Drift database. Rows with a
/// `deletedAt` (a soft-deleted session) are ignored. A session's task is a foreign key, so the task must be stored
/// first; deleting the task nulls `taskId` and keeps the session.
class DriftFocusSessionRepository implements FocusSessionRepository {
  DriftFocusSessionRepository(this._db);

  final AppDatabase _db;

  $FocusSessionsTable get _t => _db.focusSessions;

  SimpleSelectStatement<$FocusSessionsTable, FocusSessionRow> _activeQuery() =>
      _db.select(_t)
        ..where((r) => r.deletedAt.isNull() & r.endedAt.isNull())
        ..orderBy([
          (r) => OrderingTerm(expression: r.startedAt, mode: OrderingMode.desc),
          (r) => OrderingTerm(expression: r.id, mode: OrderingMode.desc),
        ])
        ..limit(1);

  SimpleSelectStatement<$FocusSessionsTable, FocusSessionRow> _betweenQuery(
    DateTime from,
    DateTime to,
  ) => _db.select(_t)
    ..where(
      (r) =>
          r.deletedAt.isNull() &
          r.startedAt.isBiggerOrEqualValue(toMillis(from)) &
          r.startedAt.isSmallerThanValue(toMillis(to)),
    )
    ..orderBy([
      (r) => OrderingTerm(expression: r.startedAt),
      (r) => OrderingTerm(expression: r.id),
    ]);

  @override
  Future<void> start(FocusSession session) =>
      _db.into(_t).insert(session.toCompanion());

  @override
  Future<void> update(FocusSession session) => (_db.update(
    _t,
  )..where((r) => r.id.equals(session.id))).write(session.toCompanion());

  @override
  Future<FocusSession?> getActive() async =>
      (await _activeQuery().getSingleOrNull())?.toDomain();

  @override
  Future<List<FocusSession>> getBetween(DateTime from, DateTime to) async =>
      (await _betweenQuery(from, to).get()).map((r) => r.toDomain()).toList();

  @override
  Stream<FocusSession?> watchActive() =>
      _activeQuery().watchSingleOrNull().map((r) => r?.toDomain());

  @override
  Stream<List<FocusSession>> watchBetween(DateTime from, DateTime to) =>
      _betweenQuery(
        from,
        to,
      ).watch().map((rows) => rows.map((r) => r.toDomain()).toList());
}
