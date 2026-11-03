import 'package:grind/core/core.dart';

/// Where a task that did not get done today can go.
enum RolloverChoice { keep, tomorrow, laterThisWeek, tomorrowAnyway, drop }

/// Local calendar day key, `yyyy-MM-dd`.
String dayKey(DateTime t) {
  final l = t.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-'
      '${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

/// Same local wall-clock time, [days] calendar days later (DST-safe).
DateTime shiftDays(DateTime t, int days) {
  final l = t.toLocal();
  return DateTime(
    l.year,
    l.month,
    l.day + days,
    l.hour,
    l.minute,
    l.second,
  ).toUtc();
}

/// The moment a rollover is judged against the deadline.
DateTime? _reference(Task t) => t.remindAt ?? t.scheduledStart;

/// True when moving [task] by [days] keeps it on or before its deadline.
bool fitsDeadline(Task task, int days) {
  final ref = _reference(task);
  if (ref == null) return false;
  final due = task.dueAt;
  return due == null || !shiftDays(ref, days).isAfter(due);
}

/// Moves [task] by [days]. Without [pushDeadline] the result never lands past
/// `dueAt`: returns null when it would. With it, `dueAt` moves too.
Task? rolloverTask(
  Task task,
  int days, {
  required DateTime now,
  bool pushDeadline = false,
}) {
  if (!pushDeadline && !fitsDeadline(task, days)) return null;
  DateTime? mv(DateTime? t) => t == null ? null : shiftDays(t, days);
  return task.copyWith(
    remindAt: mv(task.remindAt),
    scheduledStart: mv(task.scheduledStart),
    scheduledEnd: mv(task.scheduledEnd),
    dueAt: pushDeadline ? mv(task.dueAt) : task.dueAt,
    snoozeCount: 0,
    updatedAt: now.toUtc(),
  );
}

/// Which options a task offers in the "moves on" step.
List<RolloverChoice> optionsFor(Task task) {
  final out = <RolloverChoice>[];
  if (fitsDeadline(task, 1)) {
    out.add(RolloverChoice.tomorrow);
    if (fitsDeadline(task, 2)) out.add(RolloverChoice.laterThisWeek);
  } else {
    out.addAll([RolloverChoice.keep, RolloverChoice.tomorrowAnyway]);
  }
  out.add(RolloverChoice.drop);
  return out;
}

/// Open tasks whose reminder or due time falls on [now]'s local day.
List<Task> reviewTasksFor(Iterable<Task> all, DateTime now) {
  final key = dayKey(now);
  DateTime when(Task t) => t.remindAt ?? t.dueAt!;
  return all
      .where((t) => t.deletedAt == null && t.status == TaskStatus.open)
      .where((t) {
        final at = t.remindAt ?? t.dueAt;
        return at != null && dayKey(at) == key;
      })
      .toList()
    ..sort((a, b) => when(a).compareTo(when(b)));
}
