import 'dart:async';

import 'package:grind/core/core.dart';

import 'notification_scheduler.dart';

/// Turns notification responses into task updates and navigation requests.
///
/// - `done`: status done, `completedAt` now.
/// - `snooze`: `remindAt` moves to 15 minutes after the later of the old
///   reminder and now (a late tap never snoozes into the past),
///   `snoozeCount + 1`.
/// - `startFocus`: emits the task id on [focusRequests]; the app router
///   opens `/focus?taskId=<id>`.
/// - body tap: emits on [opened] (prompts have an empty task id).
///
/// Updates go through [TaskRepository.upsert], so [NotificationSync]
/// re-plans the pending set right after.
class NotificationRouter {
  NotificationRouter({
    required TaskRepository tasks,
    required Clock clock,
    this.snoozeBy = const Duration(minutes: 15),
  }) : _tasks = tasks,
       _clock = clock;

  final TaskRepository _tasks;
  final Clock _clock;
  final Duration snoozeBy;

  final _focus = StreamController<String>.broadcast();
  final _opened = StreamController<NotificationResponse>.broadcast();

  /// Task ids the user wants to focus on now.
  Stream<String> get focusRequests => _focus.stream;

  /// Body taps; the app decides where to go.
  Stream<NotificationResponse> get opened => _opened.stream;

  /// Route location for a focus request.
  static String focusLocation(String taskId) =>
      '/focus?taskId=${Uri.encodeQueryComponent(taskId)}';

  StreamSubscription<NotificationResponse> attach(
    Stream<NotificationResponse> responses,
  ) => responses.listen((r) => unawaited(handle(r)));

  Future<void> handle(NotificationResponse response) async {
    final action = response.action;
    if (action == null) {
      _opened.add(response);
      return;
    }
    if (response.taskId.isEmpty ||
        NotificationScheduler.isPrompt(response.notificationId)) {
      return;
    }
    if (action == NotificationAction.startFocus) {
      _focus.add(response.taskId);
      return;
    }
    final task = await _tasks.getById(response.taskId);
    if (task == null || task.status != TaskStatus.open) return;
    final now = _clock.now().toUtc();
    switch (action) {
      case NotificationAction.done:
        await _tasks.upsert(
          task.copyWith(
            status: TaskStatus.done,
            completedAt: now,
            updatedAt: now,
          ),
        );
      case NotificationAction.snooze:
        final base = task.remindAt?.toUtc();
        final from = base == null || base.isBefore(now) ? now : base;
        await _tasks.upsert(
          task.copyWith(
            remindAt: from.add(snoozeBy),
            snoozeCount: task.snoozeCount + 1,
            updatedAt: now,
          ),
        );
      case NotificationAction.moveToTonight:
      case NotificationAction.moveToTomorrow:
        // Smart snooze (#12) decides the new time; until it lands, treat a
        // move like a snooze so the tap is never lost.
        final base = task.remindAt?.toUtc();
        final from = base == null || base.isBefore(now) ? now : base;
        await _tasks.upsert(
          task.copyWith(
            remindAt: from.add(snoozeBy),
            snoozeCount: task.snoozeCount + 1,
            updatedAt: now,
          ),
        );
      case NotificationAction.startFocus:
        break;
    }
  }

  Future<void> dispose() async {
    await _focus.close();
    await _opened.close();
  }
}
