import '../../core/domain/energy.dart';
import '../recurrence/recurrence.dart';
import 'task_draft.dart';

/// One-line human-readable summary of a [TaskDraft], in EN or HE, for the
/// Ask-composer task card (#39).
///
/// Pure Dart: takes `now` as input so "today"/"tomorrow"/weekday names are
/// deterministic in tests and independent of `DateTime.now()`.
///
/// Shape:
///
///     <title> · <date and time> · <duration> · <energy> · <recurrence>
///
/// Parts the draft did not fill are left out. The separator is a non-space
/// middle dot framed by spaces — the same one the Plan card uses — so the
/// card stays readable at a glance in both scripts.
class TaskDraftPreview {
  const TaskDraftPreview._();

  /// Format [draft] using [locale] ('en' or 'he'; anything else falls back
  /// to EN) and [now] as the reference for relative dates.
  ///
  /// [now] is read for its calendar date only; its time zone is ignored
  /// (the draft already carries wall-clock date strings in the user's
  /// zone, so the comparison is calendar-to-calendar).
  static String format(
    TaskDraft draft, {
    required DateTime now,
    String locale = 'en',
  }) {
    final isHebrew = locale.toLowerCase().startsWith('he');
    final lex = isHebrew ? _he : _en;

    final parts = <String>[draft.title];

    final whenPart = _formatWhen(draft, now, lex);
    if (whenPart != null) parts.add(whenPart);

    if (draft.durationMinutes != null) {
      parts.add(_formatDuration(draft.durationMinutes!, lex));
    }

    if (draft.energy != null) {
      parts.add(_formatEnergy(draft.energy!, lex));
    }

    final rrulePart = _formatRecurrence(draft.recurrenceRrule, lex);
    if (rrulePart != null) parts.add(rrulePart);

    return parts.join(' · ');
  }

  // --------------------------------- when -------------------------------- //

  static String? _formatWhen(TaskDraft draft, DateTime now, _Lexicon lex) {
    final date = _parseDate(draft.date);
    final time = _parseTime(draft.time);
    if (date == null && time == null) return null;

    final buf = StringBuffer();
    if (date != null) {
      buf.write(_formatRelativeDate(date, now, lex));
    }
    if (time != null) {
      if (date != null) buf.write(' ');
      buf.write(_formatTime(time));
    }
    return buf.toString();
  }

  static String _formatRelativeDate(_Date d, DateTime now, _Lexicon lex) {
    final today = _Date(now.year, now.month, now.day);
    final deltaDays = _daysBetween(today, d);
    if (deltaDays == 0) return lex.today;
    if (deltaDays == 1) return lex.tomorrow;
    if (deltaDays == -1) return lex.yesterday;
    if (deltaDays > 1 && deltaDays < 7) {
      // Within the coming week → weekday name.
      final weekday = _weekdayOf(d);
      return lex.weekdays[weekday - 1];
    }
    // Anything else → short absolute date, locale-shaped.
    return lex.absoluteDate(d);
  }

  static String _formatTime(_Time t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  // ------------------------------- duration ------------------------------ //

  static String _formatDuration(int minutes, _Lexicon lex) {
    if (minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return lex.minutes(m);
    if (m == 0) return lex.hours(h);
    return '${lex.hours(h)} ${lex.minutes(m)}';
  }

  // -------------------------------- energy ------------------------------- //

  static String _formatEnergy(Energy e, _Lexicon lex) => switch (e) {
    Energy.deep => lex.energyDeep,
    Energy.light => lex.energyLight,
  };

  // ----------------------------- recurrence ------------------------------ //

  static String? _formatRecurrence(String? rrule, _Lexicon lex) {
    if (rrule == null || rrule.trim().isEmpty) return null;
    Recurrence r;
    try {
      r = Recurrence.parse(rrule);
    } on FormatException {
      return null;
    }
    return switch (r.preset) {
      RecurrencePreset.daily => lex.repeatsDaily,
      RecurrencePreset.weekdays => lex.repeatsWeekdays,
      RecurrencePreset.weekly => lex.repeatsWeekly,
      RecurrencePreset.monthly => lex.repeatsMonthly,
    };
  }
}

// ----------------------------- shared helpers --------------------------- //

class _Date {
  const _Date(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;
}

class _Time {
  const _Time(this.hour, this.minute);
  final int hour;
  final int minute;
}

_Date? _parseDate(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  final year = int.parse(m[1]!);
  final month = int.parse(m[2]!);
  final day = int.parse(m[3]!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return _Date(year, month, day);
}

_Time? _parseTime(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s);
  if (m == null) return null;
  return _Time(int.parse(m[1]!), int.parse(m[2]!));
}

/// Signed day difference between [a] and [b], ignoring any time component.
/// Uses [DateTime.utc] on both sides so a DST jump cannot widen the delta.
int _daysBetween(_Date a, _Date b) {
  final da = DateTime.utc(a.year, a.month, a.day);
  final db = DateTime.utc(b.year, b.month, b.day);
  return db.difference(da).inDays;
}

/// ISO weekday (Monday = 1 … Sunday = 7) for [_Date], without pulling in a
/// time zone.
int _weekdayOf(_Date d) => DateTime.utc(d.year, d.month, d.day).weekday;

// --------------------------------- lexicon ------------------------------ //

class _Lexicon {
  const _Lexicon({
    required this.today,
    required this.tomorrow,
    required this.yesterday,
    required this.weekdays,
    required this.energyDeep,
    required this.energyLight,
    required this.repeatsDaily,
    required this.repeatsWeekdays,
    required this.repeatsWeekly,
    required this.repeatsMonthly,
    required this.minutes,
    required this.hours,
    required this.absoluteDate,
  });

  final String today;
  final String tomorrow;
  final String yesterday;

  /// Full weekday names, index 0 = Monday … 6 = Sunday.
  final List<String> weekdays;

  final String energyDeep;
  final String energyLight;

  final String repeatsDaily;
  final String repeatsWeekdays;
  final String repeatsWeekly;
  final String repeatsMonthly;

  final String Function(int m) minutes;
  final String Function(int h) hours;
  final String Function(_Date d) absoluteDate;
}

final _Lexicon _en = _Lexicon(
  today: 'Today',
  tomorrow: 'Tomorrow',
  yesterday: 'Yesterday',
  weekdays: const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ],
  energyDeep: 'deep',
  energyLight: 'light',
  repeatsDaily: 'daily',
  repeatsWeekdays: 'weekdays',
  repeatsWeekly: 'weekly',
  repeatsMonthly: 'monthly',
  minutes: (m) => '$m min',
  hours: (h) => '${h}h',
  absoluteDate: (d) {
    const months = [
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
    return '${months[d.month - 1]} ${d.day}';
  },
);

String _heHours(int h) {
  if (h == 1) return 'שעה';
  if (h == 2) return 'שעתיים';
  return '$h שעות';
}

final _Lexicon _he = _Lexicon(
  today: 'היום',
  tomorrow: 'מחר',
  yesterday: 'אתמול',
  weekdays: const [
    'יום שני',
    'יום שלישי',
    'יום רביעי',
    'יום חמישי',
    'יום שישי',
    'שבת',
    'יום ראשון',
  ],
  energyDeep: 'עמוק',
  energyLight: 'קל',
  repeatsDaily: 'יומי',
  repeatsWeekdays: 'ימי חול',
  repeatsWeekly: 'שבועי',
  repeatsMonthly: 'חודשי',
  minutes: (m) => '$m דק׳',
  hours: _heHours,
  absoluteDate: (d) => '${d.day}.${d.month}',
);
