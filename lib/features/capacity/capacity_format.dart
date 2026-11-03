import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import 'capacity_math.dart';
import 'priority_math.dart';

/// "45 min", "3 h", "2.5 h" (whole minutes in, Pip-sized units out).
String formatSpan(BuildContext context, int minutes) {
  final l = context.l10n;
  if (minutes < 60) return l.capacityMinutesShort('$minutes');
  final h = (minutes / 6).round() / 10; // one decimal
  final text = h == h.roundToDouble() ? h.toInt().toString() : h.toString();
  return l.capacityHoursShort(text);
}

/// Short weekday ("Mon", "ב׳") for a wall-clock day.
String weekdayShort(BuildContext context, DateTime d) =>
    DateFormat.E(Localizations.localeOf(context).toString()).format(d);

/// "Mon, Nov 9".
String dayLong(BuildContext context, DateTime d) =>
    DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(d);

String stateLabel(BuildContext context, LoadState s) => switch (s) {
  LoadState.calm => context.l10n.capacityStateFits,
  LoadState.tight => context.l10n.capacityStateTight,
  LoadState.overbooked => context.l10n.capacityStateOver,
};

String reasonLabel(BuildContext context, PriorityReason r) {
  final l = context.l10n;
  return switch (r) {
    PriorityReason.pinnedTop => l.capacityReasonPinnedTop,
    PriorityReason.overdue => l.capacityReasonOverdue,
    PriorityReason.dueSoon => l.capacityReasonDueSoon,
    PriorityReason.markedHigh => l.capacityReasonMarkedHigh,
    PriorityReason.goalMatters => l.capacityReasonGoalMatters,
    PriorityReason.goalStalled => l.capacityReasonGoalStalled,
    PriorityReason.goalMoving => l.capacityReasonGoalMoving,
    PriorityReason.quickWin => l.capacityReasonQuickWin,
    PriorityReason.steady => l.capacityReasonSteady,
  };
}

String pinLabel(BuildContext context, PriorityPin p) {
  final l = context.l10n;
  return switch (p) {
    PriorityPin.top => l.capacityPinTop,
    PriorityPin.high => l.capacityPinHigh,
    PriorityPin.normal => l.capacityPinNormal,
    PriorityPin.low => l.capacityPinLow,
  };
}
