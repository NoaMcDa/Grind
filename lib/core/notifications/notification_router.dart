import 'dart:async';

import 'package:grind/core/core.dart';
import 'package:grind/features/recurrence/occurrence_completion.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_scheduler.dart';
import 'reschedule_times.dart';
import 'time_zones.dart';

/// Turns notification responses into task updates and navigation requests.
///
/// - `done`: status done, `completedAt` now, and the task's other pending
///   notifications are cancelled at once (the re-plan would drop them too,
///   but a background isolate has no re-plan). A recurring task (one with a
///   [ReminderRule]) is not completed: the occurrence is (the rule's
///   `lastCompletedAt` is stored), `remindAt` advances to the next
///   occurrence and its other pending reminders stay.
/// - `snooze`, `moveToTonight`, `moveToTomorrow` on a recurring task: ignored.
///   `remindAt` is the series anchor there, and moving it would shift every
///   later occurrence. (Proposed: a one-off snooze on `ReminderRule`.)
/// - `snooze`: `remindAt` moves to 15 minutes after the later of the old
///   reminder and now (a late tap never snoozes into the past),
///   `snoozeCount + 1`. From the second snooze on the scheduler sends the
///   smart-snooze variant instead (#12).
/// - `moveToTonight`: `remindAt` today 20:00 local, or tomorrow 20:00 when
///   that has passed; `snoozeCount` back to 0.
/// - `moveToTomorrow`: the reminder's local time on the next day;
///   `snoozeCount` back to 0.
/// - `startFocus`: emits the task id on [focusRequests]; the app router
///   opens `/focus?taskId=<id>`.
/// - body tap (and "Pick a time"): emits on [opened]; [openLocation] says
///   where to go (prompts have an empty task id).
///
/// Updates go through [TaskRepository.upsert], so [NotificationSync]
/// re-plans the pending set right after.
class NotificationRouter {
  NotificationRouter({
    required TaskRepository tasks,
    required Clock clock,
    NotificationService? notifications,
    PreferencesRepository? preferences,
    ReminderRepository? reminders,
    this.snoozeBy = const Duration(minutes: 15),
  }) : _tasks = tasks,
       _clock = clock,
       _notifications = notifications,
       _prefs = preferences,
       _reminders = reminders;

  final TaskRepository _tasks;
  final Clock _clock;
  final NotificationService? _notifications;
  final PreferencesRepository? _prefs;
  final ReminderRepository? _reminders;
  final Duration snoozeBy;

  final _focus = StreamController<String>.broadcast();
  final _opened = StreamController<NotificationResponse>.broadcast();

  /// Task ids the user wants to focus on now.
  Stream<String> get focusRequests => _focus.stream;

  /// Body taps; the app decides where to go (see [openLocation]).
  Stream<NotificationResponse> get opened => _opened.stream;

  /// Route location for a focus request.
  static String focusLocation(String taskId) =>
      '/focus?taskId=${Uri.encodeQueryComponent(taskId)}';

  /// Route location for a body tap: the task (where "Pick a time" lives),
  /// the evening review for the evening prompt, the highlights for the
  /// weekly recap, or null for the morning prompt (stay on / open Today).
  static String? openLocation(NotificationResponse response) {
    if (response.taskId.isNotEmpty) {
      return '/task/${Uri.encodeComponent(response.taskId)}';
    }
    if (response.notificationId.startsWith(NotificationScheduler.recapPrefix)) {
      return '/highlights';
    }
    if (response.notificationId.startsWith(
      NotificationScheduler.eveningPrefix,
    )) {
      return '/review';
    }
    return null;
  }

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
    final rule = await _reminders?.getForTask(task.id);
    if (rule != null) {
      await _handleRecurring(task, rule, response, now);
      return;
    }
    switch (action) {
      case NotificationAction.done:
        await _tasks.upsert(
          task.copyWith(
            status: TaskStatus.done,
            completedAt: now,
            updatedAt: now,
          ),
        );
        try {
          await _notifications?.cancelForTask(task.id);
        } on Object {
          // Best effort: the next re-plan drops them as well.
        }
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
        final location = await _location();
        await _tasks.upsert(
          task.copyWith(
            remindAt: RescheduleTimes.tonight(now, location),
            snoozeCount: 0,
            updatedAt: now,
          ),
        );
      case NotificationAction.moveToTomorrow:
        final location = await _location();
        await _tasks.upsert(
          task.copyWith(
            remindAt: RescheduleTimes.tomorrow(
              now,
              task.remindAt ?? now,
              location,
            ),
            snoozeCount: 0,
            updatedAt: now,
          ),
        );
      case NotificationAction.startFocus:
        break;
    }
  }

  /// Done completes one occurrence (the series goes on) through
  /// [storeSeriesCompletion], exactly like `TaskActions.completeRecurring`:
  /// the rule's `lastCompletedAt` advances and is stored with the task, so
  /// the re-plan drops that occurrence and schedules the next one. Every
  /// move would shift the series anchor, so those are left alone.
  Future<void> _handleRecurring(
    Task task,
    ReminderRule rule,
    NotificationResponse response,
    DateTime now,
  ) async {
    if (response.action != NotificationAction.done) return;
    final reminders = _reminders;
    if (reminders == null) return;
    // The occurrence this reminder was for (its id carries the fire time),
    // never before the pending one; without a readable id, `remindAt`.
    final fromId = occurrenceOfNotification(
      response.notificationId,
      task.id,
      rule,
    );
    if (fromId != null && isOccurrenceDone(rule, fromId)) return;
    final pending = task.remindAt?.toUtc();
    final occurrenceAt = fromId == null
        ? (pending ?? now)
        : (pending != null && fromId.isBefore(pending) ? pending : fromId);
    final prefs = await _prefs?.get();
    await storeSeriesCompletion(
      tasks: _tasks,
      rules: reminders,
      task: task,
      rule: rule,
      occurrenceAt: occurrenceAt,
      timeZoneName: prefs?.timeZoneName ?? 'UTC',
      now: now,
    );
  }

  Future<tz.Location> _location() async {
    final prefs = await _prefs?.get();
    return locationFor(prefs?.timeZoneName ?? 'UTC');
  }

  Future<void> dispose() async {
    await _focus.close();
    await _opened.close();
  }
}
