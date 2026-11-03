import 'package:flutter/foundation.dart';

import '../../tasks/day_bounds.dart' show utcOf;

import '../../../core/core.dart';
import 'goal_metric.dart';
import 'goal_record.dart';
import 'metric_period.dart';
import 'metric_ticks.dart';

/// Fraction at which a goal reads "close to done" (#26).
const closeToDoneThreshold = 0.8;

enum GoalProgressStatus { notStarted, inProgress, closeToDone, completed }

/// A crossing the cheering layer celebrates (#26, Pip / Highlights #28).
/// [metricHit]: a recurring quota was reached for the current period.
enum GoalMilestone { closeToDone, completed, metricHit }

/// Where a goal stands: "8 of 12 lessons · 67%", or for a recurring
/// metric "3 of 4 workouts this week" ([period] set, [current] is the
/// current period's count and [target] the quota).
@immutable
class GoalProgress {
  const GoalProgress({
    required this.current,
    required this.target,
    required this.unit,
    required this.status,
    this.hasMetric = true,
    this.period,
    this.periodStart,
  });

  /// A goal with no metric: only its status says anything.
  const GoalProgress.none({required bool done})
    : current = done ? 1 : 0,
      target = 1,
      unit = '',
      hasMetric = false,
      period = null,
      periodStart = null,
      status = done
          ? GoalProgressStatus.completed
          : GoalProgressStatus.notStarted;

  final int current;
  final int target;
  final String unit;
  final GoalProgressStatus status;
  final bool hasMetric;

  /// Week or month for a recurring metric; null for finite / none.
  final MetricPeriod? period;

  /// Start of the period [current] counts (recurring only).
  final DateTime? periodStart;

  bool get isRecurring => period != null;

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
  /// goal's id (a [MetricSource.linkedTasks] metric and a recurring metric
  /// read them). A recurring metric counts the period holding
  /// [period]`.now` (UTC, Sunday week, now when omitted).
  factory GoalProgress.of(
    GoalRecord goal, {
    List<Task> linkedTasks = const [],
    PeriodContext? period,
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
                .where((t) => t.isDone && !isMetricTick(t))
                .length,
        };
        return GoalProgress(
          current: current < 0 ? 0 : current,
          target: metric.target,
          unit: metric.unit,
          status: statusFor(current, metric.target, done: done),
        );
      case RecurringMetric():
        final ctx = period ?? PeriodContext.utc(DateTime.now().toUtc());
        final bounds = periodOf(metric.period, ctx);
        final current = countInPeriod(linkedTasks, goal.id, bounds);
        return GoalProgress(
          current: current,
          target: metric.quota,
          unit: metric.unit,
          status: statusFor(current, metric.quota, done: done),
          period: metric.period,
          periodStart: utcOf(bounds.start),
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
  /// down never produces one (misses never reset or scold). A recurring
  /// metric only has [GoalMilestone.metricHit], and only within one period
  /// (a new period starting is not a crossing).
  static GoalMilestone? milestoneBetween(
    GoalProgress before,
    GoalProgress after,
  ) {
    if (after.isRecurring) {
      final samePeriod =
          before.isRecurring &&
          before.periodStart == after.periodStart &&
          before.period == after.period;
      if (samePeriod &&
          before.current < before.target &&
          after.current >= after.target) {
        return GoalMilestone.metricHit;
      }
      return null;
    }
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
      other.hasMetric == hasMetric &&
      other.period == period &&
      other.periodStart == periodStart;

  @override
  int get hashCode => Object.hash(
    current,
    target,
    unit,
    status,
    hasMetric,
    period,
    periodStart,
  );
}
