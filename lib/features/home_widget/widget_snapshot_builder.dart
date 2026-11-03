import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notification_scheduler.dart';
import 'package:grind/features/companion/effort_score.dart';

import 'widget_snapshot.dart';

/// Pure builder: turns the current notification plan and the momentum
/// score into a [WidgetSnapshot] the iOS widget reads through the App
/// Group (#23). No I/O, no plugin — the writer slice calls this and hands
/// the JSON to `home_widget.saveWidgetData`.
///
/// Why pure: the snapshot has to match what the OS would show next, and
/// the scheduler already computes exactly that set. Reading tasks a second
/// time would mean two sources of truth drifting apart.
abstract final class WidgetSnapshotBuilder {
  /// Builds the snapshot. [plan] is [NotificationScheduler.plan]'s output
  /// (soonest first); [momentum] comes from [EffortScore.compute].
  ///
  /// [now] is the writer's current time; the builder drops plan entries
  /// that already fired, so a snapshot saved in the background does not
  /// show a reminder the user already saw.
  static WidgetSnapshot build({
    required List<ScheduledNotification> plan,
    required EffortScore momentum,
    required DateTime now,
  }) {
    return WidgetSnapshot(
      writtenAt: now.toUtc(),
      nextReminder: _pickNextReminder(plan, now.toUtc()),
      momentum: WidgetMomentum(
        value: momentum.value,
        level: momentum.level.name,
        showedUpDays: momentum.showedUpDays,
        dayCounts: List<int>.unmodifiable(momentum.dayCounts),
      ),
    );
  }

  /// Soonest task reminder still in the future. The daily prompts and the
  /// weekly recap ([NotificationScheduler.isPrompt]) are skipped because
  /// they carry no task to act on.
  static WidgetReminder? _pickNextReminder(
    List<ScheduledNotification> plan,
    DateTime nowUtc,
  ) {
    for (final n in plan) {
      if (n.taskId.isEmpty) continue;
      if (NotificationScheduler.isPrompt(n.id)) continue;
      if (!n.fireAt.toUtc().isAfter(nowUtc)) continue;
      return WidgetReminder(
        taskId: n.taskId,
        notificationId: n.id,
        fireAt: n.fireAt.toUtc(),
        title: n.title,
        body: n.body,
        canComplete: n.actions.contains(NotificationAction.done),
        canStartFocus: n.actions.contains(NotificationAction.startFocus),
      );
    }
    return null;
  }
}
