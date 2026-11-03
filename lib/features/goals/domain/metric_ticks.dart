import '../../../core/core.dart';

/// A +1 on a recurring metric is stored as a done [Task] in this category,
/// linked to the goal, completed at the moment of the tap. That keeps the
/// per-period history without a schema change, and the tap feeds momentum
/// like any other finished task.
///
/// These tasks are not real to-dos: every task list must hide them with
/// [isMetricTick] (the goals feature does; Today and Plan filters are the
/// integrator's: `tasks.where((t) => !isMetricTick(t))`).
const metricTickCategory = 'metric-tick';

bool isMetricTick(Task t) => t.category == metricTickCategory;

/// Tasks without the metric ticks.
List<Task> withoutMetricTicks(Iterable<Task> tasks) =>
    tasks.where((t) => !isMetricTick(t)).toList();

/// The tick for one +1 on [goalId] at [at] (UTC).
Task metricTick({
  required String id,
  required String goalId,
  required String title,
  required DateTime at,
}) => Task(
  id: id,
  title: title,
  goalId: goalId,
  category: metricTickCategory,
  status: TaskStatus.done,
  completedAt: at,
  estimatedMinutes: 0,
  priority: 3,
  createdAt: at,
  updatedAt: at,
);
