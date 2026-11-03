import 'package:flutter/material.dart';
import 'package:grind/core/core.dart';
import 'package:grind/theme/app_text.dart';
import 'package:grind/theme/tokens.dart';
import 'package:grind/widgets/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

import 'occurrence_completion.dart';
import 'occurrence_expander.dart';
import 'recurrence_strings.dart';
import 'package:grind/core/notifications/time_zones.dart';

/// Which part of a recurring series an edit applies to.
enum SeriesEditChoice { thisOne, allFuture }

/// Asks "This one" or "All future". Null when dismissed.
Future<SeriesEditChoice?> showSeriesEditChoice(BuildContext context) {
  final s = RecurrenceStrings.of(Localizations.localeOf(context));
  return showStickerSheet<SeriesEditChoice>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(s.editTitle, style: AppText.display(size: 22)),
        const SizedBox(height: 6),
        Text(s.editHint, style: AppText.body(color: AppColors.muted)),
        const SizedBox(height: 16),
        PillButton(
          label: s.editThisOne,
          color: AppColors.violet,
          textColor: Colors.white,
          onPressed: () => Navigator.pop(ctx, SeriesEditChoice.thisOne),
        ),
        const SizedBox(height: 10),
        PillButton(
          label: s.editAllFuture,
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
/// [RruleText]; the `rrule` package has no EXDATE model). If the excluded
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
  final detached = _clone(
    task,
    '${task.id}~${_occurrenceKey(occurrenceAt)}',
    now,
  ).copyWith(remindAt: occurrenceAt.toUtc());
  final result = edit == null ? detached : edit(detached);

  final text = RruleText.parse(rule.rrule).withExdate(wall);
  await rules.upsert(
    rule.copyWith(rrule: text.toString(), updatedAt: now.toUtc()),
  );
  final anchor = task.remindAt;
  if (anchor != null && anchor.toUtc() == occurrenceAt.toUtc()) {
    final next = nextOccurrence(
      rule: rule.copyWith(rrule: text.toString()),
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

/// "All future": splits the series at [occurrenceAt].
///
/// The old rule gets `until` one minute before the occurrence (the "until
/// trick": history stays, future fires move to the new series). A new task
/// (id `<taskId>~<epoch minutes>`) starts at the occurrence with a new rule
/// (a copy of the old RRULE, or [newRRule]); [edit] may change the task.
/// If the occurrence is the series' first one there is nothing to preserve,
/// so the task and its rule are updated in place. Returns the task that now
/// carries the future series.
Future<Task> editAllFuture({
  required TaskRepository tasks,
  required ReminderRepository rules,
  required Task task,
  required ReminderRule rule,
  required DateTime occurrenceAt,
  required DateTime now,
  String? newRRule,
  Task Function(Task future)? edit,
}) async {
  final anchor = task.remindAt;
  final isFirst =
      anchor == null || !occurrenceAt.toUtc().isAfter(anchor.toUtc());
  if (isFirst) {
    final base = task.copyWith(remindAt: occurrenceAt.toUtc());
    final updated = edit == null ? base : edit(base);
    await tasks.upsert(updated.copyWith(updatedAt: now.toUtc()));
    if (newRRule != null) {
      await rules.upsert(
        rule.copyWith(rrule: newRRule, updatedAt: now.toUtc()),
      );
    }
    return updated;
  }

  await rules.upsert(
    rule.copyWith(
      until: occurrenceAt.toUtc().subtract(const Duration(minutes: 1)),
      updatedAt: now.toUtc(),
    ),
  );
  final id = '${task.id}~${_occurrenceKey(occurrenceAt)}';
  final future = _clone(task, id, now).copyWith(remindAt: occurrenceAt.toUtc());
  final result = edit == null ? future : edit(future);
  await tasks.upsert(result);
  await rules.upsert(
    ReminderRule(
      id: 'rule-$id',
      taskId: id,
      rrule: newRRule ?? rule.rrule,
      leadMinutes: rule.leadMinutes,
      until: null,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    ),
  );
  return result;
}
