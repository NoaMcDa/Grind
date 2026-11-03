import 'dart:ui';

import '../../l10n/app_localizations.dart';

/// Pure-Dart recurrence descriptions ("Every Mon, Wed, Fri") for
/// `Recurrence.describe`, which runs without a widget tree. All copy lives in
/// the ARB files and is looked up by locale; widgets use `context.l10n`.
class RecurrenceStrings {
  RecurrenceStrings._(this.l, this.isHebrew);

  final AppLocalizations l;
  final bool isHebrew;

  static RecurrenceStrings of(Locale locale) => RecurrenceStrings._(
    lookupAppLocalizations(Locale(locale.languageCode)),
    locale.languageCode == 'he',
  );

  String _short(int weekday) => switch (weekday) {
    1 => l.commonWeekdayShortMon,
    2 => l.commonWeekdayShortTue,
    3 => l.commonWeekdayShortWed,
    4 => l.commonWeekdayShortThu,
    5 => l.commonWeekdayShortFri,
    6 => l.commonWeekdayShortSat,
    _ => l.commonWeekdayShortSun,
  };

  String _month(int month) => [
    l.commonMonthShortJan,
    l.commonMonthShortFeb,
    l.commonMonthShortMar,
    l.commonMonthShortApr,
    l.commonMonthShortMay,
    l.commonMonthShortJun,
    l.commonMonthShortJul,
    l.commonMonthShortAug,
    l.commonMonthShortSep,
    l.commonMonthShortOct,
    l.commonMonthShortNov,
    l.commonMonthShortDec,
  ][month - 1];

  String everyDay(int n) => l.recurrenceEveryDay(n);

  String get everyWeekday => l.recurrenceEveryWeekday;

  String everyWeek(int n, List<int> days) {
    final names = [for (final d in days) _short(d)];
    final list = names.length == 1
        ? names.first
        : isHebrew
        ? l.recurrenceListJoinLast(
            names.sublist(0, names.length - 1).join(', '),
            names.last,
          )
        : names.join(', ');
    return l.recurrenceEveryWeek(n, list);
  }

  String everyWeekPlain(int n) => l.recurrenceEveryWeekPlain(n);

  String everyMonth(int n, int? day) => day == null
      ? l.recurrenceEveryMonth(n)
      : l.recurrenceEveryMonthOn(n, isHebrew ? '$day' : _ordinal(day));

  String untilSuffix(DateTime d) => ' ${l.recurrenceUntil(dateLabel(d))}';

  String countSuffix(int count) => ', ${l.recurrenceTimesCount(count)}';

  String dateLabel(DateTime d) =>
      l.recurrenceDateLabel(d.day, _month(d.month), d.year);

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }
}
