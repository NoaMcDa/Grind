import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/timezone.dart' as tz;

import 'package:grind/core/core.dart' show NotificationAction, SystemClock;
import 'package:grind/core/data/data.dart'
    show
        AppDatabase,
        DriftPreferencesRepository,
        DriftReminderRepository,
        DriftTaskRepository,
        openConnection;

import 'background_response.dart';
import 'file_notification_store.dart';
import 'local_notification_service.dart';
import 'notification_codec.dart';

/// Port name the main isolate registers so the background handler can hand
/// a response over while the app process is alive.
const notificationResponsePortName = 'grind.notifications.responses';

/// Entry point the plugin runs in a background isolate when the user taps an
/// action without the `foreground` option (Done, Snooze 15, Tonight,
/// Tomorrow) and iOS launches or resumes the app in the background.
///
/// 1. If the main isolate is alive it gets the response over a port and
///    applies it at once.
/// 2. Otherwise the response is applied right here: open the Drift
///    database, run [NotificationRouter] through [applyResponseInBackground]
///    and re-plan that task's reminders. A killed app therefore shows Done
///    as done on its next launch with nothing left to replay.
/// 3. If opening or writing the database fails, the response is appended
///    to the journal that [LocalNotificationService] replays on the next
///    launch (the wave-1 path, kept as the safety net).
///
/// See docs/adr/0003-notifications.md.
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
  if (await _applyDirectly(raw)) return;
  await appendPendingResponse(FileNotificationStore(), raw);
}

/// True when the response was applied (or there was nothing to apply).
Future<bool> _applyDirectly(RawNotificationResponse raw) async {
  final response = raw.decode();
  if (response == null) return true;
  final action = response.action;
  // Body taps and Start focus open the app; they never reach this isolate,
  // but if they do the journal hands them to the app.
  if (action == null || action == NotificationAction.startFocus) return false;
  AppDatabase? db;
  try {
    db = AppDatabase(openConnection());
    await applyResponseInBackground(
      response: response,
      tasks: DriftTaskRepository(db),
      preferences: DriftPreferencesRepository(db),
      reminders: DriftReminderRepository(db),
      clock: const SystemClock(),
      service: LocalNotificationService(
        backend: FlutterLocalNotificationsBackend.background(),
        store: FileNotificationStore(),
        replayJournal: false,
      ),
    );
    return true;
  } on Object {
    return false;
  } finally {
    try {
      await db?.close();
    } on Object {
      // Closing a database that never opened.
    }
  }
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
    : _plugin = p ?? fln.FlutterLocalNotificationsPlugin(),
      _background = false;

  /// For the background isolate: the plugin is already registered there
  /// (AppDelegate's registrant callback) and `zonedSchedule` / `cancel` work
  /// without `initialize`, which must not run again (it would replace the
  /// main isolate's callbacks and categories).
  FlutterLocalNotificationsBackend.background([
    fln.FlutterLocalNotificationsPlugin? p,
  ]) : _plugin = p ?? fln.FlutterLocalNotificationsPlugin(),
       _background = true;

  final fln.FlutterLocalNotificationsPlugin _plugin;
  final bool _background;
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
      // Smart snooze (#12): after two snoozes, offer to move instead.
      fln.DarwinNotificationCategory(
        grindRescheduleCategory,
        actions: [
          fln.DarwinNotificationAction.plain(actionIdMoveToTonight, 'Tonight'),
          fln.DarwinNotificationAction.plain(
            actionIdMoveToTomorrow,
            'Tomorrow',
          ),
          fln.DarwinNotificationAction.plain(
            actionIdPickTime,
            'Pick a time',
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
    if (_background) return;
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
    if (_background) return null;
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
    required String? category,
  }) {
    final darwin = fln.DarwinNotificationDetails(
      categoryIdentifier: category,
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
