import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../core/notifications/time_zones.dart';
import '../tasks/day_bounds.dart';
import 'plan_layout.dart' show dateOnly, nextDay, weekOf;
import 'plan_providers.dart';
import 'plan_strings.dart';
import 'scheduler/scheduler.dart' as scheduler;
import 'scheduler/scheduler.dart' show Plan, Placement, UnplacedTask;

/// What "Re-plan with Pip" proposes for one week, before the user applies it.
class PlanProposal {
  const PlanProposal({
    required this.weekStart,
    required this.weekEnd,
    required this.plan,
    required this.tasks,
    required this.location,
  });

  /// Midnight of the first day / of the day after the last day, as
  /// wall-clock values in [location].
  final DateTime weekStart;
  final DateTime weekEnd;

  /// The scheduler's output, as wall-clock values in [location].
  final Plan plan;

  /// The user's zone when the proposal was made.
  final tz.Location location;

  /// The tasks the plan talks about, by id (UTC, as stored).
  final Map<String, Task> tasks;

  /// Placements the user would get by applying (locked ones stay put).
  List<Placement> get changes => [
    for (final p in plan.placed)
      if (!p.locked) p,
  ];

  /// How many of the user's own placements are kept as they are.
  int get keptCount => plan.placed.where((p) => p.locked).length;

  List<UnplacedTask> get unplaced => plan.unplaced;

  String titleOf(String taskId) => tasks[taskId]?.title ?? '';
}

/// The outcome of "Schedule it for me" for one task.
class SingleSchedule {
  const SingleSchedule.placed(Placement this.placement) : unplaced = null;
  const SingleSchedule.unplaced(UnplacedTask this.unplaced) : placement = null;

  final Placement? placement;
  final UnplacedTask? unplaced;

  bool get isPlaced => placement != null;

  /// The one reason to show.
  String get reason => placement?.reasons.first ?? unplaced!.reason;
}

/// Connects the pure scheduler (`scheduler/`) to the repositories, the
/// clock and the selected week. The scheduler works in "local" wall-clock
/// `DateTime`s and the repositories store UTC, so every value is converted
/// here, at the boundary, and nowhere else: instants become wall-clock
/// fields in the user's zone (`Preferences.timeZoneName`, see [zoneWall])
/// and placements go back through [fromZoneWall]. Working hours, "today"
/// and the week are therefore the user's, whatever zone the device is in.
class PlanScheduler {
  PlanScheduler(this._ref);

  final Ref _ref;

  TaskRepository get _tasks => _ref.read(taskRepositoryProvider);
  CalendarRepository get _events => _ref.read(calendarRepositoryProvider);
  DateTime get _nowUtc => _ref.read(clockProvider).now().toUtc();

  Future<Preferences> _prefs() =>
      _ref.read(preferencesRepositoryProvider).get();

  /// Plans the week (by `Preferences.weekStart`) that contains [day].
  ///
  /// Input: every open task except ones the user placed by hand outside
  /// the week (they belong to another week) — pinned tasks inside the week
  /// block their time and are kept; unlocked scheduled tasks may move.
  /// Tasks are planned as one block each, since a task holds a single
  /// `scheduledStart`/`scheduledEnd`. The past part of the current week is
  /// never planned; a past week gives an empty plan.
  Future<PlanProposal> proposeWeek(DateTime day) async {
    final prefs = await _prefs();
    final loc = locationFor(prefs.timeZoneName);
    final week = weekOf(dateOnly(day), prefs.weekStart);
    final start = week.first;
    final end = nextDay(week.last);
    final now = zoneWall(_nowUtc, loc);
    final from = now.isAfter(start) ? now : start;

    final all = await _tasks.getAll();
    final input = [
      for (final t in all)
        if (_isOpen(t) && !_pinnedOutside(t, start, end, loc)) t,
    ];
    final events = await _events.getBetween(
      fromZoneWall(start, loc),
      fromZoneWall(end, loc),
    );

    final plan = from.isBefore(end)
        ? scheduler.plan(
            tasks: [for (final t in input) _toSchedulerTask(t, loc)],
            goals: const {},
            events: [for (final e in events) _toLocalEvent(e, loc)],
            prefs: prefs,
            now: from,
            horizonEnd: end,
          )
        : Plan.empty;
    return PlanProposal(
      weekStart: start,
      weekEnd: end,
      plan: plan,
      tasks: {for (final t in input) t.id: t},
      location: loc,
    );
  }

  /// Writes the proposal's placements (as UTC). Tasks the user pinned, or
  /// that were finished or deleted since the proposal, are left alone.
  /// Returns how many tasks were scheduled.
  Future<int> apply(PlanProposal proposal) async {
    final nowUtc = _nowUtc;
    final loc = proposal.location;
    final updates = <Task>[];
    for (final p in proposal.changes) {
      final t = await _tasks.getById(p.taskId);
      if (t == null || !_isOpen(t) || _isPinned(t)) continue;
      final start = fromZoneWall(p.start, loc);
      final end = fromZoneWall(p.end, loc);
      if (t.scheduledStart == start && t.scheduledEnd == end) continue;
      updates.add(
        t.copyWith(
          scheduledStart: start,
          scheduledEnd: end,
          lockedStart: false,
          updatedAt: nowUtc,
        ),
      );
    }
    if (updates.isNotEmpty) await _tasks.upsertAll(updates);
    return updates.length;
  }

  /// "Schedule it for me": places only [taskId], around every other
  /// scheduled task (treated as fixed) and the calendar, from now to the
  /// scheduler's default horizon (or the task's due date, if later). Writes
  /// the result when it fits.
  Future<SingleSchedule> scheduleOne(String taskId) async {
    final prefs = await _prefs();
    final loc = locationFor(prefs.timeZoneName);
    final task = await _tasks.getById(taskId);
    final now = zoneWall(_nowUtc, loc);
    if (task == null || !_isOpen(task)) {
      return SingleSchedule.unplaced(
        UnplacedTask(
          taskId: taskId,
          reason: PlanStrings.nothingToSchedule,
          minutes: 0,
        ),
      );
    }
    final defaultEnd = scheduler.defaultHorizonEnd(now, prefs);
    final due = task.dueAt == null ? null : zoneWall(task.dueAt!, loc);
    final horizonEnd = due != null && due.isAfter(defaultEnd)
        ? nextDay(due)
        : defaultEnd;

    final all = await _tasks.getAll();
    final others = [
      for (final t in all)
        if (t.id != taskId && _isOpen(t) && t.isScheduled)
          t.copyWith(lockedStart: true),
    ];
    final events = await _events.getBetween(
      _nowUtc,
      fromZoneWall(horizonEnd, loc),
    );
    final target = task.copyWith(
      scheduledStart: null,
      scheduledEnd: null,
      lockedStart: false,
    );
    final plan = scheduler.plan(
      tasks: [
        for (final t in [target, ...others]) _toSchedulerTask(t, loc),
      ],
      goals: const {},
      events: [for (final e in events) _toLocalEvent(e, loc)],
      prefs: prefs,
      now: now,
      horizonEnd: horizonEnd,
    );
    final placed = plan.placementsFor(taskId).where((p) => !p.locked);
    if (placed.isEmpty) {
      final miss = plan.unplaced.where((u) => u.taskId == taskId).firstOrNull;
      return SingleSchedule.unplaced(
        miss ??
            UnplacedTask(
              taskId: taskId,
              reason: PlanStrings.noRoomThisWeek,
              minutes: task.estimatedMinutes,
            ),
      );
    }
    final p = placed.first;
    await _tasks.upsert(
      task.copyWith(
        scheduledStart: fromZoneWall(p.start, loc),
        scheduledEnd: fromZoneWall(p.end, loc),
        lockedStart: false,
        updatedAt: _nowUtc,
      ),
    );
    return SingleSchedule.placed(p);
  }
}

bool _isOpen(Task t) => t.status == TaskStatus.open && t.deletedAt == null;
bool _isPinned(Task t) => t.lockedStart && t.isScheduled;

bool _pinnedOutside(Task t, DateTime start, DateTime end, tz.Location loc) {
  if (!_isPinned(t)) return false;
  final s = zoneWall(t.scheduledStart!, loc);
  final e = zoneWall(t.scheduledEnd!, loc);
  return !(s.isBefore(end) && e.isAfter(start));
}

DateTime? _wall(DateTime? t, tz.Location loc) =>
    t == null ? null : zoneWall(t, loc);

/// UTC → wall clock in [loc], and one block per task (see
/// [PlanScheduler.proposeWeek]).
Task _toSchedulerTask(Task t, tz.Location loc) => t.copyWith(
  dueAt: _wall(t.dueAt, loc),
  remindAt: _wall(t.remindAt, loc),
  scheduledStart: _wall(t.scheduledStart, loc),
  scheduledEnd: _wall(t.scheduledEnd, loc),
  notBefore: _wall(t.notBefore, loc),
  splittable: false,
);

CalendarEvent _toLocalEvent(CalendarEvent e, tz.Location loc) =>
    e.copyWith(start: zoneWall(e.start, loc), end: zoneWall(e.end, loc));

final planSchedulerProvider = Provider<PlanScheduler>(PlanScheduler.new);

/// Free vs planned time for the shown week, for the Plan header.
///
/// Free: working hours minus busy events, buffers, lunch and the daily
/// cushion, from now (in the current week) or the week's start to its end,
/// the same window "Re-plan with Pip" fills. A past week counts whole.
/// Planned: open tasks scheduled in that window.
final planWeekCapacityProvider = Provider.autoDispose<scheduler.WeekCapacity>((
  ref,
) {
  final week = ref.watch(planWeekProvider);
  final prefs = ref.watch(planPrefsProvider);
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final events =
      ref.watch(planWeekEventsProvider).valueOrNull ?? const <CalendarEvent>[];
  final end = nextDay(week.last);
  final loc = locationFor(prefs.timeZoneName);
  // The same window as "Re-plan with Pip", in the same zone.
  final now = zoneWall(ref.watch(clockProvider).now(), loc);
  final start = now.isAfter(week.first) && now.isBefore(end) ? now : week.first;
  final planned = [
    for (final t in tasks)
      if (_isOpen(t) &&
          t.isScheduled &&
          zoneWall(t.scheduledStart!, loc).isBefore(end) &&
          zoneWall(t.scheduledEnd!, loc).isAfter(start))
        _toSchedulerTask(t, loc).copyWith(lockedStart: true),
  ];
  return scheduler.weekCapacity(
    from: start,
    to: end,
    prefs: prefs,
    events: [for (final e in events) _toLocalEvent(e, loc)],
    tasks: planned,
  );
});

/// "14 h free · 9 h planned", or "Overbooked by 2 h · Pip can help".
final planCapacityLineProvider = Provider.autoDispose<String>(
  (ref) => PlanStrings.capacityLine(
    freeMinutes: ref.watch(planWeekCapacityProvider).freeMinutes,
    plannedMinutes: ref.watch(planWeekCapacityProvider).demandMinutes,
  ),
);
