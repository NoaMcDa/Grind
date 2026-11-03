enum GoalHorizon { week, month, quarter, year }

/// Stub for phase 3 (#24). Only the fields the scheduler score reads today.
class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.area,
    this.horizon = GoalHorizon.month,
    this.importance = 0.5,
    this.progress = 0,
    this.lastProgressAt,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}
