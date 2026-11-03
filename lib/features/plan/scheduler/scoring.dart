import 'dart:math' as math;

import 'package:grind/core/domain/domain.dart';

import 'models.dart';

/// Lower and upper clamp of the learned duration ratio.
const minDurationRatio = 0.5;
const maxDurationRatio = 3.0;

/// The duration ratio the scheduler applies to [category]: the category's
/// median actual ÷ estimated ratio once it has at least
/// [UserStats.minDurationSamples] samples, clamped to 0.5–3.0; 1.0 before.
double durationRatio(String? category, UserStats stats) {
  if (category == null) return 1;
  final stat = stats.durationRatioByCategory[category];
  if (stat == null || stat.n < UserStats.minDurationSamples) return 1;
  return stat.median.clamp(minDurationRatio, maxDurationRatio).toDouble();
}

/// The estimate the scheduler plans with: `estimate × durationRatio`,
/// rounded to whole minutes, at least 1.
int adjustedMinutes(Task task, UserStats stats) {
  final raw = task.estimatedMinutes * durationRatio(task.category, stats);
  return math.max(1, raw.round());
}

/// Every term of the score, so placements can explain themselves.
class ScoreBreakdown {
  const ScoreBreakdown({
    required this.urgency,
    required this.importance,
    required this.priority,
    required this.momentum,
    required this.stalled,
    required this.perMinute,
    required this.total,
  });

  final double urgency;
  final double importance;
  final double priority;
  final double momentum;
  final double stalled;
  final double perMinute;
  final double total;
}

/// Days a task without a due date is treated as having.
const undatedHorizonDays = 14;

/// The scoring function from docs/research/replanning-architecture.md §6:
///
/// ```
/// days_left  = max(0, (due ?? now+14d) − now) in days
/// work_left  = adjustedMinutes / 60
/// slack      = days_left − work_left / avgFreeHoursPerDay
/// urgency    = clamp(1 − slack / 7, 0, 1)
/// importance = goal?.importance ?? 0.5
/// priority   = (4 − task.priority) / 3
/// momentum   = goal in progress (0 < progress < 1) ? 0.2 : 0
/// stalled    = goal.lastProgressAt < now − 7d ? 0.15 : 0
/// per_minute = (urgency + importance) / max(adjustedMinutes, 15)
/// score = W.urg·urgency + W.imp·importance + W.pri·priority
///       + momentum + stalled + W.quick·per_minute
/// ```
///
/// `days_left` is fractional (minutes ÷ 1440) rather than whole days, so two
/// tasks due on the same day at different hours still order deterministically.
ScoreBreakdown scoreBreakdown(
  Task task,
  Goal? goal,
  DateTime now,
  UserStats stats,
  SchedulerWeights weights,
  double avgFreeHoursPerDay,
) {
  final due = task.dueAt ?? now.add(const Duration(days: undatedHorizonDays));
  final daysLeft = math.max(0, due.difference(now).inMinutes) / (24 * 60);
  final adjusted = adjustedMinutes(task, stats);
  final workLeft = adjusted / 60;
  final perDay = avgFreeHoursPerDay > 0 ? avgFreeHoursPerDay : 1.0;
  final slack = daysLeft - workLeft / perDay;
  final urgency = (1 - slack / 7).clamp(0.0, 1.0).toDouble();
  final importance = goal?.importance ?? 0.5;
  final priority = (4 - task.priority.clamp(1, 3)) / 3;
  final momentum = goal != null && goal.progress > 0 && goal.progress < 1
      ? 0.2
      : 0.0;
  final last = goal?.lastProgressAt;
  final stalled =
      last != null && last.isBefore(now.subtract(const Duration(days: 7)))
      ? 0.15
      : 0.0;
  final perMinute = (urgency + importance) / math.max(adjusted, 15);
  final total =
      weights.urgency * urgency +
      weights.importance * importance +
      weights.priority * priority +
      momentum +
      stalled +
      weights.quickWin * perMinute;
  return ScoreBreakdown(
    urgency: urgency,
    importance: importance,
    priority: priority,
    momentum: momentum,
    stalled: stalled,
    perMinute: perMinute,
    total: total,
  );
}

/// The task's score; higher is placed first. See [scoreBreakdown].
double score(
  Task task,
  Goal? goal,
  DateTime now,
  UserStats stats,
  SchedulerWeights weights,
  double avgFreeHoursPerDay,
) => scoreBreakdown(task, goal, now, stats, weights, avgFreeHoursPerDay).total;
