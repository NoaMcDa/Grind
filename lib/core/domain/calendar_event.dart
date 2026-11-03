enum CalendarSource { google, apple, local }

/// An event mirrored from an external calendar (or created by Grind and
/// written back). Busy events block time in the scheduler.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.source,
    required this.externalId,
    this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    this.isAllDay = false,
    this.isBusy = true,
    this.taskId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final CalendarSource source;

  /// Provider's id for the event (Google event id / EventKit identifier).
  final String externalId;
  final String? calendarId;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;

  /// False for "free"/transparent events: shown, but not blocking.
  final bool isBusy;

  /// Set when this event is the write-back of a Grind task.
  final String? taskId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Duration get duration => end.difference(start);

  CalendarEvent copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
    bool? isBusy,
    Object? calendarId = _unset,
    Object? taskId = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => CalendarEvent(
    id: id,
    source: source,
    externalId: externalId,
    calendarId: calendarId == _unset ? this.calendarId : calendarId as String?,
    title: title ?? this.title,
    start: start ?? this.start,
    end: end ?? this.end,
    isAllDay: isAllDay ?? this.isAllDay,
    isBusy: isBusy ?? this.isBusy,
    taskId: taskId == _unset ? this.taskId : taskId as String?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) => other is CalendarEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const _unset = Object();
