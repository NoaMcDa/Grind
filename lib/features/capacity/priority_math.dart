import '../../core/core.dart';
import '../plan/scheduler/scheduler.dart' as sched;
import '../plan/scheduler/scheduler.dart'
    show ScoreBreakdown, SchedulerWeights, UserStats;

/// The user's pin on a task. [high], [normal] and [low] write
/// `Task.priority` 1, 2, 3; [top] is `high` plus a "ranks above everything"
/// flag kept in `CapacityConfig.topPinned`.
enum PriorityPin {
  top,
  high,
  normal,
  low;

  /// The `Task.priority` this pin writes.
  int get taskPriority => switch (this) {
    top || high => 1,
    normal => 2,
    low => 3,
  };

  static PriorityPin of(Task t, Set<String> topPinned) {
    if (topPinned.contains(t.id)) return top;
    return switch (t.priority) {
      <= 1 => high,
      2 => normal,
      _ => low,
    };
  }
}

/// Why a task sits where it does. The UI maps each to a Pip-toned line.
enum PriorityReason {
  pinnedTop,
  overdue,
  dueSoon,
  markedHigh,
  goalMatters,
  goalStalled,
  goalMoving,
  quickWin,
  steady,
}

/// One open task with its score, rank and the reasons behind them.
class RankedTask {
  const RankedTask({
    required this.task,
    required this.goal,
    required this.breakdown,
    required this.rank,
    required this.reasons,
    required this.pin,
    required this.adjustedMinutes,
  });

  final Task task;
  final Goal? goal;
  final ScoreBreakdown breakdown;

  /// 1-based.
  final int rank;

  /// Strongest first, at most three; never empty.
  final List<PriorityReason> reasons;
  final PriorityPin pin;
  final int adjustedMinutes;

  double get score => breakdown.total;
  PriorityReason get topReason => reasons.first;
}

/// Ranks [tasks] (open ones only): top-pinned first, then by score
/// (higher first), ties by earlier due date, then id. Pure.
List<RankedTask> rankTasks({
  required Iterable<Task> tasks,
  required Map<String, Goal> goals,
  required DateTime now,
  required UserStats stats,
  required SchedulerWeights weights,
  required double avgFreeHoursPerDay,
  Set<String> topPinned = const {},
}) {
  final rows = <(Task, ScoreBreakdown)>[
    for (final t in tasks)
      if (t.status == TaskStatus.open && t.deletedAt == null)
        (
          t,
          sched.scoreBreakdown(
            t,
            goals[t.goalId],
            now,
            stats,
            weights,
            avgFreeHoursPerDay,
          ),
        ),
  ];
  rows.sort((a, b) {
    final pa = topPinned.contains(a.$1.id), pb = topPinned.contains(b.$1.id);
    if (pa != pb) return pa ? -1 : 1;
    final s = b.$2.total.compareTo(a.$2.total);
    if (s != 0) return s;
    final ad = a.$1.dueAt, bd = b.$1.dueAt;
    if (ad != bd) {
      if (ad == null) return 1;
      if (bd == null) return -1;
      final d = ad.compareTo(bd);
      if (d != 0) return d;
    }
    return a.$1.id.compareTo(b.$1.id);
  });
  return [
    for (var i = 0; i < rows.length; i++)
      RankedTask(
        task: rows[i].$1,
        goal: goals[rows[i].$1.goalId],
        breakdown: rows[i].$2,
        rank: i + 1,
        pin: PriorityPin.of(rows[i].$1, topPinned),
        adjustedMinutes: sched.adjustedMinutes(rows[i].$1, stats),
        reasons: explain(
          rows[i].$1,
          goals[rows[i].$1.goalId],
          rows[i].$2,
          weights,
          now,
          stats,
          pinnedTop: topPinned.contains(rows[i].$1.id),
        ),
      ),
  ];
}

/// The reasons for a score, strongest weighted term first (at most three).
/// A top pin always leads.
List<PriorityReason> explain(
  Task task,
  Goal? goal,
  ScoreBreakdown b,
  SchedulerWeights w,
  DateTime now,
  UserStats stats, {
  bool pinnedTop = false,
}) {
  final terms = <(PriorityReason, double)>[];
  if (b.urgency >= 0.4) {
    final overdue = task.dueAt != null && task.dueAt!.isBefore(now);
    terms.add((
      overdue ? PriorityReason.overdue : PriorityReason.dueSoon,
      w.urgency * b.urgency,
    ));
  }
  if (task.priority <= 1) {
    terms.add((PriorityReason.markedHigh, w.priority * b.priority));
  }
  if (goal != null && b.importance >= 0.7) {
    terms.add((PriorityReason.goalMatters, w.importance * b.importance));
  }
  if (b.stalled > 0) terms.add((PriorityReason.goalStalled, b.stalled));
  if (b.momentum > 0) terms.add((PriorityReason.goalMoving, b.momentum));
  if (sched.adjustedMinutes(task, stats) <= 20) {
    terms.add((PriorityReason.quickWin, w.quickWin * b.perMinute * 20));
  }
  terms.sort((a, b) => b.$2.compareTo(a.$2));
  final out = [
    if (pinnedTop) PriorityReason.pinnedTop,
    ...terms.map((t) => t.$1),
  ];
  if (out.isEmpty) out.add(PriorityReason.steady);
  return out.take(3).toList();
}

/// The feature vector logged with a preference.
Map<String, double> featuresOf(RankedTask r, DateTime now) {
  final b = r.breakdown;
  final due = r.task.dueAt;
  return {
    'urgency': b.urgency,
    'importance': b.importance,
    'priority': b.priority,
    'momentum': b.momentum,
    'stalled': b.stalled,
    'perMinute': b.perMinute,
    'score': b.total,
    'adjustedMinutes': r.adjustedMinutes.toDouble(),
    'hoursToDue': due == null ? -1 : due.difference(now).inMinutes / 60,
    'rank': r.rank.toDouble(),
    'topPinned': r.pin == PriorityPin.top ? 1 : 0,
  };
}
