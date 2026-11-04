import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notification_scheduler.dart';
import 'package:grind/features/companion/effort_score.dart';

import 'watch_snapshot.dart';

/// Pure builder: turns the current notification plan and the momentum
/// score into a [WatchSnapshot] the paired Apple Watch reads through the
/// App Group (#46). No I/O, no plugin — a writer slice calls this and
/// hands the JSON to the shared-container writer.
///
/// Mirrors the home widget's `WidgetSnapshotBuilder` (#23) on purpose:
/// the home widget and the watch complication read the same plan, so the
/// picking rule stays consistent and the Swift decoders stay parallel.
/// The watch dropouts (no 7-day strip, no notification id, no action
/// flags) happen here so the builder's callers do not have to trim by hand.
///
/// Why pure: the snapshot has to match what the OS would show next, and
/// the scheduler already computes exactly that set. Reading tasks a
/// second time would mean two sources of truth drifting apart.
abstract final class WatchSnapshotBuilder {
  /// Builds the snapshot. [plan] is [NotificationScheduler.plan]'s output
  /// (soonest first); [momentum] comes from [EffortScore.compute].
  ///
  /// [now] is the writer's current time; the builder drops plan entries
  /// that already fired so a snapshot saved in the background does not
  /// show a reminder the user already saw.
  ///
  /// [ifThenByTaskId] maps task ids to their if-then first step
  /// ("open the thesis file"). The watch's Pip screen shows it as a
  /// one-line cue; a task missing from the map keeps [WatchReminder.ifThen]
  /// null and the Pip screen hides the cue line.
  static WatchSnapshot build({
    required List<ScheduledNotification> plan,
    required EffortScore momentum,
    required DateTime now,
    Map<String, String> ifThenByTaskId = const {},
  }) {
    return WatchSnapshot(
      writtenAt: now.toUtc(),
      nextReminder: _pickNextReminder(plan, now.toUtc(), ifThenByTaskId),
      momentum: WatchMomentum(
        value: momentum.value,
        level: momentum.level.name,
      ),
    );
  }

  /// Soonest task reminder still in the future. The daily prompts and the
  /// weekly recap ([NotificationScheduler.isPrompt]) are skipped because
  /// they carry no task to act on, and entries with an empty [ScheduledNotification.taskId]
  /// are skipped for the same reason.
  static WatchReminder? _pickNextReminder(
    List<ScheduledNotification> plan,
    DateTime nowUtc,
    Map<String, String> ifThenByTaskId,
  ) {
    for (final n in plan) {
      if (n.taskId.isEmpty) continue;
      if (NotificationScheduler.isPrompt(n.id)) continue;
      if (!n.fireAt.toUtc().isAfter(nowUtc)) continue;
      final ifThen = ifThenByTaskId[n.taskId];
      return WatchReminder(
        taskId: n.taskId,
        fireAt: n.fireAt.toUtc(),
        title: n.title,
        ifThen: (ifThen != null && ifThen.isNotEmpty) ? ifThen : null,
      );
    }
    return null;
  }
}
