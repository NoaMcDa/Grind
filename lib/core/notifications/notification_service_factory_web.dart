import 'package:grind/core/core.dart';

import 'browser_notification_api_web.dart';
import 'web_notification_service.dart';

NotificationService createPlatformNotificationService(Clock clock) =>
    WebNotificationService(JsBrowserNotificationApi(), clock: clock);
