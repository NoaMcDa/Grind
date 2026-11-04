import 'package:flutter/foundation.dart';

import '../../../l10n/l10n.dart';

/// One concrete time window the assistant scheduled on the user's
/// timeline, in the user's local time zone (start inclusive, end
/// exclusive, minute-aligned).
///
/// Part of the confirmation slice of #42: a tool executor hands one
/// of these back for every window it placed (a plan, a focus session,
/// a calendar event) and [formatToolConfirmation] turns them into the
/// one-line "Done: …" sentence the assistant shows.
@immutable
class ScheduledRange {
  const ScheduledRange(this.start, this.end);

  /// Start of the window, local time.
  final DateTime start;

  /// End of the window, local time. Must be strictly after [start].
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is ScheduledRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ScheduledRange($start → $end)';
}

/// Localized "Done: 09:00–09:25 and 15:00–15:25" confirmation line for
/// a tool result (#42).
///
/// Ranges are rendered in the order given, each as `HH:mm–HH:mm` on
/// [ScheduledRange.start] / [ScheduledRange.end] (local time). An
/// empty list yields the plain "Done." / "בוצע." sentence; one range
/// skips the list separator; three or more use the serial separator
/// plus the final "and" connector.
///
/// Pure Dart on purpose — the executor and tests both call it, no
/// `BuildContext` needed.
String formatToolConfirmation(AppLocalizations l, List<ScheduledRange> ranges) {
  if (ranges.isEmpty) return l.toolConfirmationEmpty;
  final parts = [for (final r in ranges) _formatRange(r)];
  return l.toolConfirmationDone(_joinWithAnd(l, parts));
}

String _formatRange(ScheduledRange r) => '${_hm(r.start)}–${_hm(r.end)}';

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}';

/// "a", "a and b", "a, b and c". The trailing connector and the list
/// separator are both localized — Hebrew uses "ו-" and the same comma.
String _joinWithAnd(AppLocalizations l, List<String> parts) {
  if (parts.length == 1) return parts.first;
  if (parts.length == 2) return l.commonJoinAnd(parts.first, parts.last);
  final head = parts.take(parts.length - 1).join(l.commonListSeparator);
  return l.commonJoinAnd(head, parts.last);
}
