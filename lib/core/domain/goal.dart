enum GoalHorizon { week, month, quarter, year }

enum GoalStatus { active, paused, done }

/// A goal (#24). The scheduler score reads [importance] and [progress];
/// the goals feature reads the rest.
///
/// The metric is stored flat so the core needs no feature types:
/// [metricKind] names the metric (`'finite'` today; null = no metric) and
/// the goals feature maps the other `metric*` fields to its `GoalMetric`.
class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.area,
    this.horizon = GoalHorizon.month,
    this.importance = 0.5,
    this.progress = 0,
    this.lastProgressAt,
    this.targetDate,
    this.status = GoalStatus.active,
    this.notes,
    this.metricKind,
    this.metricTarget,
    this.metricUnit,
    this.metricCurrent,
    this.metricSource,
    this.metricPeriod,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String? area;
  final GoalHorizon horizon;

  /// 0..1, user-set.
  final double importance;

  /// 0..1.
  final double progress;
  final DateTime? lastProgressAt;

  /// UTC; the end of the local day the user picked.
  final DateTime? targetDate;
  final GoalStatus status;
  final String? notes;

  /// `'finite'` ("8 of 12 lessons"); a weekly quota (#27) adds another.
  final String? metricKind;
  final int? metricTarget;

  /// Plural unit label: "lessons".
  final String? metricUnit;
  final int? metricCurrent;

  /// Where the count comes from: `'manual'` or `'linkedTasks'`.
  final String? metricSource;

  /// For recurring quotas: `'week'`, `'month'`. Null for finite metrics.
  final String? metricPeriod;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Goal copyWith({
    String? title,
    Object? area = _unset,
    GoalHorizon? horizon,
    double? importance,
    double? progress,
    Object? lastProgressAt = _unset,
    Object? targetDate = _unset,
    GoalStatus? status,
    Object? notes = _unset,
    Object? metricKind = _unset,
    Object? metricTarget = _unset,
    Object? metricUnit = _unset,
    Object? metricCurrent = _unset,
    Object? metricSource = _unset,
    Object? metricPeriod = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => Goal(
    id: id,
    title: title ?? this.title,
    area: area == _unset ? this.area : area as String?,
    horizon: horizon ?? this.horizon,
    importance: importance ?? this.importance,
    progress: progress ?? this.progress,
    lastProgressAt: lastProgressAt == _unset
        ? this.lastProgressAt
        : lastProgressAt as DateTime?,
    targetDate: targetDate == _unset
        ? this.targetDate
        : targetDate as DateTime?,
    status: status ?? this.status,
    notes: notes == _unset ? this.notes : notes as String?,
    metricKind: metricKind == _unset ? this.metricKind : metricKind as String?,
    metricTarget: metricTarget == _unset
        ? this.metricTarget
        : metricTarget as int?,
    metricUnit: metricUnit == _unset ? this.metricUnit : metricUnit as String?,
    metricCurrent: metricCurrent == _unset
        ? this.metricCurrent
        : metricCurrent as int?,
    metricSource: metricSource == _unset
        ? this.metricSource
        : metricSource as String?,
    metricPeriod: metricPeriod == _unset
        ? this.metricPeriod
        : metricPeriod as String?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
  );
}

const _unset = Object();
