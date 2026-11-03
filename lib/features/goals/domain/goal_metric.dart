import 'package:flutter/foundation.dart';

/// How a goal is measured (HANDOFF.md §2.3).
///
/// [FiniteMetric] ("8 of 12 lessons", #26) has a known end;
/// [RecurringMetric] ("3 of 4 workouts this week", #27) is a quota per
/// period that starts fresh every period. Every `switch` over a metric
/// handles both.
@immutable
sealed class GoalMetric {
  const GoalMetric();

  Map<String, Object?> toJson();

  static GoalMetric? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json.cast<String, Object?>();
    return switch (j['kind']) {
      'finite' => FiniteMetric.fromJson(j),
      'recurring' => RecurringMetric.fromJson(j),
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

/// The span a [RecurringMetric] counts over.
enum MetricPeriod { week, month }

/// "3 of 4 workouts this week": a [quota] per [period].
///
/// Nothing is stored per period: a period's count is the number of the
/// goal's tasks completed inside it (linked tasks plus the hidden
/// `metric-tick` tasks a +1 creates, see `metric_ticks.dart`). So a new
/// period starts at 0 by itself, and past periods are never overwritten.
@immutable
class RecurringMetric extends GoalMetric {
  const RecurringMetric({
    required this.quota,
    required this.unit,
    this.period = MetricPeriod.week,
  }) : assert(quota > 0);

  final int quota;

  /// Plural unit label: "workouts", "days".
  final String unit;
  final MetricPeriod period;

  RecurringMetric copyWith({int? quota, String? unit, MetricPeriod? period}) =>
      RecurringMetric(
        quota: quota ?? this.quota,
        unit: unit ?? this.unit,
        period: period ?? this.period,
      );

  @override
  Map<String, Object?> toJson() => {
    'kind': 'recurring',
    'target': quota,
    'unit': unit,
    'period': period.name,
  };

  factory RecurringMetric.fromJson(Map<String, Object?> j) => RecurringMetric(
    quota: (j['target'] as num).toInt(),
    unit: j['unit'] as String? ?? '',
    period: MetricPeriod.values.firstWhere(
      (p) => p.name == j['period'],
      orElse: () => MetricPeriod.week,
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is RecurringMetric &&
      other.quota == quota &&
      other.unit == unit &&
      other.period == period;

  @override
  int get hashCode => Object.hash(quota, unit, period);
}
