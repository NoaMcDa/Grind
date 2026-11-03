import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

import '../../../core/core.dart';
import '../sync/calendar_sync_errors.dart';
import 'google_auth.dart';
import 'google_calendar_gateway.dart';
import 'google_config.dart';
import 'google_event_mapper.dart';
import 'key_value_store.dart';

/// What Grind remembers per Google calendar between syncs: the sync token,
/// the window it covers, and the mirrored events (so an incremental sync,
/// which only returns changes, can still answer "all events in the window").
class GoogleSyncState {
  GoogleSyncState({
    required this.syncToken,
    required this.windowFrom,
    required this.windowTo,
    Map<String, CalendarEvent>? events,
  }) : events = events ?? {};

  String? syncToken;
  final DateTime windowFrom;
  final DateTime windowTo;
  final Map<String, CalendarEvent> events;

  bool covers(DateTime from, DateTime to) =>
      !from.isBefore(windowFrom) && !to.isAfter(windowTo);

  bool overlaps(CalendarEvent e) =>
      e.start.isBefore(windowTo) && e.end.isAfter(windowFrom);

  String encode() => jsonEncode({
    'v': 1,
    'token': syncToken,
    'from': windowFrom.toUtc().toIso8601String(),
    'to': windowTo.toUtc().toIso8601String(),
    'events': [for (final e in events.values) GoogleEventMapper.toJson(e)],
  });

  static GoogleSyncState? decode(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      if (j['v'] != 1) return null;
      final list = (j['events'] as List? ?? const [])
          .cast<Map<String, Object?>>()
          .map(GoogleEventMapper.fromJson);
      return GoogleSyncState(
        syncToken: j['token'] as String?,
        windowFrom: DateTime.parse(j['from']! as String),
        windowTo: DateTime.parse(j['to']! as String),
        events: {for (final e in list) e.externalId: e},
      );
    } catch (_) {
      return null; // Corrupt or old format: a full resync fixes it.
    }
  }
}

/// [CalendarProvider] for Google Calendar, fully client-side.
///
/// * Sign-in and tokens: [GoogleAuth] (`google_sign_in`).
/// * API calls: [GoogleCalendarGateway] (`googleapis` calendar v3).
/// * Incremental sync: one `syncToken` per calendar in [store]; a full
///   resync of the window (+ [windowSlack]) on HTTP 410 or when the
///   requested window is no longer covered.
/// * Write-back: events carry `extendedProperties.private.grindTaskId`.
class GoogleCalendarProvider implements CalendarProvider {
  GoogleCalendarProvider({
    required this.auth,
    required this.store,
    this.config = const GoogleCalendarConfig.fromEnvironment(),
    bool? web,
    this.clock = const SystemClock(),
    this.windowSlack = const Duration(days: 7),
  }) : web = web ?? kIsWeb;

  final GoogleAuth auth;
  final KeyValueStore store;
  final GoogleCalendarConfig config;
  final bool web;
  final Clock clock;

  /// Extra days fetched past the requested window, so the rolling window
  /// stays covered (and incremental) for about a week.
  final Duration windowSlack;

  static const _prefix = 'grind.google.';
  static const _connectedKey = '${_prefix}connected';
  static String _stateKey(String calendarId) => '${_prefix}sync.$calendarId';

  /// Why the last [connect] returned false (developer-facing), if known.
  String? lastError;

  final Map<String, GoogleSyncState> _states = {};

  @override
  CalendarSource get source => CalendarSource.google;

  bool get isConfigured => config.isConfiguredFor(web: web);

  @override
  Future<bool> isConnected() async =>
      isConfigured && await store.read(_connectedKey) == '1';

  @override
  Future<bool> connect() async {
    lastError = null;
    if (!isConfigured) {
      lastError = config.setupHelp(web: web);
      return false;
    }
    final result = await auth.signIn();
    switch (result.outcome) {
      case GoogleSignInOutcome.authorized:
        await store.write(_connectedKey, '1');
        return true;
      case GoogleSignInOutcome.cancelled:
        return false;
      case GoogleSignInOutcome.failed:
        lastError = result.error;
        return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await auth.signOut();
    } catch (_) {
      // Revocation is best-effort; local state is cleared regardless.
    }
    _states.clear();
    await store.deletePrefix(_prefix);
  }

  Future<GoogleCalendarGateway> _gateway() async {
    if (!isConfigured) {
      throw CalendarAuthException(config.setupHelp(web: web));
    }
    final g = await auth.gateway();
    if (g == null) {
      throw const CalendarAuthException(
        'No Google authorization; sign in again',
      );
    }
    return g;
  }

  @override
  Future<List<ExternalCalendar>> listCalendars() async {
    final g = await _gateway();
    final entries = await g.listCalendars();
    return [
      for (final c in entries)
        if (c.id != null && c.deleted != true)
          ExternalCalendar(
            id: c.id!,
            name: c.summaryOverride ?? c.summary ?? c.id!,
            isPrimary: c.primary ?? false,
            canWrite: c.accessRole == 'owner' || c.accessRole == 'writer',
          ),
    ];
  }

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async {
    final g = await _gateway();
    final start = from.toUtc();
    final end = to.toUtc();
    final out = <CalendarEvent>[];
    for (final id in calendarIds) {
      final state = await syncCalendar(g, id, start, end);
      out.addAll(
        state.events.values.where(
          (e) => e.start.isBefore(end) && e.end.isAfter(start),
        ),
      );
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  /// Bring one calendar's mirror up to date (incremental when possible).
  @visibleForTesting
  Future<GoogleSyncState> syncCalendar(
    GoogleCalendarGateway g,
    String calendarId,
    DateTime from,
    DateTime to,
  ) async {
    var state = await _load(calendarId);
    var full =
        state == null || state.syncToken == null || !state.covers(from, to);
    if (!full) {
      try {
        await _incremental(g, calendarId, state);
      } on SyncTokenExpiredException {
        full = true;
      }
    }
    if (full) {
      state = await _full(g, calendarId, from, to.add(windowSlack));
    }
    await _save(calendarId, state!);
    return state;
  }

  Future<GoogleSyncState> _full(
    GoogleCalendarGateway g,
    String calendarId,
    DateTime from,
    DateTime to,
  ) async {
    final state = GoogleSyncState(
      syncToken: null,
      windowFrom: from,
      windowTo: to,
    );
    final now = clock.now().toUtc();
    String? page;
    do {
      final res = await g.listEvents(
        calendarId,
        timeMin: from,
        timeMax: to,
        pageToken: page,
      );
      for (final item in res.items ?? const <gcal.Event>[]) {
        final e = GoogleEventMapper.toDomain(
          item,
          calendarId: calendarId,
          now: now,
        );
        if (e != null) state.events[e.externalId] = e;
      }
      page = res.nextPageToken;
      state.syncToken = res.nextSyncToken ?? state.syncToken;
    } while (page != null);
    return state;
  }

  Future<void> _incremental(
    GoogleCalendarGateway g,
    String calendarId,
    GoogleSyncState state,
  ) async {
    final now = clock.now().toUtc();
    final token = state.syncToken!;
    final changes = <String, CalendarEvent?>{};
    String? page;
    String? next;
    do {
      final res = await g.listEvents(
        calendarId,
        syncToken: token,
        pageToken: page,
      );
      for (final item in res.items ?? const <gcal.Event>[]) {
        final id = item.id;
        if (id == null) continue;
        final e = GoogleEventMapper.toDomain(
          item,
          calendarId: calendarId,
          now: now,
        );
        changes[id] = e != null && state.overlaps(e) ? e : null;
      }
      page = res.nextPageToken;
      next = res.nextSyncToken ?? next;
    } while (page != null);
    // Apply only once every page arrived, so a failure mid-way leaves the
    // previous consistent state (and token) in place.
    changes.forEach((id, e) {
      if (e == null) {
        state.events.remove(id);
      } else {
        state.events[id] = e;
      }
    });
    if (next != null) state.syncToken = next;
  }

  Future<GoogleSyncState?> _load(String calendarId) async {
    final cached = _states[calendarId];
    if (cached != null) return cached;
    final decoded = GoogleSyncState.decode(
      await store.read(_stateKey(calendarId)),
    );
    if (decoded != null) _states[calendarId] = decoded;
    return decoded;
  }

  Future<void> _save(String calendarId, GoogleSyncState state) async {
    _states[calendarId] = state;
    await store.write(_stateKey(calendarId), state.encode());
  }

  Future<void> _remember(String calendarId, gcal.Event created) async {
    final state = await _load(calendarId);
    if (state == null) return;
    final e = GoogleEventMapper.toDomain(
      created,
      calendarId: calendarId,
      now: clock.now().toUtc(),
    );
    if (e == null || !state.overlaps(e)) {
      state.events.remove(created.id);
    } else {
      state.events[e.externalId] = e;
    }
    await _save(calendarId, state);
  }

  @override
  Future<String> createEvent({
    required String calendarId,
    required Task task,
  }) async {
    final g = await _gateway();
    final created = await g.insertEvent(
      calendarId,
      GoogleEventMapper.fromTask(task),
    );
    final id = created.id;
    if (id == null) {
      throw const CalendarSyncException('Google returned an event without id');
    }
    await _remember(calendarId, created);
    return id;
  }

  @override
  Future<void> updateEvent({
    required String calendarId,
    required String externalId,
    required Task task,
  }) async {
    final g = await _gateway();
    final updated = await g.patchEvent(
      calendarId,
      externalId,
      GoogleEventMapper.fromTask(task),
    );
    await _remember(calendarId, updated);
  }

  @override
  Future<void> deleteEvent({
    required String calendarId,
    required String externalId,
  }) async {
    final g = await _gateway();
    await g.deleteEvent(calendarId, externalId);
    final state = await _load(calendarId);
    if (state != null) {
      state.events.remove(externalId);
      await _save(calendarId, state);
    }
  }
}
