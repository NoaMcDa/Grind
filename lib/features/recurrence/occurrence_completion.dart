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
  return next.isEmpty ? null : _plainUtc(next.first);
}

/// [t] as a plain UTC [DateTime] (the expander hands back `TZDateTime`s;
/// stored values are plain).
DateTime _plainUtc(DateTime t) =>
    DateTime.fromMillisecondsSinceEpoch(t.millisecondsSinceEpoch, isUtc: true);

/// The last occurrence strictly before [before] (within a year), or null
/// when [before] is the series' first one.
DateTime? previousOccurrence({
  required ReminderRule rule,
  required DateTime anchor,
  required DateTime before,
  required String timeZoneName,
}) {
  final start = seriesStart(rule, anchor, timeZoneName);
  final yearAgo = before.toUtc().subtract(const Duration(days: 366));
  final past = expandOccurrences(
    rule: rule.copyWith(leadMinutes: 0),
    anchor: anchor,
    from: start.isAfter(yearAgo) ? start : yearAgo,
    to: before,
    timeZoneName: timeZoneName,
    maxResults: 2000,
  );
  return past.isEmpty ? null : _plainUtc(past.last);
}

/// A recurring task and its rule after a completion change.
typedef SeriesProgress = ({Task task, ReminderRule rule});

/// Whether [occurrenceAt] of the series counts as done: at or before
/// `rule.lastCompletedAt`.
bool isOccurrenceDone(ReminderRule rule, DateTime occurrenceAt) {
  final last = rule.lastCompletedAt;
  return last != null && !occurrenceAt.toUtc().isAfter(last.toUtc());
}

/// Completes one occurrence of a recurring task without completing the
/// series.
///
/// The rule remembers the progress: `lastCompletedAt` becomes
/// [occurrenceAt] (never moves backwards), and the series start is pinned as
/// DTSTART ([pinSeriesStart]) so `COUNT` and `until` keep counting from it.
/// The task's `remindAt` moves to the next occurrence after that, for the
/// notification scheduler; when no occurrence is left the task is done.
SeriesProgress completeSeriesOccurrence({
  required Task task,
  required ReminderRule rule,
  required DateTime occurrenceAt,
  required String timeZoneName,
  required DateTime now,
}) {
  final anchor = task.remindAt ?? occurrenceAt;
  final pinned = pinSeriesStart(rule, anchor, timeZoneName);
  final at = _plainUtc(occurrenceAt);
  final prior = pinned.lastCompletedAt;
  final last = prior != null && prior.isAfter(at) ? prior : at;
  final nextRule = pinned.copyWith(
    lastCompletedAt: last,
    updatedAt: now.toUtc(),
  );
  final next = nextOccurrence(
    rule: nextRule,
    anchor: anchor,
    after: last,
    timeZoneName: timeZoneName,
  );
  final nextTask = next == null
      ? task.copyWith(
          status: TaskStatus.done,
          completedAt: now.toUtc(),
          updatedAt: now.toUtc(),
        )
      : task.copyWith(remindAt: next, snoozeCount: 0, updatedAt: now.toUtc());
  return (task: nextTask, rule: nextRule);
}

/// Takes the completion of [occurrenceAt] back: `lastCompletedAt` returns to
/// the occurrence before it (or null for the first one), the task is open
/// again and `remindAt` is the first occurrence after the new
/// `lastCompletedAt` (the series start when null).
SeriesProgress uncompleteSeriesOccurrence({
  required Task task,
  required ReminderRule rule,
  required DateTime occurrenceAt,
  required String timeZoneName,
  required DateTime now,
}) {
  final anchor = task.remindAt ?? occurrenceAt;
  final pinned = pinSeriesStart(rule, anchor, timeZoneName);
  final previous = previousOccurrence(
    rule: pinned,
    anchor: anchor,
    before: occurrenceAt,
    timeZoneName: timeZoneName,
  );
  final nextRule = pinned.copyWith(
    lastCompletedAt: previous,
    updatedAt: now.toUtc(),
  );
  final after =
      previous ??
      seriesStart(
        pinned,
        anchor,
        timeZoneName,
      ).subtract(const Duration(minutes: 1));
  final pending = nextOccurrence(
    rule: nextRule,
    anchor: anchor,
    after: after,
    timeZoneName: timeZoneName,
  );
  return (
    task: task.copyWith(
      status: TaskStatus.open,
      completedAt: null,
      remindAt: pending ?? _plainUtc(occurrenceAt),
      snoozeCount: 0,
      updatedAt: now.toUtc(),
    ),
    rule: nextRule,
  );
}

/// Task side of [completeSeriesOccurrence], for callers that only write the
/// task. Prefer [completeSeriesOccurrence] and store the rule too: without
/// it `lastCompletedAt` is not recorded and, for a rule without DTSTART,
/// `COUNT` restarts from the moved `remindAt`.
Task completeOccurrence({
  required Task task,
  required ReminderRule rule,
  required DateTime occurrenceAt,
  required String timeZoneName,
  required DateTime now,
}) => completeSeriesOccurrence(
  task: task,
  rule: rule,
  occurrenceAt: occurrenceAt,
  timeZoneName: timeZoneName,
  now: now,
).task;
