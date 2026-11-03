import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/focus/providers.dart';
import 'package:grind/features/plan/scheduler/models.dart';

import 'stats.dart';

const focusDays = 14;
const trendWeeks = 8;

String _tz(Ref ref) =>
    (ref.watch(preferencesProvider).value ?? const Preferences()).timeZoneName;

/// What the plan scheduler should pass as `UserStats` (integrator wires it).
final userStatsProvider = Provider<UserStats>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  return userStatsFrom(tasks, const [], tzName: _tz(ref));
});

/// Focus minutes per day for the last [focusDays] days, today last.
final focusWeekProvider = StreamProvider<List<DayMinutes>>((ref) {
  final now = ref.watch(clockProvider).now();
  final tzName = _tz(ref);
  final from = addLocalDays(now, -(focusDays - 1), tzName);
  final to = addLocalDays(now, 1, tzName);
  return ref
      .watch(focusSessionRepositoryProvider)
      .watchBetween(from.toUtc(), to.toUtc())
      .map((s) => focusMinutesPerDay(s, from, to, tzName));
});

/// Completion rate for the last [trendWeeks] weeks, this week last.
final completionTrendProvider = Provider<List<WeekRate>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final prefs = ref.watch(preferencesProvider).value ?? const Preferences();
  return completionRatePerWeek(
    tasks,
    trendWeeks,
    prefs.weekStart,
    prefs.timeZoneName,
    now: ref.watch(clockProvider).now(),
  );
});

/// Estimate accuracy per category.
final estimateAccuracyProvider = Provider<List<CategoryAccuracy>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  return estimateAccuracy(tasks);
});
