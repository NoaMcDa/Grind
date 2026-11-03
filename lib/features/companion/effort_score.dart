import 'dart:math' as math;

import 'package:grind/core/core.dart';

/// Momentum bands. There is no "bad" level: [quiet] is a resting Pip.
enum MomentumLevel { quiet, steady, strong }

/// One thing that happened, with its weight.
class EffortEvent {
  const EffortEvent(this.at, this.weight, {this.completed = true});
  final DateTime at;
  final double weight;

  /// True for finished work; false for "started or scheduled" nudges, which
  /// feed the score but not the "showed up" days or the week bars.
  final bool completed;
}

/// Pip's 7-day effort score (#32, #33).
///
/// Rolling window of weighted events with exponential decay (half-life
/// [halfLifeDays]), clamped to 0..100. There are no streaks and nothing ever
/// resets: a quiet day only lets older effort fade a little.
class EffortScore {
  const EffortScore({
    required this.value,
    required this.recent,
    required this.carry,
    required this.level,
    required this.showedUpDays,
    required this.dayCounts,
    required this.eventCount,
  });

  /// 0..100.
  final double value;

  /// Part of [value] from the last [recentDays] days (violet in the meter).
  final double recent;

  /// Part of [value] carried over from older days, already decayed (pink).
  final double carry;

  final MomentumLevel level;

  /// Distinct calendar days with any effort in the last 7 (0..7).
  final int showedUpDays;

  /// Effort events per day for the last 7 days, oldest first (today last).
  final List<int> dayCounts;

  final int eventCount;

  static const windowDays = 7;
  static const recentDays = 2;
  static const halfLifeDays = 3.0;

  /// Event weights.
  static const taskDoneWeight = 1.0;
  static const sessionDoneWeight = 1.5;
  static const startedWeight = 0.25;

  /// Weighted sum that maps to a score of 100.
  static const saturation = 8.0;

  static const steadyFrom = 20.0;
  static const strongFrom = 55.0;

  static const empty = EffortScore(
    value: 0,
    recent: 0,
    carry: 0,
    level: MomentumLevel.quiet,
    showedUpDays: 0,
    dayCounts: [0, 0, 0, 0, 0, 0, 0],
    eventCount: 0,
  );

  static MomentumLevel levelFor(double value) => value >= strongFrom
      ? MomentumLevel.strong
      : value >= steadyFrom
      ? MomentumLevel.steady
      : MomentumLevel.quiet;

  /// Turns tasks and sessions into events. Deleted tasks are ignored.
  static List<EffortEvent> eventsOf(
    List<Task> tasks,
    List<FocusSession> sessions,
  ) {
    final out = <EffortEvent>[];
    for (final t in tasks) {
      if (t.deletedAt != null) continue;
      if (t.status == TaskStatus.done) {
        out.add(EffortEvent(t.completedAt ?? t.updatedAt, taskDoneWeight));
      } else if (t.status == TaskStatus.open &&
          (t.isScheduled || t.minutesDone > 0)) {
        out.add(EffortEvent(t.updatedAt, startedWeight, completed: false));
      }
    }
    for (final s in sessions) {
      if (s.completed) {
        out.add(EffortEvent(s.endedAt ?? s.startedAt, sessionDoneWeight));
      }
    }
    return out;
  }

  static double _sum(
    List<EffortEvent> events,
    DateTime now, {
    double maxAgeDays = windowDays + 0.0,
  }) {
    var sum = 0.0;
    for (final e in events) {
      final age = now.difference(e.at).inMinutes / (60 * 24);
      if (age < 0 || age >= maxAgeDays) continue;
      sum += e.weight * math.pow(0.5, age / halfLifeDays);
    }
    return sum;
  }

  static double _scaled(double sum) =>
      (sum / saturation * 100).clamp(0.0, 100.0);

  static DateTime _day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  /// Pure: the same inputs always give the same score.
  static EffortScore compute({
    required List<Task> tasks,
    List<FocusSession> sessions = const [],
    required DateTime now,
  }) {
    final events = eventsOf(tasks, sessions);
    final total = _sum(events, now);
    final value = _scaled(total);
    // Share of the value from the last few days; the rest is carry-over.
    final recentSum = _sum(events, now, maxAgeDays: recentDays + 0.0);
    final recent = total == 0 ? 0.0 : value * (recentSum / total);

    // A quiet day never drops the level: take the better of now and a day ago.
    final yesterday = now.subtract(const Duration(days: 1));
    final before = _scaled(_sum(events, yesterday));
    final level = levelFor(math.max(value, before));

    final today = _day(now);
    final counts = List<int>.filled(windowDays, 0);
    for (final e in events.where((e) => e.completed)) {
      final daysAgo = (today.difference(_day(e.at)).inHours / 24).round();
      if (daysAgo < 0 || daysAgo >= windowDays) continue;
      counts[windowDays - 1 - daysAgo]++;
    }
    return EffortScore(
      value: value,
      recent: recent,
      carry: value - recent,
      level: level,
      showedUpDays: counts.where((c) => c > 0).length,
      dayCounts: counts,
      eventCount: counts.fold(0, (a, b) => a + b),
    );
  }
}
