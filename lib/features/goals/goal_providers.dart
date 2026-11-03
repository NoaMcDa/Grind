import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/core.dart';
import 'domain/goal_metric.dart';
import 'domain/goal_progress.dart';
import 'domain/goal_record.dart';
import 'domain/goal_repository.dart';

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

/// Non-deleted tasks whose `goalId` is [goalId]: open ones first.
final goalLinkedTasksProvider = Provider.family<List<Task>, String>((
  ref,
  goalId,
) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final linked = all
      .where((t) => t.deletedAt == null && t.goalId == goalId)
      .toList();
  linked.sort((a, b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    return a.createdAt.compareTo(b.createdAt);
  });
  return linked;
});

/// Progress of the goal [goalId]: the stored count, or done linked tasks
/// for a [MetricSource.linkedTasks] metric.
final goalProgressProvider = Provider.family<GoalProgress, String>((
  ref,
  goalId,
) {
  final goal = ref.watch(goalByIdProvider(goalId));
  if (goal == null) return const GoalProgress.none(done: false);
  return GoalProgress.of(
    goal,
    linkedTasks: ref.watch(goalLinkedTasksProvider(goalId)),
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
  ),
);

/// Writes for the goals screens. Methods that change progress return the
/// milestone they crossed, for the cheering layer to celebrate.
class GoalActions {
  GoalActions(this._goals, this._tasks, this._clock);

  final GoalRepository _goals;
  final TaskRepository _tasks;
  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

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

  /// Soft-deletes the goal and unlinks its tasks.
  Future<void> delete(GoalRecord goal) async {
    await _goals.delete(goal.id);
    final tasks = await _tasks.getAll();
    final now = _now;
    await _tasks.upsertAll([
      for (final t in tasks)
        if (t.goalId == goal.id) t.copyWith(goalId: null, updatedAt: now),
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

  /// +1 on a manual finite metric.
  Future<GoalMilestone?> increment(GoalRecord goal, {int by = 1}) async {
    final m = goal.finite;
    if (m == null) return null;
    return setCount(goal, m.current + by);
  }

  Future<void> setStatus(GoalRecord goal, GoalStatus status) =>
      save(goal.copyWith(status: status));

  Future<void> linkTask(Task task, String? goalId) =>
      _tasks.upsert(task.copyWith(goalId: goalId, updatedAt: _now));

  /// Ticks a linked task on or off. On a linked-tasks metric this moves
  /// the count, so the crossing is returned like [increment].
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
    final m = goal.finite;
    if (m == null || m.source != MetricSource.linkedTasks) return null;
    if (done) await save(goal.copyWith(lastProgressAt: now));
    final after = [for (final t in linkedBefore) t.id == task.id ? next : t];
    return GoalProgress.milestoneBetween(
      GoalProgress.of(goal, linkedTasks: linkedBefore),
      GoalProgress.of(goal, linkedTasks: after),
    );
  }
}
