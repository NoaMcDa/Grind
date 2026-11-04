import 'dart:convert';

import 'replan_trigger.dart';

/// One past "Re-plan with Pip" event, recorded so the user can see the
/// history of re-plans the app applied on their day (epic #18).
///
/// Immutable value object: the trigger that prompted the re-plan, the
/// one-line summary Pip showed ("the seminar ran over"), when the re-plan
/// was applied, and shallow counts of how the plan changed. It intentionally
/// does not carry the full [PlanDiff]: a later surface may want to reach
/// through [id] for the deep view, but the audit row shows at most "moved 3,
/// dropped 1, added 1" and the trigger's own sentence.
///
/// Pure data. Equality is value-based so two equal entries encode to the
/// same JSON and hash the same. A sibling slice adds the in-memory ring
/// buffer that holds these, mirroring `assistant_action_log.dart` (#42).
class ReplanAuditEntry {
  ReplanAuditEntry({
    required this.id,
    required this.appliedAt,
    required this.reason,
    required this.summary,
    this.moveCount = 0,
    this.addCount = 0,
    this.removeCount = 0,
    this.taskId,
    this.eventId,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must be non-empty');
    }
    if (!appliedAt.isUtc) {
      throw ArgumentError.value(appliedAt, 'appliedAt', 'must be UTC');
    }
    if (moveCount < 0) {
      throw ArgumentError.value(moveCount, 'moveCount', 'must be >= 0');
    }
    if (addCount < 0) {
      throw ArgumentError.value(addCount, 'addCount', 'must be >= 0');
    }
    if (removeCount < 0) {
      throw ArgumentError.value(removeCount, 'removeCount', 'must be >= 0');
    }
    if (reason == ReplanReason.none && summary.isNotEmpty) {
      throw ArgumentError.value(
        summary,
        'summary',
        'must be empty when reason is ReplanReason.none',
      );
    }
    if (taskId != null && taskId!.isEmpty) {
      throw ArgumentError.value(taskId, 'taskId', 'must be null or non-empty');
    }
    if (eventId != null && eventId!.isEmpty) {
      throw ArgumentError.value(
        eventId,
        'eventId',
        'must be null or non-empty',
      );
    }
  }

  /// Stable identifier (a UUID or similar). The row the UI renders, and the
  /// handle a future "show the diff for this re-plan" link would use.
  final String id;

  /// When the re-plan was applied. UTC — the audit is a technical record,
  /// not a user-facing "activity feed": local-time rendering is the UI's job.
  final DateTime appliedAt;

  /// Why the re-plan was offered, from `replan_trigger.dart`. A manual tap
  /// on the "Re-plan with Pip" button is recorded with [ReplanReason.none]
  /// and an empty [summary]: no automated trigger fired, the user asked.
  final ReplanReason reason;

  /// The sentence Pip showed above the diff ("the seminar ran over"). Empty
  /// for a manual re-plan; never empty for an automated one.
  final String summary;

  /// How many unlocked placements the new plan moved from where they were
  /// in the previous plan.
  final int moveCount;

  /// How many tasks the new plan placed that the previous one did not.
  final int addCount;

  /// How many tasks the previous plan had placed that the new one dropped
  /// (done, skipped, deleted, or no longer fits).
  final int removeCount;

  /// The task the trigger pointed at, when [reason] is a task-shaped one
  /// ([ReplanReason.taskSkipped], [ReplanReason.taskDoneLate],
  /// [ReplanReason.taskOverrun]). Null otherwise.
  final String? taskId;

  /// The event the trigger pointed at, when [reason] is an event-shaped
  /// one ([ReplanReason.calendarEventAdded],
  /// [ReplanReason.calendarEventMoved]). Null otherwise.
  final String? eventId;

  /// True when the plan actually changed — there is something to show in
  /// the audit row. A re-plan that produced no moves, adds, or removals is
  /// still worth logging (the user asked, Pip looked, nothing budged), so
  /// this is a UI hint, not a validation rule.
  bool get isEmpty => moveCount == 0 && addCount == 0 && removeCount == 0;

  /// Returns a copy with the fields passed overridden. Unset fields keep
  /// their current values; passing `null` for a non-nullable field is a
  /// no-op.
  ReplanAuditEntry copyWith({
    String? id,
    DateTime? appliedAt,
    ReplanReason? reason,
    String? summary,
    int? moveCount,
    int? addCount,
    int? removeCount,
    String? taskId,
    String? eventId,
  }) {
    return ReplanAuditEntry(
      id: id ?? this.id,
      appliedAt: appliedAt ?? this.appliedAt,
      reason: reason ?? this.reason,
      summary: summary ?? this.summary,
      moveCount: moveCount ?? this.moveCount,
      addCount: addCount ?? this.addCount,
      removeCount: removeCount ?? this.removeCount,
      taskId: taskId ?? this.taskId,
      eventId: eventId ?? this.eventId,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'appliedAt': appliedAt.toUtc().toIso8601String(),
    'reason': reason.name,
    'summary': summary,
    'moveCount': moveCount,
    'addCount': addCount,
    'removeCount': removeCount,
    if (taskId != null) 'taskId': taskId,
    if (eventId != null) 'eventId': eventId,
  };

  /// Stable JSON for persistence. Two equal entries encode to the same
  /// bytes so a consumer can dedupe by string match.
  String encode() => jsonEncode(toJson());

  /// Returns null when [raw] is missing, unreadable, or does not carry
  /// every required field. A later persisted-log slice decodes the stored
  /// rows with this and silently drops malformed ones.
  static ReplanAuditEntry? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return null;
      return fromJson(map);
    } on FormatException {
      return null;
    }
  }

  /// Rebuilds an entry from a decoded JSON map. Returns null when any
  /// required field is missing or of the wrong type. Unknown reasons fall
  /// back to [ReplanReason.none] with the summary cleared, so an entry
  /// written by a newer build still decodes to a valid row.
  static ReplanAuditEntry? fromJson(Map<String, Object?> map) {
    final id = map['id'];
    final appliedAtRaw = map['appliedAt'];
    final reasonRaw = map['reason'];
    final summary = map['summary'];
    if (id is! String || id.isEmpty) return null;
    if (appliedAtRaw is! String) return null;
    final appliedAt = DateTime.tryParse(appliedAtRaw);
    if (appliedAt == null) return null;
    if (summary is! String) return null;
    final reason = _reasonFromName(reasonRaw);
    final effectiveSummary = reason == ReplanReason.none && summary.isNotEmpty
        ? ''
        : summary;
    final moveCount = _asNonNegativeInt(map['moveCount']);
    final addCount = _asNonNegativeInt(map['addCount']);
    final removeCount = _asNonNegativeInt(map['removeCount']);
    if (moveCount == null || addCount == null || removeCount == null) {
      return null;
    }
    final taskId = map['taskId'];
    final eventId = map['eventId'];
    return ReplanAuditEntry(
      id: id,
      appliedAt: appliedAt.toUtc(),
      reason: reason,
      summary: effectiveSummary,
      moveCount: moveCount,
      addCount: addCount,
      removeCount: removeCount,
      taskId: taskId is String && taskId.isNotEmpty ? taskId : null,
      eventId: eventId is String && eventId.isNotEmpty ? eventId : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReplanAuditEntry &&
      other.id == id &&
      other.appliedAt == appliedAt &&
      other.reason == reason &&
      other.summary == summary &&
      other.moveCount == moveCount &&
      other.addCount == addCount &&
      other.removeCount == removeCount &&
      other.taskId == taskId &&
      other.eventId == eventId;

  @override
  int get hashCode => Object.hash(
    id,
    appliedAt,
    reason,
    summary,
    moveCount,
    addCount,
    removeCount,
    taskId,
    eventId,
  );

  @override
  String toString() =>
      'ReplanAuditEntry(id: $id, reason: ${reason.name}, '
      'moved: $moveCount, added: $addCount, removed: $removeCount)';
}

ReplanReason _reasonFromName(Object? raw) {
  if (raw is! String) return ReplanReason.none;
  for (final value in ReplanReason.values) {
    if (value.name == raw) return value;
  }
  return ReplanReason.none;
}

int? _asNonNegativeInt(Object? raw) {
  if (raw == null) return 0;
  if (raw is int) return raw < 0 ? null : raw;
  if (raw is num) {
    final i = raw.toInt();
    return i < 0 ? null : i;
  }
  return null;
}
