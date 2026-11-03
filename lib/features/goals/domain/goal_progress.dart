import 'package:flutter/foundation.dart';

import '../../../core/core.dart';
import 'goal_metric.dart';
import 'goal_record.dart';

/// Fraction at which a goal reads "close to done" (#26).
const closeToDoneThreshold = 0.8;

enum GoalProgressStatus { notStarted, inProgress, closeToDone, completed }

/// A crossing the cheering layer celebrates (#26, Pip / Highlights #28).
enum GoalMilestone { closeToDone, completed }

/// Where a goal stands: "8 of 12 lessons · 67%".
@immutable
class GoalProgress {
  const GoalProgress({
    required this.current,
    required this.target,
    required this.unit,
    required this.status,
    this.hasMetric = true,
  });

  /// A goal with no metric: only its status says anything.
  const GoalProgress.none({required bool done})
    : current = done ? 1 : 0,
      target = 1,
      unit = '',
      hasMetric = false,
      status = done
          ? GoalProgressStatus.completed
          : GoalProgressStatus.notStarted;

  final int current;
  final int target;
  final String unit;
  final GoalProgressStatus status;
  final bool hasMetric;

  /// 0..1.
  double get fraction => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  /// Rounded percent, 0..100 ("8 of 12" is 67). Never shows 100 before
  /// the target is actually reached.
  int get percent {
    final p = (fraction * 100).round();
    return p == 100 && current < target ? 99 : p;
  }

  bool get isCompleted => status == GoalProgressStatus.completed;
  bool get isCloseToDone => status == GoalProgressStatus.closeToDone;

  /// Progress of [goal]; [linkedTasks] are the tasks whose `goalId` is the
  /// goal's id (only a [MetricSource.linkedTasks] metric reads them).
  factory GoalProgress.of(
    GoalRecord goal, {
    List<Task> linkedTasks = const [],
  }) {
    final done = goal.status == GoalStatus.done;
    final metric = goal.metric;
    switch (metric) {
      case null:
        return GoalProgress.none(done: done);
      case FiniteMetric():
        final current = switch (metric.source) {
          MetricSource.manual => metric.current,
          MetricSource.linkedTasks =>
            linkedTasks
                .where((t) => t.deletedAt == null && t.goalId == goal.id)
                .where((t) => t.isDone)
                .length,
        };
        return GoalProgress(
          current: current < 0 ? 0 : current,
          target: metric.target,
          unit: metric.unit,
          status: statusFor(current, metric.target, done: done),
        );
    }
  }

  /// Thresholds: completed when the count reaches the target (or the goal
  /// is marked done), close to done from 80 %, else started / not started.
  static GoalProgressStatus statusFor(
    int current,
    int target, {
    bool done = false,
  }) {
    if (done || (target > 0 && current >= target)) {
      return GoalProgressStatus.completed;
    }
    if (target > 0 && current / target >= closeToDoneThreshold) {
      return GoalProgressStatus.closeToDone;
    }
    return current > 0
        ? GoalProgressStatus.inProgress
        : GoalProgressStatus.notStarted;
  }

  /// The milestone crossed going from [before] to [after], if any. Going
  /// down never produces one (misses never reset or scold).
  static GoalMilestone? milestoneBetween(
    GoalProgress before,
    GoalProgress after,
  ) {
    if (!before.isCompleted && after.isCompleted) {
      return GoalMilestone.completed;
    }
    if (before.status.index < GoalProgressStatus.closeToDone.index &&
        after.isCloseToDone) {
      return GoalMilestone.closeToDone;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is GoalProgress &&
      other.current == current &&
      other.target == target &&
      other.unit == unit &&
      other.status == status &&
      other.hasMetric == hasMetric;

  @override
  int get hashCode => Object.hash(current, target, unit, status, hasMetric);
}
