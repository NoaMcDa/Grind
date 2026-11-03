import 'package:flutter/foundation.dart';

/// How a goal is measured (HANDOFF.md §2.3).
///
/// Only [FiniteMetric] exists today (#26). The recurring weekly quota
/// ("3 of 4 workouts this week", #27) becomes a second subclass here, so
/// every `switch` over a metric has to handle it.
@immutable
sealed class GoalMetric {
  const GoalMetric();

  Map<String, Object?> toJson();

  static GoalMetric? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json.cast<String, Object?>();
    return switch (j['kind']) {
      'finite' => FiniteMetric.fromJson(j),
      _ => null,
    };
  }
}

/// Where a finite metric's count comes from.
enum MetricSource {
  /// The user counts: +1 button or "edit count".
  manual,

  /// Count of done tasks linked to the goal; the stored count is ignored.
  linkedTasks,
}

/// "8 of 12 lessons": a goal with a known end.
@immutable
class FiniteMetric extends GoalMetric {
  const FiniteMetric({
    required this.target,
    required this.unit,
    this.current = 0,
    this.source = MetricSource.manual,
  }) : assert(target > 0);

  final int target;

  /// Plural unit label: "lessons", "chapters".
  final String unit;

  /// The stored count (manual source). Never negative.
  final int current;
  final MetricSource source;

  FiniteMetric copyWith({
    int? target,
    String? unit,
    int? current,
    MetricSource? source,
  }) => FiniteMetric(
    target: target ?? this.target,
    unit: unit ?? this.unit,
    current: current ?? this.current,
    source: source ?? this.source,
  );

  @override
  Map<String, Object?> toJson() => {
    'kind': 'finite',
    'target': target,
    'unit': unit,
    'current': current,
    'source': source.name,
  };

  factory FiniteMetric.fromJson(Map<String, Object?> j) => FiniteMetric(
    target: (j['target'] as num).toInt(),
    unit: j['unit'] as String? ?? '',
    current: (j['current'] as num?)?.toInt() ?? 0,
    source: MetricSource.values.firstWhere(
      (s) => s.name == j['source'],
      orElse: () => MetricSource.manual,
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is FiniteMetric &&
      other.target == target &&
      other.unit == unit &&
      other.current == current &&
      other.source == source;

  @override
  int get hashCode => Object.hash(target, unit, current, source);
}
