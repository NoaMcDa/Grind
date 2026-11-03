import 'dart:io';

import 'package:grind/core/core.dart';

import 'file_notification_store.dart';
import 'flutter_local_notifications_backend.dart';
import 'local_notification_service.dart';

NotificationService createPlatformNotificationService(Clock clock) {
  if (Platform.isIOS || Platform.isMacOS) {
    return LocalNotificationService(
      backend: FlutterLocalNotificationsBackend(),
      store: FileNotificationStore(),
      clock: clock,
    );
  }
  // Android is not a target; desktop and `flutter test` get the fake.
  return FakeNotificationService();
}
