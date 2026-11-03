import 'dart:convert';

import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:grind/features/calendar/google/google_auth.dart';
import 'package:grind/features/calendar/google/google_calendar_gateway.dart';
import 'package:grind/features/calendar/sync/calendar_sync_errors.dart';

/// In-memory stand-in for the Google Calendar API, with sync tokens and
/// paging that behave like the real thing (enough for our calls).
class FakeGateway implements GoogleCalendarGateway {
  FakeGateway({this.pageSize = 250});

  final int pageSize;
  final Map<String, Map<String, gcal.Event>> calendars = {'primary': {}};
  final List<gcal.CalendarListEntry> calendarList = [
    gcal.CalendarListEntry(
      id: 'primary',
      summary: 'me@example.com',
      primary: true,
      accessRole: 'owner',
    ),
  ];

  /// Every list call, for assertions.
  final List<({String calendarId, String? syncToken, DateTime? timeMin})>
  listCalls = [];

  /// Change log: version -> (calendar, event id).
  final List<(String, String)> _log = [];
  int _version = 0;
  bool expireTokens = false;
  int _nextId = 1;

  String _token() => 'tok-$_version';

  void put(String calendarId, gcal.Event e) {
    (calendars[calendarId] ??= {})[e.id!] = e;
    _version++;
    _log.add((calendarId, e.id!));
  }

  /// Delete in the "Google UI": incremental syncs report it as cancelled.
  void cancel(String calendarId, String id) {
    final e = calendars[calendarId]![id]!;
    e.status = 'cancelled';
    _version++;
    _log.add((calendarId, id));
  }

  @override
  Future<List<gcal.CalendarListEntry>> listCalendars() async => calendarList;

  @override
  Future<gcal.Events> listEvents(
    String calendarId, {
    String? syncToken,
    DateTime? timeMin,
    DateTime? timeMax,
    String? pageToken,
  }) async {
    if (pageToken == null) {
      listCalls.add((
        calendarId: calendarId,
        syncToken: syncToken,
        timeMin: timeMin,
      ));
    }
    final all = calendars[calendarId] ?? {};
    List<gcal.Event> items;
    if (syncToken != null) {
      if (expireTokens) throw SyncTokenExpiredException(calendarId);
      final since = int.parse(syncToken.substring(4));
      final ids = {
        for (final (cal, id) in _log.skip(since))
          if (cal == calendarId) id,
      };
      items = [for (final id in ids) all[id]!];
    } else {
      items = all.values.where((e) => e.status != 'cancelled').where((e) {
        final s = e.start!.dateTime ?? e.start!.date!;
        final en = e.end!.dateTime ?? e.end!.date!;
        return s.isBefore(timeMax!) && en.isAfter(timeMin!);
      }).toList();
    }
    final offset = pageToken == null ? 0 : int.parse(pageToken);
    final page = items.skip(offset).take(pageSize).toList();
    final more = offset + pageSize < items.length;
    return gcal.Events(
      items: page,
      nextPageToken: more ? '${offset + pageSize}' : null,
      nextSyncToken: more ? null : _token(),
    );
  }

  @override
  Future<gcal.Event> insertEvent(String calendarId, gcal.Event event) async {
    final copy = clone(event)..id = 'g${_nextId++}';
    put(calendarId, copy);
    return copy;
  }

  @override
  Future<gcal.Event> patchEvent(
    String calendarId,
    String eventId,
    gcal.Event event,
  ) async {
    final current = calendars[calendarId]?[eventId];
    if (current == null || current.status == 'cancelled') {
      throw ExternalEventMissingException('no $eventId');
    }
    final merged = gcal.Event.fromJson({...asJson(current), ...asJson(event)})
      ..id = eventId;
    put(calendarId, merged);
    return merged;
  }

  @override
  Future<void> deleteEvent(String calendarId, String eventId) async {
    if (calendars[calendarId]?[eventId] == null) return;
    cancel(calendarId, eventId);
  }
}

class FakeAuth implements GoogleAuth {
  FakeAuth(this.gw, {this.outcome = GoogleSignInOutcome.authorized});

  final FakeGateway gw;
  GoogleSignInOutcome outcome;
  bool sessionValid = true;
  int signIns = 0;
  int signOuts = 0;

  @override
  Future<({GoogleSignInOutcome outcome, String? error})> signIn() async {
    signIns++;
    return (
      outcome: outcome,
      error: outcome == GoogleSignInOutcome.failed ? 'popup_closed' : null,
    );
  }

  @override
  Future<GoogleCalendarGateway?> gateway() async => sessionValid ? gw : null;

  @override
  Future<void> signOut() async => signOuts++;
}

gcal.Event timed(String id, DateTime start, DateTime end, {String? title}) =>
    gcal.Event(
      id: id,
      summary: title ?? 'Event $id',
      start: gcal.EventDateTime(dateTime: start),
      end: gcal.EventDateTime(dateTime: end),
      updated: DateTime.utc(2026, 11, 1),
      created: DateTime.utc(2026, 11, 1),
    );

/// Deep copy (the generated `toJson` is shallow).
gcal.Event clone(gcal.Event e) =>
    gcal.Event.fromJson(jsonDecode(jsonEncode(e)) as Map<String, dynamic>);

Map<String, dynamic> asJson(gcal.Event e) =>
    jsonDecode(jsonEncode(e)) as Map<String, dynamic>;
