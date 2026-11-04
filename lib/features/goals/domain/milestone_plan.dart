import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/core.dart';
import '../../tasks/day_bounds.dart';
import 'goal_metric.dart';
import 'metric_period.dart';
import 'metric_ticks.dart';

/// One milestone as the goal screen shows it (#25): its weekly tasks and,
/// when its date passed while it was open, the date Pip suggests instead.
/// A milestone is never "missed": it is [moved].
@immutable
class MilestoneView {
  const MilestoneView({
    required this.milestone,
    this.tasks = const [],
    this.suggestedDueAt,
  });

  final Milestone milestone;

  /// Non-deleted tasks linked to the milestone, open first, oldest first.
  final List<Task> tasks;

  /// Set when the milestone is open and its date is before today: the same
  /// weekday within the next seven days, at the end of that day.
  final DateTime? suggestedDueAt;

  bool get moved => suggestedDueAt != null;
  int get tasksDone => tasks.where((t) => t.isDone).length;

  @override
  bool operator ==(Object other) =>
      other is MilestoneView &&
      other.milestone == milestone &&
      listEquals(other.tasks, tasks) &&
      other.suggestedDueAt == suggestedDueAt;

  @override
  int get hashCode =>
      Object.hash(milestone, Object.hashAll(tasks), suggestedDueAt);
}

/// The milestone block of a goal: done / total, the next open milestone
/// and the next scheduled task of the whole goal.
@immutable
class MilestonePlan {
  const MilestonePlan({required this.items, this.nextTask});

  static const empty = MilestonePlan(items: []);

  /// In order.
  final List<MilestoneView> items;

  /// The goal's next scheduled open task (any linked task, not only the
  /// milestone ones), or null when nothing is on the calendar.
  final Task? nextTask;

  int get total => items.length;
  int get done => items.where((v) => v.milestone.isDone).length;

  /// 0..1; 0 when there are no milestones.
  double get fraction => total == 0 ? 0 : done / total;

  /// The first open milestone in order.
  MilestoneView? get next {
    for (final v in items) {
      if (!v.milestone.isDone) return v;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is MilestonePlan &&
      listEquals(other.items, items) &&
      other.nextTask == nextTask;

  @override
  int get hashCode => Object.hash(Object.hashAll(items), nextTask);
}

/// Builds the [MilestonePlan] of one goal.
///
/// [milestones] are the goal's (any order), [links] every task link, and
/// [goalTasks] the goal's tasks (`goalId` = the goal). A linked task that
/// is deleted or missing is skipped.
MilestonePlan buildMilestonePlan({
  required List<Milestone> milestones,
  required List<MilestoneTaskLink> links,
  required List<Task> tasks,
  required String goalId,
  required PeriodContext ctx,
}) {
  final byId = {
    for (final t in tasks)
      if (t.deletedAt == null) t.id: t,
  };
  final ordered = [
    for (final m in milestones)
      if (m.goalId == goalId && m.deletedAt == null) m,
  ]..sort(compareMilestones);
  final items = [
    for (final m in ordered)
      MilestoneView(
        milestone: m,
        tasks: [
          for (final l in links)
            if (l.milestoneId == m.id && byId[l.taskId] != null)
              byId[l.taskId]!,
        ]..sort(_openFirst),
        suggestedDueAt: suggestedMoveDate(m, ctx),
      ),
  ];
  return MilestonePlan(
    items: items,
    nextTask: nextScheduledTask(byId.values, goalId, ctx.now),
  );
}

int _openFirst(Task a, Task b) {
  if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
  final c = a.createdAt.compareTo(b.createdAt);
  if (c != 0) return c;
  final t = a.title.compareTo(b.title);
  return t != 0 ? t : a.id.compareTo(b.id);
}

/// The open task of [goalId] whose scheduled block is the soonest that has
/// not ended by [now]. Hidden metric ticks never count.
Task? nextScheduledTask(Iterable<Task> tasks, String goalId, DateTime now) {
  Task? best;
  for (final t in tasks) {
    final start = t.scheduledStart;
    if (start == null ||
        t.deletedAt != null ||
        t.isDone ||
        t.goalId != goalId ||
        isMetricTick(t)) {
      continue;
    }
    final end = t.scheduledEnd ?? start;
    if (!end.isAfter(now) && !start.isAfter(now)) continue;
    if (best == null || start.isBefore(best.scheduledStart!)) best = t;
  }
  return best;
}

/// The new date for an open milestone whose [Milestone.dueAt] is before
/// today in [ctx]'s zone: the same weekday, a whole number of weeks later,
/// in the coming seven days after today ("next week" for one that just
/// slipped). Null when the milestone is done, undated or not yet due.
DateTime? suggestedMoveDate(Milestone m, PeriodContext ctx) {
  final due = m.dueAt;
  if (due == null || m.isDone) return null;
  final today = localDayBoundsIn(ctx.now, ctx.location);
  if (!due.isBefore(today.start)) return null;
  final dueDay = localDayBoundsIn(due, ctx.location).date;
  final t = today.date;
  final gap = DateTime.utc(
    t.year,
    t.month,
    t.day,
  ).difference(DateTime.utc(dueDay.year, dueDay.month, dueDay.day)).inDays;
  // Whole weeks until the weekday falls after today: 1..7 days ahead, so
  // the suggestion is never "today" (no pressure) and never far off.
  final weeks = gap ~/ 7 + 1;
  final day = DateTime(dueDay.year, dueDay.month, dueDay.day + 7 * weeks);
  return endOfLocalDay(day, ctx.location);
}

/// 23:59 on the calendar date [day] in [location], as UTC: how goal and
/// milestone dates are stored.
DateTime endOfLocalDay(DateTime day, tz.Location location) =>
    utcOf(tz.TZDateTime(location, day.year, day.month, day.day, 23, 59));

/// Which week a new milestone task lands in.
enum MilestoneTaskWeek { thisWeek, nextWeek }

/// The week [week] in [ctx]: this week or the one after.
PeriodBounds weekFor(MilestoneTaskWeek week, PeriodContext ctx) {
  final current = periodOf(MetricPeriod.week, ctx);
  return week == MilestoneTaskWeek.thisWeek ? current : current.shift(1);
}
