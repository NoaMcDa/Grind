import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../app/logging.dart';
import 'watch_connectivity_service.dart';

/// Names shared with the future `ios/Runner/WatchConnectivityPlugin.swift`.
/// A contract test checks the Swift file uses the same strings once that
/// file lands.
abstract final class WatchConnectivityMethods {
  static const channel = 'grind/watch_connectivity';

  /// Phone → watch.
  static const startSession = 'startSession';
  static const updateSession = 'updateSession';
  static const endSession = 'endSession';
  static const outgoing = [startSession, updateSession, endSession];

  /// Watch → phone: the plugin invokes this one back on the Dart side, with
  /// a [kind] string matching [WatchSessionEventKind.name].
  static const sessionEvent = 'sessionEvent';

  /// Argument keys. Times are epoch milliseconds.
  static const taskTitle = 'taskTitle';
  static const taskId = 'taskId';
  static const endDateMs = 'endDateMs';
  static const paused = 'paused';
  static const pausedAtMs = 'pausedAtMs';
  static const atMs = 'atMs';
  static const kind = 'kind';
  static const keys = [
    taskTitle,
    taskId,
    endDateMs,
    paused,
    pausedAtMs,
    atMs,
    kind,
  ];
}

/// [WatchConnectivityService] over the `grind/watch_connectivity` method
/// channel. iOS only; [watchConnectivityServiceProvider] picks it there.
/// Swallows platform errors (a missing plugin, no paired watch) so the
/// focus session never fails because of the watch.
class MethodChannelWatchConnectivityService
    implements WatchConnectivityService {
  MethodChannelWatchConnectivityService({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(WatchConnectivityMethods.channel) {
    _channel.setMethodCallHandler(_onIncoming);
  }

  final MethodChannel _channel;
  final StreamController<WatchSessionEvent> _events =
      StreamController.broadcast();

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e, st) {
      log('watch connectivity $method failed', error: e, stackTrace: st);
    } on MissingPluginException {
      // Plugin not registered (older build, or a background isolate).
    }
    return null;
  }

  Future<dynamic> _onIncoming(MethodCall call) async {
    handleIncoming(call);
    return null;
  }

  /// The MethodCallHandler the Swift bridge invokes for watch → phone
  /// events. Package-private so the unit test can drive it without a
  /// deprecated binary-messenger call.
  @visibleForTesting
  void handleIncoming(MethodCall call) {
    if (call.method != WatchConnectivityMethods.sessionEvent) return;
    final args = call.arguments;
    if (args is! Map) return;
    final kindName = args[WatchConnectivityMethods.kind];
    WatchSessionEventKind? kind;
    for (final k in WatchSessionEventKind.values) {
      if (k.name == kindName) {
        kind = k;
        break;
      }
    }
    if (kind == null) return;
    if (_events.isClosed) return;
    final atMs = args[WatchConnectivityMethods.atMs];
    _events.add(
      WatchSessionEvent(
        kind: kind,
        taskId: args[WatchConnectivityMethods.taskId] as String?,
        at: atMs is int
            ? DateTime.fromMillisecondsSinceEpoch(atMs, isUtc: true)
            : null,
      ),
    );
  }

  @override
  Future<bool> startSession({
    required String taskTitle,
    required DateTime endDate,
    DateTime? pausedAt,
  }) async {
    final mirrored =
        await _invoke<bool>(WatchConnectivityMethods.startSession, {
          WatchConnectivityMethods.taskTitle: taskTitle,
          WatchConnectivityMethods.endDateMs: endDate.millisecondsSinceEpoch,
          WatchConnectivityMethods.pausedAtMs: pausedAt?.millisecondsSinceEpoch,
        });
    return mirrored ?? false;
  }

  @override
  Future<void> updateSession({
    required bool paused,
    required DateTime endDate,
    DateTime? pausedAt,
  }) => _invoke<void>(WatchConnectivityMethods.updateSession, {
    WatchConnectivityMethods.paused: paused,
    WatchConnectivityMethods.endDateMs: endDate.millisecondsSinceEpoch,
    WatchConnectivityMethods.pausedAtMs: paused
        ? pausedAt?.millisecondsSinceEpoch
        : null,
  });

  @override
  Future<void> endSession() =>
      _invoke<void>(WatchConnectivityMethods.endSession);

  @override
  Stream<WatchSessionEvent> events() => _events.stream;

  /// Releases the broadcast controller and unregisters the incoming
  /// handler. The provider calls this on dispose; tests can call it too.
  /// Idempotent.
  Future<void> dispose() {
    _channel.setMethodCallHandler(null);
    if (_events.isClosed) return Future<void>.value();
    return _events.close();
  }
}
