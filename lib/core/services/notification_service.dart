/// Actions a user can take on a reminder notification without opening the app.
enum NotificationAction { done, snooze, startFocus }

/// A request to show one notification at one moment.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.taskId,
    required this.fireAt,
    required this.title,
    required this.body,
    this.actions = const [
      NotificationAction.done,
      NotificationAction.snooze,
      NotificationAction.startFocus,
    ],
  });

  /// Stable per (task, occurrence) so rescheduling replaces, not duplicates.
  final String id;
  final String taskId;
  final DateTime fireAt;
  final String title;
  final String body;
  final List<NotificationAction> actions;
}

/// What the user did on a notification; delivered to the app (possibly from
/// a background isolate) so the task can be updated.
class NotificationResponse {
  const NotificationResponse({
    required this.notificationId,
    required this.taskId,
    this.action,
  });

  final String notificationId;
  final String taskId;

  /// Null when the user tapped the notification body (open the app).
  final NotificationAction? action;
}

/// Platform notifications. The real implementation (#5) wraps
/// flutter_local_notifications on iOS and the Notification API on web and
/// enforces the iOS pending limit; [FakeNotificationService] records calls.
abstract interface class NotificationService {
  Future<bool> requestPermission();
  Future<bool> hasPermission();

  /// Replace the whole pending set with [notifications] (the caller decides
  /// the window, e.g. the next 7 days). Implementations may trim to the OS cap.
  Future<void> replaceAll(List<ScheduledNotification> notifications);

  Future<void> cancelForTask(String taskId);

  /// Responses to delivered notifications, including action buttons.
  Stream<NotificationResponse> get responses;
}

class FakeNotificationService implements NotificationService {
  bool permission = true;
  final List<ScheduledNotification> pending = [];
  final List<String> cancelledTaskIds = [];

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    pending
      ..clear()
      ..addAll(notifications);
  }

  @override
  Future<void> cancelForTask(String taskId) async {
    cancelledTaskIds.add(taskId);
    pending.removeWhere((n) => n.taskId == taskId);
  }

  @override
  Stream<NotificationResponse> get responses => const Stream.empty();
}
