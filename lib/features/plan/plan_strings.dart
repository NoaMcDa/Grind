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
  static const openInCalendarApple =
      'Open the Calendar app to see this one. A direct link is coming.';
  static const openInCalendarLocal = 'This one lives in Grind only.';
  static const openInCalendarFailed = "Couldn't open the calendar just now.";

  // Scheduler (#16).
  static const replan = 'Re-plan with Pip';
  static const replanTitle = "Pip's draft for the week";
  static const replanPlacedLabel = 'WHERE THINGS GO';
  static const replanUnplacedLabel = "WHAT DIDN'T FIT";
  static const replanNothing =
      'Nothing to move. Your week already looks settled.';
  static const replanPast = 'This week is behind us. Pick today or later.';
  static String replanKept(int n) => n == 1
      ? 'One thing you placed yourself stays put.'
      : '$n things you placed yourself stay put.';
  static const apply = 'Apply';
  static const notNow = 'Not now';
  static String applied(int n) => n == 0
      ? 'All set, nothing needed moving.'
      : n == 1
      ? 'Done. One thing has a spot now.'
      : 'Done. $n things have a spot now.';
  static const scheduleForMe = 'Schedule it for me';
  static const details = 'Details';
  static String scheduledAt(String when, String reason) => '$when · $reason';
  static String notScheduled(String reason) => 'No spot yet: $reason';
  static const nothingToSchedule = 'this one is already done';
  static const noRoomThisWeek = 'no free gap before the end of the week';

  static String _hours(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = (minutes / 30).round() / 2;
    return h == h.roundToDouble() ? '${h.toInt()} h' : '$h h';
  }

  /// "14 h free · 9 h planned", or a soft heads-up when the week is full.
  static String capacityLine({
    required int freeMinutes,
    required int plannedMinutes,
  }) {
    if (plannedMinutes > freeMinutes) {
      return 'A full week: over by ${_hours(plannedMinutes - freeMinutes)}. '
          'Pip can help trim it.';
    }
    return '${_hours(freeMinutes)} free · ${_hours(plannedMinutes)} planned';
  }

  /// "Thu 14:00–14:45".
  static String slot(DateTime s, DateTime e) {
    String hm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    return '${weekdayShort[s.weekday - 1]} ${hm(s)}–${hm(e)}';
  }

  static const markDone = 'Mark done';
  static const markOpen = 'Mark as not done';
  static const unschedule = 'Unschedule';
  static const taskDetailTitle = 'Task';
  static const back = 'Back';
  static const cantDropHere = 'That slot is taken by an event.';
}
