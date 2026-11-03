import 'package:flutter/foundation.dart';

import '../../../core/core.dart';
import '../../review/review_repository.dart';
import '../../tasks/day_bounds.dart';
import 'goal_metric.dart';
import 'goal_record.dart';
import 'metric_period.dart';
import 'metric_ticks.dart';

/// A recurring quota reached during the recap week.
@immutable
class MetricHit {
  const MetricHit({
    required this.goal,
    required this.count,
    required this.quota,
    required this.unit,
    required this.period,
  });

  final GoalRecord goal;
  final int count;
  final int quota;
  final String unit;
  final MetricPeriod period;
}

/// What leads the recap (and its notification, #28): the biggest win.
enum RecapLead { goalCompleted, metricHit, win, tasksDone, quiet }

/// The week in review, in Pip's terms: only things that happened.
@immutable
class WeeklyRecap {
  const WeeklyRecap({
    required this.week,
    required this.isCurrentWeek,
    required this.wins,
    required this.metricHits,
    required this.completedGoals,
    required this.movedGoals,
    required this.doneCount,
    required this.rolledOver,
  });

  final PeriodBounds week;

  /// True on the week's last day (the recap of the week now ending);
  /// otherwise this is last week's recap.
  final bool isCurrentWeek;

  /// Wins from the evening reviews, newest first.
  final List<String> wins;
  final List<MetricHit> metricHits;

  /// Goals finished during the week.
  final List<GoalRecord> completedGoals;

  /// Goals with any progress during the week (completed ones included).
  final List<GoalRecord> movedGoals;

  /// Real tasks finished in the week (metric ticks are not tasks).
  final int doneCount;

  /// Tasks the evening reviews moved on to another day.
  final int rolledOver;

  bool get isEmpty =>
      wins.isEmpty &&
      metricHits.isEmpty &&
      movedGoals.isEmpty &&
      doneCount == 0 &&
      rolledOver == 0;

  RecapLead get lead {
    if (completedGoals.isNotEmpty) return RecapLead.goalCompleted;
    if (metricHits.isNotEmpty) return RecapLead.metricHit;
    if (wins.isNotEmpty) return RecapLead.win;
    if (doneCount > 0) return RecapLead.tasksDone;
    return RecapLead.quiet;
  }
}

/// The week the recap covers: the current week on its last day, else the
/// week before (the recap appears once a week has ended).
({PeriodBounds week, bool isCurrent}) recapWeek(PeriodContext ctx) {
  final current = periodOf(MetricPeriod.week, ctx);
  final today = localDayBoundsIn(ctx.now, ctx.location).date;
  final onLastDay = today == current.lastDay;
  return onLastDay
      ? (week: current, isCurrent: true)
      : (week: current.shift(-1), isCurrent: false);
}

/// Builds the recap of [week] from the goals, all tasks and the reviews.
WeeklyRecap buildWeeklyRecap({
  required PeriodBounds week,
  required bool isCurrentWeek,
  required Iterable<GoalRecord> goals,
  required Iterable<Task> tasks,
  required Iterable<ReviewEntry> reviews,
}) {
  final first = _key(week.firstDay);
  final last = _key(week.lastDay);
  final inWeek =
      reviews
          .where(
            (r) => r.date.compareTo(first) >= 0 && r.date.compareTo(last) <= 0,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  final allTasks = tasks.where((t) => t.deletedAt == null).toList();
  final doneInWeek = allTasks
      .where((t) => t.isDone && week.contains(t.completedAt))
      .toList();

  final hits = <MetricHit>[];
  final completed = <GoalRecord>[];
  final moved = <GoalRecord>[];
  for (final g in goals) {
    if (g.deletedAt != null) continue;
    final m = g.metric;
    if (m is RecurringMetric) {
      final hit = _hitDuringWeek(g, m, allTasks, week);
      if (hit != null) hits.add(hit);
    }
    final finishedNow =
        g.status == GoalStatus.done && week.contains(g.updatedAt);
    final finiteReached =
        m is FiniteMetric &&
        m.source == MetricSource.manual &&
        m.current >= m.target &&
        week.contains(g.lastProgressAt);
    if (finishedNow || finiteReached) completed.add(g);
    final anyTask = doneInWeek.any((t) => t.goalId == g.id);
    if (anyTask || week.contains(g.lastProgressAt) || finishedNow) {
      moved.add(g);
    }
  }

  return WeeklyRecap(
    week: week,
    isCurrentWeek: isCurrentWeek,
    wins: [
      for (final r in inWeek)
        if (r.win.trim().isNotEmpty) r.win.trim(),
    ],
    metricHits: hits,
    completedGoals: completed,
    movedGoals: moved,
    doneCount: doneInWeek.where((t) => !isMetricTick(t)).length,
    rolledOver: inWeek.fold(0, (s, r) => s + r.movedCount),
  );
}

/// A weekly quota reached in [week], or a monthly one crossed during it.
MetricHit? _hitDuringWeek(
  GoalRecord g,
  RecurringMetric m,
  List<Task> tasks,
  PeriodBounds week,
) {
  switch (m.period) {
    case MetricPeriod.week:
      final c = countInPeriod(tasks, g.id, week);
      if (c < m.quota) return null;
      return MetricHit(
        goal: g,
        count: c,
        quota: m.quota,
        unit: m.unit,
        period: m.period,
      );
    case MetricPeriod.month:
      final month = periodContaining(
        week.end.subtract(const Duration(milliseconds: 1)),
        MetricPeriod.month,
        week.location,
        week.weekStart,
      );
      int upTo(DateTime t) => tasks
          .where(
            (x) =>
                countsFor(x, g.id) &&
                month.contains(x.completedAt) &&
                x.completedAt!.isBefore(t),
          )
          .length;
      final atEnd = upTo(week.end);
      final atStart = month.contains(week.start) ? upTo(week.start) : 0;
      if (atEnd < m.quota || atStart >= m.quota) return null;
      return MetricHit(
        goal: g,
        count: atEnd,
        quota: m.quota,
        unit: m.unit,
        period: m.period,
      );
  }
}

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
