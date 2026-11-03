import 'package:flutter/services.dart';

import '../../../app/logging.dart';
import 'live_activity_service.dart';

/// Names shared with `ios/Runner/LiveActivityPlugin.swift`. The contract test
/// checks the Swift file uses the same strings.
abstract final class LiveActivityMethods {
  static const channel = 'grind/live_activity';
  static const start = 'start';
  static const update = 'update';
  static const end = 'end';
  static const all = [start, update, end];

  /// Argument keys. Times are epoch milliseconds.
  static const taskTitle = 'taskTitle';
  static const endDateMs = 'endDateMs';
  static const accessory = 'accessory';
  static const paused = 'paused';
  static const pausedAtMs = 'pausedAtMs';
  static const focusingLabel = 'focusingLabel';
  static const pausedLabel = 'pausedLabel';
  static const keys = [
    taskTitle,
    endDateMs,
    accessory,
    paused,
    pausedAtMs,
    focusingLabel,
    pausedLabel,
  ];

  /// The widget's tap target. An empty host keeps `/focus` as the URI path,
  /// which is what go_router matches (`grind://focus` would parse as host
  /// `focus` with an empty path and land on `/today`).
  static const deepLink = 'grind:///focus';
}

/// [LiveActivityService] over the `grind/live_activity` method channel. iOS
/// only; [liveActivityServiceProvider] picks it there. Swallows platform
/// errors (a missing plugin, ActivityKit refusing) so the timer never fails
/// because of the Lock Screen.
class MethodChannelLiveActivityService implements LiveActivityService {
  MethodChannelLiveActivityService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(LiveActivityMethods.channel);

  final MethodChannel _channel;

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e, st) {
      log('live activity $method failed', error: e, stackTrace: st);
    } on MissingPluginException {
      // Plugin not registered (older build, or a background isolate).
    }
    return null;
  }

  @override
  Future<bool> start({
    required String taskTitle,
    required DateTime endDate,
    String accessory = 'none',
    DateTime? pausedAt,
    String focusingLabel = 'Focusing',
    String pausedLabel = 'Paused',
  }) async {
    final shown = await _invoke<bool>(LiveActivityMethods.start, {
      LiveActivityMethods.taskTitle: taskTitle,
      LiveActivityMethods.endDateMs: endDate.millisecondsSinceEpoch,
      LiveActivityMethods.accessory: accessory,
      LiveActivityMethods.pausedAtMs: pausedAt?.millisecondsSinceEpoch,
      LiveActivityMethods.focusingLabel: focusingLabel,
      LiveActivityMethods.pausedLabel: pausedLabel,
    });
    return shown ?? false;
  }

  @override
  Future<void> update({
    required bool paused,
    required DateTime endDate,
    DateTime? pausedAt,
  }) => _invoke<void>(LiveActivityMethods.update, {
    LiveActivityMethods.paused: paused,
    LiveActivityMethods.endDateMs: endDate.millisecondsSinceEpoch,
    LiveActivityMethods.pausedAtMs: paused
        ? pausedAt?.millisecondsSinceEpoch
        : null,
  });

  @override
  Future<void> end() => _invoke<void>(LiveActivityMethods.end);
}
