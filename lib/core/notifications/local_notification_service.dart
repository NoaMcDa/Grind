import 'dart:async';
import 'dart:convert';

import 'package:grind/core/core.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_codec.dart';
import 'notification_store.dart';
import 'time_zones.dart';

/// Implemented by services that schedule in a named IANA zone.
/// [NotificationSync] keeps it equal to `Preferences.timeZoneName`.
abstract interface class TimeZoneAware {
  set timeZoneName(String name);
}

/// The thin slice of `flutter_local_notifications` the service uses, so the
/// scheduling logic is testable against a fake plugin on the VM. The real
/// one is `FlutterLocalNotificationsBackend`.
abstract interface class LocalNotificationsBackend {
  /// Registers categories and the response callbacks. [onResponse] receives
  /// foreground taps and responses forwarded from the background isolate.
  Future<void> initialize({
    required void Function(RawNotificationResponse) onResponse,
  });

  /// The response that launched the app from terminated, if any.
  Future<RawNotificationResponse?> launchResponse();

  Future<bool> requestPermission();
  Future<bool> hasPermission();

  Future<void> schedule({
    required int platformId,
    required tz.TZDateTime at,
    required String title,
    required String body,
    required String payload,

    /// iOS category (`categoryFor`), null for no action buttons.
    required String? category,
  });

  Future<void> cancel(int platformId);

  /// Removes pending requests only; delivered notifications stay in
  /// Notification Center.
  Future<void> cancelAllPending();
}

/// [NotificationService] over local notifications (iOS).
///
/// - Trims to [maxPending] (below iOS's 64) keeping the soonest.
/// - Keeps an index of platform id -> (notification id, task id) in
///   [NotificationStore] so [cancelForTask] works after a relaunch.
/// - [responses] first replays responses journalled by the background
///   handler while the app was not running, then the launch response, then
///   live ones. See docs/adr/0003-notifications.md.
class LocalNotificationService implements NotificationService, TimeZoneAware {
  LocalNotificationService({
    required LocalNotificationsBackend backend,
    required NotificationStore store,
    Clock clock = const SystemClock(),
    this.maxPending = 60,
    String timeZoneName = 'UTC',
    this.replayJournal = true,
  }) : _backend = backend,
       _store = store,
       _clock = clock,
       _timeZoneName = timeZoneName;

  final LocalNotificationsBackend _backend;
  final NotificationStore _store;
  final Clock _clock;
  final int maxPending;

  /// False in the background isolate: the journal belongs to the next app
  /// launch, and nobody listens to [responses] there.
  final bool replayJournal;
  String _timeZoneName;

  final _live = StreamController<NotificationResponse>.broadcast();
  final List<NotificationResponse> _backlog = [];
  final Map<int, _IndexEntry> _index = {};
  Future<void> _queue = Future.value();

  late final Future<void> _ready = _init();

  /// Ensures the plugin is initialised. Every public method awaits it, so
  /// calling this is optional; `main` may call it early.
  Future<void> get ready => _ready;

  @override
  set timeZoneName(String name) => _timeZoneName = name;

  /// The ids currently scheduled, soonest first (for tests and debugging).
  List<String> get scheduledIds => _index.values.map((e) => e.id).toList();

  Future<void> _init() async {
    await _backend.initialize(onResponse: _onRaw);
    await _loadIndex();
    if (!replayJournal) return;
    for (final raw in await drainPendingResponses(_store)) {
      _emit(raw.decode());
    }
    _emit((await _backend.launchResponse())?.decode());
  }

  void _onRaw(RawNotificationResponse raw) => _emit(raw.decode());

  void _emit(NotificationResponse? r) {
    if (r == null) return;
    if (_live.hasListener) {
      _live.add(r);
    } else {
      final dup = _backlog.any(
        (b) => b.notificationId == r.notificationId && b.action == r.action,
      );
      if (!dup) _backlog.add(r);
    }
  }

  @override
  Stream<NotificationResponse> get responses async* {
    await _ready;
    final pending = List.of(_backlog);
    _backlog.clear();
    for (final r in pending) {
      yield r;
    }
    yield* _live.stream;
  }

  @override
  Future<bool> requestPermission() async {
    await _ready;
    return _backend.requestPermission();
  }

  @override
  Future<bool> hasPermission() async {
    await _ready;
    return _backend.hasPermission();
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) =>
      _serial(() async {
        final now = _clock.now().toUtc();
        final keep =
            notifications.where((n) => n.fireAt.toUtc().isAfter(now)).toList()
              ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
        final trimmed = keep.take(maxPending);
        final location = locationFor(_timeZoneName);

        await _backend.cancelAllPending();
        _index.clear();
        for (final n in trimmed) {
          await _scheduleOne(n, location);
        }
        await _saveIndex();
      });

  /// Replaces only [taskId]'s own reminders (ids `task:<taskId>:…`) with
  /// [notifications], leaving prompts and recurrence occurrences alone.
  /// Used by the background isolate after a snooze or a move, where there
  /// is no full re-plan (recurrence extras live in the main isolate).
  Future<void> replaceTaskReminders(
    String taskId,
    List<ScheduledNotification> notifications,
  ) => _serial(() async {
    final prefix = 'task:$taskId:';
    final stale = [
      for (final e in _index.entries)
        if (e.value.id.startsWith(prefix)) e.key,
    ];
    for (final id in stale) {
      await _backend.cancel(id);
      _index.remove(id);
    }
    final now = _clock.now().toUtc();
    final location = locationFor(_timeZoneName);
    for (final n in notifications) {
      if (!n.fireAt.toUtc().isAfter(now)) continue;
      if (_index.length >= maxPending) break;
      await _scheduleOne(n, location);
    }
    await _saveIndex();
  });

  Future<void> _scheduleOne(
    ScheduledNotification n,
    tz.Location location,
  ) async {
    var pid = platformIdFor(n.id);
    while (_index.containsKey(pid)) {
      pid = (pid + 1) & 0x7fffffff;
    }
    _index[pid] = _IndexEntry(n.id, n.taskId);
    await _backend.schedule(
      platformId: pid,
      at: tz.TZDateTime.from(n.fireAt, location),
      title: n.title,
      body: n.body,
      payload: encodePayload(n),
      category: categoryFor(n.actions),
    );
  }

  @override
  Future<void> cancelForTask(String taskId) => _serial(() async {
    final ids = [
      for (final e in _index.entries)
        if (e.value.taskId == taskId) e.key,
    ];
    for (final id in ids) {
      await _backend.cancel(id);
      _index.remove(id);
    }
    if (ids.isNotEmpty) await _saveIndex();
  });

  Future<void> dispose() => _live.close();

  Future<void> _serial(Future<void> Function() job) {
    final next = _queue.then((_) => _ready).then((_) => job());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _loadIndex() async {
    final raw = await _store.read(indexDocument);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((k, v) {
        final entry = v as Map<String, dynamic>;
        _index[int.parse(k)] = _IndexEntry(
          entry['id'] as String,
          entry['taskId'] as String,
        );
      });
    } on Object {
      _index.clear(); // A corrupt index only costs a stale cancelForTask.
    }
  }

  Future<void> _saveIndex() => _store.write(
    indexDocument,
    jsonEncode({
      for (final e in _index.entries)
        '${e.key}': {'id': e.value.id, 'taskId': e.value.taskId},
    }),
  );
}

class _IndexEntry {
  const _IndexEntry(this.id, this.taskId);
  final String id;
  final String taskId;
}

/// Appends a response to the journal. Called from the background isolate
/// when the main isolate is not running.
Future<void> appendPendingResponse(
  NotificationStore store,
  RawNotificationResponse raw,
) async {
  final list = await _readJournal(store);
  list.add(raw.toJson());
  await store.write(pendingResponsesDocument, jsonEncode(list));
}

/// Reads and clears the journal.
Future<List<RawNotificationResponse>> drainPendingResponses(
  NotificationStore store,
) async {
  final list = await _readJournal(store);
  if (list.isEmpty) return const [];
  await store.delete(pendingResponsesDocument);
  return [
    for (final m in list)
      RawNotificationResponse.fromJson(Map<String, Object?>.from(m as Map)),
  ];
}

Future<List<Object?>> _readJournal(NotificationStore store) async {
  final raw = await store.read(pendingResponsesDocument);
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    return decoded is List ? List<Object?>.of(decoded) : [];
  } on FormatException {
    return [];
  }
}
