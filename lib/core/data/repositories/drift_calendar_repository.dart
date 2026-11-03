import 'package:drift/drift.dart';

import '../../domain/domain.dart';
import '../../repositories/calendar_repository.dart';
import '../../services/clock.dart';
import '../database.dart';
import '../mappers.dart';

/// [CalendarRepository] on the local Drift database. Same semantics as
/// [InMemoryCalendarRepository]: [delete] is soft, [clearSource] is hard.
class DriftCalendarRepository implements CalendarRepository {
  DriftCalendarRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  $CalendarEventsTable get _t => _db.calendarEvents;

  SimpleSelectStatement<$CalendarEventsTable, CalendarEventRow> _between(
    DateTime from,
    DateTime to,
  ) => _db.select(_t)
    ..where(
      (e) =>
          e.deletedAt.isNull() &
          e.startAt.isSmallerThanValue(toMillis(to)) &
          e.endAt.isBiggerThanValue(toMillis(from)),
    )
    ..orderBy([
      (e) => OrderingTerm(expression: e.startAt),
      (e) => OrderingTerm(expression: e.id),
    ]);

  @override
  Future<List<CalendarEvent>> getBetween(DateTime from, DateTime to) async =>
      (await _between(from, to).get()).map((r) => r.toDomain()).toList();

  @override
  Future<CalendarEvent?> getById(String id) async {
    final q = _db.select(_t)
      ..where((e) => e.id.equals(id) & e.deletedAt.isNull());
    return (await q.getSingleOrNull())?.toDomain();
  }

  @override
  Future<CalendarEvent?> getByExternalId(
    CalendarSource source,
    String externalId,
  ) async {
    final q = _db.select(_t)
      ..where(
        (e) =>
            e.deletedAt.isNull() &
            e.source.equalsValue(source) &
            e.externalId.equals(externalId),
      )
      ..limit(1);
    return (await q.getSingleOrNull())?.toDomain();
  }

  @override
  Future<void> upsert(CalendarEvent event) =>
      _db.into(_t).insertOnConflictUpdate(event.toCompanion());

  @override
  Future<void> upsertAll(List<CalendarEvent> events) => _db.batch((b) {
    for (final e in events) {
      b.insert(
        _t,
        e.toCompanion(),
        onConflict: DoUpdate((_) => e.toCompanion()),
      );
    }
  });

  @override
  Future<void> delete(String id) async {
    final now = toMillis(_clock.now().toUtc());
    await (_db.update(_t)..where((e) => e.id.equals(id))).write(
      CalendarEventsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> clearSource(CalendarSource source) =>
      (_db.delete(_t)..where((e) => e.source.equalsValue(source))).go();

  @override
  Stream<List<CalendarEvent>> watchBetween(DateTime from, DateTime to) =>
      _between(
        from,
        to,
      ).watch().map((rows) => rows.map((r) => r.toDomain()).toList());
}
