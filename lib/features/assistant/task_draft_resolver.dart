import 'package:timezone/timezone.dart' as tz;

import '../../core/domain/energy.dart';
import '../../core/domain/task.dart';
import '../recurrence/recurrence.dart';
import '../tasks/day_bounds.dart' show fromZoneWall;
import 'task_draft.dart';

/// A [TaskDraft] resolved into concrete, persist-ready domain values.
///
/// The parser (#107) and the LLM path (#38) produce wall-clock strings
/// in the user's zone; the "Add" action on the task card (#39) then
/// needs real UTC [DateTime]s to hand to the repository. This is the
/// hinge between the draft and the task.
///
/// Recurrence travels alongside the task because `ReminderRule` needs
/// the task's id — the caller allocates that, saves the task, then
/// builds the rule from [recurrence].
class ResolvedTaskDraft {
  const ResolvedTaskDraft({required this.task, this.recurrence});

  /// The task ready to persist. Fields the draft did not fill carry
  /// the [Task] defaults (30 min, [Energy.light]).
  final Task task;

  /// The parsed recurrence, or null for a one-off draft.
  final Recurrence? recurrence;
}

/// Resolves a [TaskDraft] into a persist-ready [Task] (+ optional
/// [Recurrence]) in the user's zone.
///
/// Pure Dart: takes `now` and the task id as inputs, so the Ask
/// composer can stay deterministic in tests and on-device.
class TaskDraftResolver {
  const TaskDraftResolver({
    this.defaultDurationMinutes = 30,
    this.defaultEnergy = Energy.light,
  });

  /// Used when the draft gave no explicit duration. Matches [Task]'s
  /// own default so a captured task behaves the same on the Plan as a
  /// manually-added one.
  final int defaultDurationMinutes;

  /// Used when the draft gave no energy hint.
  final Energy defaultEnergy;

  /// Resolve [draft] into a persist-ready [Task].
  ///
  /// - [location]: the user's zone; wall-clock `date`+`time` are mapped
  ///   to UTC via it.
  /// - [now]: used for `createdAt`/`updatedAt` (stored as UTC) and, for
  ///   a recurring draft without an explicit date, as the series anchor.
  /// - [id]: the task id the caller allocated.
  ///
  /// Behaviour:
  /// - date + time → `scheduledStart`/`scheduledEnd` set and
  ///   [Task.lockedStart] true (the user said the time, the scheduler
  ///   does not move it), `remindAt` at the start, and `dueAt` at end
  ///   of that day in [location].
  /// - date only → `dueAt` at 23:59 in [location]; `scheduledStart`
  ///   stays null so the Plan can place the task on the day.
  /// - no date → no scheduling fields; the task just sits in the
  ///   backlog until the user or the Plan slots it.
  /// - recurrence present and no anchor → `remindAt` seeded at the
  ///   start of the day (or today in [location]) so the occurrence
  ///   expander has something to walk from.
  /// - an unparseable [TaskDraft.recurrenceRrule] drops to `null`
  ///   rather than raising: capture never breaks over a bad RRULE.
  ResolvedTaskDraft resolve(
    TaskDraft draft, {
    required tz.Location location,
    required DateTime now,
    required String id,
  }) {
    final estimated = draft.durationMinutes ?? defaultDurationMinutes;
    final energy = draft.energy ?? defaultEnergy;
    final utcNow = now.toUtc();

    DateTime? scheduledStart;
    DateTime? scheduledEnd;
    DateTime? dueAt;
    DateTime? remindAt;
    var locked = false;

    final date = _parseDate(draft.date);
    final time = _parseTime(draft.time);

    if (date != null) {
      if (time != null) {
        scheduledStart = fromZoneWall(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
          location,
        );
        scheduledEnd = scheduledStart.add(Duration(minutes: estimated));
        remindAt = scheduledStart;
        locked = true;
      }
      dueAt = fromZoneWall(
        DateTime(date.year, date.month, date.day, 23, 59),
        location,
      );
    }

    final recurrence = _parseRecurrence(draft.recurrenceRrule);

    // A series needs a remindAt anchor for the occurrence expander.
    // Fall back to midnight of the draft's date, or of today in [location].
    if (recurrence != null && remindAt == null) {
      final anchor = date ?? _todayIn(now, location);
      remindAt = fromZoneWall(
        DateTime(anchor.year, anchor.month, anchor.day),
        location,
      );
    }

    final task = Task(
      id: id,
      title: draft.title,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      lockedStart: locked,
      dueAt: dueAt,
      remindAt: remindAt,
      estimatedMinutes: estimated,
      energy: energy,
      firstAction: draft.firstAction,
      createdAt: utcNow,
      updatedAt: utcNow,
    );

    return ResolvedTaskDraft(task: task, recurrence: recurrence);
  }
}

Recurrence? _parseRecurrence(String? rrule) {
  if (rrule == null || rrule.trim().isEmpty) return null;
  try {
    return Recurrence.parse(rrule);
  } on FormatException {
    return null;
  }
}

class _Date {
  const _Date(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;
}

class _Time {
  const _Time(this.hour, this.minute);
  final int hour;
  final int minute;
}

_Date? _parseDate(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  final year = int.parse(m[1]!);
  final month = int.parse(m[2]!);
  final day = int.parse(m[3]!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return _Date(year, month, day);
}

_Time? _parseTime(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s);
  if (m == null) return null;
  return _Time(int.parse(m[1]!), int.parse(m[2]!));
}

_Date _todayIn(DateTime now, tz.Location location) {
  final local = tz.TZDateTime.from(now, location);
  return _Date(local.year, local.month, local.day);
}
