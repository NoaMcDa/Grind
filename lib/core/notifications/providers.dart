import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';

import 'notification_router.dart';
import 'notification_service_factory.dart';
import 'notification_sync.dart';

/// Applies notification responses to tasks. Reading it attaches it to
/// [notificationServiceProvider]'s response stream.
final notificationRouterProvider = Provider<NotificationRouter>((ref) {
  final router = NotificationRouter(
    tasks: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
    notifications: ref.watch(notificationServiceProvider),
    preferences: ref.watch(preferencesRepositoryProvider),
  );
  final sub = router.attach(ref.watch(notificationServiceProvider).responses);
  ref.onDispose(() {
    sub.cancel();
    router.dispose();
  });
  return router;
});

/// Feature-supplied reminders for the plan. Null by default; the integrator
/// overrides it with the recurrence hook (#11), e.g.
/// `notificationExtraProvider.overrideWith((ref) => ref.watch(recurrenceExtraProvider))`.
final notificationExtraProvider = Provider<ExtraNotifications?>((_) => null);

/// Keeps pending notifications in step with tasks and preferences. Reading
/// it starts listening; the app should also call `refresh()` on launch and
/// `bindAppLifecycle()` once.
final notificationSyncProvider = Provider<NotificationSync>((ref) {
  final sync = NotificationSync(
    tasks: ref.watch(taskRepositoryProvider),
    preferences: ref.watch(preferencesRepositoryProvider),
    reminders: ref.watch(reminderRepositoryProvider),
    service: ref.watch(notificationServiceProvider),
    clock: ref.watch(clockProvider),
    extra: ref.watch(notificationExtraProvider),
  )..start();
  ref.onDispose(sync.dispose);
  return sync;
});

/// Overrides the integrator applies in `main.dart` to swap the fake for the
/// platform service (local notifications on iOS, Notification API on web).
List<Override> notificationOverrides({
  NotificationService? service,
  Clock clock = const SystemClock(),
}) => [
  notificationServiceProvider.overrideWithValue(
    service ?? createNotificationService(clock: clock),
  ),
];
