import 'dart:ui';

import 'package:rrule/rrule.dart';

import 'recurrence_strings.dart';

enum RecurrencePreset { daily, weekdays, weekly, monthly }

/// A small typed view of the RRULE subset the app supports: daily, weekdays,
/// weekly on chosen days, monthly on a day-of-month, with an interval and an
/// end (until date or count). Round-trips through [toRRule] / [parse].
///
/// Weekday numbers follow [DateTime]: Monday = 1 ... Sunday = 7.
class Recurrence {
  const Recurrence({
    required this.preset,
    this.weekdays = const {},
    this.interval = 1,
    this.monthDay,
    this.until,
    this.count,
  }) : assert(interval >= 1),
       assert(monthDay == null || (monthDay >= 1 && monthDay <= 31));

  const Recurrence.daily({int interval = 1, DateTime? until, int? count})
    : this(
        preset: RecurrencePreset.daily,
        interval: interval,
        until: until,
        count: count,
      );

  const Recurrence.weekdays({DateTime? until, int? count})
    : this(preset: RecurrencePreset.weekdays, until: until, count: count);

  const Recurrence.weekly(
    Set<int> days, {
    int interval = 1,
    DateTime? until,
    int? count,
  }) : this(
         preset: RecurrencePreset.weekly,
         weekdays: days,
         interval: interval,
         until: until,
         count: count,
       );

  const Recurrence.monthly(
    int? day, {
    int interval = 1,
    DateTime? until,
    int? count,
  }) : this(
         preset: RecurrencePreset.monthly,
         monthDay: day,
         interval: interval,
         until: until,
         count: count,
       );

  static const monFriSet = {1, 2, 3, 4, 5};

  final RecurrencePreset preset;

  /// For [RecurrencePreset.weekly]; empty means "the anchor's weekday".
  final Set<int> weekdays;
  final int interval;

  /// For [RecurrencePreset.monthly]; null means "the anchor's day".
  final int? monthDay;

  /// Last day the series may fire (date part used; inclusive).
  final DateTime? until;
  final int? count;

  List<int> get sortedWeekdays => weekdays.toList()..sort();

  Recurrence copyWith({
    RecurrencePreset? preset,
    Set<int>? weekdays,
    int? interval,
    Object? monthDay = _unset,
    Object? until = _unset,
    Object? count = _unset,
  }) => Recurrence(
    preset: preset ?? this.preset,
    weekdays: weekdays ?? this.weekdays,
    interval: interval ?? this.interval,
    monthDay: monthDay == _unset ? this.monthDay : monthDay as int?,
    until: until == _unset ? this.until : until as DateTime?,
    count: count == _unset ? this.count : count as int?,
  );

  /// RRULE body without the `RRULE:` prefix, e.g.
  /// `FREQ=WEEKLY;BYDAY=MO,WE,FR`. `UNTIL` is written as the end of that day,
  /// as a floating wall-clock time marked UTC (see occurrence_expander.dart).
  String toRRule() {
    final frequency = switch (preset) {
      RecurrencePreset.daily => Frequency.daily,
      RecurrencePreset.weekdays || RecurrencePreset.weekly => Frequency.weekly,
      RecurrencePreset.monthly => Frequency.monthly,
    };
    final days = switch (preset) {
      RecurrencePreset.weekdays => monFriSet.toList(),
      RecurrencePreset.weekly => sortedWeekdays,
      _ => const <int>[],
    };
    final rule = RecurrenceRule(
      frequency: frequency,
      interval: preset == RecurrencePreset.weekdays || interval == 1
          ? null
          : interval,
      byWeekDays: [for (final d in days) ByWeekDayEntry(d)],
      byMonthDays: preset == RecurrencePreset.monthly && monthDay != null
          ? [monthDay!]
          : const [],
      until: until == null
          ? null
          : DateTime.utc(until!.year, until!.month, until!.day, 23, 59, 59),
      count: count,
    );
    return rule.toString().replaceFirst('RRULE:', '');
  }

  /// Parses an RRULE body (with or without `RRULE:`; extra lines such as
  /// `EXDATE:` are ignored). Throws [FormatException] for rules outside the
  /// supported subset.
  static Recurrence parse(String rrule) {
    var body = rrule.split('\n').first.trim();
    if (!body.startsWith('RRULE:')) body = 'RRULE:$body';
    final RecurrenceRule rule;
    try {
      rule = RecurrenceRule.fromString(body);
    } on Object catch (e) {
      throw FormatException('Unsupported RRULE "$rrule": $e');
    }
    final until = rule.until == null
        ? null
        : DateTime(rule.until!.year, rule.until!.month, rule.until!.day);
    final interval = rule.interval ?? 1;
    final days = {for (final e in rule.byWeekDays) e.day};
    switch (rule.frequency) {
      case Frequency.daily:
        return Recurrence(
          preset: RecurrencePreset.daily,
          interval: interval,
          until: until,
          count: rule.count,
        );
      case Frequency.weekly:
        final isWeekdays =
            interval == 1 && days.length == 5 && days.containsAll(monFriSet);
        return Recurrence(
          preset: isWeekdays
              ? RecurrencePreset.weekdays
              : RecurrencePreset.weekly,
          weekdays: isWeekdays ? const {} : days,
          interval: interval,
          until: until,
          count: rule.count,
        );
      case Frequency.monthly:
        return Recurrence(
          preset: RecurrencePreset.monthly,
          monthDay: rule.byMonthDays.isEmpty ? null : rule.byMonthDays.first,
          interval: interval,
          until: until,
          count: rule.count,
        );
      default:
        throw FormatException('Unsupported frequency in "$rrule"');
    }
  }

  /// "Every Mon, Wed, Fri" / "כל יום שני, רביעי ושישי".
  String describe(Locale locale) {
    final s = RecurrenceStrings.of(locale);
    var text = switch (preset) {
      RecurrencePreset.daily => s.everyDay(interval),
      RecurrencePreset.weekdays => s.everyWeekday,
      RecurrencePreset.weekly =>
        weekdays.isEmpty
            ? s.everyWeekPlain(interval)
            : s.everyWeek(interval, sortedWeekdays),
      RecurrencePreset.monthly => s.everyMonth(interval, monthDay),
    };
    if (until != null) text += s.untilSuffix(until!);
    if (count != null) text += s.countSuffix(count!);
    return text;
  }

  @override
  bool operator ==(Object other) =>
      other is Recurrence && other.toRRule() == toRRule();

  @override
  int get hashCode => toRRule().hashCode;

  @override
  String toString() => 'Recurrence(${toRRule()})';
}

const _unset = Object();
