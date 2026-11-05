import 'package:flutter/foundation.dart';

/// A typed description of how to undo one assistant-applied tool call
/// (#42).
///
/// [AssistantAction.inverseDescriptor][] is deliberately a loose
/// [Map] so the audit log does not depend on the tool-call schema. This
/// file is the matching *typed* layer for the executor: build one of
/// the six [AssistantActionReversal] subclasses when applying a tool,
/// hand its [toDescriptor] to [AssistantAction], and later read it back
/// with [AssistantActionReversal.fromDescriptor] to dispatch the undo.
///
/// Each concrete reversal maps 1:1 to a [ToolCall] subclass (see
/// `tool_call.dart`, #109):
///
/// - `addTask`             → [DeleteTaskReversal]
/// - `moveTask`            → [RestoreMoveTaskReversal]
/// - `splitTask`           → [MergeSplitTaskReversal]
/// - `startFocus`          → [CancelFocusReversal]
/// - `createCalendarEvent` → [DeleteCalendarEventReversal]
///
/// `replan` has no reversal here — undoing a plan requires a snapshot
/// of the previous schedule, which a later slice adds. Attempting to
/// parse a descriptor for it fails cleanly with
/// [AssistantActionReversalFormatException].
@immutable
sealed class AssistantActionReversal {
  const AssistantActionReversal();

  /// Stable kind tag for the descriptor's `kind` field. Matches the
  /// values the audit log already stores as strings — do not rename
  /// without a migration.
  String get kind;

  /// Serializes this reversal to the shape [AssistantAction] stores:
  /// `{"kind": "<kind>", ...}` with JSON-primitive values.
  Map<String, Object?> toDescriptor();

  /// Parses a descriptor the audit log stored. Throws
  /// [AssistantActionReversalFormatException] on any unknown kind,
  /// missing field or type mismatch.
  static AssistantActionReversal fromDescriptor(Object? json) {
    if (json is! Map) {
      throw const AssistantActionReversalFormatException(
        'reversal descriptor must be a JSON object',
      );
    }
    final j = json.cast<String, Object?>();
    final kind = j['kind'];
    if (kind is! String || kind.isEmpty) {
      throw const AssistantActionReversalFormatException(
        'reversal descriptor is missing a "kind"',
      );
    }
    return switch (kind) {
      DeleteTaskReversal.kindName => DeleteTaskReversal._fromMap(j),
      RestoreMoveTaskReversal.kindName => RestoreMoveTaskReversal._fromMap(j),
      MergeSplitTaskReversal.kindName => MergeSplitTaskReversal._fromMap(j),
      CancelFocusReversal.kindName => CancelFocusReversal._fromMap(j),
      DeleteCalendarEventReversal.kindName =>
        DeleteCalendarEventReversal._fromMap(j),
      _ => throw AssistantActionReversalFormatException(
        'unknown reversal kind "$kind"',
      ),
    };
  }
}

/// Thrown when a reversal descriptor is malformed or carries an
/// unknown kind.
@immutable
class AssistantActionReversalFormatException implements Exception {
  const AssistantActionReversalFormatException(this.message);
  final String message;
  @override
  String toString() => 'AssistantActionReversalFormatException: $message';
}

// ───────────────────────── helpers ─────────────────────────

String _requireString(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw AssistantActionReversalFormatException(
      '"$key" must be a non-empty string',
    );
  }
  return v;
}

DateTime _requireUtcMinute(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw AssistantActionReversalFormatException(
      '"$key" must be an ISO-8601 timestamp',
    );
  }
  final DateTime parsed;
  try {
    parsed = DateTime.parse(v);
  } on FormatException {
    throw AssistantActionReversalFormatException(
      '"$key" is not a valid ISO-8601 timestamp',
    );
  }
  final utc = parsed.toUtc();
  if (utc.second != 0 || utc.millisecond != 0 || utc.microsecond != 0) {
    throw AssistantActionReversalFormatException(
      '"$key" must be aligned to the minute',
    );
  }
  return utc;
}

List<String> _requireStringList(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! List) {
    throw AssistantActionReversalFormatException('"$key" must be a list');
  }
  final out = <String>[];
  for (var i = 0; i < v.length; i++) {
    final e = v[i];
    if (e is! String || e.isEmpty) {
      throw AssistantActionReversalFormatException(
        '"$key[$i]" must be a non-empty string',
      );
    }
    out.add(e);
  }
  return out;
}

void _ensureMinute(String key, DateTime t) {
  final u = t.toUtc();
  if (u.second != 0 || u.millisecond != 0 || u.microsecond != 0) {
    throw AssistantActionReversalFormatException(
      '"$key" must be aligned to the minute',
    );
  }
}

/// UTC ISO-8601 string with trailing `Z`, rounded to the minute.
/// Mirrors the formatter in `tool_call.dart` so round-tripping a
/// descriptor through the audit log yields byte-identical JSON.
String _isoMinute(DateTime t) {
  final u = t.toUtc();
  String p(int n, [int width = 2]) => n.toString().padLeft(width, '0');
  return '${p(u.year, 4)}-${p(u.month)}-${p(u.day)}T'
      '${p(u.hour)}:${p(u.minute)}:00Z';
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ───────────────────────── deleteTask (undo addTask) ─────────────────────────

/// Undoes an `addTask` by deleting the task the executor just created.
@immutable
class DeleteTaskReversal extends AssistantActionReversal {
  DeleteTaskReversal({required this.taskId}) {
    if (taskId.isEmpty) {
      throw const AssistantActionReversalFormatException(
        '"taskId" must be non-empty',
      );
    }
  }

  static const kindName = 'deleteTask';

  /// Id of the task to delete on undo.
  final String taskId;

  @override
  String get kind => kindName;

  @override
  Map<String, Object?> toDescriptor() => {'kind': kind, 'taskId': taskId};

  factory DeleteTaskReversal._fromMap(Map<String, Object?> j) =>
      DeleteTaskReversal(taskId: _requireString(j, 'taskId'));

  @override
  bool operator ==(Object other) =>
      other is DeleteTaskReversal && other.taskId == taskId;

  @override
  int get hashCode => Object.hash(kind, taskId);
}

// ─────────────────── restoreMoveTask (undo moveTask) ───────────────────

/// Undoes a `moveTask` by restoring the task's previous time window.
///
/// [previousStart] / [previousEnd] are the slot the executor
/// overwrote — the undo puts the task back in those minutes. Both are
/// minute-aligned UTC.
@immutable
class RestoreMoveTaskReversal extends AssistantActionReversal {
  RestoreMoveTaskReversal({
    required this.taskId,
    required this.previousStart,
    required this.previousEnd,
  }) {
    if (taskId.isEmpty) {
      throw const AssistantActionReversalFormatException(
        '"taskId" must be non-empty',
      );
    }
    _ensureMinute('previousStart', previousStart);
    _ensureMinute('previousEnd', previousEnd);
    if (!previousEnd.isAfter(previousStart)) {
      throw const AssistantActionReversalFormatException(
        '"previousEnd" must be after "previousStart"',
      );
    }
  }

  static const kindName = 'restoreMoveTask';

  final String taskId;
  final DateTime previousStart;
  final DateTime previousEnd;

  @override
  String get kind => kindName;

  @override
  Map<String, Object?> toDescriptor() => {
    'kind': kind,
    'taskId': taskId,
    'previousStart': _isoMinute(previousStart),
    'previousEnd': _isoMinute(previousEnd),
  };

  factory RestoreMoveTaskReversal._fromMap(Map<String, Object?> j) =>
      RestoreMoveTaskReversal(
        taskId: _requireString(j, 'taskId'),
        previousStart: _requireUtcMinute(j, 'previousStart'),
        previousEnd: _requireUtcMinute(j, 'previousEnd'),
      );

  @override
  bool operator ==(Object other) =>
      other is RestoreMoveTaskReversal &&
      other.taskId == taskId &&
      other.previousStart == previousStart &&
      other.previousEnd == previousEnd;

  @override
  int get hashCode => Object.hash(kind, taskId, previousStart, previousEnd);
}

// ─────────────────── mergeSplitTask (undo splitTask) ───────────────────

/// Undoes a `splitTask` by deleting the chunk tasks and leaving the
/// executor to restore [originalTaskId] to its pre-split state.
///
/// [chunkTaskIds] are the task ids the split produced, in the order it
/// produced them. Must hold at least two ids — a split that made one
/// chunk was not really a split.
@immutable
class MergeSplitTaskReversal extends AssistantActionReversal {
  MergeSplitTaskReversal({
    required this.originalTaskId,
    required List<String> chunkTaskIds,
  }) : chunkTaskIds = List.unmodifiable(chunkTaskIds) {
    if (originalTaskId.isEmpty) {
      throw const AssistantActionReversalFormatException(
        '"originalTaskId" must be non-empty',
      );
    }
    if (chunkTaskIds.length < 2) {
      throw const AssistantActionReversalFormatException(
        '"chunkTaskIds" must list at least two chunks',
      );
    }
    for (var i = 0; i < chunkTaskIds.length; i++) {
      if (chunkTaskIds[i].isEmpty) {
        throw AssistantActionReversalFormatException(
          '"chunkTaskIds[$i]" must be a non-empty string',
        );
      }
    }
    final seen = <String>{};
    for (final id in chunkTaskIds) {
      if (!seen.add(id)) {
        throw AssistantActionReversalFormatException(
          '"chunkTaskIds" must not repeat id "$id"',
        );
      }
    }
  }

  static const kindName = 'mergeSplitTask';

  final String originalTaskId;
  final List<String> chunkTaskIds;

  @override
  String get kind => kindName;

  @override
  Map<String, Object?> toDescriptor() => {
    'kind': kind,
    'originalTaskId': originalTaskId,
    'chunkTaskIds': List<String>.from(chunkTaskIds),
  };

  factory MergeSplitTaskReversal._fromMap(Map<String, Object?> j) =>
      MergeSplitTaskReversal(
        originalTaskId: _requireString(j, 'originalTaskId'),
        chunkTaskIds: _requireStringList(j, 'chunkTaskIds'),
      );

  @override
  bool operator ==(Object other) =>
      other is MergeSplitTaskReversal &&
      other.originalTaskId == originalTaskId &&
      _listEquals(other.chunkTaskIds, chunkTaskIds);

  @override
  int get hashCode =>
      Object.hash(kind, originalTaskId, Object.hashAll(chunkTaskIds));
}

// ─────────────────── cancelFocus (undo startFocus) ───────────────────

/// Undoes a `startFocus` by cancelling the focus session the executor
/// just started (and drops any time logged against it).
@immutable
class CancelFocusReversal extends AssistantActionReversal {
  CancelFocusReversal({required this.sessionId}) {
    if (sessionId.isEmpty) {
      throw const AssistantActionReversalFormatException(
        '"sessionId" must be non-empty',
      );
    }
  }

  static const kindName = 'cancelFocus';

  final String sessionId;

  @override
  String get kind => kindName;

  @override
  Map<String, Object?> toDescriptor() => {'kind': kind, 'sessionId': sessionId};

  factory CancelFocusReversal._fromMap(Map<String, Object?> j) =>
      CancelFocusReversal(sessionId: _requireString(j, 'sessionId'));

  @override
  bool operator ==(Object other) =>
      other is CancelFocusReversal && other.sessionId == sessionId;

  @override
  int get hashCode => Object.hash(kind, sessionId);
}

// ─────────── deleteCalendarEvent (undo createCalendarEvent) ───────────

/// Undoes a `createCalendarEvent` by deleting the event on
/// [calendarId]. Both [calendarId] and [eventId] are the ids the
/// calendar provider returned when the executor wrote the event, so
/// the undo targets the exact object that was created.
@immutable
class DeleteCalendarEventReversal extends AssistantActionReversal {
  DeleteCalendarEventReversal({
    required this.calendarId,
    required this.eventId,
  }) {
    if (calendarId.isEmpty) {
      throw const AssistantActionReversalFormatException(
        '"calendarId" must be non-empty',
      );
    }
    if (eventId.isEmpty) {
      throw const AssistantActionReversalFormatException(
        '"eventId" must be non-empty',
      );
    }
  }

  static const kindName = 'deleteCalendarEvent';

  final String calendarId;
  final String eventId;

  @override
  String get kind => kindName;

  @override
  Map<String, Object?> toDescriptor() => {
    'kind': kind,
    'calendarId': calendarId,
    'eventId': eventId,
  };

  factory DeleteCalendarEventReversal._fromMap(Map<String, Object?> j) =>
      DeleteCalendarEventReversal(
        calendarId: _requireString(j, 'calendarId'),
        eventId: _requireString(j, 'eventId'),
      );

  @override
  bool operator ==(Object other) =>
      other is DeleteCalendarEventReversal &&
      other.calendarId == calendarId &&
      other.eventId == eventId;

  @override
  int get hashCode => Object.hash(kind, calendarId, eventId);
}
