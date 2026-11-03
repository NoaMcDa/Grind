import 'package:grind/core/core.dart';

import 'local_notification_service.dart';
import 'notification_router.dart';
import 'notification_scheduler.dart';

/// Applies a Lock Screen action (Done, Snooze 15, Tonight, Tomorrow) with no
/// app UI running: the background isolate calls this with the Drift
/// repositories and a [LocalNotificationService] that does not replay the
/// journal.
///
/// The task update goes through the same [NotificationRouter] the app uses.
/// Afterwards only this task's own reminders are re-planned (a snooze or a
/// move schedules the next one at once); prompts and recurring tasks are
/// left to the next full re-plan in the app.
///
/// Throws only if the task update fails, so the caller can fall back to the
/// journal without risking a double apply; notification errors after the
/// update are swallowed (the next launch re-plans anyway).
Future<void> applyResponseInBackground({
  required NotificationResponse response,
  required TaskRepository tasks,
  required PreferencesRepository preferences,
  required Clock clock,
  LocalNotificationService? service,
  ReminderRepository? reminders,
}) async {
  final prefs = await preferences.get();
  service?.timeZoneName = prefs.timeZoneName;
  final router = NotificationRouter(
    tasks: tasks,
    clock: clock,
    notifications: service,
    preferences: preferences,
  );
  try {
    await router.handle(response);
  } finally {
    await router.dispose();
  }
  final action = response.action;
  final moved =
      action == NotificationAction.snooze ||
      action == NotificationAction.moveToTonight ||
      action == NotificationAction.moveToTomorrow;
  if (service == null || !moved) return;
  try {
    final task = await tasks.getById(response.taskId);
    // A recurring task's occurrences share the `task:<id>:` ids and come
    // from the recurrence hook, which only the app runs: leave them.
    if (await reminders?.getForTask(response.taskId) != null) return;
    final next = task == null
        ? const <ScheduledNotification>[]
        : NotificationScheduler.plan(
            tasks: [task],
            prefs: prefs,
            clock: clock,
            prompts: const PromptSettings(
              morningEnabled: false,
              eveningEnabled: false,
            ),
          );
    await service.replaceTaskReminders(response.taskId, next);
  } on Object {
    // Best effort; the app re-plans on its next launch.
  }
}
