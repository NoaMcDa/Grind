import 'dart:async';

import 'package:flutter/services.dart';

import 'write_back_marker.dart';

/// EventKit authorization, as the Swift plugin reports it.
enum AppleAuthStatus {
  notDetermined,
  restricted,
  denied,

  /// Read and write (iOS 17 `fullAccess`, earlier `authorized`).
  fullAccess,

  /// iOS 17+: may add events, cannot read any.
  writeOnly;

  bool get isGranted => this == fullAccess || this == writeOnly;
  bool get canRead => this == fullAccess;

  /// iOS will not show the prompt again; only the Settings app can change it.
  bool get isFinalNo => this == denied || this == restricted;

  static AppleAuthStatus parse(Object? raw) => switch (raw) {
    'notDetermined' => notDetermined,
    'restricted' => restricted,
    'fullAccess' => fullAccess,
    'writeOnly' => writeOnly,
    _ => denied,
  };
}

/// A calendar as `listCalendars` returns it.
class AppleCalendarInfo {
  const AppleCalendarInfo({
    required this.id,
    required this.title,
    this.allowsContentModifications = true,
    this.isPrimary = false,
  });

  factory AppleCalendarInfo.fromMap(Map<Object?, Object?> map) =>
      AppleCalendarInfo(
        id: map['id']! as String,
        title: (map['title'] as String?) ?? '',
        allowsContentModifications:
            (map['allowsContentModifications'] as bool?) ?? false,
        isPrimary: (map['isPrimary'] as bool?) ?? false,
      );

  final String id;
  final String title;
  final bool allowsContentModifications;
  final bool isPrimary;
}

/// An event (or one occurrence of a recurring event) as `fetchEvents`
/// returns it. Times are epoch milliseconds.
class AppleEventData {
  const AppleEventData({
    required this.eventIdentifier,
    required this.calendarIdentifier,
    required this.title,
    required this.startMs,
    required this.endMs,
    this.isAllDay = false,
    this.isBusy = true,
    this.isRecurring = false,
    this.notes,
    this.url,
    this.createdMs,
    this.updatedMs,
  });

  factory AppleEventData.fromMap(Map<Object?, Object?> map) => AppleEventData(
    eventIdentifier: map['eventIdentifier']! as String,
    calendarIdentifier: (map['calendarIdentifier'] as String?) ?? '',
    title: (map['title'] as String?) ?? '',
    startMs: (map['startMs']! as num).toInt(),
    endMs: (map['endMs']! as num).toInt(),
    isAllDay: (map['isAllDay'] as bool?) ?? false,
    isBusy: (map['isBusy'] as bool?) ?? true,
    isRecurring: (map['isRecurring'] as bool?) ?? false,
    notes: map['notes'] as String?,
    url: map['url'] as String?,
    createdMs: (map['createdMs'] as num?)?.toInt(),
    updatedMs: (map['updatedMs'] as num?)?.toInt(),
  );

  final String eventIdentifier;
  final String calendarIdentifier;
  final String title;
  final int startMs;
  final int endMs;
  final bool isAllDay;
  final bool isBusy;
  final bool isRecurring;
  final String? notes;
  final String? url;
  final int? createdMs;
  final int? updatedMs;

  AppleEventData copyWith({
    String? title,
    int? startMs,
    int? endMs,
    String? notes,
    String? url,
    int? updatedMs,
  }) => AppleEventData(
    eventIdentifier: eventIdentifier,
    calendarIdentifier: calendarIdentifier,
    title: title ?? this.title,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    isAllDay: isAllDay,
    isBusy: isBusy,
    isRecurring: isRecurring,
    notes: notes ?? this.notes,
    url: url ?? this.url,
    createdMs: createdMs,
    updatedMs: updatedMs ?? this.updatedMs,
  );
}

/// Thrown by the channel and the provider.
class AppleCalendarException implements Exception {
  const AppleCalendarException(this.code, [this.message]);

  /// `notFound`, `invalidArgs`, `eventKit`, `unavailable`, `notAuthorized`
  /// or `notScheduled`.
  final String code;
  final String? message;

  bool get isNotFound => code == 'notFound';

  @override
  String toString() =>
      'AppleCalendarException($code${message == null ? '' : ': $message'})';
}

/// Names shared with `ios/Runner/AppleCalendarPlugin.swift`. A test checks
/// the Swift file handles every one of them.
abstract final class AppleCalendarMethods {
  static const channel = 'grind/apple_calendar';
  static const changesChannel = 'grind/apple_calendar/changes';
  static const changeEvent = 'onStoreChanged';

  static const authorizationStatus = 'authorizationStatus';
  static const requestFullAccess = 'requestFullAccess';
  static const requestWriteOnlyAccess = 'requestWriteOnlyAccess';
  static const listCalendars = 'listCalendars';
  static const fetchEvents = 'fetchEvents';
  static const createEvent = 'createEvent';
  static const updateEvent = 'updateEvent';
  static const deleteEvent = 'deleteEvent';

  static const all = [
    authorizationStatus,
    requestFullAccess,
    requestWriteOnlyAccess,
    listCalendars,
    fetchEvents,
    createEvent,
    updateEvent,
    deleteEvent,
  ];
}

/// The raw EventKit surface. [AppleCalendarProvider] is the only caller.
abstract interface class AppleCalendarChannel {
  Future<AppleAuthStatus> authorizationStatus();
  Future<AppleAuthStatus> requestFullAccess();
  Future<AppleAuthStatus> requestWriteOnlyAccess();
  Future<List<AppleCalendarInfo>> listCalendars();
  Future<List<AppleEventData>> fetchEvents({
    required List<String> calendarIds,
    required int fromMs,
    required int toMs,
  });

  /// [calendarId] null or unknown writes to the default calendar.
  Future<String> createEvent({
    String? calendarId,
    required String title,
    required int startMs,
    required int endMs,
    String? notes,
    String? taskId,
  });
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required int startMs,
    required int endMs,
    String? notes,
    String? taskId,
  });
  Future<void> deleteEvent(String eventId);

  /// One event per `EKEventStoreChanged` notification.
  Stream<void> get changes;
}

/// The real channel to the Swift plugin.
class MethodChannelAppleCalendarChannel implements AppleCalendarChannel {
  MethodChannelAppleCalendarChannel({
    MethodChannel methods = const MethodChannel(AppleCalendarMethods.channel),
    EventChannel events = const EventChannel(
      AppleCalendarMethods.changesChannel,
    ),
  }) : _methods = methods,
       _events = events;

  final MethodChannel _methods;
  final EventChannel _events;
  Stream<void>? _changes;

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _methods.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw AppleCalendarException(e.code, e.message);
    } on MissingPluginException catch (e) {
      throw AppleCalendarException('unavailable', e.message);
    }
  }

  Future<AppleAuthStatus> _status(String method) async =>
      AppleAuthStatus.parse(await _call<String>(method));

  @override
  Future<AppleAuthStatus> authorizationStatus() =>
      _status(AppleCalendarMethods.authorizationStatus);

  @override
  Future<AppleAuthStatus> requestFullAccess() =>
      _status(AppleCalendarMethods.requestFullAccess);

  @override
  Future<AppleAuthStatus> requestWriteOnlyAccess() =>
      _status(AppleCalendarMethods.requestWriteOnlyAccess);

  @override
  Future<List<AppleCalendarInfo>> listCalendars() async {
    final raw = await _call<List<Object?>>(AppleCalendarMethods.listCalendars);
    return [
      for (final item in raw ?? const [])
        AppleCalendarInfo.fromMap(item! as Map<Object?, Object?>),
    ];
  }

  @override
  Future<List<AppleEventData>> fetchEvents({
    required List<String> calendarIds,
    required int fromMs,
    required int toMs,
  }) async {
    final raw = await _call<List<Object?>>(AppleCalendarMethods.fetchEvents, {
      'calendarIds': calendarIds,
      'fromMs': fromMs,
      'toMs': toMs,
    });
    return [
      for (final item in raw ?? const [])
        AppleEventData.fromMap(item! as Map<Object?, Object?>),
    ];
  }

  @override
  Future<String> createEvent({
    String? calendarId,
    required String title,
    required int startMs,
    required int endMs,
    String? notes,
    String? taskId,
  }) async {
    final id = await _call<String>(AppleCalendarMethods.createEvent, {
      'calendarId': calendarId,
      'title': title,
      'startMs': startMs,
      'endMs': endMs,
      'notes': notes,
      'taskId': taskId,
    });
    if (id == null) {
      throw const AppleCalendarException('eventKit', 'No event identifier');
    }
    return id;
  }

  @override
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required int startMs,
    required int endMs,
    String? notes,
    String? taskId,
  }) => _call<void>(AppleCalendarMethods.updateEvent, {
    'eventId': eventId,
    'title': title,
    'startMs': startMs,
    'endMs': endMs,
    'notes': notes,
    'taskId': taskId,
  });

  @override
  Future<void> deleteEvent(String eventId) =>
      _call<void>(AppleCalendarMethods.deleteEvent, {'eventId': eventId});

  @override
  Stream<void> get changes => _changes ??= _events
      .receiveBroadcastStream()
      .where((e) => e == AppleCalendarMethods.changeEvent)
      .map<void>((_) {})
      .asBroadcastStream();
}

/// In-memory EventKit for tests and previews. Behaves like the plugin:
/// write-only cannot read, a denied/restricted request does not change the
/// status, a missing id is `notFound`.
class FakeAppleCalendarChannel implements AppleCalendarChannel {
  FakeAppleCalendarChannel({
    this.status = AppleAuthStatus.notDetermined,
    this.answerToPrompt = true,
    List<AppleCalendarInfo>? calendars,
    List<AppleEventData>? events,
  }) : calendars =
           calendars ??
           [
             const AppleCalendarInfo(
               id: 'home',
               title: 'Home',
               isPrimary: true,
             ),
           ],
       events = events ?? [];

  AppleAuthStatus status;

  /// What the user taps when a prompt is shown: true = Allow.
  bool answerToPrompt;
  final List<AppleCalendarInfo> calendars;
  final List<AppleEventData> events;
  final requests = <String>[];
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  /// Simulates an edit in Calendar.app.
  void emitChange() => _changes.add(null);

  Future<AppleAuthStatus> _prompt(AppleAuthStatus grant) async {
    if (status.isFinalNo || status == AppleAuthStatus.fullAccess) {
      return status;
    }
    if (status == AppleAuthStatus.writeOnly &&
        grant == AppleAuthStatus.writeOnly) {
      return status;
    }
    if (answerToPrompt) {
      status = grant;
    } else if (status == AppleAuthStatus.notDetermined) {
      status = AppleAuthStatus.denied;
    }
    return status;
  }

  @override
  Future<AppleAuthStatus> authorizationStatus() async => status;

  @override
  Future<AppleAuthStatus> requestFullAccess() {
    requests.add(AppleCalendarMethods.requestFullAccess);
    return _prompt(AppleAuthStatus.fullAccess);
  }

  @override
  Future<AppleAuthStatus> requestWriteOnlyAccess() {
    requests.add(AppleCalendarMethods.requestWriteOnlyAccess);
    return _prompt(AppleAuthStatus.writeOnly);
  }

  @override
  Future<List<AppleCalendarInfo>> listCalendars() async =>
      status.canRead ? List.of(calendars) : const [];

  @override
  Future<List<AppleEventData>> fetchEvents({
    required List<String> calendarIds,
    required int fromMs,
    required int toMs,
  }) async {
    if (!status.canRead) return const [];
    return events
        .where(
          (e) =>
              calendarIds.contains(e.calendarIdentifier) &&
              e.startMs < toMs &&
              e.endMs > fromMs,
        )
        .toList();
  }

  @override
  Future<String> createEvent({
    String? calendarId,
    required String title,
    required int startMs,
    required int endMs,
    String? notes,
    String? taskId,
  }) async {
    if (!status.isGranted) {
      throw const AppleCalendarException('eventKit', 'Not authorized');
    }
    final calendar = calendars.firstWhere(
      (c) => c.id == calendarId,
      orElse: () => calendars.firstWhere((c) => c.isPrimary),
    );
    final id = 'ek-${_nextId++}';
    events.add(
      AppleEventData(
        eventIdentifier: id,
        calendarIdentifier: calendar.id,
        title: title,
        startMs: startMs,
        endMs: endMs,
        notes: notes,
        url: taskId == null ? null : WriteBackMarker.urlFor(taskId),
      ),
    );
    return id;
  }

  int _indexOf(String eventId) {
    // Write-only access cannot look events up, exactly like EventKit.
    final i = status.canRead
        ? events.indexWhere((e) => e.eventIdentifier == eventId)
        : -1;
    if (i < 0) throw AppleCalendarException('notFound', 'No event $eventId');
    return i;
  }

  @override
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required int startMs,
    required int endMs,
    String? notes,
    String? taskId,
  }) async {
    final i = _indexOf(eventId);
    events[i] = events[i].copyWith(
      title: title,
      startMs: startMs,
      endMs: endMs,
      notes: notes,
      url: taskId == null ? null : WriteBackMarker.urlFor(taskId),
    );
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    events.removeAt(_indexOf(eventId));
  }

  @override
  Stream<void> get changes => _changes.stream;
}
