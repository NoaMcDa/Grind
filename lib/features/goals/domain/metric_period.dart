import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/core.dart';
import '../../tasks/day_bounds.dart';
import 'goal_metric.dart';
import 'metric_ticks.dart';

/// "Now" for period math: the instant, the user's zone and week start
/// (`Preferences.timeZoneName`, `Preferences.weekStart`).
@immutable
class PeriodContext {
  const PeriodContext({
    required this.now,
    required this.location,
    this.weekStart = DateTime.sunday,
  });

  /// UTC fallback for callers without preferences (tests, previews).
  PeriodContext.utc(this.now, {this.weekStart = DateTime.sunday})
    : location = tz.UTC;

  final DateTime now;
  final tz.Location location;

  /// `DateTime.monday` .. `DateTime.sunday`.
  final int weekStart;

  @override
  bool operator ==(Object other) =>
      other is PeriodContext &&
      other.now.isAtSameMomentAs(now) &&
      other.location.name == location.name &&
      other.weekStart == weekStart;

  @override
  int get hashCode =>
      Object.hash(now.millisecondsSinceEpoch, location.name, weekStart);
}

/// One week or month in the user's zone: `[start, end)`, both local
/// midnights, so DST changes inside the period never move its edges.
@immutable
class PeriodBounds {
  const PeriodBounds(this.period, this.start, this.end, this.weekStart);

  final MetricPeriod period;
  final tz.TZDateTime start;
  final tz.TZDateTime end;
  final int weekStart;

  tz.Location get location => start.location;

  /// The first day as a floating `DateTime(y, m, d)`.
  DateTime get firstDay => DateTime(start.year, start.month, start.day);

  /// The last day as a floating `DateTime(y, m, d)`.
  DateTime get lastDay {
    final d = firstDay;
    return switch (period) {
      MetricPeriod.week => DateTime(d.year, d.month, d.day + 6),
      MetricPeriod.month => DateTime(d.year, d.month + 1, 0),
    };
  }

  bool contains(DateTime? t) {
    if (t == null) return false;
    return !t.isBefore(start) && t.isBefore(end);
  }

  /// The period [n] steps later (negative: earlier), by calendar date.
  PeriodBounds shift(int n) {
    final d = firstDay;
    return switch (period) {
      MetricPeriod.week => periodStartingOn(
        DateTime(d.year, d.month, d.day + 7 * n),
        period,
        location,
        weekStart,
      ),
      MetricPeriod.month => periodStartingOn(
        DateTime(d.year, d.month + n, 1),
        period,
        location,
        weekStart,
      ),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is PeriodBounds &&
      other.period == period &&
      other.start.isAtSameMomentAs(start) &&
      other.end.isAtSameMomentAs(end);

  @override
  int get hashCode =>
      Object.hash(period, start.millisecondsSinceEpoch, end.hashCode);

  @override
  String toString() => 'PeriodBounds($period, $start, $end)';
}

PeriodBounds periodStartingOn(
  DateTime firstDay,
  MetricPeriod period,
  tz.Location location,
  int weekStart,
) {
  final start = dayBoundsOf(firstDay, location).start;
  final endDay = switch (period) {
    MetricPeriod.week => DateTime(
      firstDay.year,
      firstDay.month,
      firstDay.day + 7,
    ),
    MetricPeriod.month => DateTime(firstDay.year, firstDay.month + 1, 1),
  };
  return PeriodBounds(
    period,
    start,
    dayBoundsOf(endDay, location).start,
    weekStart,
  );
}

/// The week or month in [ctx]'s zone that holds [ctx]`.now`. A week starts
/// on [PeriodContext.weekStart]; a month on the 1st.
PeriodBounds periodOf(MetricPeriod period, PeriodContext ctx) =>
    periodContaining(ctx.now, period, ctx.location, ctx.weekStart);

PeriodBounds periodContaining(
  DateTime instant,
  MetricPeriod period,
  tz.Location location,
  int weekStart,
) {
  final day = localDayBoundsIn(instant, location).date;
  final first = switch (period) {
    MetricPeriod.week => DateTime(
      day.year,
      day.month,
      day.day - (day.weekday - weekStart + 7) % 7,
    ),
    MetricPeriod.month => DateTime(day.year, day.month, 1),
  };
  return periodStartingOn(first, period, location, weekStart);
}

/// One period of a recurring metric's history.
@immutable
class PeriodCount {
  const PeriodCount({
    required this.bounds,
    required this.count,
    required this.quota,
    this.tracked = true,
  });

  final PeriodBounds bounds;
  final int count;
  final int quota;

  /// False for periods that ended before the goal existed: no data, drawn
  /// as an empty slot. A tracked period with 0 is a quiet period: data,
  /// never a broken streak.
  final bool tracked;

  bool get hit => tracked && count >= quota;

  @override
  bool operator ==(Object other) =>
      other is PeriodCount &&
      other.bounds == bounds &&
      other.count == count &&
      other.quota == quota &&
      other.tracked == tracked;

  @override
  int get hashCode => Object.hash(bounds, count, quota, tracked);
}

/// Done, non-deleted tasks of [goalId] completed inside [bounds]: linked
/// tasks and +1 ticks alike.
int countInPeriod(Iterable<Task> tasks, String goalId, PeriodBounds bounds) =>
    tasks
        .where((t) => countsFor(t, goalId) && bounds.contains(t.completedAt))
        .length;

/// Whether [t] counts towards a recurring metric of [goalId].
bool countsFor(Task t, String goalId) =>
    t.deletedAt == null && t.goalId == goalId && t.isDone;

/// The last [periods] periods of [metric], oldest first; the last entry is
/// the current period. Periods that ended before [since] (the goal's
/// creation) are untracked, unless a task was completed in them anyway.
List<PeriodCount> recurringHistory({
  required String goalId,
  required RecurringMetric metric,
  required Iterable<Task> tasks,
  required PeriodContext ctx,
  DateTime? since,
  int periods = 8,
}) {
  final current = periodOf(metric.period, ctx);
  final mine = tasks.where((t) => countsFor(t, goalId)).toList();
  return [
    for (var i = periods - 1; i >= 0; i--)
      () {
        final b = current.shift(-i);
        final count = mine.where((t) => b.contains(t.completedAt)).length;
        final before = since != null && !b.end.isAfter(since);
        return PeriodCount(
          bounds: b,
          count: count,
          quota: metric.quota,
          tracked: !before || count > 0,
        );
      }(),
  ];
}

/// The ticks among [tasks] for [goalId] in [bounds], newest first.
List<Task> ticksInPeriod(
  Iterable<Task> tasks,
  String goalId,
  PeriodBounds bounds,
) =>
    tasks
        .where(
          (t) =>
              isMetricTick(t) &&
              countsFor(t, goalId) &&
              bounds.contains(t.completedAt),
        )
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
