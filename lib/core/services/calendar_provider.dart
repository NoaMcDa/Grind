import '../domain/domain.dart';

/// One connectable calendar inside a provider account.
class ExternalCalendar {
  const ExternalCalendar({
    required this.id,
    required this.name,
    this.isPrimary = false,
    this.canWrite = true,
  });

  final String id;
  final String name;
  final bool isPrimary;
  final bool canWrite;
}

/// A connection to an external calendar system (Google: #13, Apple: #14).
/// Sync code reads events through this and writes the result into
/// [CalendarRepository]; the UI never talks to a provider directly.
abstract interface class CalendarProvider {
  CalendarSource get source;

  Future<bool> isConnected();

  /// Starts the provider's auth flow. Returns false if the user cancelled.
  Future<bool> connect();
  Future<void> disconnect();

  Future<List<ExternalCalendar>> listCalendars();

  /// Events in [from, to) for the chosen calendars.
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  });

  /// Write a Grind task to the calendar; returns the provider's event id.
  Future<String> createEvent({required String calendarId, required Task task});

  Future<void> updateEvent({
    required String calendarId,
    required String externalId,
    required Task task,
  });

  Future<void> deleteEvent({
    required String calendarId,
    required String externalId,
  });
}

/// Disconnected provider used until #13/#14 land and in tests.
class FakeCalendarProvider implements CalendarProvider {
  FakeCalendarProvider(this.source, {this.events = const []});

  @override
  final CalendarSource source;
  final List<CalendarEvent> events;
  bool connected = false;
  int nextId = 1;

  @override
  Future<bool> isConnected() async => connected;

  @override
  Future<bool> connect() async => connected = true;

  @override
  Future<void> disconnect() async => connected = false;

  @override
  Future<List<ExternalCalendar>> listCalendars() async => const [
    ExternalCalendar(id: 'primary', name: 'Primary', isPrimary: true),
  ];

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async =>
      events.where((e) => e.start.isBefore(to) && e.end.isAfter(from)).toList();

  @override
  Future<String> createEvent({
    required String calendarId,
    required Task task,
  }) async => 'fake-${nextId++}';

  @override
  Future<void> updateEvent({
    required String calendarId,
    required String externalId,
    required Task task,
  }) async {}

  @override
  Future<void> deleteEvent({
    required String calendarId,
    required String externalId,
  }) async {}
}
