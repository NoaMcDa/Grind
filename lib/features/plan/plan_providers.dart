import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import 'plan_layout.dart';
import 'plan_strings.dart';

/// The local date the Plan tab shows. Defaults to today per the app clock.
class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(ref.read(clockProvider).now());

  void select(DateTime day) => state = dateOnly(day);
  void shift(int days) =>
      state = DateTime(state.year, state.month, state.day + days);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

/// "Thu, Oct 29".
final planDayLabelProvider = Provider<String>(
  (ref) => formatPlanDay(ref.watch(selectedDayProvider)),
);

String formatPlanDay(DateTime d) =>
    '${PlanStrings.weekdayShort[d.weekday - 1]}, '
    '${PlanStrings.monthShort[d.month - 1]} ${d.day}';

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

List<Task> tasksOnDay(Iterable<Task> tasks, DateTime day) {
  final from = dateOnly(day);
  final to = nextDay(day);
  return tasks
      .where(
        (t) =>
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
  return tasksOnDay(tasks, day);
});

/// Calendar events on the selected day, live.
final planEventsProvider = StreamProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  final day = ref.watch(selectedDayProvider);
  return ref
      .watch(calendarRepositoryProvider)
      .watchBetween(dateOnly(day).toUtc(), nextDay(day).toUtc());
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
  return ref
      .watch(calendarRepositoryProvider)
      .watchBetween(week.first.toUtc(), nextDay(week.last).toUtc());
});

/// Booked share (0..1) per day of the shown week.
final planWeekLoadProvider = Provider.autoDispose<Map<DateTime, double>>((ref) {
  final week = ref.watch(planWeekProvider);
  final prefs = ref.watch(planPrefsProvider);
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final events =
      ref.watch(planWeekEventsProvider).valueOrNull ?? const <CalendarEvent>[];
  return {
    for (final d in week)
      d: dayLoad(
        day: d,
        tasks: tasksOnDay(tasks, d),
        events: events.where(
          (e) => e.start.isBefore(nextDay(d)) && e.end.isAfter(dateOnly(d)),
        ),
        prefs: prefs,
      ),
  };
});
