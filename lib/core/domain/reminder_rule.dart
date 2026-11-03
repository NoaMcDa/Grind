/// Recurrence for a task's reminder, as an RFC 5545 RRULE string
/// (e.g. `FREQ=WEEKLY;BYDAY=MO,WE,FR`). One-time reminders have no rule.
///
/// Occurrence expansion (issue #11) turns a rule plus the task's [Task.remindAt]
/// anchor into concrete fire times; the notification scheduler (#5) keeps
/// only the next 7 days pending.
class ReminderRule {
  const ReminderRule({
    required this.id,
    required this.taskId,
    required this.rrule,
    this.leadMinutes = 0,
    this.until,
    this.lastCompletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String taskId;

  /// RRULE body without the `RRULE:` prefix.
  final String rrule;

  /// Minutes before the occurrence to fire (0 = at the time).
  final int leadMinutes;
  final DateTime? until;

  /// When the most recent occurrence was marked done, so completing one
  /// occurrence does not complete the series (see review H1).
  final DateTime? lastCompletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ReminderRule copyWith({
    String? rrule,
    int? leadMinutes,
    Object? until = _unset,
    Object? lastCompletedAt = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => ReminderRule(
    id: id,
    taskId: taskId,
    rrule: rrule ?? this.rrule,
    leadMinutes: leadMinutes ?? this.leadMinutes,
    until: until == _unset ? this.until : until as DateTime?,
    lastCompletedAt: lastCompletedAt == _unset
        ? this.lastCompletedAt
        : lastCompletedAt as DateTime?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) => other is ReminderRule && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const _unset = Object();
