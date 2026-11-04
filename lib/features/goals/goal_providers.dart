import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/core.dart';
import '../review/review_providers.dart';
import '../review/review_repository.dart';
import '../tasks/day_bounds.dart' show utcOf, zoneLocationProvider;
import 'domain/goal_metric.dart';
import 'domain/goal_progress.dart';
import 'domain/goal_record.dart';
import 'domain/goal_repository.dart';
import 'domain/highlights.dart';
import 'domain/metric_period.dart';
import 'domain/metric_ticks.dart';
import 'domain/milestone_plan.dart';
import 'domain/weekly_recap.dart';

/// The goal store. In memory by default; `main.dart` overrides it with
/// `DriftGoalRepository(db, clock: ...)` (see the PR for the override).
final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => InMemoryGoalRepository(clock: ref.watch(clockProvider)),
);

/// Live list of all goals.
final goalsProvider = StreamProvider<List<GoalRecord>>(
  (ref) => ref.watch(goalRepositoryProvider).watchAll(),
);

/// The live goal with [id], or null when missing or deleted.
final goalByIdProvider = Provider.family<GoalRecord?, String>((ref, id) {
  final all = ref.watch(goalsProvider).valueOrNull ?? const <GoalRecord>[];
  return findGoal(all, id);
});

/// The user's week start (`Preferences.weekStart`).
final goalWeekStartProvider = Provider<int>(
  (ref) => ref.watch(
    preferencesProvider.select(
      (p) => p.valueOrNull?.weekStart ?? const Preferences().weekStart,
    ),
  ),
);

/// Period math "now": the clock, the user's zone and week start. Read
/// fresh by every provider that recomputes (on any goal or task change),
/// so a long-lived listener never counts a stale period.
PeriodContext periodContextOf(Ref ref) => PeriodContext(
  now: ref.watch(clockProvider).now().toUtc(),
  location: ref.watch(zoneLocationProvider),
  weekStart: ref.watch(goalWeekStartProvider),
);

/// Every non-deleted task of [goalId], +1 ticks included (the counts read
/// these; lists use [goalLinkedTasksProvider]).
final goalTasksProvider = Provider.autoDispose.family<List<Task>, String>((
  ref,
  goalId,
) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  return all.where((t) => t.deletedAt == null && t.goalId == goalId).toList();
});

/// Non-deleted tasks whose `goalId` is [goalId], without the hidden
/// `metric-tick` tasks: open ones first.
final goalLinkedTasksProvider = Provider.family<List<Task>, String>((
  ref,
  goalId,
) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final linked = all
      .where(
        (t) => t.deletedAt == null && t.goalId == goalId && !isMetricTick(t),
      )
      .toList();
  linked.sort((a, b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    return a.createdAt.compareTo(b.createdAt);
  });
  return linked;
});

/// Progress of the goal [goalId]: the stored count, done linked tasks for
/// a [MetricSource.linkedTasks] metric, or this period's count for a
/// recurring one.
final goalProgressProvider = Provider.autoDispose.family<GoalProgress, String>((
  ref,
  goalId,
) {
  final goal = ref.watch(goalByIdProvider(goalId));
  if (goal == null) return const GoalProgress.none(done: false);
  return GoalProgress.of(
    goal,
    linkedTasks: ref.watch(goalTasksProvider(goalId)),
    period: periodContextOf(ref),
  );
});

/// The last 8 periods of a recurring goal, oldest first (current last);
/// empty for other goals.
final goalHistoryProvider = Provider.autoDispose
    .family<List<PeriodCount>, String>((ref, goalId) {
      final goal = ref.watch(goalByIdProvider(goalId));
      final m = goal?.recurring;
      if (goal == null || m == null) return const [];
      return recurringHistory(
        goalId: goalId,
        metric: m,
        tasks: ref.watch(goalTasksProvider(goalId)),
        ctx: periodContextOf(ref),
        since: goal.createdAt,
      );
    });

List<Task> _tasksOf(List<Task> tasks, String goalId) => [
  for (final t in tasks)
    if (t.deletedAt == null && t.goalId == goalId) t,
];

/// Progress of every goal by id; null until goals and tasks have loaded
/// (so a late task list never looks like a sudden jump).
final allGoalProgressProvider =
    Provider.autoDispose<Map<String, GoalProgress>?>((ref) {
      final goals = ref.watch(goalsProvider).valueOrNull;
      final tasks = ref.watch(tasksProvider).valueOrNull;
      if (goals == null || tasks == null) return null;
      final ctx = periodContextOf(ref);
      return {
        for (final g in goals)
          g.id: GoalProgress.of(
            g,
            linkedTasks: _tasksOf(tasks, g.id),
            period: ctx,
          ),
      };
    });

/// A milestone a goal just crossed, wherever the change came from (the
/// goal screens, a task ticked on Today, an import).
@immutable
class GoalMilestoneEvent {
  const GoalMilestoneEvent({
    required this.goalId,
    required this.title,
    required this.milestone,
    required this.progress,
  });

  final String goalId;
  final String title;
  final GoalMilestone milestone;
  final GoalProgress progress;

  @override
  String toString() => 'GoalMilestoneEvent($goalId, $milestone)';
}

/// Live milestones: `closeToDone` / `completed` for finite metrics and
/// `metricHit` when a recurring quota is reached in the current period.
/// The companion listens: `ref.listen(goalMilestoneEventsProvider, ...)`.
/// Nothing fires for the first snapshot or for a new period starting.
final goalMilestoneEventsProvider =
    StreamProvider.autoDispose<GoalMilestoneEvent>((ref) {
      final controller = StreamController<GoalMilestoneEvent>();
      ref.onDispose(controller.close);
      ref.listen<Map<String, GoalProgress>?>(allGoalProgressProvider, (
        before,
        after,
      ) {
        if (before == null || after == null) return;
        final goals = ref.read(goalsProvider).valueOrNull ?? const [];
        for (final e in after.entries) {
          final prev = before[e.key];
          if (prev == null) continue;
          final m = GoalProgress.milestoneBetween(prev, e.value);
          if (m == null) continue;
          controller.add(
            GoalMilestoneEvent(
              goalId: e.key,
              title: findGoal(goals, e.key)?.title ?? '',
              milestone: m,
              progress: e.value,
            ),
          );
        }
      });
      return controller.stream;
    });

/// Goals grouped for the Highlights screen (#28).
final highlightsProvider =
    Provider.autoDispose<Map<HighlightGroup, List<GoalHighlight>>>((ref) {
      final goals = ref.watch(goalsProvider).valueOrNull ?? const [];
      final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
      final ctx = periodContextOf(ref);
      return groupHighlights(
        goals: goals,
        tasks: tasks,
        progressOf: (g) =>
            GoalProgress.of(g, linkedTasks: _tasksOf(tasks, g.id), period: ctx),
        now: ctx.now,
      );
    });

/// Saved evening reviews (wins and rolled-over counts) for the recap.
final recapReviewsProvider = FutureProvider.autoDispose<List<ReviewEntry>>(
  (ref) => ref.watch(reviewRepositoryProvider).all(),
);

/// The weekly recap: this week on its last day, otherwise last week.
final weeklyRecapProvider = Provider.autoDispose<WeeklyRecap>((ref) {
  final w = recapWeek(periodContextOf(ref));
  return buildWeeklyRecap(
    week: w.week,
    isCurrentWeek: w.isCurrent,
    goals: ref.watch(goalsProvider).valueOrNull ?? const [],
    tasks: ref.watch(tasksProvider).valueOrNull ?? const <Task>[],
    reviews: ref.watch(recapReviewsProvider).valueOrNull ?? const [],
  );
});

/// Goals grouped by horizon (week, month, quarter, year: always all four
/// keys). Within a horizon: active by importance, then paused, then done.
final goalsByHorizonProvider = Provider<Map<GoalHorizon, List<GoalRecord>>>((
  ref,
) {
  final all = ref.watch(goalsProvider).valueOrNull ?? const <GoalRecord>[];
  int rank(GoalRecord g) => switch (g.status) {
    GoalStatus.active => 0,
    GoalStatus.paused => 1,
    GoalStatus.done => 2,
  };
  return {
    for (final h in GoalHorizon.values)
      h: all.where((g) => g.horizon == h).toList()
        ..sort((a, b) {
          final r = rank(a).compareTo(rank(b));
          if (r != 0) return r;
          final i = b.importance.compareTo(a.importance);
          return i != 0 ? i : a.createdAt.compareTo(b.createdAt);
        }),
  };
});

final goalActionsProvider = Provider<GoalActions>(
  (ref) => GoalActions(
    ref.watch(goalRepositoryProvider),
    ref.watch(taskRepositoryProvider),
    ref.watch(clockProvider),
    milestones: ref.watch(milestoneRepositoryProvider),
    periodContext: () => PeriodContext(
      now: ref.read(clockProvider).now().toUtc(),
      location: ref.read(zoneLocationProvider),
      weekStart: ref.read(goalWeekStartProvider),
    ),
  ),
);

/// Writes for the goals screens. Methods that change progress return the
/// milestone they crossed, for the screen's toast. (The cheering layer
/// listens to [goalMilestoneEventsProvider] instead, which also sees
/// changes made outside the goal screens.)
class GoalActions {
  GoalActions(
    this._goals,
    this._tasks,
    this._clock, {
    PeriodContext Function()? periodContext,
    MilestoneRepository? milestones,
  }) : _periodContext = periodContext,
       _milestones = milestones;

  final GoalRepository _goals;
  final MilestoneRepository? _milestones;
  final TaskRepository _tasks;
  final Clock _clock;
  final PeriodContext Function()? _periodContext;

  DateTime get _now => _clock.now().toUtc();

  PeriodContext get _ctx => _periodContext?.call() ?? PeriodContext.utc(_now);

  /// A new goal with a fresh id and timestamps.
  GoalRecord draft({
    required String title,
    String? area,
    GoalHorizon horizon = GoalHorizon.month,
    int importance = 3,
    DateTime? targetDate,
    String? notes,
    GoalMetric? metric,
  }) {
    final now = _now;
    return GoalRecord(
      id: const Uuid().v4(),
      title: title,
      area: area,
      horizon: horizon,
      importance: importance,
      targetDate: targetDate,
      notes: notes,
      metric: metric,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> save(GoalRecord goal) =>
      _goals.upsert(goal.copyWith(updatedAt: _now));

  /// Soft-deletes the goal and its milestones and unlinks its tasks (its
  /// +1 ticks go too).
  Future<void> delete(GoalRecord goal) async {
    await _goals.delete(goal.id);
    final milestones = _milestones;
    if (milestones != null) {
      for (final m in await milestones.getAll()) {
        if (m.goalId == goal.id) await milestones.delete(m.id);
      }
    }
    final tasks = await _tasks.getAll();
    final now = _now;
    final mine = tasks.where((t) => t.goalId == goal.id).toList();
    for (final t in mine.where(isMetricTick)) {
      await _tasks.delete(t.id);
    }
    await _tasks.upsertAll([
      for (final t in mine)
        if (!isMetricTick(t)) t.copyWith(goalId: null, updatedAt: now),
    ]);
  }

  /// Sets the manual count to [count] (clamped at 0).
  Future<GoalMilestone?> setCount(GoalRecord goal, int count) async {
    final m = goal.finite;
    if (m == null || m.source != MetricSource.manual) return null;
    final next = goal.copyWith(
      metric: m.copyWith(current: count < 0 ? 0 : count),
      lastProgressAt: count > m.current ? _now : goal.lastProgressAt,
    );
    await save(next);
    return GoalProgress.milestoneBetween(
      GoalProgress.of(goal),
      GoalProgress.of(next),
    );
  }

  /// +1 on a manual finite metric, or one occurrence on a recurring one
  /// (a hidden `metric-tick` task completed now; returns
  /// [GoalMilestone.metricHit] when that reaches this period's quota).
  Future<GoalMilestone?> increment(GoalRecord goal, {int by = 1}) async {
    if (goal.recurring != null) return _tick(goal, by);
    final m = goal.finite;
    if (m == null) return null;
    return setCount(goal, m.current + by);
  }

  /// Takes back the latest +1 of the current period on a recurring goal.
  /// Linked tasks are untouched (untick them instead). False when there is
  /// no +1 this period.
  Future<bool> undoTick(GoalRecord goal) async {
    final m = goal.recurring;
    if (m == null) return false;
    final bounds = periodOf(m.period, _ctx);
    final ticks = ticksInPeriod(await _tasks.getAll(), goal.id, bounds);
    if (ticks.isEmpty) return false;
    await _tasks.delete(ticks.first.id);
    return true;
  }

  Future<GoalMilestone?> _tick(GoalRecord goal, int by) async {
    if (by <= 0) return null;
    final ctx = _ctx;
    final now = _now;
    final before = (await _tasks.getAll())
        .where((t) => t.goalId == goal.id)
        .toList();
    final ticks = [
      for (var i = 0; i < by; i++)
        metricTick(
          id: const Uuid().v4(),
          goalId: goal.id,
          title: goal.title,
          at: now,
        ),
    ];
    await _tasks.upsertAll(ticks);
    await save(goal.copyWith(lastProgressAt: now));
    return GoalProgress.milestoneBetween(
      GoalProgress.of(goal, linkedTasks: before, period: ctx),
      GoalProgress.of(goal, linkedTasks: [...before, ...ticks], period: ctx),
    );
  }

  Future<void> setStatus(GoalRecord goal, GoalStatus status) =>
      save(goal.copyWith(status: status));

  Future<void> linkTask(Task task, String? goalId) =>
      _tasks.upsert(task.copyWith(goalId: goalId, updatedAt: _now));

  /// Ticks a linked task on or off. On a linked-tasks or recurring metric
  /// this moves the count, so the crossing is returned like [increment].
  Future<GoalMilestone?> toggleTask(
    GoalRecord goal,
    Task task,
    List<Task> linkedBefore,
  ) async {
    final now = _now;
    final done = !task.isDone;
    final next = task.copyWith(
      status: done ? TaskStatus.done : TaskStatus.open,
      completedAt: done ? now : null,
      updatedAt: now,
    );
    await _tasks.upsert(next);
    final recurring = goal.recurring != null;
    if (!recurring && goal.finite?.source != MetricSource.linkedTasks) {
      return null;
    }
    if (done) await save(goal.copyWith(lastProgressAt: now));
    // A recurring count also reads this period's +1 ticks.
    final all = recurring
        ? (await _tasks.getAll()).where((t) => t.goalId == goal.id).toList()
        : linkedBefore;
    final ctx = _ctx;
    return GoalProgress.milestoneBetween(
      GoalProgress.of(
        goal,
        linkedTasks: [for (final t in all) t.id == task.id ? task : t],
        period: ctx,
      ),
      GoalProgress.of(
        goal,
        linkedTasks: [for (final t in all) t.id == task.id ? next : t],
        period: ctx,
      ),
    );
  }
}

// ---------------------------------------------------------------- Milestones (#25)

/// The milestone store. In memory by default; `main.dart` overrides it
/// with `DriftMilestoneRepository(db, clock: ...)`, next to the goal
/// repository override.
final milestoneRepositoryProvider = Provider<MilestoneRepository>(
  (ref) => InMemoryMilestoneRepository(clock: ref.watch(clockProvider)),
);

/// Live list of every goal's milestones.
final milestonesProvider = StreamProvider<List<Milestone>>(
  (ref) => ref.watch(milestoneRepositoryProvider).watchAll(),
);

/// Live milestone → task links.
final milestoneLinksProvider = StreamProvider<List<MilestoneTaskLink>>(
  (ref) => ref.watch(milestoneRepositoryProvider).watchLinks(),
);

/// The goal's milestones with their tasks, progress, rollover suggestions
/// and the goal's next scheduled task.
final goalMilestonePlanProvider = Provider.autoDispose
    .family<MilestonePlan, String>((ref, goalId) {
      final milestones = ref.watch(milestonesProvider).valueOrNull;
      final links = ref.watch(milestoneLinksProvider).valueOrNull ?? const [];
      final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
      return buildMilestonePlan(
        milestones: milestones ?? const [],
        links: links,
        tasks: tasks,
        goalId: goalId,
        ctx: periodContextOf(ref),
      );
    });

final milestoneActionsProvider = Provider<MilestoneActions>(
  (ref) => MilestoneActions(
    ref.watch(milestoneRepositoryProvider),
    ref.watch(taskRepositoryProvider),
    ref.watch(clockProvider),
    periodContext: () => PeriodContext(
      now: ref.read(clockProvider).now().toUtc(),
      location: ref.read(zoneLocationProvider),
      weekStart: ref.read(goalWeekStartProvider),
    ),
  ),
);

/// Writes for the milestone block of the goal screen.
class MilestoneActions {
  MilestoneActions(
    this._milestones,
    this._tasks,
    this._clock, {
    PeriodContext Function()? periodContext,
  }) : _periodContext = periodContext;

  final MilestoneRepository _milestones;
  final TaskRepository _tasks;
  final Clock _clock;
  final PeriodContext Function()? _periodContext;

  DateTime get _now => _clock.now().toUtc();

  PeriodContext get _ctx => _periodContext?.call() ?? PeriodContext.utc(_now);

  Future<List<Milestone>> _ofGoal(String goalId) async => [
    for (final m in await _milestones.getAll())
      if (m.goalId == goalId) m,
  ]..sort(compareMilestones);

  /// A new milestone at the end of [goalId]'s list.
  Future<Milestone> add({
    required String goalId,
    required String title,
    DateTime? dueAt,
  }) async {
    final mine = await _ofGoal(goalId);
    final now = _now;
    final m = Milestone(
      id: const Uuid().v4(),
      goalId: goalId,
      title: title,
      dueAt: dueAt,
      sortOrder: mine.isEmpty ? 0 : mine.last.sortOrder + 1,
      createdAt: now,
      updatedAt: now,
    );
    await _milestones.upsert(m);
    return m;
  }

  Future<void> edit(
    Milestone m, {
    required String title,
    DateTime? dueAt,
  }) async {
    final current = await _milestones.getById(m.id) ?? m;
    await _milestones.upsert(
      current.copyWith(title: title, dueAt: dueAt, updatedAt: _now),
    );
  }

  /// Done ↔ open.
  Future<Milestone> toggleDone(Milestone m) async {
    final current = await _milestones.getById(m.id) ?? m;
    final now = _now;
    final next = current.isDone
        ? current.copyWith(
            status: MilestoneStatus.open,
            completedAt: null,
            updatedAt: now,
          )
        : current.copyWith(
            status: MilestoneStatus.done,
            completedAt: now,
            updatedAt: now,
          );
    await _milestones.upsert(next);
    return next;
  }

  /// Accepts the rollover: the milestone takes its suggested date. No-op
  /// when it is not moved.
  Future<void> acceptMove(Milestone m) async {
    final current = await _milestones.getById(m.id) ?? m;
    final date = suggestedMoveDate(current, _ctx);
    if (date == null) return;
    await _milestones.upsert(current.copyWith(dueAt: date, updatedAt: _now));
  }

  /// Moves [m] [by] places (negative: up) and renumbers the goal's list
  /// 0..n-1. Out-of-range moves stop at the ends.
  Future<void> reorder(Milestone m, int by) async {
    final mine = await _ofGoal(m.goalId);
    final from = mine.indexWhere((x) => x.id == m.id);
    if (from < 0) return;
    final to = (from + by).clamp(0, mine.length - 1);
    if (to == from) return;
    final moved = mine.removeAt(from);
    mine.insert(to, moved);
    final now = _now;
    await _milestones.upsertAll([
      for (final (i, x) in mine.indexed)
        if (x.sortOrder != i) x.copyWith(sortOrder: i, updatedAt: now),
    ]);
  }

  /// Soft-deletes [m]; its tasks stay with the goal.
  Future<void> delete(Milestone m) => _milestones.delete(m.id);

  /// A weekly task for [m]: linked to its goal and to it, due at the end
  /// of [week] and, for next week, not planned before that week starts.
  Future<Task> addTask(
    Milestone m, {
    required String title,
    int estimatedMinutes = 30,
    MilestoneTaskWeek week = MilestoneTaskWeek.thisWeek,
  }) async {
    final ctx = _ctx;
    final bounds = weekFor(week, ctx);
    final now = _now;
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      goalId: m.goalId,
      dueAt: endOfLocalDay(bounds.lastDay, ctx.location),
      notBefore: week == MilestoneTaskWeek.nextWeek
          ? utcOf(bounds.start)
          : null,
      estimatedMinutes: estimatedMinutes,
      createdAt: now,
      updatedAt: now,
    );
    await _tasks.upsert(task);
    await _milestones.linkTask(task.id, m.id);
    return task;
  }

  /// Ticks a milestone task on or off.
  Future<void> toggleTask(Task task) {
    final now = _now;
    final done = !task.isDone;
    return _tasks.upsert(
      task.copyWith(
        status: done ? TaskStatus.done : TaskStatus.open,
        completedAt: done ? now : null,
        updatedAt: now,
      ),
    );
  }

  /// Takes the task off the milestone; it stays linked to the goal.
  Future<void> unlinkTask(Task task) => _milestones.unlinkTask(task.id);
}
