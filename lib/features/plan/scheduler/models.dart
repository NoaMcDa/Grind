import 'package:grind/core/domain/domain.dart';

import 'time_math.dart';

/// A half-open interval of local time, `[start, end)`.
class Slot {
  const Slot(this.start, this.end);

  final DateTime start;
  final DateTime end;

  int get minutes => end.difference(start).inMinutes;
  bool get isEmpty => !end.isAfter(start);

  bool overlaps(Slot other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  bool contains(Slot other) =>
      !other.start.isBefore(start) && !other.end.isAfter(end);

  @override
  bool operator ==(Object other) =>
      other is Slot && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Slot(${ymd(start)} ${hm(start)}-${hm(end)})';
}

/// One block of a task on the timeline. A splittable task may have several.
class Placement {
  const Placement({
    required this.taskId,
    required this.start,
    required this.end,
    required this.reasons,
    this.locked = false,
  });

  final String taskId;
  final DateTime start;
  final DateTime end;

  /// 1–3 short, human reasons in Pip's tone ("due Thursday").
  final List<String> reasons;

  /// True when the user placed it by hand; copied verbatim.
  final bool locked;

  int get minutes => end.difference(start).inMinutes;
  Slot get slot => Slot(start, end);

  @override
  bool operator ==(Object other) =>
      other is Placement &&
      other.taskId == taskId &&
      other.start == start &&
      other.end == end &&
      other.locked == locked &&
      sameList(other.reasons, reasons);

  @override
  int get hashCode =>
      Object.hash(taskId, start, end, locked, Object.hashAll(reasons));

  @override
  String toString() =>
      'Placement($taskId ${ymd(start)} ${hm(start)}-${hm(end)} $reasons)';
}

/// A task (or the rest of one) the scheduler could not fit, with why.
class UnplacedTask {
  const UnplacedTask({
    required this.taskId,
    required this.reason,
    required this.minutes,
  });

  final String taskId;
  final String reason;

  /// Minutes that did not fit (the whole task, or the remainder of a split).
  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is UnplacedTask &&
      other.taskId == taskId &&
      other.reason == reason &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(taskId, reason, minutes);

  @override
  String toString() => 'UnplacedTask($taskId, $minutes min, $reason)';
}

class DayCapacity {
  const DayCapacity({
    required this.date,
    required this.freeMinutes,
    required this.deepCapacityMinutes,
    required this.demandMinutes,
  });

  /// Local midnight of the day.
  final DateTime date;

  /// Free minutes inside working hours after events, buffers, lunch and the
  /// daily cushion. Locked tasks are *not* subtracted (they count as demand).
  final int freeMinutes;

  /// `min(freeMinutes, maxDeepBlocksPerDay × deepBlockMinutes)`.
  final int deepCapacityMinutes;

  /// Minutes of placements (locked and scheduled) on this day.
  final int demandMinutes;

  @override
  bool operator ==(Object other) =>
      other is DayCapacity &&
      other.date == date &&
      other.freeMinutes == freeMinutes &&
      other.deepCapacityMinutes == deepCapacityMinutes &&
      other.demandMinutes == demandMinutes;

  @override
  int get hashCode =>
      Object.hash(date, freeMinutes, deepCapacityMinutes, demandMinutes);

  @override
  String toString() =>
      'DayCapacity(${ymd(date)} free $freeMinutes deep $deepCapacityMinutes '
      'demand $demandMinutes)';
}

class WeekCapacity {
  const WeekCapacity({
    required this.days,
    required this.freeMinutes,
    required this.demandMinutes,
    required this.overbooked,
    this.deepCapacityMinutes = 0,
    this.deepDemandMinutes = 0,
  });

  static const empty = WeekCapacity(
    days: [],
    freeMinutes: 0,
    demandMinutes: 0,
    overbooked: false,
  );

  final List<DayCapacity> days;
  final int freeMinutes;

  /// Sum of adjusted estimates of every open task handed to the scheduler.
  final int demandMinutes;
  final int deepCapacityMinutes;
  final int deepDemandMinutes;

  /// `demand > free`, or deep demand > deep capacity.
  final bool overbooked;

  @override
  bool operator ==(Object other) =>
      other is WeekCapacity &&
      other.freeMinutes == freeMinutes &&
      other.demandMinutes == demandMinutes &&
      other.overbooked == overbooked &&
      other.deepCapacityMinutes == deepCapacityMinutes &&
      other.deepDemandMinutes == deepDemandMinutes &&
      sameList(other.days, days);

  @override
  int get hashCode => Object.hash(
    freeMinutes,
    demandMinutes,
    overbooked,
    deepCapacityMinutes,
    deepDemandMinutes,
    Object.hashAll(days),
  );

  @override
  String toString() =>
      'WeekCapacity(free $freeMinutes, demand $demandMinutes, '
      'deep $deepDemandMinutes/$deepCapacityMinutes, overbooked $overbooked)';
}

/// "Move this to next week" when the week is overbooked.
class DeferralSuggestion {
  const DeferralSuggestion({
    required this.taskId,
    required this.minutes,
    required this.reason,
  });

  final String taskId;

  /// Adjusted minutes that deferring frees.
  final int minutes;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is DeferralSuggestion &&
      other.taskId == taskId &&
      other.minutes == minutes &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(taskId, minutes, reason);

  @override
  String toString() => 'DeferralSuggestion($taskId, $minutes min, $reason)';
}

/// The scheduler's output.
class Plan {
  const Plan({
    required this.placed,
    required this.unplaced,
    required this.capacity,
    this.deferralSuggestions = const [],
  });

  static const empty = Plan(
    placed: [],
    unplaced: [],
    capacity: WeekCapacity.empty,
  );

  /// Sorted by start, then task id.
  final List<Placement> placed;
  final List<UnplacedTask> unplaced;
  final WeekCapacity capacity;

  /// Lowest score first. Empty unless [WeekCapacity.overbooked].
  final List<DeferralSuggestion> deferralSuggestions;

  List<Placement> placementsFor(String taskId) =>
      placed.where((p) => p.taskId == taskId).toList();

  @override
  bool operator ==(Object other) =>
      other is Plan &&
      other.capacity == capacity &&
      sameList(other.placed, placed) &&
      sameList(other.unplaced, unplaced) &&
      sameList(other.deferralSuggestions, deferralSuggestions);

  @override
  int get hashCode => Object.hash(
    capacity,
    Object.hashAll(placed),
    Object.hashAll(unplaced),
    Object.hashAll(deferralSuggestions),
  );

  @override
  String toString() =>
      'Plan(placed: $placed, unplaced: $unplaced, capacity: $capacity, '
      'deferrals: $deferralSuggestions)';
}

/// Median of the recent actual ÷ estimated ratios for one category.
class DurationStat {
  const DurationStat({required this.median, required this.n});

  /// Running median of the last [window] ratios (medians shrug off the one
  /// 3-hour outlier a mean would absorb). [n] counts every sample seen.
  factory DurationStat.fromRatios(Iterable<double> ratios, {int window = 10}) {
    final all = ratios.toList();
    final recent = all.length > window ? all.sublist(all.length - window) : all;
    if (recent.isEmpty) return const DurationStat(median: 1, n: 0);
    final sorted = [...recent]..sort();
    final mid = sorted.length ~/ 2;
    final median = sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
    return DurationStat(median: median, n: all.length);
  }

  final double median;

  /// Number of samples seen.
  final int n;
}

/// Completed vs planned blocks in one (hour band, energy) cell.
class RateStat {
  const RateStat({required this.completed, required this.planned});

  final int completed;
  final int planned;

  double get rate => planned == 0 ? 0 : completed / planned;
}

enum HourBand {
  /// 05:00–09:00
  earlyMorning,

  /// 09:00–12:00
  morning,

  /// 12:00–17:00
  afternoon,

  /// 17:00–22:00
  evening,

  /// 22:00–05:00
  night;

  static HourBand of(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 9) return earlyMorning;
    if (h >= 9 && h < 12) return morning;
    if (h >= 12 && h < 17) return afternoon;
    if (h >= 17 && h < 22) return evening;
    return night;
  }
}

/// Per-user statistics (phase 2). Everything is optional and gated by a
/// minimum sample size, so a new user gets the same plan as an empty stats
/// object.
class UserStats {
  const UserStats({
    this.durationRatioByCategory = const {},
    this.completionRateByHourBand = const {},
  });

  /// Samples needed before a category's duration ratio is trusted.
  static const minDurationSamples = 5;

  /// Samples needed before a completion-rate cell is trusted.
  static const minCompletionSamples = 10;

  final Map<String, DurationStat> durationRatioByCategory;

  /// Not used for placement in v1; reserved for the phase-2 tie-breaker.
  final Map<HourBand, Map<Energy, RateStat>> completionRateByHourBand;
}

/// Weights of the scoring function. A future learned ranker only changes
/// these numbers, never the scheduler.
class SchedulerWeights {
  const SchedulerWeights({
    this.urgency = 0.40,
    this.importance = 0.25,
    this.priority = 0.20,
    this.quickWin = 0.15,
  });

  final double urgency;
  final double importance;
  final double priority;
  final double quickWin;
}
