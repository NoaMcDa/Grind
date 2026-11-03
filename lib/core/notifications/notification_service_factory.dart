import 'package:grind/core/core.dart';

import 'notification_service_factory_stub.dart'
    if (dart.library.js_interop) 'notification_service_factory_web.dart'
    if (dart.library.io) 'notification_service_factory_io.dart'
    as impl;

/// The real [NotificationService] for the current platform:
/// - iOS / macOS: `LocalNotificationService` over flutter_local_notifications.
/// - web: `WebNotificationService` (in-tab only, see its docs).
/// - anything else (Android, desktop, tests): [FakeNotificationService].
NotificationService createNotificationService({
  Clock clock = const SystemClock(),
}) => impl.createPlatformNotificationService(clock);
