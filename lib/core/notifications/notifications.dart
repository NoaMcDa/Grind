/// Notifications infrastructure (#5). Platform-neutral entry point: safe to
/// import on iOS, web and in tests. The plugin backend and file store are
/// reached only through [createNotificationService].
library;

export 'local_notification_service.dart'
    show
        LocalNotificationService,
        LocalNotificationsBackend,
        TimeZoneAware,
        appendPendingResponse,
        drainPendingResponses;
export 'notification_codec.dart';
export 'notification_router.dart';
export 'notification_scheduler.dart';
export 'notification_service_factory.dart';
export 'notification_store.dart';
export 'notification_sync.dart';
export 'providers.dart';
export 'time_zones.dart';
export 'web_notification_service.dart';
