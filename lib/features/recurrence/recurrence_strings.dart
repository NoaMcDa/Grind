import 'dart:ui';

/// Unit kinds for [RecurrenceStrings.intervalUnit].
enum RecurrenceUnit { day, week, month }

/// Copy for recurrence UI and descriptions, English and Hebrew. Kept here
/// until the integrator moves it into the ARB files.
class RecurrenceStrings {
  const RecurrenceStrings._(this.isHebrew);

  final bool isHebrew;

  static RecurrenceStrings of(Locale locale) =>
      RecurrenceStrings._(locale.languageCode == 'he');

  // Index 0 = Monday ... 6 = Sunday.
  static const _enShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _enFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _heDay = [
    'שני',
    'שלישי',
    'רביעי',
    'חמישי',
    'שישי',
    'שבת',
    'ראשון',
  ];
  static const _heLetter = ['ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳', 'א׳'];
  static const _enLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Short weekday name used in lists ("Mon"); weekday 1 = Monday.
  String weekdayShort(int weekday) =>
      isHebrew ? _heDay[weekday - 1] : _enShort[weekday - 1];

  /// One-letter toggle label.
  String weekdayLetter(int weekday) =>
      isHebrew ? _heLetter[weekday - 1] : _enLetter[weekday - 1];

  String weekdayFull(int weekday) =>
      isHebrew ? 'יום ${_heDay[weekday - 1]}' : _enFull[weekday - 1];

  String get doesNotRepeat => isHebrew ? 'לא חוזר' : 'Does not repeat';
  String get daily => isHebrew ? 'כל יום' : 'Daily';
  String get weekdays => isHebrew ? 'ימי חול' : 'Weekdays';
  String get weekly => isHebrew ? 'שבועי' : 'Weekly';
  String get monthly => isHebrew ? 'חודשי' : 'Monthly';
  String get repeatLabel => isHebrew ? 'חזרה' : 'Repeat';
  String get onDays => isHebrew ? 'בימים' : 'On days';
  String get everyLabel => isHebrew ? 'כל' : 'Every';
  String get endsLabel => isHebrew ? 'מסתיים' : 'Ends';
  String get never => isHebrew ? 'אף פעם' : 'Never';
  String get onDate => isHebrew ? 'בתאריך' : 'On a date';
  String get done => isHebrew ? 'סיום' : 'Done';
  String get increase => isHebrew ? 'הגדלה' : 'Increase';
  String get decrease => isHebrew ? 'הקטנה' : 'Decrease';

  String intervalUnit(RecurrenceUnit unit, int n) {
    if (isHebrew) {
      return switch (unit) {
        RecurrenceUnit.day => n == 1 ? 'יום' : 'ימים',
        RecurrenceUnit.week => n == 1 ? 'שבוע' : 'שבועות',
        RecurrenceUnit.month => n == 1 ? 'חודש' : 'חודשים',
      };
    }
    return switch (unit) {
      RecurrenceUnit.day => n == 1 ? 'day' : 'days',
      RecurrenceUnit.week => n == 1 ? 'week' : 'weeks',
      RecurrenceUnit.month => n == 1 ? 'month' : 'months',
    };
  }

  String get editThisOne => isHebrew ? 'רק את זה' : 'This one';
  String get editAllFuture => isHebrew ? 'את כל הבאים' : 'All future';
  String get editTitle =>
      isHebrew ? 'לערוך רק את הפעם הזאת?' : 'Change just this one?';
  String get editHint => isHebrew
      ? 'אפשר לשנות פעם אחת, או את הסדרה מכאן והלאה.'
      : 'Change this one time, or the series from here on.';

  // --- descriptions ---

  String everyDay(int n) => isHebrew
      ? (n == 1 ? 'כל יום' : 'כל $n ימים')
      : (n == 1 ? 'Every day' : 'Every $n days');

  String get everyWeekday => isHebrew ? 'בכל יום חול' : 'Every weekday';

  String everyWeek(int n, List<int> days) {
    if (isHebrew) {
      final list = _heJoin([for (final d in days) _heDay[d - 1]]);
      return n == 1 ? 'כל יום $list' : 'כל $n שבועות ביום $list';
    }
    final list = [for (final d in days) _enShort[d - 1]].join(', ');
    return n == 1 ? 'Every $list' : 'Every $n weeks on $list';
  }

  String everyWeekPlain(int n) => isHebrew
      ? (n == 1 ? 'כל שבוע' : 'כל $n שבועות')
      : (n == 1 ? 'Every week' : 'Every $n weeks');

  String everyMonth(int n, int? day) {
    if (isHebrew) {
      final head = n == 1 ? 'כל חודש' : 'כל $n חודשים';
      return day == null ? head : '$head ב-$day';
    }
    final head = n == 1 ? 'Every month' : 'Every $n months';
    return day == null ? head : '$head on the ${_ordinal(day)}';
  }

  String untilSuffix(DateTime d) =>
      isHebrew ? ' עד ${d.day}/${d.month}/${d.year}' : ' until ${_date(d)}';

  String countSuffix(int count) =>
      isHebrew ? ', $count פעמים' : ', $count times';

  String dateLabel(DateTime d) =>
      isHebrew ? '${d.day}/${d.month}/${d.year}' : _date(d);

  String _date(DateTime d) {
    const m = [
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
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  static String _heJoin(List<String> items) {
    if (items.length == 1) return items.first;
    final head = items.sublist(0, items.length - 1).join(', ');
    return '$head ו${items.last}';
  }
}
