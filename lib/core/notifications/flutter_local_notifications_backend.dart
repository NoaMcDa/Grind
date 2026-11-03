import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/timezone.dart' as tz;

import 'file_notification_store.dart';
import 'local_notification_service.dart';
import 'notification_codec.dart';

/// Port name the main isolate registers so the background handler can hand
/// a response over while the app process is alive.
const notificationResponsePortName = 'grind.notifications.responses';

/// Entry point the plugin runs in a background isolate when the user taps an
/// action without the `foreground` option (Done, Snooze) and iOS launches or
/// resumes the app in the background.
///
/// If the main isolate is alive it gets the response over a port and
/// applies it at once. Otherwise the response is appended to a journal file
/// that [LocalNotificationService] replays on the next launch. The journal
/// is chosen over opening the database here because the database (#2) is
/// not merged yet and two isolates writing one SQLite file needs care; see
/// docs/adr/0003-notifications.md for the follow-up.
@pragma('vm:entry-point')
Future<void> grindNotificationBackgroundHandler(
  fln.NotificationResponse response,
) async {
  final raw = rawFrom(response);
  final port = IsolateNameServer.lookupPortByName(notificationResponsePortName);
  if (port != null) {
    port.send(raw.toJson());
    return;
  }
  DartPluginRegistrant.ensureInitialized();
  await appendPendingResponse(FileNotificationStore(), raw);
}

RawNotificationResponse rawFrom(fln.NotificationResponse r) =>
    RawNotificationResponse(
      platformId: r.id,
      actionId:
          r.notificationResponseType ==
              fln.NotificationResponseType.selectedNotificationAction
          ? r.actionId
          : null,
      payload: r.payload,
    );

/// [LocalNotificationsBackend] over `flutter_local_notifications` v20 for
/// iOS (and macOS, same Darwin settings).
class FlutterLocalNotificationsBackend implements LocalNotificationsBackend {
  FlutterLocalNotificationsBackend([fln.FlutterLocalNotificationsPlugin? p])
    : _plugin = p ?? fln.FlutterLocalNotificationsPlugin();

  final fln.FlutterLocalNotificationsPlugin _plugin;
  ReceivePort? _port;

  static final _darwin = fln.DarwinInitializationSettings(
    // Permission is asked later by requestPermission(), after Pip's
    // rationale screen, never at launch.
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: [
      fln.DarwinNotificationCategory(
        grindReminderCategory,
        actions: [
          fln.DarwinNotificationAction.plain(actionIdDone, 'Done'),
          fln.DarwinNotificationAction.plain(actionIdSnooze, 'Snooze 15'),
          fln.DarwinNotificationAction.plain(
            actionIdStartFocus,
            'Start focus',
            options: {fln.DarwinNotificationActionOption.foreground},
          ),
        ],
      ),
    ],
  );

  fln.IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        fln.IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize({
    required void Function(RawNotificationResponse) onResponse,
  }) async {
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(notificationResponsePortName);
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      notificationResponsePortName,
    );
    port.listen((msg) {
      if (msg is Map) {
        onResponse(
          RawNotificationResponse.fromJson(Map<String, Object?>.from(msg)),
        );
      }
    });
    _port = port;

    await _plugin.initialize(
      settings: fln.InitializationSettings(iOS: _darwin, macOS: _darwin),
      onDidReceiveNotificationResponse: (r) => onResponse(rawFrom(r)),
      onDidReceiveBackgroundNotificationResponse:
          grindNotificationBackgroundHandler,
    );
  }

  @override
  Future<RawNotificationResponse?> launchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final r = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || r == null) return null;
    return rawFrom(r);
  }

  @override
  Future<bool> requestPermission() async =>
      await _ios?.requestPermissions(alert: true, badge: true, sound: true) ??
      false;

  @override
  Future<bool> hasPermission() async =>
      (await _ios?.checkPermissions())?.isEnabled ?? false;

  @override
  Future<void> schedule({
    required int platformId,
    required tz.TZDateTime at,
    required String title,
    required String body,
    required String payload,
    required bool withActions,
  }) {
    final darwin = fln.DarwinNotificationDetails(
      categoryIdentifier: withActions ? grindReminderCategory : null,
      threadIdentifier: 'grind',
    );
    return _plugin.zonedSchedule(
      id: platformId,
      scheduledDate: at,
      notificationDetails: fln.NotificationDetails(iOS: darwin, macOS: darwin),
      androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int platformId) => _plugin.cancel(id: platformId);

  @override
  Future<void> cancelAllPending() => _plugin.cancelAllPendingNotifications();

  void dispose() {
    _port?.close();
    IsolateNameServer.removePortNameMapping(notificationResponsePortName);
  }
}
