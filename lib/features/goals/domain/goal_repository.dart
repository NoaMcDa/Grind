import 'dart:async';

import '../../../core/core.dart';
import 'goal_record.dart';

/// Persistence contract for goals (#24). Same shape as the core
/// repositories: soft delete, live views emit the current value first.
abstract interface class GoalRepository {
  /// All non-deleted goals, oldest first.
  Future<List<GoalRecord>> getAll();

  Future<GoalRecord?> getById(String id);

  /// Insert or replace by id.
  Future<void> upsert(GoalRecord goal);

  /// Soft delete (sets deletedAt).
  Future<void> delete(String id);

  Stream<List<GoalRecord>> watchAll();

  /// The live goal, or null once it is missing or deleted.
  Stream<GoalRecord?> watchById(String id);
}

class InMemoryGoalRepository implements GoalRepository {
  InMemoryGoalRepository({
    Iterable<GoalRecord> seed = const [],
    Clock clock = const SystemClock(),
  }) : _clock = clock {
    for (final g in seed) {
      _goals[g.id] = g;
    }
  }

  final Clock _clock;
  final Map<String, GoalRecord> _goals = {};
  final _changes = StreamController<List<GoalRecord>>.broadcast();

  List<GoalRecord> get _live =>
      _goals.values.where((g) => g.deletedAt == null).toList()..sort(_byAge);

  void _notify() => _changes.add(_live);

  @override
  Future<List<GoalRecord>> getAll() async => _live;

  @override
  Future<GoalRecord?> getById(String id) async {
    final g = _goals[id];
    return g == null || g.deletedAt != null ? null : g;
  }

  @override
  Future<void> upsert(GoalRecord goal) async {
    _goals[goal.id] = goal;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    final g = _goals[id];
    if (g == null) return;
    final now = _clock.now().toUtc();
    _goals[id] = g.copyWith(deletedAt: now, updatedAt: now);
    _notify();
  }

  @override
  Stream<List<GoalRecord>> watchAll() async* {
    yield _live;
    yield* _changes.stream;
  }

  @override
  Stream<GoalRecord?> watchById(String id) =>
      watchAll().map((all) => findGoal(all, id)).distinct();
}

int _byAge(GoalRecord a, GoalRecord b) {
  final c = a.createdAt.compareTo(b.createdAt);
  return c != 0 ? c : a.id.compareTo(b.id);
}

GoalRecord? findGoal(Iterable<GoalRecord> goals, String id) {
  for (final g in goals) {
    if (g.id == id) return g;
  }
  return null;
}
