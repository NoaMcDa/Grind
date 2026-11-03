/// English strings still read by files outside the Today/Plan l10n
/// migration: `plan_task_sheet.dart` and `tasks/task_detail_screen.dart`.
/// Everything else moved to `context.l10n` (see `lib/l10n/MIGRATION.md`);
/// delete this file when those two switch over.
abstract final class PlanStrings {
  static const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

  static const scheduleForMe = 'Schedule it for me';
  static const details = 'Details';

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
}
