import '../../l10n/l10n.dart';
import 'plan_l10n.dart';

const _englishWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _englishMonths = [
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

/// Shows a scheduler reason in the app language.
///
/// The pure scheduler core writes its `reasons` in English. When [reason]
/// matches one of its known templates it is rebuilt from ARB strings;
/// anything else is returned unchanged.
String localizePlanReason(AppLocalizations l, String reason) {
  Match? m(String pattern) => RegExp('^$pattern\$').firstMatch(reason);

  switch (reason) {
    case 'you placed this here':
      return l.planReasonPlacedByYou;
    case 'your focus window':
      return l.planReasonFocusWindow;
    case 'the due date has passed, want to pick a new one?':
      return l.planReasonDatePassed;
    case 'this one is already done':
      return l.planNothingToSchedule;
    case 'no free gap before the end of the week':
      return l.planNoRoomThisWeek;
    case 'keeps your focus window clear':
      return l.planReasonFocusClear;
    case 'in the order you chose':
      return l.planReasonYourOrder;
  }
  var r = m(r'due (.+)');
  if (r != null) return l.planReasonDue(_dayWord(l, r[1]!));
  r = m(r'part of (.+)');
  if (r != null) return l.planReasonPartOf(r[1]!);
  r = m(r'(first|next|last) (\d+) of (\d+) min');
  if (r != null) {
    final minutes = int.parse(r[2]!);
    final total = int.parse(r[3]!);
    return switch (r[1]) {
      'first' => l.planReasonChunkFirst(minutes, total),
      'last' => l.planReasonChunkLast(minutes, total),
      _ => l.planReasonChunkNext(minutes, total),
    };
  }
  r = m(r'earliest free (\d+)-minute gap');
  if (r != null) return l.planReasonEarliestGap(int.parse(r[1]!));
  r = m(r'earliest free (\d+)-minute gap before (.+)');
  if (r != null) {
    return l.planReasonEarliestGapBefore(
      int.parse(r[1]!),
      _deadlineWord(l, r[2]!),
    );
  }
  r = m(r'fills a (\d+)-minute gap');
  if (r != null) return l.planReasonFillsGap(int.parse(r[1]!));
  r = m(r'focus blocks are full (.+)');
  if (r != null) return l.planReasonFocusFull(_by(l, r[1]!));
  r = m(r'only (\d+) of (\d+) min fit (.+)');
  if (r != null) {
    return l.planReasonOnlyFit(
      int.parse(r[1]!),
      int.parse(r[2]!),
      _by(l, r[3]!),
    );
  }
  r = m(r'no free (\d+)-minute slot (.+)');
  if (r != null) return l.planReasonNoSlot(int.parse(r[1]!), _by(l, r[2]!));
  return reason;
}

/// "today", "tomorrow", "Thursday" or "Nov 12".
String _dayWord(AppLocalizations l, String w) {
  if (w == 'today') return l.planWordToday;
  if (w == 'tomorrow') return l.planWordTomorrow;
  final wd = _englishWeekdays.indexOf(w);
  if (wd >= 0) return weekdayFullL(l, wd + 1);
  final date = RegExp(r'^([A-Z][a-z]{2}) (\d{1,2})$').firstMatch(w);
  if (date != null) {
    final mo = _englishMonths.indexOf(date[1]!);
    if (mo >= 0) {
      return l.goalsDate(monthShortL(l, mo + 1), int.parse(date[2]!));
    }
  }
  return w;
}

/// "today's deadline", "tomorrow's deadline" or "the Thursday deadline".
String _deadlineWord(AppLocalizations l, String w) {
  if (w == "today's deadline") return l.planDeadlineToday;
  if (w == "tomorrow's deadline") return l.planDeadlineTomorrow;
  final m = RegExp(r'^the (.+) deadline$').firstMatch(w);
  if (m != null) return l.planDeadlineOn(_dayWord(l, m[1]!));
  return w;
}

/// "this week" or "before" plus a deadline or a day.
String _by(AppLocalizations l, String by) {
  if (by == 'this week') return l.planByThisWeek;
  if (by == 'today') return l.planByToday;
  if (by.startsWith('before ')) {
    final rest = by.substring(7);
    final isDeadline = rest.endsWith('deadline');
    return l.planByBefore(
      isDeadline ? _deadlineWord(l, rest) : _dayWord(l, rest),
    );
  }
  return by;
}
