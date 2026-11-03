import 'dart:convert';

import '../domain/goal_record.dart';

/// Holds the [GoalExtras] (target date, status, notes, metric) by goal id
/// until the `goals` table has columns for them (schema v3, see the PR).
///
/// Synchronous on purpose: [DriftGoalRepository] reads it while mapping
/// rows inside a `watch()`.
abstract interface class GoalExtrasStore {
  GoalExtras? get(String goalId);
  void put(String goalId, GoalExtras extras);
}

class InMemoryGoalExtrasStore implements GoalExtrasStore {
  InMemoryGoalExtrasStore([Map<String, GoalExtras>? seed]) : _byId = {...?seed};

  final Map<String, GoalExtras> _byId;

  @override
  GoalExtras? get(String goalId) => _byId[goalId];

  @override
  void put(String goalId, GoalExtras extras) => _byId[goalId] = extras;

  /// The whole store as one JSON string, e.g. for a preferences blob or a
  /// backup until the columns exist.
  String toJsonString() =>
      jsonEncode({for (final e in _byId.entries) e.key: e.value.toJson()});

  factory InMemoryGoalExtrasStore.fromJsonString(String json) {
    final map = (jsonDecode(json) as Map).cast<String, Object?>();
    return InMemoryGoalExtrasStore({
      for (final e in map.entries)
        e.key: GoalExtras.fromJson((e.value as Map).cast<String, Object?>()),
    });
  }
}
