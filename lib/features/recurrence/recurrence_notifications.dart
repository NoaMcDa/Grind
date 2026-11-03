import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notification_scheduler.dart';
import 'package:grind/core/notifications/notification_sync.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:timezone/timezone.dart' as tz;

import 'occurrence_expander.dart';

/// The [ExtraNotifications] hook for `NotificationSync(extra: ...)`: for
/// every open task with a recurrence rule, expands the next [horizonDays]
/// days into [ScheduledNotification]s.
///
/// Ids come from [NotificationScheduler.taskNotificationId], so the same
/// occurrence always has the same id and the scheduler's own entry for
/// `Task.remindAt` (lead 0) is de-duplicated. `NotificationScheduler.plan`
/// applies quiet hours, the horizon window and the pending cap afterwards.
ExtraNotifications recurrenceExtraNotifications(
  ReminderRepository rules, {
  required int horizonDays,
  Clock clock = const SystemClock(),
}) {
  return (List<Task> tasks, Preferences prefs) async {
    final all = await rules.getAll();
    if (all.isEmpty) return const [];
    final byTask = {
      for (final r in all)
        if (r.deletedAt == null) r.taskId: r,
    };
    final now = clock.now().toUtc();
    final end = now.add(Duration(days: horizonDays));
    final location = locationFor(prefs.timeZoneName);
    final out = <ScheduledNotification>[];
    for (final task in tasks) {
      final rule = byTask[task.id];
      final anchor = task.remindAt;
      if (rule == null || anchor == null) continue;
      if (task.status != TaskStatus.open || task.deletedAt != null) continue;
      final fires = expandOccurrences(
        rule: rule,
        anchor: anchor,
        from: now,
        to: end,
        timeZoneName: prefs.timeZoneName,
      );
      for (final fire in fires) {
        final occurrence = tz.TZDateTime.from(
          fire.add(Duration(minutes: rule.leadMinutes)),
          location,
        );
        out.add(
          ScheduledNotification(
            id: NotificationScheduler.taskNotificationId(task.id, fire),
            taskId: task.id,
            fireAt: fire.toUtc(),
            title: _title(task),
            body: _body(task, occurrence),
          ),
        );
      }
    }
    return out;
  };
}

// Mirrors NotificationScheduler's private copy builder (title "Grind" plus
// the task title, or the task title plus an if-then "HH:mm — step." body).
String _title(Task task) => _step(task) == null ? 'Grind' : task.title;

String _body(Task task, tz.TZDateTime local) {
  final step = _step(task);
  if (step == null) return task.title;
  String two(int v) => v.toString().padLeft(2, '0');
  final stop = RegExp(r'[.!?]$').hasMatch(step) ? '' : '.';
  return '${two(local.hour)}:${two(local.minute)} — $step$stop';
}

String? _step(Task task) {
  final s = task.firstAction?.trim();
  return s == null || s.isEmpty ? null : s;
}
