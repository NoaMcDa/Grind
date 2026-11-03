import 'dart:async';

import '../domain/domain.dart';

/// Local mirror of external calendar events (filled by the sync code in
/// #13/#14) plus Grind's own write-backs.
abstract interface class CalendarRepository {
  /// Events overlapping [from, to), all sources, non-deleted.
  Future<List<CalendarEvent>> getBetween(DateTime from, DateTime to);

  Future<CalendarEvent?> getById(String id);

  Future<CalendarEvent?> getByExternalId(
    CalendarSource source,
    String externalId,
  );

  Future<void> upsert(CalendarEvent event);
  Future<void> upsertAll(List<CalendarEvent> events);
  Future<void> delete(String id);

  /// Remove everything from one source (full resync).
  Future<void> clearSource(CalendarSource source);

  Stream<List<CalendarEvent>> watchBetween(DateTime from, DateTime to);
}

class InMemoryCalendarRepository implements CalendarRepository {
  InMemoryCalendarRepository([Iterable<CalendarEvent> seed = const []]) {
    for (final e in seed) {
      _events[e.id] = e;
    }
  }

  final Map<String, CalendarEvent> _events = {};
  final _changes = StreamController<void>.broadcast();

  List<CalendarEvent> _between(DateTime from, DateTime to) =>
      _events.values
          .where((e) => e.deletedAt == null)
          .where((e) => e.start.isBefore(to) && e.end.isAfter(from))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  @override
  Future<List<CalendarEvent>> getBetween(DateTime from, DateTime to) async =>
      _between(from, to);

  @override
  Future<CalendarEvent?> getById(String id) async {
    final e = _events[id];
    return e == null || e.deletedAt != null ? null : e;
  }

  @override
  Future<CalendarEvent?> getByExternalId(
    CalendarSource source,
    String externalId,
  ) async => _events.values
      .where((e) => e.deletedAt == null)
      .where((e) => e.source == source && e.externalId == externalId)
      .firstOrNull;

  @override
  Future<void> upsert(CalendarEvent event) async {
    _events[event.id] = event;
    _changes.add(null);
  }

  @override
  Future<void> upsertAll(List<CalendarEvent> events) async {
    for (final e in events) {
      _events[e.id] = e;
    }
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    final e = _events[id];
    if (e == null) return;
    final now = DateTime.now().toUtc();
    _events[id] = e.copyWith(deletedAt: now, updatedAt: now);
    _changes.add(null);
  }

  @override
  Future<void> clearSource(CalendarSource source) async {
    _events.removeWhere((_, e) => e.source == source);
    _changes.add(null);
  }

  @override
  Stream<List<CalendarEvent>> watchBetween(DateTime from, DateTime to) async* {
    yield _between(from, to);
    yield* _changes.stream.map((_) => _between(from, to));
  }
}
