import 'package:googleapis/calendar/v3.dart' as gcal;

import '../sync/calendar_sync_errors.dart';

/// The Google Calendar API calls Grind makes, behind an interface so tests
/// never hit the network. Uses the `googleapis` data classes as-is.
abstract interface class GoogleCalendarGateway {
  /// Every calendar in the user's list (all pages).
  Future<List<gcal.CalendarListEntry>> listCalendars();

  /// One page of events. Pass [syncToken] for an incremental sync (then
  /// [timeMin]/[timeMax] must be null) or the window for a full sync.
  /// Throws [SyncTokenExpiredException] on HTTP 410.
  Future<gcal.Events> listEvents(
    String calendarId, {
    String? syncToken,
    DateTime? timeMin,
    DateTime? timeMax,
    String? pageToken,
  });

  Future<gcal.Event> insertEvent(String calendarId, gcal.Event event);

  /// Throws [ExternalEventMissingException] when the event is gone.
  Future<gcal.Event> patchEvent(
    String calendarId,
    String eventId,
    gcal.Event event,
  );

  /// Succeeds silently when the event is already gone.
  Future<void> deleteEvent(String calendarId, String eventId);
}

/// Google answered 410 Gone to a sync token: do a full resync.
class SyncTokenExpiredException implements Exception {
  const SyncTokenExpiredException(this.calendarId);
  final String calendarId;

  @override
  String toString() => 'SyncTokenExpiredException($calendarId)';
}

/// [GoogleCalendarGateway] over `googleapis`' [gcal.CalendarApi].
class GoogleApisCalendarGateway implements GoogleCalendarGateway {
  GoogleApisCalendarGateway(this.api);

  final gcal.CalendarApi api;

  @override
  Future<List<gcal.CalendarListEntry>> listCalendars() => _guard(() async {
    final out = <gcal.CalendarListEntry>[];
    String? page;
    do {
      final list = await api.calendarList.list(pageToken: page);
      out.addAll(list.items ?? const []);
      page = list.nextPageToken;
    } while (page != null);
    return out;
  });

  @override
  Future<gcal.Events> listEvents(
    String calendarId, {
    String? syncToken,
    DateTime? timeMin,
    DateTime? timeMax,
    String? pageToken,
  }) async {
    try {
      return await api.events.list(
        calendarId,
        singleEvents: true,
        maxResults: 250,
        syncToken: syncToken,
        timeMin: syncToken == null ? timeMin?.toUtc() : null,
        timeMax: syncToken == null ? timeMax?.toUtc() : null,
        pageToken: pageToken,
      );
    } on gcal.DetailedApiRequestError catch (e) {
      if (e.status == 410) throw SyncTokenExpiredException(calendarId);
      throw _map(e);
    }
  }

  @override
  Future<gcal.Event> insertEvent(String calendarId, gcal.Event event) =>
      _guard(() => api.events.insert(event, calendarId, sendUpdates: 'none'));

  @override
  Future<gcal.Event> patchEvent(
    String calendarId,
    String eventId,
    gcal.Event event,
  ) async {
    try {
      return await api.events.patch(
        event,
        calendarId,
        eventId,
        sendUpdates: 'none',
      );
    } on gcal.DetailedApiRequestError catch (e) {
      if (e.status == 404 || e.status == 410) {
        throw ExternalEventMissingException('event $eventId gone', cause: e);
      }
      throw _map(e);
    }
  }

  @override
  Future<void> deleteEvent(String calendarId, String eventId) async {
    try {
      await api.events.delete(calendarId, eventId, sendUpdates: 'none');
    } on gcal.DetailedApiRequestError catch (e) {
      if (e.status == 404 || e.status == 410) return;
      throw _map(e);
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on gcal.DetailedApiRequestError catch (e) {
      throw _map(e);
    }
  }

  static CalendarSyncException _map(gcal.DetailedApiRequestError e) =>
      e.status == 401
      ? CalendarAuthException('Google said ${e.status}: ${e.message}', cause: e)
      : CalendarSyncException(
          'Google said ${e.status}: ${e.message}',
          cause: e,
        );
}
