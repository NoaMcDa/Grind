import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../analytics/analytics_providers.dart';
import '../calendar/sync/task_mirrors.dart';
import '../goals/goal_providers.dart';
import '../plan/plan_layout.dart' show dateOnly, nextDay, weekOf;
import '../plan/scheduler/scheduler.dart'
    show SchedulerWeights, avgFreeHoursPerDay;
import '../tasks/day_bounds.dart';
import 'capacity_math.dart';
import 'capacity_settings.dart';
import 'json_doc_store.dart';
import 'preference_log.dart';
import 'priority_math.dart';

/// The JSON store behind the log and the settings: a file on iOS,
/// `localStorage` on web. Override with [InMemoryJsonDocStore] in tests.
final jsonDocStoreProvider = Provider<JsonDocStore>(
  (_) => platformJsonDocStore(),
);

final preferenceLogProvider = Provider<PreferenceLog>(
  (ref) => JsonPreferenceLog(ref.watch(jsonDocStoreProvider)),
);

final capacitySettingsProvider = Provider<CapacitySettings>(
  (ref) => JsonCapacitySettings(ref.watch(jsonDocStoreProvider)),
);

/// The tuned weights and top pins. Starts at the defaults, then swaps in the
/// stored values when they load.
///
/// The plan scheduler should `ref.watch(capacityConfigProvider).weights` and
/// pass it as `weights:` to `scheduler.plan(...)`.
final capacityConfigProvider =
    NotifierProvider<CapacityConfigNotifier, CapacityConfig>(
      CapacityConfigNotifier.new,
    );

class CapacityConfigNotifier extends Notifier<CapacityConfig> {
  bool _touched = false;
  bool _disposed = false;

  @override
  CapacityConfig build() {
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const CapacityConfig();
  }

  Future<void> _load() async {
    final loaded = await ref.read(capacitySettingsProvider).load();
    if (!_touched && !_disposed) state = loaded;
  }

  Future<void> _set(CapacityConfig c) {
    _touched = true;
    state = c;
    return ref.read(capacitySettingsProvider).save(c);
  }

  Future<void> setWeights(SchedulerWeights w) =>
      _set(state.copyWith(weights: w));

  Future<void> resetWeights() =>
      _set(state.copyWith(weights: const SchedulerWeights()));

  Future<void> setTopPinned(String taskId, bool pinned) {
    final next = {...state.topPinned};
    pinned ? next.add(taskId) : next.remove(taskId);
    return _set(state.copyWith(topPinned: next));
  }
}

/// Midnight of the first day and of the day after the last, for the week
/// that contains today, as wall-clock values in the user's zone.
final capacityWeekRangeProvider =
    Provider.autoDispose<({DateTime start, DateTime end})>((ref) {
      final loc = ref.watch(zoneLocationProvider);
      final prefs =
          ref.watch(preferencesProvider).valueOrNull ?? const Preferences();
      final today = dateOnly(zoneWall(ref.watch(clockProvider).now(), loc));
      final week = weekOf(today, prefs.weekStart);
      return (start: week.first, end: nextDay(week.last));
    });

final _weekEventsProvider = StreamProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  final loc = ref.watch(zoneLocationProvider);
  final r = ref.watch(capacityWeekRangeProvider);
  return ref
      .watch(calendarRepositoryProvider)
      .watchBetween(fromZoneWall(r.start, loc), fromZoneWall(r.end, loc));
});

/// Core goals by id (importance 0..1 for the score).
final capacityGoalsProvider = Provider.autoDispose<Map<String, Goal>>((ref) {
  final all = ref.watch(goalsProvider).valueOrNull ?? const [];
  return {
    for (final g in all)
      if (g.deletedAt == null) g.id: g.toCore(),
  };
});

DateTime? _wall(DateTime? t, tz.Location loc) =>
    t == null ? null : zoneWall(t, loc);

/// The tasks as the scheduler sees them: UTC instants become wall-clock
/// values in [loc] (what `PlanScheduler` does at its boundary).
Task taskToWall(Task t, tz.Location loc) => t.copyWith(
  dueAt: _wall(t.dueAt, loc),
  remindAt: _wall(t.remindAt, loc),
  scheduledStart: _wall(t.scheduledStart, loc),
  scheduledEnd: _wall(t.scheduledEnd, loc),
  notBefore: _wall(t.notBefore, loc),
);

/// Free vs planned time for the current week, per day and in total, with
/// deferral suggestions when overbooked.
final weekReportProvider = Provider.autoDispose<WeekReport>((ref) {
  final loc = ref.watch(zoneLocationProvider);
  final range = ref.watch(capacityWeekRangeProvider);
  final prefs =
      ref.watch(preferencesProvider).valueOrNull ?? const Preferences();
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final events = ref.watch(_weekEventsProvider).valueOrNull ?? const [];
  final config = ref.watch(capacityConfigProvider);
  return buildWeekReport(
    weekStart: range.start,
    weekEnd: range.end,
    now: zoneWall(ref.watch(clockProvider).now(), loc),
    prefs: prefs,
    // The calendar copies of tasks (write-backs, "Add as task" imports)
    // are booked through the tasks; counting the events too would double
    // the planned time.
    events: [
      for (final e in withoutTaskMirrors(events, tasks))
        e.copyWith(start: zoneWall(e.start, loc), end: zoneWall(e.end, loc)),
    ],
    tasks: [for (final t in tasks) taskToWall(t, loc)],
    goals: ref.watch(capacityGoalsProvider),
    stats: ref.watch(userStatsProvider),
    weights: config.weights,
    topPinned: config.topPinned,
  );
});

/// Every open task with its score, rank and reasons, best first.
final priorityRankProvider = Provider.autoDispose<List<RankedTask>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final config = ref.watch(capacityConfigProvider);
  final report = ref.watch(weekReportProvider);
  return rankTasks(
    tasks: tasks,
    goals: ref.watch(capacityGoalsProvider),
    now: ref.watch(clockProvider).now().toUtc(),
    stats: ref.watch(userStatsProvider),
    weights: config.weights,
    avgFreeHoursPerDay: avgFreeHoursPerDay(report.capacity),
    topPinned: config.topPinned,
  );
});

final capacityActionsProvider = Provider<CapacityActions>(CapacityActions.new);

/// Writes: moving tasks to next week, pins and drag reorders.
class CapacityActions {
  CapacityActions(this._ref);

  final Ref _ref;

  TaskRepository get _tasks => _ref.read(taskRepositoryProvider);
  DateTime get _now => _ref.read(clockProvider).now().toUtc();

  /// Moves [taskIds] to next week: unschedules them and holds them back
  /// (`notBefore`) until the first day of next week, so the planner will
  /// only place them from then on. Simpler than re-planning each task and
  /// it cannot collide with this week's plan. Returns how many moved.
  Future<int> deferToNextWeek(Iterable<String> taskIds) async {
    final loc = _ref.read(zoneLocationProvider);
    final nextStart = fromZoneWall(
      _ref.read(capacityWeekRangeProvider).end,
      loc,
    );
    final updates = <Task>[];
    for (final id in taskIds) {
      final t = await _tasks.getById(id);
      if (t == null || t.status != TaskStatus.open || t.deletedAt != null) {
        continue;
      }
      updates.add(
        t.copyWith(
          scheduledStart: null,
          scheduledEnd: null,
          lockedStart: false,
          notBefore: nextStart,
          updatedAt: _now,
        ),
      );
    }
    if (updates.isNotEmpty) await _tasks.upsertAll(updates);
    return updates.length;
  }

  /// Sets [task]'s pin. "Top" also flags the task above every score.
  /// Logs a pairwise preference against the task that was ranked first
  /// (for top) or last (for low).
  Future<void> setPin(Task task, PriorityPin pin) async {
    final ranked = _ref.read(priorityRankProvider);
    final self = ranked.where((r) => r.task.id == task.id).firstOrNull;
    final config = _ref.read(capacityConfigProvider.notifier);
    await config.setTopPinned(task.id, pin == PriorityPin.top);
    if (task.priority != pin.taskPriority) {
      await _tasks.upsert(
        task.copyWith(priority: pin.taskPriority, updatedAt: _now),
      );
    }
    if (self == null) return;
    final other = switch (pin) {
      PriorityPin.top => ranked.firstOrNull,
      PriorityPin.low => ranked.lastOrNull,
      _ => null,
    };
    if (other == null || other.task.id == task.id) return;
    await _log(
      pin == PriorityPin.top ? self : other,
      pin == PriorityPin.top ? other : self,
      'pin',
    );
  }

  /// A drag in the ranked list ([newIndex] as `ReorderableListView` reports
  /// it). Records "moved over the one it jumped" (or "the one above over
  /// the moved one" going down) and nudges the task's pin: to the top it
  /// becomes "top", up elsewhere "high", to the bottom "low", down elsewhere
  /// it takes its new neighbour's priority if lower.
  Future<void> reorder(
    List<RankedTask> ranked,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= ranked.length ||
        newIndex < 0 ||
        newIndex >= ranked.length) {
      return;
    }
    final list = [...ranked];
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    final up = newIndex < oldIndex;
    final above = newIndex > 0 ? list[newIndex - 1] : null;
    final below = newIndex < list.length - 1 ? list[newIndex + 1] : null;

    final PriorityPin pin;
    if (up) {
      // Up to the top: "top". Anywhere else: "high" (the strongest nudge
      // short of top; the score still decides between close neighbours).
      pin = above == null ? PriorityPin.top : PriorityPin.high;
    } else {
      pin = below == null
          ? PriorityPin.low
          : _pinFor(moved, max: below.task.priority);
    }
    final config = _ref.read(capacityConfigProvider.notifier);
    await config.setTopPinned(moved.task.id, pin == PriorityPin.top);
    if (moved.task.priority != pin.taskPriority) {
      await _tasks.upsert(
        moved.task.copyWith(priority: pin.taskPriority, updatedAt: _now),
      );
    }
    if (up) {
      await _log(moved, below!, 'drag');
    } else {
      await _log(above!, moved, 'drag');
    }
  }

  PriorityPin _pinFor(RankedTask moved, {required int max}) {
    var p = moved.task.priority;
    if (max > p) p = max;
    return switch (p) {
      <= 1 => PriorityPin.high,
      2 => PriorityPin.normal,
      _ => PriorityPin.low,
    };
  }

  Future<void> _log(RankedTask winner, RankedTask loser, String source) {
    final now = _now;
    return _ref
        .read(preferenceLogProvider)
        .record(
          PairwisePreference(
            winnerId: winner.task.id,
            loserId: loser.task.id,
            winnerFeatures: featuresOf(winner, now),
            loserFeatures: featuresOf(loser, now),
            at: now,
            source: source,
          ),
        );
  }
}
