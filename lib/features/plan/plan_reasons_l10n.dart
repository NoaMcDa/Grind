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
/// anything else is returned unchanged. Covers placement reasons, unplaced
/// reasons and the move / removal reasons produced by `diffPlans` for the
/// "Re-plan with Pip" diff view.
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
    // Re-plan diff: move reasons from `_moveReason` in `replan.dart`.
    case 'that time has passed':
      return l.planDiffReasonTimePassed;
    case 'your hours changed':
      return l.planDiffReasonHoursChanged;
    case 'an earlier slot opened up':
      return l.planDiffReasonEarlierOpened;
    case "reshuffled around today's changes":
      return l.planDiffReasonReshuffled;
    // Re-plan diff: removal reasons from `_removalReason` in `replan.dart`.
    case 'no longer on your list':
      return l.planDiffRemovedNotOnList;
    case 'done, nice work':
      return l.planDiffRemovedDone;
    case 'skipped for now':
      return l.planDiffRemovedSkipped;
    case 'no longer fits this week':
      return l.planDiffRemovedNoLongerFits;
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
  // Re-plan diff: parameterized move reasons from `_moveReason` in
  // `replan.dart`. "you put" and "made room for" are checked before the
  // broader "{title} now takes that time" because titles are free-form.
  r = m(r'you put (.+) there');
  if (r != null) return l.planDiffReasonPinned(r[1]!);
  r = m(r'made room for (.+)');
  if (r != null) return l.planDiffReasonMadeRoomFor(r[1]!);
  r = m(r'(.+) now takes that time');
  if (r != null) return l.planDiffReasonEventTook(r[1]!);
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

/// Shows a re-plan trigger summary in the app language.
///
/// `replanTrigger(...)` in `scheduler/replan_trigger.dart` writes its
/// `summary` in English ("you skipped X", "X ran 15 min over", "Dentist
/// lands at 15:00", "Seminar moved to Thursday 09:00"). When [summary]
/// matches one of those templates it is rebuilt from ARB strings; anything
/// else is returned unchanged. The patterns with specific English suffixes
/// are checked before the broader "{title} moved to ..." so a title that
/// contains those phrases still routes correctly.
String localizeReplanTriggerSummary(AppLocalizations l, String summary) {
  Match? m(String pattern) => RegExp('^$pattern\$').firstMatch(summary);

  var r = m(r'you skipped (.+)');
  if (r != null) return l.planTriggerSkipped(r[1]!);
  r = m(r'(.+) ran (\d+)h (\d+)m over');
  if (r != null) {
    return l.planTriggerOverrunHoursMinutes(
      r[1]!,
      int.parse(r[2]!),
      int.parse(r[3]!),
    );
  }
  r = m(r'(.+) ran (\d+)h over');
  if (r != null) return l.planTriggerOverrunHours(r[1]!, int.parse(r[2]!));
  r = m(r'(.+) ran (\d+) min over');
  if (r != null) return l.planTriggerOverrunMinutes(r[1]!, int.parse(r[2]!));
  r = m(r'(.+) lands at (\d{2}:\d{2})');
  if (r != null) return l.planTriggerEventLands(r[1]!, r[2]!);
  // `dayWord` from the scheduler core: "today", "tomorrow", a weekday, or
  // "Nov 12" (month + day).
  r = m(
    r'(.+) moved to (today|tomorrow|[A-Z][a-z]+(?: \d{1,2})?) '
    r'(\d{2}:\d{2})',
  );
  if (r != null) {
    return l.planTriggerEventMovedDayTime(r[1]!, _dayWord(l, r[2]!), r[3]!);
  }
  r = m(r'(.+) moved to (\d{2}:\d{2})');
  if (r != null) return l.planTriggerEventMovedTime(r[1]!, r[2]!);
  return summary;
}
