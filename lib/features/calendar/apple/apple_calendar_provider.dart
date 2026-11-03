import 'package:grind/core/core.dart';

import 'apple_calendar_channel.dart';
import 'platform_support.dart';
import 'write_back_marker.dart';

/// [CalendarProvider] over EventKit (#14). See docs/adr/0004-apple-calendar.md.
///
/// Off iOS (web, Android, desktop, tests) every call reports "unavailable"
/// gracefully: [connect] returns false, lists are empty, [changes] never
/// fires, and only the write calls throw [AppleCalendarException].
class AppleCalendarProvider implements CalendarProvider {
  AppleCalendarProvider({
    AppleCalendarChannel? channel,
    Clock clock = const SystemClock(),
    bool? isSupported,
  }) : _channelOverride = channel,
       _clock = clock,
       isSupported = isSupported ?? isAppleCalendarPlatform();

  final AppleCalendarChannel? _channelOverride;
  final Clock _clock;

  /// False off iOS. Injectable so tests can run both ways.
  final bool isSupported;

  AppleCalendarChannel? _lazyChannel;
  AppleCalendarChannel get _channel =>
      _channelOverride ??
      (_lazyChannel ??= MethodChannelAppleCalendarChannel());

  /// iOS permission cannot be revoked from inside the app, so "disconnect"
  /// only stops this session from using it; [connect] clears it. The lasting
  /// choice (which calendars to sync) lives in `Preferences`.
  bool _disconnected = false;

  @override
  CalendarSource get source => CalendarSource.apple;

  /// Current EventKit permission; [AppleAuthStatus.denied] when unavailable.
  Future<AppleAuthStatus> status() async {
    if (!isSupported) return AppleAuthStatus.denied;
    try {
      return await _channel.authorizationStatus();
    } on AppleCalendarException {
      return AppleAuthStatus.denied;
    }
  }

  /// One event per change in the device's calendar database (any app). The
  /// sync engine re-pulls on each.
  Stream<void> get changes =>
      isSupported ? _channel.changes : const Stream<void>.empty();

  /// Granted (full or write-only) and not disconnected this session.
  /// Independent of `Preferences`.
  @override
  Future<bool> isConnected() async =>
      !_disconnected && (await status()).isGranted;

  /// Asks for full access (read + write). False when the user says no, when
  /// access was denied before (iOS will not ask again: point to Settings),
  /// or when restricted by Screen Time / MDM.
  @override
  Future<bool> connect() async {
    if (!isSupported) return false;
    var current = await status();
    if (!current.canRead && !current.isFinalNo) {
      current = await _request(_channel.requestFullAccess);
    }
    if (current.canRead) _disconnected = false;
    return current.canRead;
  }

  /// Asks only to add events (iOS 17+; earlier iOS shows the full prompt).
  /// Use when the user wants tasks in their calendar but not their events in
  /// Grind. Write-only cannot read, move-detection, update or delete.
  Future<bool> connectWriteOnly() async {
    if (!isSupported) return false;
    var current = await status();
    if (!current.isGranted && !current.isFinalNo) {
      current = await _request(_channel.requestWriteOnlyAccess);
    }
    if (current.isGranted) _disconnected = false;
    return current.isGranted;
  }

  Future<AppleAuthStatus> _request(
    Future<AppleAuthStatus> Function() request,
  ) async {
    try {
      return await request();
    } on AppleCalendarException {
      return AppleAuthStatus.denied;
    }
  }

  @override
  Future<void> disconnect() async => _disconnected = true;

  Future<bool> _canRead() async =>
      isSupported && !_disconnected && (await status()).canRead;

  @override
  Future<List<ExternalCalendar>> listCalendars() async {
    if (!await _canRead()) return const [];
    final calendars = await _channel.listCalendars();
    return [
      for (final c in calendars)
        ExternalCalendar(
          id: c.id,
          name: c.title,
          isPrimary: c.isPrimary,
          canWrite: c.allowsContentModifications,
        ),
    ];
  }

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async {
    if (calendarIds.isEmpty || !from.isBefore(to) || !await _canRead()) {
      return const [];
    }
    final raw = await _channel.fetchEvents(
      calendarIds: calendarIds,
      fromMs: from.millisecondsSinceEpoch,
      toMs: to.millisecondsSinceEpoch,
    );
    return [for (final e in raw) toCalendarEvent(e)];
  }

  /// Maps one EventKit event to the shared model. Recurring occurrences
  /// share an `eventIdentifier`, so their local id adds the start time.
  CalendarEvent toCalendarEvent(AppleEventData e) {
    final now = _clock.now().toUtc();
    DateTime utc(int ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return CalendarEvent(
      id: e.isRecurring
          ? 'apple:${e.eventIdentifier}@${e.startMs}'
          : 'apple:${e.eventIdentifier}',
      source: CalendarSource.apple,
      externalId: e.eventIdentifier,
      calendarId: e.calendarIdentifier.isEmpty ? null : e.calendarIdentifier,
      title: e.title,
      start: utc(e.startMs),
      end: utc(e.endMs),
      isAllDay: e.isAllDay,
      isBusy: e.isBusy,
      taskId: WriteBackMarker.parse(url: e.url, notes: e.notes),
      createdAt: e.createdMs == null ? now : utc(e.createdMs!),
      updatedAt: e.updatedMs == null ? now : utc(e.updatedMs!),
    );
  }

  Future<void> _requireWrite() async {
    if (!isSupported) {
      throw const AppleCalendarException(
        'unavailable',
        'Apple Calendar is only on iPhone',
      );
    }
    if (_disconnected || !(await status()).isGranted) {
      throw const AppleCalendarException('notAuthorized');
    }
  }

  static (int, int) _times(Task task) {
    final start = task.scheduledStart;
    final end = task.scheduledEnd;
    if (start == null || end == null || !end.isAfter(start)) {
      throw AppleCalendarException('notScheduled', 'Task ${task.id}');
    }
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }

  /// Writes a scheduled task; returns the EventKit `eventIdentifier`. An
  /// empty [calendarId] means the user's default calendar.
  @override
  Future<String> createEvent({
    required String calendarId,
    required Task task,
  }) async {
    await _requireWrite();
    final (startMs, endMs) = _times(task);
    return _channel.createEvent(
      calendarId: calendarId.isEmpty ? null : calendarId,
      title: task.title,
      startMs: startMs,
      endMs: endMs,
      notes: WriteBackMarker.notesFor(taskId: task.id, taskNotes: task.notes),
      taskId: task.id,
    );
  }

  /// Throws [AppleCalendarException] with `notFound` when the event is gone
  /// (deleted in Calendar.app, or write-only access): create a new one.
  @override
  Future<void> updateEvent({
    required String calendarId,
    required String externalId,
    required Task task,
  }) async {
    await _requireWrite();
    final (startMs, endMs) = _times(task);
    await _channel.updateEvent(
      eventId: externalId,
      title: task.title,
      startMs: startMs,
      endMs: endMs,
      notes: WriteBackMarker.notesFor(taskId: task.id, taskNotes: task.notes),
      taskId: task.id,
    );
  }

  /// Idempotent: an event that is already gone counts as deleted. A no-op
  /// off iOS.
  @override
  Future<void> deleteEvent({
    required String calendarId,
    required String externalId,
  }) async {
    if (!isSupported) return;
    await _requireWrite();
    try {
      await _channel.deleteEvent(externalId);
    } on AppleCalendarException catch (e) {
      if (!e.isNotFound) rethrow;
    }
  }
}
