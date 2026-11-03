import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/plan/scheduler/models.dart';
import 'package:grind/features/plan/scheduler/scoring.dart'
    show maxDurationRatio, minDurationRatio;
import 'package:timezone/timezone.dart' as tz;

/// Pure analytics maths (#22). No Flutter, no providers: everything takes
/// plain lists plus a time-zone name, so DST days are testable.

/// Window of recent ratios the running median looks at.
const estimateWindow = 10;

/// Focus minutes on one local calendar day.
class DayMinutes {
  const DayMinutes(this.day, this.minutes);

  /// Local midnight of the day.
  final DateTime day;
  final int minutes;

  /// A day with no focus time. Shown as "rest day", never as a failure.
  bool get isRest => minutes == 0;
}

/// Completed vs planned tasks in one week.
class WeekRate {
  const WeekRate({
    required this.weekStart,
    required this.completed,
    required this.planned,
  });

  /// Local midnight of the first day of the week.
  final DateTime weekStart;
  final int completed;
  final int planned;

  /// 0..1, or null when nothing was planned that week (no 0% to feel bad about).
  double? get rate => planned == 0 ? null : completed / planned;
}

/// How one category's real time compares with its estimates.
class CategoryAccuracy {
  const CategoryAccuracy({
    required this.category,
    required this.ratio,
    required this.n,
  });

  final String category;

  /// Running median of actual / estimated over the last [estimateWindow]
  /// samples, clamped like the scheduler clamps it. 1.0 = on the nose.
  final double ratio;

  /// Every completed task with both numbers seen for this category.
  final int n;

  /// Enough samples for Pip (and the scheduler) to trust [ratio].
  bool get trusted => n >= UserStats.minDurationSamples;
}

tz.TZDateTime _local(DateTime t, tz.Location loc) =>
    tz.TZDateTime.from(t.toUtc(), loc);

tz.TZDateTime _midnight(tz.TZDateTime t, tz.Location loc, [int addDays = 0]) =>
    tz.TZDateTime(loc, t.year, t.month, t.day + addDays);

/// Local midnight at the start of the day that contains [t].
DateTime startOfLocalDay(DateTime t, String tzName) {
  final loc = locationFor(tzName);
  return _midnight(_local(t, loc), loc);
}

/// Local midnight [days] calendar days after the day containing [t].
DateTime addLocalDays(DateTime t, int days, String tzName) {
  final loc = locationFor(tzName);
  return _midnight(_local(t, loc), loc, days);
}

/// Local midnight of the first day of the week containing [t].
/// [weekStart] uses [DateTime.monday]..[DateTime.sunday].
DateTime startOfLocalWeek(DateTime t, int weekStart, String tzName) {
  final loc = locationFor(tzName);
  final l = _local(t, loc);
  final back = (l.weekday - weekStart) % 7;
  return _midnight(l, loc, -back);
}

int _dayKey(tz.TZDateTime t) => t.year * 10000 + t.month * 100 + t.day;

/// Focus minutes for every local calendar day from the day containing [from]
/// up to (excluding) [to], oldest first, zero-filled. A session counts on the
/// day it started; only ended sessions count.
///
/// Later (pause tracking, #19 follow-up): subtract `pausedMs` here.
List<DayMinutes> focusMinutesPerDay(
  Iterable<FocusSession> sessions,
  DateTime from,
  DateTime to,
  String tzName,
) {
  final loc = locationFor(tzName);
  final totals = <int, int>{};
  for (final s in sessions) {
    if (s.endedAt == null) continue;
    if (s.startedAt.isBefore(from) || !s.startedAt.isBefore(to)) continue;
    final m = s.actualMinutes ?? 0; // + subtract pausedMs when it exists
    if (m <= 0) continue;
    final k = _dayKey(_local(s.startedAt, loc));
    totals[k] = (totals[k] ?? 0) + m;
  }
  final out = <DayMinutes>[];
  var d = _midnight(_local(from, loc), loc);
  final end = to.toUtc();
  while (d.toUtc().isBefore(end)) {
    out.add(DayMinutes(d, totals[_dayKey(d)] ?? 0));
    d = _midnight(d, loc, 1);
  }
  return out;
}

/// Completion rate for the last [weeks] weeks ending with the week that
/// contains [now], oldest first. A task belongs to the week of its due date,
/// else its scheduled start, else when it was done, else when it was made.
/// Skipped and deleted tasks are left out.
List<WeekRate> completionRatePerWeek(
  Iterable<Task> tasks,
  int weeks,
  int weekStart,
  String tzName, {
  required DateTime now,
}) {
  final loc = locationFor(tzName);
  final thisWeek = startOfLocalWeek(now, weekStart, tzName) as tz.TZDateTime;
  final starts = [
    for (var i = weeks - 1; i >= 0; i--) _midnight(thisWeek, loc, -7 * i),
  ];
  final ends = [for (final s in starts) _midnight(s, loc, 7)];
  final planned = List.filled(weeks, 0);
  final done = List.filled(weeks, 0);
  for (final t in tasks) {
    if (t.deletedAt != null || t.status == TaskStatus.skipped) continue;
    final a = (t.dueAt ?? t.scheduledStart ?? t.completedAt ?? t.createdAt)
        .toUtc();
    for (var i = 0; i < weeks; i++) {
      if (!a.isBefore(starts[i].toUtc()) && a.isBefore(ends[i].toUtc())) {
        planned[i]++;
        if (t.isDone) done[i]++;
        break;
      }
    }
  }
  return [
    for (var i = 0; i < weeks; i++)
      WeekRate(weekStart: starts[i], completed: done[i], planned: planned[i]),
  ];
}

/// Completed, live tasks that carry a category and both durations, oldest
/// completion first.
Iterable<Task> _measured(Iterable<Task> tasks) {
  final list = tasks
      .where(
        (t) =>
            t.status == TaskStatus.done &&
            t.deletedAt == null &&
            (t.category?.isNotEmpty ?? false) &&
            (t.actualMinutes ?? 0) > 0 &&
            t.estimatedMinutes > 0,
      )
      .toList();
  list.sort(
    (a, b) =>
        (a.completedAt ?? a.updatedAt).compareTo(b.completedAt ?? b.updatedAt),
  );
  return list;
}

Map<String, DurationStat> _durationStats(Iterable<Task> tasks) {
  final byCat = <String, List<double>>{};
  for (final t in _measured(tasks)) {
    byCat
        .putIfAbsent(t.category!, () => [])
        .add(t.actualMinutes! / t.estimatedMinutes);
  }
  return {
    for (final e in byCat.entries)
      e.key: DurationStat.fromRatios(e.value, window: estimateWindow),
  };
}

/// Per-category estimate accuracy, most samples first (then A to Z).
List<CategoryAccuracy> estimateAccuracy(Iterable<Task> tasks) {
  final out = [
    for (final e in _durationStats(tasks).entries)
      CategoryAccuracy(
        category: e.key,
        ratio: e.value.median
            .clamp(minDurationRatio, maxDurationRatio)
            .toDouble(),
        n: e.value.n,
      ),
  ];
  out.sort((a, b) {
    final c = b.n.compareTo(a.n);
    return c != 0 ? c : a.category.compareTo(b.category);
  });
  return out;
}

/// The scheduler's [UserStats] from history (research doc section 3):
/// per-category running median of actual / estimated, only for categories
/// with at least [UserStats.minDurationSamples] samples, clamped to 0.5..3.0;
/// completion rate per (hour band, energy) cell of scheduled tasks, only
/// cells with at least [UserStats.minCompletionSamples] planned.
///
/// [sessions] is accepted now so session-derived actuals can join later;
/// task `actualMinutes` is the source today. Hour bands use [tzName], or the
/// device zone when null.
UserStats userStatsFrom(
  Iterable<Task> tasks,
  Iterable<FocusSession> sessions, {
  String? tzName,
}) {
  final durations = <String, DurationStat>{};
  for (final e in _durationStats(tasks).entries) {
    if (e.value.n < UserStats.minDurationSamples) continue;
    durations[e.key] = DurationStat(
      median: e.value.median.clamp(minDurationRatio, maxDurationRatio),
      n: e.value.n,
    );
  }

  final planned = <HourBand, Map<Energy, int>>{};
  final completed = <HourBand, Map<Energy, int>>{};
  final loc = tzName == null ? null : locationFor(tzName);
  for (final t in tasks) {
    final start = t.scheduledStart;
    if (start == null || t.deletedAt != null) continue;
    if (t.status == TaskStatus.skipped) continue;
    final l = loc == null ? start.toLocal() : _local(start, loc);
    final band = HourBand.of(l);
    final p = planned.putIfAbsent(band, () => {});
    p[t.energy] = (p[t.energy] ?? 0) + 1;
    if (t.isDone) {
      final c = completed.putIfAbsent(band, () => {});
      c[t.energy] = (c[t.energy] ?? 0) + 1;
    }
  }
  final rates = <HourBand, Map<Energy, RateStat>>{};
  for (final b in planned.entries) {
    for (final e in b.value.entries) {
      if (e.value < UserStats.minCompletionSamples) continue;
      rates.putIfAbsent(b.key, () => {})[e.key] = RateStat(
        completed: completed[b.key]?[e.key] ?? 0,
        planned: e.value,
      );
    }
  }
  return UserStats(
    durationRatioByCategory: durations,
    completionRateByHourBand: rates,
  );
}
