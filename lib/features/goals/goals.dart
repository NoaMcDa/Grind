/// Goals (#24), finite metrics (#26), recurring metrics (#27) and
/// Highlights with the weekly recap (#28).
///
/// Routes: `/goals` → [GoalsScreen], `/goals/:id` → [GoalDetailScreen],
/// `/highlights` → [HighlightsScreen] ([HighlightsLinkCard] for the Pip
/// screen). Recurring +1s are hidden `metric-tick` tasks: task lists hide
/// them with [isMetricTick]. Milestones: [goalMilestoneEventsProvider].
/// Goal milestones with weekly tasks (#25): [goalMilestonePlanProvider],
/// [MilestoneActions].
/// Persistence: override [goalRepositoryProvider] with
/// `DriftGoalRepository` and [milestoneRepositoryProvider] with
/// `DriftMilestoneRepository` (import `data/drift_goal_repository.dart` and
/// `data/drift_milestone_repository.dart` from
/// `main.dart`; it is not exported here so the feature stays free of Drift).
library;

export 'domain/goal_area.dart';
export 'domain/goal_metric.dart';
export 'domain/goal_progress.dart';
export 'domain/goal_record.dart';
export 'domain/goal_repository.dart';
export 'domain/highlights.dart';
export 'domain/metric_period.dart';
export 'domain/metric_ticks.dart';
export 'domain/milestone_plan.dart';
export 'domain/weekly_recap.dart';
export 'goal_providers.dart';
export 'presentation/goal_detail_screen.dart';
export 'presentation/goal_form.dart';
export 'presentation/goal_widgets.dart';
export 'presentation/goals_screen.dart';
export 'presentation/highlights_screen.dart';
export 'presentation/metric_trend.dart';
export 'presentation/milestone_section.dart';
