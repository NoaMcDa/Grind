import 'dart:async';

import 'package:grind/core/core.dart';

/// The browser Notification API, reduced to what [WebNotificationService]
/// needs. The real implementation is `browser_notification_api_web.dart`
/// (`dart:js_interop`); tests use a fake, so this file compiles everywhere.
abstract interface class BrowserNotificationApi {
  bool get supported;

  /// `granted`, `denied` or `default`.
  String get permission;
  Future<String> requestPermission();

  void show({
    required String title,
    required String body,
    required String tag,
    required void Function() onClick,
  });
}

/// Best-effort web reminders.
///
/// Honest limits: notifications fire only while a Grind tab is open, from a
/// `Timer` per pending item. Nothing fires while the tab is closed, and
/// action buttons (Done / Snooze) are unavailable because they need a
/// service worker; a click opens the app (`action == null`). Background
/// delivery needs web push, issue #47.
class WebNotificationService implements NotificationService {
  WebNotificationService(this._api, {Clock clock = const SystemClock()})
    : _clock = clock;

  final BrowserNotificationApi _api;
  final Clock _clock;
  final _responses = StreamController<NotificationResponse>.broadcast();
  final Map<String, ({ScheduledNotification n, Timer timer})> _timers = {};

  /// Browsers overflow `setTimeout` past ~24.8 days.
  static const _maxDelay = Duration(days: 24);

  /// Ids with an armed timer (for tests).
  Iterable<String> get armedIds => _timers.keys;

  @override
  Future<bool> hasPermission() async =>
      _api.supported && _api.permission == 'granted';

  @override
  Future<bool> requestPermission() async {
    if (!_api.supported) return false;
    if (_api.permission == 'granted') return true;
    return await _api.requestPermission() == 'granted';
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    for (final t in _timers.values) {
      t.timer.cancel();
    }
    _timers.clear();
    final now = _clock.now().toUtc();
    for (final n in notifications) {
      final delay = n.fireAt.toUtc().difference(now);
      if (delay.isNegative || delay > _maxDelay) continue;
      _timers[n.id] = (n: n, timer: Timer(delay, () => _fire(n)));
    }
  }

  @override
  Future<void> cancelForTask(String taskId) async {
    _timers.removeWhere((_, t) {
      if (t.n.taskId != taskId) return false;
      t.timer.cancel();
      return true;
    });
  }

  @override
  Stream<NotificationResponse> get responses => _responses.stream;

  void _fire(ScheduledNotification n) {
    _timers.remove(n.id);
    if (!_api.supported || _api.permission != 'granted') return;
    _api.show(
      title: n.title,
      body: n.body,
      tag: n.id,
      onClick: () => _responses.add(
        NotificationResponse(notificationId: n.id, taskId: n.taskId),
      ),
    );
  }

  Future<void> dispose() async {
    for (final t in _timers.values) {
      t.timer.cancel();
    }
    _timers.clear();
    await _responses.close();
  }
}
