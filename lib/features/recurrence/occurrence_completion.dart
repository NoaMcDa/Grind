import 'package:grind/core/core.dart';

import 'occurrence_expander.dart';

/// The first occurrence strictly after [after] (the occurrence time, i.e.
/// ignoring the lead), or null when the series has ended.
DateTime? nextOccurrence({
  required ReminderRule rule,
  required DateTime anchor,
  required DateTime after,
  required String timeZoneName,
}) {
  final next = expandOccurrences(
    rule: rule.copyWith(leadMinutes: 0),
    anchor: anchor,
    from: after.add(const Duration(minutes: 1)),
    to: after.add(const Duration(days: 800)),
    timeZoneName: timeZoneName,
    maxResults: 1,
  );
  return next.isEmpty ? null : next.first.toUtc();
}

/// Completes one occurrence of a recurring task without completing the
/// series: returns the task with `remindAt` advanced to the next occurrence.
/// When no occurrence is left the task is marked done instead.
///
/// Limitation: the rule has nowhere to remember completions, so the series
/// is "anchored" at `remindAt` and moves forward with it. `COUNT` therefore
/// restarts from the new anchor, and a skipped (never completed) past
/// occurrence is simply not remembered. Proposed fix: a
/// `ReminderRule.lastCompletedAt` field (see the PR description).
Task completeOccurrence({
  required Task task,
  required ReminderRule rule,
  required DateTime occurrenceAt,
  required String timeZoneName,
  required DateTime now,
}) {
  final anchor = task.remindAt ?? occurrenceAt;
  final next = nextOccurrence(
    rule: rule,
    anchor: anchor,
    after: occurrenceAt,
    timeZoneName: timeZoneName,
  );
  if (next == null) {
    return task.copyWith(
      status: TaskStatus.done,
      completedAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
  }
  return task.copyWith(remindAt: next, snoozeCount: 0, updatedAt: now.toUtc());
}
