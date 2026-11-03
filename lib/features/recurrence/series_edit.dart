import 'package:flutter/material.dart';
import 'package:grind/core/core.dart';
import 'package:grind/theme/app_text.dart';
import 'package:grind/theme/tokens.dart';
import 'package:grind/widgets/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

import 'occurrence_completion.dart';
import 'occurrence_expander.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/core/notifications/time_zones.dart';

/// Which part of a recurring series an edit applies to.
enum SeriesEditChoice { thisOne, allFuture }

/// Asks "This one" or "All future". Null when dismissed.
Future<SeriesEditChoice?> showSeriesEditChoice(BuildContext context) {
  final s = context.l10n;
  return showStickerSheet<SeriesEditChoice>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(s.recurrenceEditTitle, style: AppText.display(size: 22)),
        const SizedBox(height: 6),
        Text(s.recurrenceEditHint, style: AppText.body(color: AppColors.muted)),
        const SizedBox(height: 16),
        PillButton(
          label: s.recurrenceEditThisOne,
          color: AppColors.violet,
          textColor: Colors.white,
          onPressed: () => Navigator.pop(ctx, SeriesEditChoice.thisOne),
        ),
        const SizedBox(height: 10),
        PillButton(
          label: s.recurrenceEditAllFuture,
          onPressed: () => Navigator.pop(ctx, SeriesEditChoice.allFuture),
        ),
      ],
    ),
  );
}

Task _clone(Task t, String id, DateTime now) => Task(
  id: id,
  title: t.title,
  notes: t.notes,
  goalId: t.goalId,
  dueAt: t.dueAt,
  remindAt: t.remindAt,
  scheduledStart: t.scheduledStart,
  scheduledEnd: t.scheduledEnd,
  lockedStart: t.lockedStart,
  notBefore: t.notBefore,
  minutesDone: 0,
  estimatedMinutes: t.estimatedMinutes,
  energy: t.energy,
  firstAction: t.firstAction,
  priority: t.priority,
  category: t.category,
  splittable: t.splittable,
  minChunkMinutes: t.minChunkMinutes,
  createdAt: now.toUtc(),
  updatedAt: now.toUtc(),
);

String _occurrenceKey(DateTime at) =>
    '${at.toUtc().millisecondsSinceEpoch ~/ 60000}';

/// "This one": detaches [occurrenceAt] from the series.
///
/// Creates a one-off task copy (id `<taskId>~<epoch minutes>`, no rule) at
/// that occurrence, which [edit] may change, and excludes the occurrence
/// from the series with an EXDATE line in [ReminderRule.rrule] (see
/// [RruleText]; the `rrule` package has no EXDATE model). The copy is done
/// when the occurrence was ([isOccurrenceDone]); the series keeps its
/// `lastCompletedAt` and its start (pinned as DTSTART). If the excluded
/// occurrence is the series' current `remindAt`, the series task advances to
/// its next occurrence so the core scheduler does not fire the old one.
/// Returns the new one-off task.
Future<Task> editThisOccurrence({
  required TaskRepository tasks,
  required ReminderRepository rules,
  required Task task,
  required ReminderRule rule,
  required DateTime occurrenceAt,
  required String timeZoneName,
  required DateTime now,
  Task Function(Task detached)? edit,
}) async {
  final location = locationFor(timeZoneName);
  final wall = tz.TZDateTime.from(occurrenceAt, location);
  var detached = _clone(
    task,
    '${task.id}~${_occurrenceKey(occurrenceAt)}',
    now,
  ).copyWith(remindAt: occurrenceAt.toUtc());
  if (isOccurrenceDone(rule, occurrenceAt)) {
    detached = detached.copyWith(
      status: TaskStatus.done,
      completedAt: rule.lastCompletedAt!.toUtc(),
    );
  }
  final result = edit == null ? detached : edit(detached);

  final anchor = task.remindAt;
  final pinned = anchor == null
      ? rule
      : pinSeriesStart(rule, anchor, timeZoneName);
  final text = RruleText.parse(pinned.rrule).withExdate(wall);
  final nextRule = pinned.copyWith(
    rrule: text.toString(),
    updatedAt: now.toUtc(),
  );
  await rules.upsert(nextRule);
  if (anchor != null && anchor.toUtc() == occurrenceAt.toUtc()) {
    final next = nextOccurrence(
      rule: nextRule,
      anchor: anchor,
      after: occurrenceAt,
      timeZoneName: timeZoneName,
    );
    await tasks.upsert(
      next == null
          ? task.copyWith(
              status: TaskStatus.done,
              completedAt: now.toUtc(),
              updatedAt: now.toUtc(),
            )
          : task.copyWith(remindAt: next, updatedAt: now.toUtc()),
    );
  }
  await tasks.upsert(result);
  return result;
}

final _count = RegExp(r'(^|;)COUNT=(\d+)');

/// "All future": splits the series at [occurrenceAt].
///
/// The old rule gets `until` one minute before the occurrence (the "until
/// trick": history stays, future fires move to the new series) and keeps its
/// start (DTSTART) and `lastCompletedAt`; when nothing is pending before the
/// split any more, the old task is done. A new task (id
/// `<taskId>~<epoch minutes>`) starts at the occurrence with a new rule (a
/// copy of the old RRULE with the `COUNT` that is left and the later EXDATEs, or
/// [newRRule]); [edit] may change the task. A `lastCompletedAt` at or after
/// the occurrence moves to the new series, whose `remindAt` is then its next
/// pending occurrence.
///
/// If the occurrence is the series' first one (at or before its start)
/// there is nothing to preserve, so the task and its rule are updated in
/// place: the series restarts at the occurrence and keeps `lastCompletedAt`.
/// Returns the task that now carries the future series.
Future<Task> editAllFuture({
  required TaskRepository tasks,
  required ReminderRepository rules,
  required Task task,
  required ReminderRule rule,
  required DateTime occurrenceAt,
  required String timeZoneName,
  required DateTime now,
  String? newRRule,
  Task Function(Task future)? edit,
}) async {
  final utcNow = now.toUtc();
  final at = occurrenceAt.toUtc();
  final anchor = task.remindAt;
  final text = RruleText.parse(rule.rrule);
  if (anchor == null || !at.isAfter(seriesStart(rule, anchor, timeZoneName))) {
    final base = task.copyWith(remindAt: at);
    final updated = edit == null ? base : edit(base);
    await tasks.upsert(updated.copyWith(updatedAt: utcNow));
    if (newRRule != null || text.dtstart != null) {
      await rules.upsert(
        rule.copyWith(
          rrule: newRRule ?? text.withDtstart(null).toString(),
          updatedAt: utcNow,
        ),
      );
    }
    return updated;
  }

  final old = pinSeriesStart(rule, anchor, timeZoneName);
  await rules.upsert(
    old.copyWith(
      until: at.subtract(const Duration(minutes: 1)),
      updatedAt: utcNow,
    ),
  );
  if (!anchor.toUtc().isBefore(at)) {
    // remindAt is the next pending occurrence: none is left before the split.
    await tasks.upsert(
      task.copyWith(
        status: TaskStatus.done,
        completedAt: utcNow,
        updatedAt: utcNow,
      ),
    );
  }

  final futureText = newRRule ?? _futureText(old, anchor, at, timeZoneName);
  final id = '${task.id}~${_occurrenceKey(at)}';
  final future = _clone(task, id, now).copyWith(remindAt: at);
  var result = edit == null ? future : edit(future);
  final carried = isOccurrenceDone(rule, at) ? rule.lastCompletedAt : null;
  var futureRule = ReminderRule(
    id: 'rule-$id',
    taskId: id,
    rrule: futureText,
    leadMinutes: rule.leadMinutes,
    until: null,
    lastCompletedAt: carried?.toUtc(),
    createdAt: utcNow,
    updatedAt: utcNow,
  );
  final futureStart = result.remindAt;
  if (carried != null && futureStart != null) {
    futureRule = pinSeriesStart(futureRule, futureStart, timeZoneName);
    final next = nextOccurrence(
      rule: futureRule,
      anchor: futureStart,
      after: carried,
      timeZoneName: timeZoneName,
    );
    result = next == null
        ? result.copyWith(status: TaskStatus.done, completedAt: utcNow)
        : result.copyWith(remindAt: next);
  }
  await tasks.upsert(result);
  await rules.upsert(futureRule);
  return result;
}

/// The old series' RRULE for the part from [at] on: the `COUNT` that is
/// left (excluded dates count, RFC 5545) and the EXDATEs from [at] on. The
/// new series starts at its task's `remindAt`, so no DTSTART.
String _futureText(
  ReminderRule old,
  DateTime anchor,
  DateTime at,
  String timeZoneName,
) {
  final text = RruleText.parse(old.rrule);
  var body = text.body;
  final m = _count.firstMatch(body);
  if (m != null) {
    final used = expandOccurrences(
      rule: old.copyWith(
        rrule: RruleText(text.body, const [], text.dtstart).toString(),
        leadMinutes: 0,
        until: null,
      ),
      anchor: anchor,
      from: seriesStart(old, anchor, timeZoneName),
      to: at,
      timeZoneName: timeZoneName,
      maxResults: 100000,
    ).length;
    final left = int.parse(m.group(2)!) - used;
    body = body.replaceFirst(
      _count,
      '${m.group(1)}COUNT=${left < 1 ? 1 : left}',
    );
  }
  final location = locationFor(timeZoneName);
  final later = [
    for (final d in text.exdates)
      if (!tz.TZDateTime(
        location,
        d.year,
        d.month,
        d.day,
        d.hour,
        d.minute,
        d.second,
      ).toUtc().isBefore(at))
        d,
  ];
  return RruleText(body, later).toString();
}
