import 'package:flutter/foundation.dart';

import '../../../core/core.dart';
import 'goal_metric.dart';

enum GoalStatus { active, paused, done }

/// The fields of a goal (#24) that the core [Goal] row does not hold yet:
/// target date, status, notes and the metric. Serialisable as one JSON
/// blob so it can live in a single column once the schema has one.
@immutable
class GoalExtras {
  const GoalExtras({
    this.targetDate,
    this.status = GoalStatus.active,
    this.notes,
    this.metric,
  });

  final DateTime? targetDate;
  final GoalStatus status;
  final String? notes;
  final GoalMetric? metric;

  Map<String, Object?> toJson() => {
    'targetDate': targetDate?.toUtc().toIso8601String(),
    'status': status.name,
    'notes': notes,
    'metric': metric?.toJson(),
  };

  factory GoalExtras.fromJson(Map<String, Object?> j) => GoalExtras(
    targetDate: j['targetDate'] == null
        ? null
        : DateTime.parse(j['targetDate'] as String).toUtc(),
    status: GoalStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => GoalStatus.active,
    ),
    notes: j['notes'] as String?,
    metric: GoalMetric.fromJson(j['metric']),
  );
}

/// A goal as the goals feature sees it: the core [Goal] plus [GoalExtras].
///
/// [importance] is the user's 1–5; the core keeps it as 0..1 for the
/// scheduler score ([importanceToCore]).
@immutable
class GoalRecord {
  const GoalRecord({
    required this.id,
    required this.title,
    this.area,
    this.horizon = GoalHorizon.month,
    this.importance = 3,
    this.targetDate,
    this.status = GoalStatus.active,
    this.notes,
    this.metric,
    this.lastProgressAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : assert(importance >= 1 && importance <= 5);

  final String id;
  final String title;

  /// A [GoalArea] id or a custom area label.
  final String? area;
  final GoalHorizon horizon;

  /// 1 (nice) .. 5 (matters most).
  final int importance;

  /// UTC; the end of the local day the user picked.
  final DateTime? targetDate;
  final GoalStatus status;
  final String? notes;
  final GoalMetric? metric;
  final DateTime? lastProgressAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  GoalExtras get extras => GoalExtras(
    targetDate: targetDate,
    status: status,
    notes: notes,
    metric: metric,
  );

  /// The stored metric as finite, or null.
  FiniteMetric? get finite => switch (metric) {
    final FiniteMetric m => m,
    null => null,
  };

  static double importanceToCore(int level) => level.clamp(1, 5) / 5;
  static int importanceFromCore(double value) =>
      (value * 5).round().clamp(1, 5);

  /// The core row. `progress` is the stored metric fraction (a done goal
  /// counts as 1), so the scheduler can read it without this feature.
  Goal toCore() {
    final m = finite;
    final progress = status == GoalStatus.done
        ? 1.0
        : m == null || m.source != MetricSource.manual
        ? 0.0
        : (m.current / m.target).clamp(0.0, 1.0);
    return Goal(
      id: id,
      title: title,
      area: area,
      horizon: horizon,
      importance: importanceToCore(importance),
      progress: progress,
      lastProgressAt: lastProgressAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory GoalRecord.fromCore(Goal g, [GoalExtras? extras]) => GoalRecord(
    id: g.id,
    title: g.title,
    area: g.area,
    horizon: g.horizon,
    importance: importanceFromCore(g.importance),
    targetDate: extras?.targetDate,
    status: extras?.status ?? GoalStatus.active,
    notes: extras?.notes,
    metric: extras?.metric,
    lastProgressAt: g.lastProgressAt,
    createdAt: g.createdAt,
    updatedAt: g.updatedAt,
    deletedAt: g.deletedAt,
  );

  GoalRecord copyWith({
    String? title,
    Object? area = _unset,
    GoalHorizon? horizon,
    int? importance,
    Object? targetDate = _unset,
    GoalStatus? status,
    Object? notes = _unset,
    Object? metric = _unset,
    Object? lastProgressAt = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => GoalRecord(
    id: id,
    title: title ?? this.title,
    area: area == _unset ? this.area : area as String?,
    horizon: horizon ?? this.horizon,
    importance: importance ?? this.importance,
    targetDate: targetDate == _unset
        ? this.targetDate
        : targetDate as DateTime?,
    status: status ?? this.status,
    notes: notes == _unset ? this.notes : notes as String?,
    metric: metric == _unset ? this.metric : metric as GoalMetric?,
    lastProgressAt: lastProgressAt == _unset
        ? this.lastProgressAt
        : lastProgressAt as DateTime?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is GoalRecord &&
      other.id == id &&
      other.title == title &&
      other.area == area &&
      other.horizon == horizon &&
      other.importance == importance &&
      other.targetDate == targetDate &&
      other.status == status &&
      other.notes == notes &&
      other.metric == metric &&
      other.lastProgressAt == lastProgressAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(id, title, updatedAt, metric, status);

  @override
  String toString() => 'GoalRecord($id, $title, $horizon, $status)';
}

const _unset = Object();
