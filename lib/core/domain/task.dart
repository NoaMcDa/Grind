import 'energy.dart';

enum TaskStatus { open, done, skipped }

/// The unit everything hangs off: a thing to do, optionally reminded,
/// optionally scheduled onto the timeline, optionally linked to a goal.
///
/// Immutable. Use [copyWith]. Times are UTC [DateTime]s; display converts.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.notes,
    this.goalId,
    this.dueAt,
    this.remindAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.lockedStart = false,
    this.notBefore,
    this.minutesDone = 0,
    this.estimatedMinutes = 30,
    this.energy = Energy.light,
    this.firstAction,
    this.priority = 2,
    this.category,
    this.splittable = false,
    this.minChunkMinutes = 25,
    this.status = TaskStatus.open,
    this.completedAt,
    this.actualMinutes,
    this.snoozeCount = 0,
    this.calendarEventId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String? notes;
  final String? goalId;

  /// Hard deadline (end of that day if only a date was given).
  final DateTime? dueAt;

  /// When the reminder fires. Recurrence lives in [ReminderRule].
  final DateTime? remindAt;

  /// Placement on the timeline, set by the user (drag) or the scheduler.
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;

  /// True when the user placed it by hand; the scheduler never moves it.
  final bool lockedStart;

  /// Earliest allowed start for the scheduler (null = now).
  final DateTime? notBefore;

  /// Minutes already spent, so the scheduler plans only the remainder.
  final int minutesDone;

  final int estimatedMinutes;
  final Energy energy;

  /// The if-then first step: "open the thesis file".
  final String? firstAction;

  /// 1 = must, 2 = should (default), 3 = nice to have.
  final int priority;

  /// Free-form bucket for duration statistics ("study", "admin", "workout").
  final String? category;
  final bool splittable;
  final int minChunkMinutes;

  final TaskStatus status;
  final DateTime? completedAt;
  final int? actualMinutes;
  final int snoozeCount;

  /// Id of the [CalendarEvent] written back to an external calendar.
  final String? calendarEventId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDone => status == TaskStatus.done;
  bool get isScheduled => scheduledStart != null && scheduledEnd != null;

  Task copyWith({
    String? title,
    Object? notes = _unset,
    Object? goalId = _unset,
    Object? dueAt = _unset,
    Object? remindAt = _unset,
    Object? scheduledStart = _unset,
    Object? scheduledEnd = _unset,
    bool? lockedStart,
    Object? notBefore = _unset,
    int? minutesDone,
    int? estimatedMinutes,
    Energy? energy,
    Object? firstAction = _unset,
    int? priority,
    Object? category = _unset,
    bool? splittable,
    int? minChunkMinutes,
    TaskStatus? status,
    Object? completedAt = _unset,
    Object? actualMinutes = _unset,
    int? snoozeCount,
    Object? calendarEventId = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => Task(
    id: id,
    title: title ?? this.title,
    notes: notes == _unset ? this.notes : notes as String?,
    goalId: goalId == _unset ? this.goalId : goalId as String?,
    dueAt: dueAt == _unset ? this.dueAt : dueAt as DateTime?,
    remindAt: remindAt == _unset ? this.remindAt : remindAt as DateTime?,
    scheduledStart: scheduledStart == _unset
        ? this.scheduledStart
        : scheduledStart as DateTime?,
    scheduledEnd: scheduledEnd == _unset
        ? this.scheduledEnd
        : scheduledEnd as DateTime?,
    lockedStart: lockedStart ?? this.lockedStart,
    notBefore: notBefore == _unset ? this.notBefore : notBefore as DateTime?,
    minutesDone: minutesDone ?? this.minutesDone,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    energy: energy ?? this.energy,
    firstAction: firstAction == _unset
        ? this.firstAction
        : firstAction as String?,
    priority: priority ?? this.priority,
    category: category == _unset ? this.category : category as String?,
    splittable: splittable ?? this.splittable,
    minChunkMinutes: minChunkMinutes ?? this.minChunkMinutes,
    status: status ?? this.status,
    completedAt: completedAt == _unset
        ? this.completedAt
        : completedAt as DateTime?,
    actualMinutes: actualMinutes == _unset
        ? this.actualMinutes
        : actualMinutes as int?,
    snoozeCount: snoozeCount ?? this.snoozeCount,
    calendarEventId: calendarEventId == _unset
        ? this.calendarEventId
        : calendarEventId as String?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) => other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task($id, $title, $status)';
}

const _unset = Object();
