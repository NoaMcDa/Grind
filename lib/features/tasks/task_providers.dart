import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rrule/rrule.dart';

import '../../core/core.dart';
import '../recurrence/occurrence_completion.dart';
import '../recurrence/occurrence_expander.dart';
import '../recurrence/providers.dart';
import 'day_bounds.dart';

/// The live task with [id], or null when missing or deleted.
final taskByIdProvider = Provider.family<Task?, String>((ref, id) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  for (final t in all) {
    if (t.id == id) return t;
  }
  return null;
});

DateTime? _when(Task t) => t.remindAt ?? t.dueAt;

int _byWhen(Task a, Task b) {
  final x = _when(a), y = _when(b);
  if (x == null && y == null) return a.createdAt.compareTo(b.createdAt);
  if (x == null) return 1;
  if (y == null) return -1;
  return x.compareTo(y);
}

/// Open tasks, soonest first; tasks without a time go last.
final openTasksProvider = Provider<List<Task>>((ref) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  return all.where((t) => !t.isDone && t.deletedAt == null).toList()
    ..sort(_byWhen);
});

/// One row of the Today list: a task, and for a recurring task the
/// occurrence that falls on the day.
class TodayItem {
  const TodayItem(this.task, {this.at, this.occurrence = false, bool? done})
    : _done = done;

  final Task task;

  /// The time shown on the row (UTC): the occurrence for a series, else
  /// the task's reminder.
  final DateTime? at;

  /// True for an occurrence of a recurring task: completing it completes
  /// this occurrence only.
  final bool occurrence;

  final bool? _done;

  /// Done: the task, or for an occurrence, at or before the rule's
  /// `lastCompletedAt` (the series task itself stays open).
  bool get isDone => _done ?? task.isDone;

  /// Stable per row (a series can occur more than once a day).
  String get key =>
      occurrence ? '${task.id}@${at!.millisecondsSinceEpoch}' : task.id;

  @override
  bool operator ==(Object other) =>
      other is TodayItem &&
      other.task == task &&
      other.at == at &&
      other.occurrence == occurrence &&
      other.isDone == isDone;

  @override
  int get hashCode => Object.hash(task, at, occurrence, isDone);
}

/// What falls on [day]: one-off tasks whose reminder or due time is on the
/// day, and each occurrence of a recurring task on the day (expanded from
/// its rule in the day's zone). A series whose rule cannot be expanded, or
/// a finished one without completions, is treated as a one-off. Open first
/// by time, done last.
///
/// Occurrences at or before the rule's `lastCompletedAt` are done: when
/// `lastCompletedAt` falls on [day] they stay as done rows (so "1 of 3
/// today" counts them), on other days they are not due and are left out.
List<TodayItem> itemsOnDay({
  required Iterable<Task> tasks,
  required Map<String, ReminderRule> rules,
  required DayBounds day,
}) {
  final out = <TodayItem>[];
  for (final t in tasks) {
    if (t.deletedAt != null) continue;
    final rule = rules[t.id];
    final anchor = t.remindAt;
    final last = rule?.lastCompletedAt;
    if (rule != null &&
        anchor != null &&
        (!t.isDone || last != null) &&
        _expandable(rule)) {
      final occurrences = expandOccurrences(
        rule: rule.copyWith(leadMinutes: 0),
        anchor: anchor,
        from: day.start,
        to: day.end,
        timeZoneName: day.location.name,
      );
      for (final o in occurrences) {
        final at = utcOf(o);
        final done = isOccurrenceDone(rule, at);
        if (done ? !day.contains(last) : t.isDone) continue;
        out.add(TodayItem(t, at: at, occurrence: true, done: done));
      }
      continue;
    }
    if (day.contains(t.remindAt) || day.contains(t.dueAt)) {
      out.add(TodayItem(t, at: t.remindAt));
    }
  }
  out.sort((a, b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    final x = a.at ?? a.task.dueAt, y = b.at ?? b.task.dueAt;
    if (x == null && y == null) {
      return a.task.createdAt.compareTo(b.task.createdAt);
    }
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  });
  return out;
}

bool _expandable(ReminderRule rule) {
  final body = RruleText.parse(rule.rrule).body;
  if (body.isEmpty) return false;
  try {
    RecurrenceRule.fromString('RRULE:$body');
    return true;
  } on Object {
    return false;
  }
}

/// Today's rows in the user's zone (`Preferences.timeZoneName`), per
/// [clockProvider]; see [itemsOnDay].
final todayTasksProvider = Provider.autoDispose<List<TodayItem>>((ref) {
  final day = ref.watch(todayBoundsProvider);
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final rules =
      ref.watch(reminderRulesProvider).valueOrNull ?? const <ReminderRule>[];
  return itemsOnDay(
    tasks: all,
    rules: {for (final r in rules) r.taskId: r},
    day: day,
  );
});

/// How many of today's rows are done.
final todayDoneCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(todayTasksProvider).where((t) => t.isDone).length,
);
