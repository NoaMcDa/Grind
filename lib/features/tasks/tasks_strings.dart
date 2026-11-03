/// English strings for the tasks feature. The integrator moves these into
/// the ARB files after Wave 2 (see docs/plans/ownership.md).
abstract final class TasksStrings {
  static const newTask = 'New task';
  static const editTask = 'Edit task';
  static const titleLabel = 'What needs doing?';
  static const titleRequired = 'Give it a short name and you are set.';
  static const dueLabel = 'Due';
  static const today = 'Today';
  static const tomorrow = 'Tomorrow';
  static const pickDate = 'Pick a date';
  static const noDate = 'No date';
  static const dueTime = 'Due time';
  static const reminderTime = 'Reminder';
  static const addTime = 'Add a time';
  static const clear = 'Clear';
  static const estimateLabel = 'How long?';
  static const custom = 'Custom';
  static const customMinutes = 'Minutes';
  static const energyLabel = 'Energy';
  static const deep = 'Deep focus';
  static const light = 'Light';
  static const firstActionLabel = 'First action';
  static const firstActionHint = "If it's 7:00, then open the thesis file";
  static const notesLabel = 'Notes';
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const addTask = 'Add a task';
  static const goalLabel = 'Goal';
  static const noGoal = 'No goal';

  static const detailTitle = 'Task';
  static const notFound = 'This task is not here anymore.';
  static const backToToday = 'Back to Today';
  static const complete = 'Complete';
  static const reopen = 'Mark as open';
  static const edit = 'Edit';
  static const delete = 'Delete';
  static const deleteTitle = 'Delete this task?';
  static const deleteBody = 'You can undo it right after.';
  static const keep = 'Keep it';
  static const deleted = 'Task deleted';
  static const markedDone = 'Nicely done';
  static const undo = 'Undo';
  static const nextOneSet = 'Nicely done. The next one is lined up.';
  static const repeatsLabel = 'Repeats';
  static const scheduledLabel = 'On the plan';
  static const notScheduled = 'Not placed yet';

  static const emptyTitle = 'Nothing due today';
  static const emptyBody = 'Add one small thing and Pip will remind you.';
  static const emptyAction = 'Add a task';
  static const upNext = 'Up next';
  static const momentum = 'Momentum';

  static String doneOf(int done, int total) => '$done of $total today';
  static String minutes(int m) => '$m min';

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

  /// "Thu, Oct 29" for a local date.
  static String date(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
}
