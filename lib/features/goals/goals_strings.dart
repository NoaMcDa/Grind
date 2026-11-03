import '../../core/core.dart';
import 'domain/goal_progress.dart';

/// English strings for the goals feature (#24, #26). The integrator moves
/// these into the ARB files (see docs/plans/ownership.md). Pip's tone:
/// warm, specific, never guilt.
abstract final class GoalsStrings {
  static const title = 'Goals';
  static const subtitle = 'Near and far. Every small step counts.';
  static const newGoal = 'New goal';
  static const editGoal = 'Edit goal';
  static const emptyTitle = 'No goals yet';
  static const emptyBody =
      'Pick one thing you would love to move this month. Pip will cheer.';
  static const emptyAction = 'Add a goal';

  static String horizon(GoalHorizon h) => switch (h) {
    GoalHorizon.week => 'This week',
    GoalHorizon.month => 'This month',
    GoalHorizon.quarter => 'This quarter',
    GoalHorizon.year => 'This year',
  };

  static String horizonShort(GoalHorizon h) => switch (h) {
    GoalHorizon.week => 'Week',
    GoalHorizon.month => 'Month',
    GoalHorizon.quarter => 'Quarter',
    GoalHorizon.year => 'Year',
  };

  static String status(GoalStatus s) => switch (s) {
    GoalStatus.active => 'Active',
    GoalStatus.paused => 'Paused',
    GoalStatus.done => 'Done',
  };

  static const closeToDone = 'Almost there';
  static const completed = 'Completed';
  static const paused = 'Resting';

  /// "8 of 12 lessons".
  static String ofTarget(int current, int target, String unit) =>
      unit.isEmpty ? '$current of $target' : '$current of $target $unit';

  /// "8 of 12 lessons · 67%".
  static String progressLine(GoalProgress p) =>
      '${ofTarget(p.current, p.target, p.unit)} · ${p.percent}%';

  static const noMetric = 'Add a count to see progress';
  static String byDate(DateTime d) => 'by ${date(d)}';

  // Detail
  static const detailTitle = 'Goal';
  static const notFound = 'This goal is not here anymore.';
  static const backToGoals = 'Back to goals';
  static const back = 'Back';
  static const plusOne = '+1';
  static String plusOneLabel(String unit) =>
      unit.isEmpty ? 'Add one' : 'Add one to $unit';
  static const editCount = 'Edit count';
  static const countLabel = 'Count so far';
  static const countInvalid = 'A whole number from 0 works.';
  static const linkedCountHint = 'Counts up when you tick off a linked task.';
  static const linkedTasks = 'Linked tasks';
  static const noLinkedTasks =
      'No tasks here yet. Link one and it will count toward this goal.';
  static const linkTask = 'Link a task';
  static const newTask = 'New task';
  static const pickTask = 'Which task moves this goal?';
  static const noTasksToLink = 'Every open task already has a goal.';
  static const unlink = 'Unlink';
  static const targetDateLabel = 'Target date';
  static const noTargetDate = 'Whenever it fits';
  static const importanceLabel = 'Importance';
  static String importanceValue(int n) => '$n of 5';
  static const notesLabel = 'Notes';
  static const edit = 'Edit';
  static const delete = 'Delete';
  static const deleteTitle = 'Delete this goal?';
  static const deleteBody =
      'Its tasks stay; they just will not point to a goal anymore.';
  static const keep = 'Keep it';
  static const deleted = 'Goal deleted';
  static const markDone = 'Mark as done';
  static const reopen = 'Back to active';

  // Form
  static const titleLabel = 'What do you want to reach?';
  static const titleHint = 'Finish the project management course';
  static const titleRequired = 'Give it a short name and you are set.';
  static const areaLabel = 'Area';
  static const customArea = 'Your own';
  static const customAreaHint = 'Name your area';
  static const horizonLabel = 'Horizon';
  static const pickDate = 'Pick a date';
  static const clear = 'Clear';
  static const metricLabel = 'Measure it (optional)';
  static const targetLabel = 'Target';
  static const targetHint = '12';
  static const targetInvalid = 'A whole number above 0 works.';
  static const unitLabel = 'Unit';
  static const unitHint = 'lessons';
  static const defaultUnit = 'steps';
  static const linkedUnit = 'tasks';
  static const countManual = 'I count';
  static const countLinked = 'Linked tasks';
  static const statusLabel = 'Status';
  static const save = 'Save';
  static const cancel = 'Cancel';

  // Cheers (cheering layer, #26)
  static String milestone(GoalMilestone m, String title) => switch (m) {
    GoalMilestone.closeToDone => 'Almost there on "$title". Lovely pace.',
    GoalMilestone.completed => 'You did it: "$title" is complete.',
  };
  static const counted = 'Counted. Nice step.';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Dec 31" (local date).
  static String date(DateTime d) {
    final l = d.toLocal();
    return '${_months[l.month - 1]} ${l.day}';
  }
}
