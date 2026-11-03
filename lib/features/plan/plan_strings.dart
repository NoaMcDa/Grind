/// Plan tab strings. The integrator moves these into the ARB files.
abstract final class PlanStrings {
  static const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const monthShort = [
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

  static const titleToday = 'Your day, drafted';
  static const titleOtherDay = 'Your day';
  static String subtitle(int tasks, int events) =>
      'Pip arranged $tasks ${tasks == 1 ? 'task' : 'tasks'} around '
      '$events ${events == 1 ? 'event' : 'events'}. Long-press a task to move it.';

  static const emptyTitle = 'Nothing planned yet';
  static const emptyBody =
      'A quiet day. Add a task and Pip will find it a good spot.';

  static const previousDay = 'Previous day';
  static const nextDay = 'Next day';
  static const pickDay = 'Pick a day';
  static const weekStripLabel = 'Week';
  static const nowLabel = 'Now';
  static String dayLoad(String day, int percent) => '$day, $percent% booked';

  static String doneCount(int done, int total) => '$done of $total done';

  static const fromCalendar = 'FROM CALENDAR';
  static const allDay = 'All day';
  static const calendarGoogle = 'Google Calendar';
  static const calendarApple = 'Apple Calendar';
  static const calendarLocal = 'Grind';
  static const calendarLabel = 'Calendar';
  static const openInCalendar = 'Open in calendar';
  static const openInCalendarSoon = 'Opening the calendar app is coming soon.';

  static const markDone = 'Mark done';
  static const markOpen = 'Mark as not done';
  static const unschedule = 'Unschedule';
  static const taskDetailTitle = 'Task';
  static const back = 'Back';
  static const cantDropHere = 'That slot is taken by an event.';
}
