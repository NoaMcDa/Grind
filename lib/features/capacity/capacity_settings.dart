import 'dart:convert';

import '../plan/scheduler/models.dart' show SchedulerWeights;
import 'json_doc_store.dart';

/// What the capacity feature persists: the tuned scoring weights and the
/// tasks the user pinned to the very top.
class CapacityConfig {
  const CapacityConfig({
    this.weights = const SchedulerWeights(),
    this.topPinned = const {},
  });

  final SchedulerWeights weights;

  /// Task ids pinned "top". `Task.priority` only has 1-3, so "top" (above
  /// "high") lives here and ranks above every computed score.
  final Set<String> topPinned;

  CapacityConfig copyWith({
    SchedulerWeights? weights,
    Set<String>? topPinned,
  }) => CapacityConfig(
    weights: weights ?? this.weights,
    topPinned: topPinned ?? this.topPinned,
  );

  Map<String, Object?> toJson() => {
    'urgency': weights.urgency,
    'importance': weights.importance,
    'priority': weights.priority,
    'quickWin': weights.quickWin,
    'topPinned': topPinned.toList()..sort(),
  };

  factory CapacityConfig.fromJson(Map<String, Object?> j) {
    const d = SchedulerWeights();
    double w(String k, double fallback) =>
        ((j[k] as num?)?.toDouble() ?? fallback).clamp(0.0, 1.0).toDouble();
    return CapacityConfig(
      weights: SchedulerWeights(
        urgency: w('urgency', d.urgency),
        importance: w('importance', d.importance),
        priority: w('priority', d.priority),
        quickWin: w('quickWin', d.quickWin),
      ),
      topPinned: {...?(j['topPinned'] as List?)?.cast<String>()},
    );
  }
}

/// Where [CapacityConfig] lives.
///
/// The plan scheduler should read the weights through
/// `capacityConfigProvider` and pass them to `plan(...)` / `score(...)`.
abstract interface class CapacitySettings {
  Future<CapacityConfig> load();
  Future<void> save(CapacityConfig config);
}

class InMemoryCapacitySettings implements CapacitySettings {
  InMemoryCapacitySettings([this.config = const CapacityConfig()]);

  CapacityConfig config;

  @override
  Future<CapacityConfig> load() async => config;

  @override
  Future<void> save(CapacityConfig config) async => this.config = config;
}

class JsonCapacitySettings implements CapacitySettings {
  JsonCapacitySettings(this._store);

  static const docName = 'capacity_settings';

  final JsonDocStore _store;

  @override
  Future<CapacityConfig> load() async {
    final raw = await _store.read(docName);
    if (raw == null) return const CapacityConfig();
    try {
      return CapacityConfig.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return const CapacityConfig();
    }
  }

  @override
  Future<void> save(CapacityConfig config) =>
      _store.write(docName, jsonEncode(config.toJson()));
}

/// `copyWith` for [SchedulerWeights] (the scheduler's class has none).
extension SchedulerWeightsX on SchedulerWeights {
  static SchedulerWeights of(
    SchedulerWeights base, {
    double? urgency,
    double? importance,
    double? priority,
    double? quickWin,
  }) => SchedulerWeights(
    urgency: urgency ?? base.urgency,
    importance: importance ?? base.importance,
    priority: priority ?? base.priority,
    quickWin: quickWin ?? base.quickWin,
  );
}
