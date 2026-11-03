import 'dart:async';

import '../domain/domain.dart';

/// Persistence contract for tasks. Implemented by Drift (#2) and by
/// [InMemoryTaskRepository] for tests and for agents whose dependency
/// has not merged yet.
abstract interface class TaskRepository {
  /// All non-deleted tasks, any status.
  Future<List<Task>> getAll();

  Future<Task?> getById(String id);

  /// Open tasks whose reminder (or, failing that, due time) is in [from, to).
  Future<List<Task>> getDueBetween(DateTime from, DateTime to);

  /// Tasks scheduled on the timeline overlapping [from, to).
  Future<List<Task>> getScheduledBetween(DateTime from, DateTime to);

  /// Insert or replace by id.
  Future<void> upsert(Task task);

  Future<void> upsertAll(List<Task> tasks);

  /// Soft delete (sets deletedAt).
  Future<void> delete(String id);

  /// Live view of all non-deleted tasks: current value first, then every change.
  Stream<List<Task>> watchAll();
}

class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository([Iterable<Task> seed = const []]) {
    for (final t in seed) {
      _tasks[t.id] = t;
    }
  }

  final Map<String, Task> _tasks = {};
  final _changes = StreamController<List<Task>>.broadcast();

  List<Task> get _live =>
      _tasks.values.where((t) => t.deletedAt == null).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  void _notify() => _changes.add(_live);

  @override
  Future<List<Task>> getAll() async => _live;

  @override
  Future<Task?> getById(String id) async {
    final t = _tasks[id];
    return t == null || t.deletedAt != null ? null : t;
  }

  @override
  Future<List<Task>> getDueBetween(DateTime from, DateTime to) async =>
      _live.where((t) => t.status == TaskStatus.open).where((t) {
        final when = t.remindAt ?? t.dueAt;
        return when != null && !when.isBefore(from) && when.isBefore(to);
      }).toList();

  @override
  Future<List<Task>> getScheduledBetween(DateTime from, DateTime to) async =>
      _live
          .where(
            (t) =>
                t.isScheduled &&
                t.scheduledStart!.isBefore(to) &&
                t.scheduledEnd!.isAfter(from),
          )
          .toList();

  @override
  Future<void> upsert(Task task) async {
    _tasks[task.id] = task;
    _notify();
  }

  @override
  Future<void> upsertAll(List<Task> tasks) async {
    for (final t in tasks) {
      _tasks[t.id] = t;
    }
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    final t = _tasks[id];
    if (t == null) return;
    final now = DateTime.now().toUtc();
    _tasks[id] = t.copyWith(deletedAt: now, updatedAt: now);
    _notify();
  }

  @override
  Stream<List<Task>> watchAll() async* {
    yield _live;
    yield* _changes.stream;
  }
}
