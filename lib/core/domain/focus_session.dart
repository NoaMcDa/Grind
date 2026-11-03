/// What a stored session timed. (`break` is a reserved word in Dart.)
enum FocusSessionKind { focus, breakTime }

/// One timed focus session (#19) or break. A session is active while
/// [endedAt] is null.
class FocusSession {
  const FocusSession({
    required this.id,
    this.taskId,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    this.completed = false,
    this.pausedMs = 0,
    this.pausedAt,
    this.win,
    this.kind = FocusSessionKind.focus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? taskId;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool completed;

  /// Sum of the finished pauses, in milliseconds, so a restored session
  /// does not count paused time as focused.
  final int pausedMs;

  /// Start of the current pause; null while running or after the end.
  final DateTime? pausedAt;

  /// The user's one-line note on what got done ("drafted section 2").
  final String? win;
  final FocusSessionKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Duration get paused => Duration(milliseconds: pausedMs);
  bool get isPaused => pausedAt != null && endedAt == null;

  /// Wall-clock minutes from start to end, pauses included.
  int? get actualMinutes => endedAt?.difference(startedAt).inMinutes;

  FocusSession copyWith({
    Object? taskId = _unset,
    int? plannedMinutes,
    DateTime? startedAt,
    Object? endedAt = _unset,
    bool? completed,
    int? pausedMs,
    Object? pausedAt = _unset,
    Object? win = _unset,
    FocusSessionKind? kind,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => FocusSession(
    id: id,
    taskId: taskId == _unset ? this.taskId : taskId as String?,
    plannedMinutes: plannedMinutes ?? this.plannedMinutes,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt == _unset ? this.endedAt : endedAt as DateTime?,
    completed: completed ?? this.completed,
    pausedMs: pausedMs ?? this.pausedMs,
    pausedAt: pausedAt == _unset ? this.pausedAt : pausedAt as DateTime?,
    win: win == _unset ? this.win : win as String?,
    kind: kind ?? this.kind,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
  );

  @override
  String toString() => 'FocusSession($id, ${kind.name}, $startedAt)';
}

const _unset = Object();
