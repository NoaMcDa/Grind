import '../../l10n/l10n.dart';
import 'scheduler/scheduler.dart' show WeekCapacity;

/// Localized date and time pieces for the Today and Plan screens.
///
/// Weekday 1 = Monday, month 1 = January, matching `DateTime`.
String weekdayShortL(AppLocalizations l, int weekday) => [
  l.commonWeekdayShortMon,
  l.commonWeekdayShortTue,
  l.commonWeekdayShortWed,
  l.commonWeekdayShortThu,
  l.commonWeekdayShortFri,
  l.commonWeekdayShortSat,
  l.commonWeekdayShortSun,
][weekday - 1];

String weekdayFullL(AppLocalizations l, int weekday) => [
  l.commonWeekdayFullMon,
  l.commonWeekdayFullTue,
  l.commonWeekdayFullWed,
  l.commonWeekdayFullThu,
  l.commonWeekdayFullFri,
  l.commonWeekdayFullSat,
  l.commonWeekdayFullSun,
][weekday - 1];

String monthShortL(AppLocalizations l, int month) => [
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

/// "Thu, Oct 29" (Hebrew: "יום ה׳, 29 באוק׳").
String formatPlanDay(AppLocalizations l, DateTime d) => l.commonDateShort(
  weekdayShortL(l, d.weekday),
  monthShortL(l, d.month),
  d.day,
);

/// "Thursday, Oct 29" for the Today header.
String formatTodayLabel(AppLocalizations l, DateTime d) => l.commonDateShort(
  weekdayFullL(l, d.weekday),
  monthShortL(l, d.month),
  d.day,
);

/// "Thu 14:00–14:45".
String formatPlanSlot(AppLocalizations l, DateTime s, DateTime e) {
  String hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
  return '${weekdayShortL(l, s.weekday)} ${hm(s)}–${hm(e)}';
}

String _hoursShort(AppLocalizations l, int minutes) {
  if (minutes < 60) return l.commonMinutes(minutes);
  final h = (minutes / 30).round() / 2;
  return l.planHoursShort(h == h.roundToDouble() ? '${h.toInt()}' : '$h');
}

/// "14 h free · 9 h planned", or a soft heads-up when the week is full.
String planCapacityLine(
  AppLocalizations l, {
  required int freeMinutes,
  required int plannedMinutes,
}) {
  if (plannedMinutes > freeMinutes) {
    return l.planCapacityFull(_hoursShort(l, plannedMinutes - freeMinutes));
  }
  if (plannedMinutes == 0) {
    return l.planCapacityNothing(_hoursShort(l, freeMinutes));
  }
  return l.planCapacityLine(
    _hoursShort(l, freeMinutes),
    _hoursShort(l, plannedMinutes),
  );
}

String _durationLong(AppLocalizations l, int minutes) => minutes < 60
    ? l.planDurationMinutes(minutes)
    : l.planDurationHours((minutes / 60).round());

/// The replan sheet's one-line summary of free vs planned time.
String planCapacitySummary(
  AppLocalizations l,
  WeekCapacity capacity, {
  int deferrals = 0,
}) {
  final head = l.planSummaryHead(
    _durationLong(l, capacity.freeMinutes),
    _durationLong(l, capacity.demandMinutes),
  );
  if (!capacity.overbooked) return l.planSummaryFits(head);
  if (deferrals == 0) return l.planSummaryLighter(head);
  return l.planSummaryDefer(head, deferrals);
}
