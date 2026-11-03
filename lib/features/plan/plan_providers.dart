import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../goals/domain/metric_ticks.dart';
import '../tasks/day_bounds.dart';
import 'plan_layout.dart';

/// The date the Plan tab shows (a floating `DateTime(y, m, d)` in the
/// user's zone). Defaults to today there, per the app clock.
class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => localDayBoundsIn(
    ref.read(clockProvider).now(),
    ref.read(zoneLocationProvider),
  ).date;

  void select(DateTime day) => state = dateOnly(day);
  void shift(int days) =>
      state = DateTime(state.year, state.month, state.day + days);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

/// Today's date in the user's zone, as a Plan day.
final planTodayProvider = Provider.autoDispose<DateTime>(
  (ref) => ref.watch(todayBoundsProvider).date,
);

/// Current time, refreshed every minute (drives the "now" line).
final planNowProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock.now());
});

/// Preferences with defaults while they load.
final planPrefsProvider = Provider<Preferences>(
  (ref) => ref.watch(preferencesProvider).valueOrNull ?? const Preferences(),
);

/// Tasks scheduled on the Plan day [day] in [location] (the device zone
/// without one), by start.
List<Task> tasksOnDay(
  Iterable<Task> tasks,
  DateTime day, [
  tz.Location? location,
]) {
  final b = location == null ? null : planDayUtc(day, location);
  final from = b?.start ?? dateOnly(day);
  final to = b?.end ?? nextDay(day);
  return tasks
      .where(
        (t) =>
            !isMetricTick(t) &&
            t.isScheduled &&
            t.scheduledStart!.isBefore(to) &&
            t.scheduledEnd!.isAfter(from),
      )
      .toList()
    ..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
}

/// Tasks scheduled on the selected day, ordered by start, live (from the
/// repository's `watchAll`).
final planTasksProvider = Provider.autoDispose<List<Task>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  return tasksOnDay(tasks, day, ref.watch(zoneLocationProvider));
});

/// Calendar events on the selected day, live.
final planEventsProvider = StreamProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  final day = planDayUtc(
    ref.watch(selectedDayProvider),
    ref.watch(zoneLocationProvider),
  );
  return ref.watch(calendarRepositoryProvider).watchBetween(day.start, day.end);
});

/// The 7 days of the selected day's week, from `Preferences.weekStart`.
final planWeekProvider = Provider.autoDispose<List<DateTime>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return weekOf(day, ref.watch(planPrefsProvider).weekStart);
});

/// Events across the shown week (for the load bars).
final planWeekEventsProvider = StreamProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  final week = ref.watch(planWeekProvider);
  final location = ref.watch(zoneLocationProvider);
  return ref
      .watch(calendarRepositoryProvider)
      .watchBetween(
        planDayUtc(week.first, location).start,
        planDayUtc(week.last, location).end,
      );
});

/// Booked share (0..1) per day of the shown week.
final planWeekLoadProvider = Provider.autoDispose<Map<DateTime, double>>((ref) {
  final week = ref.watch(planWeekProvider);
  final prefs = ref.watch(planPrefsProvider);
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final events =
      ref.watch(planWeekEventsProvider).valueOrNull ?? const <CalendarEvent>[];
  final location = ref.watch(zoneLocationProvider);
  return {
    for (final d in week)
      d: () {
        final b = planDayUtc(d, location);
        return dayLoad(
          day: d,
          tasks: tasksOnDay(tasks, d, location),
          events: events.where(
            (e) => e.start.isBefore(b.end) && e.end.isAfter(b.start),
          ),
          prefs: prefs,
          location: location,
        );
      }(),
  };
});
