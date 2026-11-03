import 'dart:math' as math;

import '../../core/core.dart';
import '../plan/scheduler/scheduler.dart' as sched;
import '../plan/scheduler/scheduler.dart'
    show
        DayCapacity,
        DeferralSuggestion,
        Plan,
        SchedulerWeights,
        UserStats,
        WeekCapacity;

/// How loaded a day or a week is. Never an error: "tight" is a heads-up and
/// "overbooked" is an invitation to move something.
enum LoadState { calm, tight, overbooked }

/// Planned time at or above this share of free time reads as "tight".
const tightShare = 0.85;

/// [planned] against [free] minutes.
LoadState loadStateOf(int free, int planned) {
  if (planned <= 0) return LoadState.calm;
  if (planned > free) return LoadState.overbooked;
  return planned >= free * tightShare ? LoadState.tight : LoadState.calm;
}

/// One day's bar: free and planned minutes.
class DayBar {
  const DayBar({
    required this.date,
    required this.freeMinutes,
    required this.plannedMinutes,
  });

  /// Midnight of the day (wall clock in the user's zone).
  final DateTime date;
  final int freeMinutes;
  final int plannedMinutes;

  LoadState get state => loadStateOf(freeMinutes, plannedMinutes);
}

/// A task Pip suggests moving to next week, with the facts behind it.
class DeferralItem {
  const DeferralItem({
    required this.task,
    required this.minutes,
    this.slackDays,
  });

  final Task task;

  /// Adjusted minutes freed by moving it.
  final int minutes;

  /// Whole days between the end of this week and the due date; null when
  /// the task has no deadline.
  final int? slackDays;
}

/// The week as the capacity screen shows it.
class WeekReport {
  const WeekReport({
    required this.start,
    required this.end,
    required this.capacity,
    required this.days,
    required this.deferrals,
  });

  static final empty = WeekReport(
    start: DateTime(2000),
    end: DateTime(2000, 1, 8),
    capacity: WeekCapacity.empty,
    days: const [],
    deferrals: const [],
  );

  /// Midnight of the first day / of the day after the last, wall clock.
  final DateTime start;
  final DateTime end;
  final WeekCapacity capacity;
  final List<DayBar> days;
  final List<DeferralItem> deferrals;

  int get freeMinutes => capacity.freeMinutes;
  int get plannedMinutes => capacity.demandMinutes;

  /// Minutes over the line, 0 when it fits.
  int get overMinutes => math.max(
    0,
    math.max(
      capacity.demandMinutes - capacity.freeMinutes,
      capacity.deepDemandMinutes - capacity.deepCapacityMinutes,
    ),
  );

  LoadState get verdict {
    if (capacity.overbooked) return LoadState.overbooked;
    return loadStateOf(capacity.freeMinutes, capacity.demandMinutes);
  }
}

/// The open tasks that count against this week: scheduled inside it, or due
/// inside it (or already overdue). Tasks held back with `notBefore` on or
/// after [end] are not this week's.
///
/// All times are wall-clock in one zone (see `PlanScheduler`).
List<Task> weekDemandTasks(
  Iterable<Task> tasks, {
  required DateTime from,
  required DateTime end,
}) => [
  for (final t in tasks)
    if (t.status == TaskStatus.open &&
        t.deletedAt == null &&
        !(t.notBefore != null && !t.notBefore!.isBefore(end)) &&
        (_scheduledIn(t, from, end) ||
            (!t.isScheduled && t.dueAt != null && t.dueAt!.isBefore(end))))
      t,
];

bool _scheduledIn(Task t, DateTime from, DateTime end) =>
    t.isScheduled &&
    t.scheduledStart!.isBefore(end) &&
    t.scheduledEnd!.isAfter(from);

/// Planned minutes per day of [days] (midnights): scheduled tasks by the
/// time they cover (from [from] on), unscheduled ones on their due day
/// (overdue ones on the first day).
List<DayBar> dayBars({
  required List<DayCapacity> free,
  required List<Task> demand,
  required DateTime from,
  required UserStats stats,
}) {
  final planned = List<int>.filled(free.length, 0);
  for (final t in demand) {
    if (t.isScheduled) {
      for (var i = 0; i < free.length; i++) {
        final day = free[i].date;
        final next = DateTime(day.year, day.month, day.day + 1);
        final s = _max(t.scheduledStart!, _max(day, from));
        final e = t.scheduledEnd!.isBefore(next) ? t.scheduledEnd! : next;
        if (e.isAfter(s)) planned[i] += e.difference(s).inMinutes;
      }
    } else if (t.dueAt != null && free.isNotEmpty) {
      var i = free.indexWhere((d) {
        final next = DateTime(d.date.year, d.date.month, d.date.day + 1);
        return t.dueAt!.isBefore(next);
      });
      if (i < 0) i = free.length - 1;
      planned[i] += sched.adjustedMinutes(t, stats);
    }
  }
  return [
    for (var i = 0; i < free.length; i++)
      DayBar(
        date: free[i].date,
        freeMinutes: free[i].freeMinutes,
        plannedMinutes: planned[i],
      ),
  ];
}

DateTime _max(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

/// Builds the report for the week `[weekStart, weekEnd)`.
///
/// Every input is a wall-clock value in the user's zone (tasks and events
/// converted at the boundary, as `PlanScheduler` does). [now] inside the
/// week narrows the window to "from now". [topPinned] tasks stay put: they
/// count as demand but are never suggested for deferral, and neither is
/// anything due inside the week (that is `deferralSuggestions`' own rule).
WeekReport buildWeekReport({
  required DateTime weekStart,
  required DateTime weekEnd,
  required DateTime now,
  required Preferences prefs,
  required List<CalendarEvent> events,
  required List<Task> tasks,
  Map<String, Goal> goals = const {},
  UserStats stats = const UserStats(),
  SchedulerWeights weights = const SchedulerWeights(),
  Set<String> topPinned = const {},
}) {
  final from = now.isAfter(weekStart) && now.isBefore(weekEnd)
      ? now
      : weekStart;
  final demand = weekDemandTasks(tasks, from: from, end: weekEnd);
  final cap = sched.weekCapacity(
    from: from,
    to: weekEnd,
    prefs: prefs,
    events: events,
    tasks: demand,
    stats: stats,
  );
  final suggestions = sched.deferralSuggestions(
    Plan(placed: const [], unplaced: const [], capacity: cap),
    tasks: [
      for (final t in demand)
        if (!topPinned.contains(t.id)) t,
    ],
    goals: goals,
    now: now,
    horizonEnd: weekEnd,
    stats: stats,
    weights: weights,
  );
  final byId = {for (final t in demand) t.id: t};
  return WeekReport(
    start: weekStart,
    end: weekEnd,
    capacity: cap,
    days: dayBars(free: cap.days, demand: demand, from: from, stats: stats),
    deferrals: [
      for (final DeferralSuggestion s in suggestions)
        if (byId[s.taskId] case final t?)
          DeferralItem(
            task: t,
            minutes: s.minutes,
            slackDays: t.dueAt?.difference(weekEnd).inDays,
          ),
    ],
  );
}
