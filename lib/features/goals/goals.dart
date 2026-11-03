/// Goals (#24) and finite metrics (#26).
///
/// Routes: `/goals` → [GoalsScreen], `/goals/:id` → [GoalDetailScreen].
/// Persistence: override [goalRepositoryProvider] with
/// `DriftGoalRepository` (import `data/drift_goal_repository.dart` from
/// `main.dart`; it is not exported here so the feature stays free of Drift).
library;

export 'domain/goal_area.dart';
export 'domain/goal_metric.dart';
export 'domain/goal_progress.dart';
export 'domain/goal_record.dart';
export 'domain/goal_repository.dart';
export 'goal_providers.dart';
export 'presentation/goal_detail_screen.dart';
export 'presentation/goal_form.dart';
export 'presentation/goal_widgets.dart';
export 'presentation/goals_screen.dart';
