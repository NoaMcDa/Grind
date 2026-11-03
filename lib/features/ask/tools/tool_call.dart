import 'package:flutter/foundation.dart';

import '../../../core/domain/energy.dart';

/// A typed, strict description of one action the assistant proposes to
/// take on the user's behalf (#42).
///
/// Six tools map to the six user-visible actions Ask Pip can suggest:
/// [AddTaskCall], [MoveTaskCall], [SplitTaskCall], [StartFocusCall],
/// [CreateCalendarEventCall] and [ReplanCall]. A tool call is only a
/// proposal — the client previews it as a card and applies it when the
/// user confirms (see the executor slice).
///
/// The JSON shape is the Anthropic tool-use convention:
/// `{"name": "<toolName>", "arguments": {...}}`. Parse with
/// [ToolCall.fromJson]; invalid input throws [ToolCallFormatException].
@immutable
sealed class ToolCall {
  const ToolCall();

  /// Stable tool name sent to the model and used to dispatch on the
  /// client. These values are the schema — do not rename without a
  /// migration.
  String get name;

  /// The `arguments` payload. Does not include the `name` field.
  Map<String, Object?> argumentsJson();

  /// Envelope: `{"name": ..., "arguments": {...}}`.
  Map<String, Object?> toJson() => {
    'name': name,
    'arguments': argumentsJson(),
  };

  /// Parse a tool call envelope. Throws [ToolCallFormatException] on any
  /// unknown name or malformed arguments.
  static ToolCall fromJson(Object? json) {
    if (json is! Map) {
      throw const ToolCallFormatException('tool call must be a JSON object');
    }
    final j = json.cast<String, Object?>();
    final name = j['name'];
    if (name is! String || name.isEmpty) {
      throw const ToolCallFormatException('tool call is missing a name');
    }
    final rawArgs = j['arguments'] ?? const <String, Object?>{};
    if (rawArgs is! Map) {
      throw ToolCallFormatException(
        'arguments for "$name" must be a JSON object',
      );
    }
    final args = rawArgs.cast<String, Object?>();
    return switch (name) {
      AddTaskCall.toolName => AddTaskCall.fromArguments(args),
      MoveTaskCall.toolName => MoveTaskCall.fromArguments(args),
      SplitTaskCall.toolName => SplitTaskCall.fromArguments(args),
      StartFocusCall.toolName => StartFocusCall.fromArguments(args),
      CreateCalendarEventCall.toolName =>
        CreateCalendarEventCall.fromArguments(args),
      ReplanCall.toolName => ReplanCall.fromArguments(args),
      _ => throw ToolCallFormatException('unknown tool "$name"'),
    };
  }
}

/// Thrown when a tool call payload is malformed or violates the schema.
///
/// Carries just a message — the caller logs it and surfaces a "couldn't
/// use that suggestion" chip to the user.
@immutable
class ToolCallFormatException implements Exception {
  const ToolCallFormatException(this.message);
  final String message;
  @override
  String toString() => 'ToolCallFormatException: $message';
}

// ───────────────────────── helpers ─────────────────────────

/// Cap for any duration-in-minutes field. One day is more than any sane
/// focus session, event or task estimate and makes overflow/malice bugs
/// stand out at parse time.
const _maxMinutes = 24 * 60;

String _requireString(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw ToolCallFormatException('"$key" must be a non-empty string');
  }
  return v;
}

String? _optionalString(Map<String, Object?> j, String key) {
  if (!j.containsKey(key) || j[key] == null) return null;
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw ToolCallFormatException('"$key" must be a non-empty string if set');
  }
  return v;
}

int _requireInt(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! num) {
    throw ToolCallFormatException('"$key" must be a number');
  }
  if (v != v.toInt()) {
    throw ToolCallFormatException('"$key" must be an integer');
  }
  return v.toInt();
}

int? _optionalInt(Map<String, Object?> j, String key) {
  if (!j.containsKey(key) || j[key] == null) return null;
  return _requireInt(j, key);
}

int _requireMinutes(Map<String, Object?> j, String key) {
  final n = _requireInt(j, key);
  if (n <= 0 || n > _maxMinutes) {
    throw ToolCallFormatException(
      '"$key" must be between 1 and $_maxMinutes minutes',
    );
  }
  return n;
}

DateTime _requireUtcMinute(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw ToolCallFormatException('"$key" must be an ISO-8601 timestamp');
  }
  final DateTime parsed;
  try {
    parsed = DateTime.parse(v);
  } on FormatException {
    throw ToolCallFormatException('"$key" is not a valid ISO-8601 timestamp');
  }
  final utc = parsed.toUtc();
  if (utc.second != 0 || utc.millisecond != 0 || utc.microsecond != 0) {
    throw ToolCallFormatException('"$key" must be aligned to the minute');
  }
  return utc;
}

DateTime? _optionalUtcMinute(Map<String, Object?> j, String key) {
  if (!j.containsKey(key) || j[key] == null) return null;
  return _requireUtcMinute(j, key);
}

bool? _optionalBool(Map<String, Object?> j, String key) {
  if (!j.containsKey(key) || j[key] == null) return null;
  final v = j[key];
  if (v is! bool) {
    throw ToolCallFormatException('"$key" must be a boolean');
  }
  return v;
}

/// UTC ISO-8601 string with trailing `Z`, rounded to the minute.
String _isoMinute(DateTime t) {
  final u = t.toUtc();
  String p(int n, [int width = 2]) => n.toString().padLeft(width, '0');
  return '${p(u.year, 4)}-${p(u.month)}-${p(u.day)}T'
      '${p(u.hour)}:${p(u.minute)}:00Z';
}

// ───────────────────────── addTask ─────────────────────────

/// Create a new task. The executor turns these fields into a [Task]
/// after the user confirms; the assistant proposes, it does not write.
@immutable
class AddTaskCall extends ToolCall {
  AddTaskCall({
    required this.title,
    this.estimatedMinutes = 30,
    this.energy = Energy.light,
    this.priority = 2,
    this.notes,
    this.goalId,
    this.category,
    this.firstAction,
    this.dueAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.splittable,
  }) {
    if (title.isEmpty) {
      throw const ToolCallFormatException('"title" must be non-empty');
    }
    if (estimatedMinutes <= 0 || estimatedMinutes > _maxMinutes) {
      throw ToolCallFormatException(
        '"estimatedMinutes" must be between 1 and $_maxMinutes',
      );
    }
    if (priority < 1 || priority > 3) {
      throw const ToolCallFormatException(
        '"priority" must be 1 (must), 2 (should) or 3 (nice-to-have)',
      );
    }
    _ensureMinute('dueAt', dueAt);
    _ensureMinute('scheduledStart', scheduledStart);
    _ensureMinute('scheduledEnd', scheduledEnd);
    final start = scheduledStart;
    final end = scheduledEnd;
    if ((start == null) != (end == null)) {
      throw const ToolCallFormatException(
        '"scheduledStart" and "scheduledEnd" must be set together',
      );
    }
    if (start != null && end != null && !end.isAfter(start)) {
      throw const ToolCallFormatException(
        '"scheduledEnd" must be after "scheduledStart"',
      );
    }
  }

  static const toolName = 'addTask';

  final String title;
  final int estimatedMinutes;
  final Energy energy;

  /// 1 = must, 2 = should, 3 = nice-to-have. Matches [Task.priority].
  final int priority;

  final String? notes;
  final String? goalId;
  final String? category;
  final String? firstAction;

  /// Hard deadline. Must be minute-aligned UTC.
  final DateTime? dueAt;

  /// Optional placement on the timeline, set together with [scheduledEnd].
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;

  final bool? splittable;

  @override
  String get name => toolName;

  @override
  Map<String, Object?> argumentsJson() => {
    'title': title,
    'estimatedMinutes': estimatedMinutes,
    'energy': energy.name,
    'priority': priority,
    if (notes != null) 'notes': notes,
    if (goalId != null) 'goalId': goalId,
    if (category != null) 'category': category,
    if (firstAction != null) 'firstAction': firstAction,
    if (dueAt != null) 'dueAt': _isoMinute(dueAt!),
    if (scheduledStart != null) 'scheduledStart': _isoMinute(scheduledStart!),
    if (scheduledEnd != null) 'scheduledEnd': _isoMinute(scheduledEnd!),
    if (splittable != null) 'splittable': splittable,
  };

  factory AddTaskCall.fromArguments(Map<String, Object?> j) => AddTaskCall(
    title: _requireString(j, 'title'),
    estimatedMinutes: _optionalInt(j, 'estimatedMinutes') ?? 30,
    energy: _parseEnergy(j['energy']) ?? Energy.light,
    priority: _optionalInt(j, 'priority') ?? 2,
    notes: _optionalString(j, 'notes'),
    goalId: _optionalString(j, 'goalId'),
    category: _optionalString(j, 'category'),
    firstAction: _optionalString(j, 'firstAction'),
    dueAt: _optionalUtcMinute(j, 'dueAt'),
    scheduledStart: _optionalUtcMinute(j, 'scheduledStart'),
    scheduledEnd: _optionalUtcMinute(j, 'scheduledEnd'),
    splittable: _optionalBool(j, 'splittable'),
  );

  @override
  bool operator ==(Object other) =>
      other is AddTaskCall &&
      other.title == title &&
      other.estimatedMinutes == estimatedMinutes &&
      other.energy == energy &&
      other.priority == priority &&
      other.notes == notes &&
      other.goalId == goalId &&
      other.category == category &&
      other.firstAction == firstAction &&
      other.dueAt == dueAt &&
      other.scheduledStart == scheduledStart &&
      other.scheduledEnd == scheduledEnd &&
      other.splittable == splittable;

  @override
  int get hashCode => Object.hash(
    title,
    estimatedMinutes,
    energy,
    priority,
    notes,
    goalId,
    category,
    firstAction,
    dueAt,
    scheduledStart,
    scheduledEnd,
    splittable,
  );
}

// ───────────────────────── moveTask ─────────────────────────

/// Reschedule an existing task to a new time window.
@immutable
class MoveTaskCall extends ToolCall {
  MoveTaskCall({
    required this.taskId,
    required this.scheduledStart,
    required this.scheduledEnd,
  }) {
    if (taskId.isEmpty) {
      throw const ToolCallFormatException('"taskId" must be non-empty');
    }
    _ensureMinute('scheduledStart', scheduledStart);
    _ensureMinute('scheduledEnd', scheduledEnd);
    if (!scheduledEnd.isAfter(scheduledStart)) {
      throw const ToolCallFormatException(
        '"scheduledEnd" must be after "scheduledStart"',
      );
    }
  }

  static const toolName = 'moveTask';

  final String taskId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;

  @override
  String get name => toolName;

  @override
  Map<String, Object?> argumentsJson() => {
    'taskId': taskId,
    'scheduledStart': _isoMinute(scheduledStart),
    'scheduledEnd': _isoMinute(scheduledEnd),
  };

  factory MoveTaskCall.fromArguments(Map<String, Object?> j) => MoveTaskCall(
    taskId: _requireString(j, 'taskId'),
    scheduledStart: _requireUtcMinute(j, 'scheduledStart'),
    scheduledEnd: _requireUtcMinute(j, 'scheduledEnd'),
  );

  @override
  bool operator ==(Object other) =>
      other is MoveTaskCall &&
      other.taskId == taskId &&
      other.scheduledStart == scheduledStart &&
      other.scheduledEnd == scheduledEnd;

  @override
  int get hashCode => Object.hash(taskId, scheduledStart, scheduledEnd);
}

// ───────────────────────── splitTask ─────────────────────────

/// Break a task into smaller chunks. Either [chunkMinutes] (size of each
/// chunk) or [chunkCount] (how many chunks) must be set; set both to
/// pin size and count, and the executor refuses when they can't both be
/// honoured against the task's estimated minutes.
@immutable
class SplitTaskCall extends ToolCall {
  SplitTaskCall({
    required this.taskId,
    this.chunkMinutes,
    this.chunkCount,
  }) {
    if (taskId.isEmpty) {
      throw const ToolCallFormatException('"taskId" must be non-empty');
    }
    if (chunkMinutes == null && chunkCount == null) {
      throw const ToolCallFormatException(
        'splitTask needs either "chunkMinutes" or "chunkCount"',
      );
    }
    final m = chunkMinutes;
    if (m != null && (m < 5 || m > _maxMinutes)) {
      throw ToolCallFormatException(
        '"chunkMinutes" must be between 5 and $_maxMinutes',
      );
    }
    final c = chunkCount;
    if (c != null && (c < 2 || c > 24)) {
      throw const ToolCallFormatException(
        '"chunkCount" must be between 2 and 24',
      );
    }
  }

  static const toolName = 'splitTask';

  final String taskId;

  /// Target minutes per chunk. Minimum 5 matches [Task.minChunkMinutes].
  final int? chunkMinutes;

  /// How many chunks to produce.
  final int? chunkCount;

  @override
  String get name => toolName;

  @override
  Map<String, Object?> argumentsJson() => {
    'taskId': taskId,
    if (chunkMinutes != null) 'chunkMinutes': chunkMinutes,
    if (chunkCount != null) 'chunkCount': chunkCount,
  };

  factory SplitTaskCall.fromArguments(Map<String, Object?> j) => SplitTaskCall(
    taskId: _requireString(j, 'taskId'),
    chunkMinutes: _optionalInt(j, 'chunkMinutes'),
    chunkCount: _optionalInt(j, 'chunkCount'),
  );

  @override
  bool operator ==(Object other) =>
      other is SplitTaskCall &&
      other.taskId == taskId &&
      other.chunkMinutes == chunkMinutes &&
      other.chunkCount == chunkCount;

  @override
  int get hashCode => Object.hash(taskId, chunkMinutes, chunkCount);
}

// ───────────────────────── startFocus ─────────────────────────

/// Begin a focus session (#19). [taskId] is optional — a standalone
/// session with just a duration is fine.
@immutable
class StartFocusCall extends ToolCall {
  StartFocusCall({
    required this.plannedMinutes,
    this.taskId,
  }) {
    if (plannedMinutes < 1 || plannedMinutes > 240) {
      throw const ToolCallFormatException(
        '"plannedMinutes" must be between 1 and 240',
      );
    }
    final id = taskId;
    if (id != null && id.isEmpty) {
      throw const ToolCallFormatException('"taskId" must be non-empty if set');
    }
  }

  static const toolName = 'startFocus';

  final int plannedMinutes;
  final String? taskId;

  @override
  String get name => toolName;

  @override
  Map<String, Object?> argumentsJson() => {
    'plannedMinutes': plannedMinutes,
    if (taskId != null) 'taskId': taskId,
  };

  factory StartFocusCall.fromArguments(Map<String, Object?> j) =>
      StartFocusCall(
        plannedMinutes: _requireMinutes(j, 'plannedMinutes'),
        taskId: _optionalString(j, 'taskId'),
      );

  @override
  bool operator ==(Object other) =>
      other is StartFocusCall &&
      other.plannedMinutes == plannedMinutes &&
      other.taskId == taskId;

  @override
  int get hashCode => Object.hash(plannedMinutes, taskId);
}

// ───────────────────────── createCalendarEvent ─────────────────────────

/// Write a new event to an external calendar. [calendarId] picks which
/// one — the executor falls back to the user's primary when unset. A
/// linked [taskId] marks the event as a task write-back.
@immutable
class CreateCalendarEventCall extends ToolCall {
  CreateCalendarEventCall({
    required this.title,
    required this.start,
    required this.end,
    this.isBusy = true,
    this.calendarId,
    this.taskId,
    this.notes,
  }) {
    if (title.isEmpty) {
      throw const ToolCallFormatException('"title" must be non-empty');
    }
    _ensureMinute('start', start);
    _ensureMinute('end', end);
    if (!end.isAfter(start)) {
      throw const ToolCallFormatException('"end" must be after "start"');
    }
    final cid = calendarId;
    if (cid != null && cid.isEmpty) {
      throw const ToolCallFormatException(
        '"calendarId" must be non-empty if set',
      );
    }
    final tid = taskId;
    if (tid != null && tid.isEmpty) {
      throw const ToolCallFormatException('"taskId" must be non-empty if set');
    }
  }

  static const toolName = 'createCalendarEvent';

  final String title;
  final DateTime start;
  final DateTime end;

  /// False marks the event "free"/transparent — shown but not blocking.
  final bool isBusy;

  final String? calendarId;
  final String? taskId;
  final String? notes;

  @override
  String get name => toolName;

  @override
  Map<String, Object?> argumentsJson() => {
    'title': title,
    'start': _isoMinute(start),
    'end': _isoMinute(end),
    'isBusy': isBusy,
    if (calendarId != null) 'calendarId': calendarId,
    if (taskId != null) 'taskId': taskId,
    if (notes != null) 'notes': notes,
  };

  factory CreateCalendarEventCall.fromArguments(Map<String, Object?> j) =>
      CreateCalendarEventCall(
        title: _requireString(j, 'title'),
        start: _requireUtcMinute(j, 'start'),
        end: _requireUtcMinute(j, 'end'),
        isBusy: _optionalBool(j, 'isBusy') ?? true,
        calendarId: _optionalString(j, 'calendarId'),
        taskId: _optionalString(j, 'taskId'),
        notes: _optionalString(j, 'notes'),
      );

  @override
  bool operator ==(Object other) =>
      other is CreateCalendarEventCall &&
      other.title == title &&
      other.start == start &&
      other.end == end &&
      other.isBusy == isBusy &&
      other.calendarId == calendarId &&
      other.taskId == taskId &&
      other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(title, start, end, isBusy, calendarId, taskId, notes);
}

// ───────────────────────── replan ─────────────────────────

/// Ask the scheduler to re-plan a day. [date] is a local calendar day
/// (`YYYY-MM-DD`, no time component) — the scheduler already works in
/// the user's preference time zone. [from] optionally moves the "now"
/// cutoff for the plan (used by "re-plan from 14:00").
@immutable
class ReplanCall extends ToolCall {
  ReplanCall({
    required this.date,
    this.from,
  }) {
    if (!_isDateOnly(date)) {
      throw const ToolCallFormatException(
        '"date" must be YYYY-MM-DD with no time component',
      );
    }
    final f = from;
    if (f != null) {
      final u = f.toUtc();
      if (u.second != 0 || u.millisecond != 0 || u.microsecond != 0) {
        throw const ToolCallFormatException(
          '"from" must be aligned to the minute',
        );
      }
    }
  }

  static const toolName = 'replan';

  /// Local day to re-plan. Constructed through [DateTime] with
  /// year/month/day only (no time, no UTC flag).
  final DateTime date;

  /// Cutoff for the plan ("now"). Minute-aligned UTC when set.
  final DateTime? from;

  @override
  String get name => toolName;

  @override
  Map<String, Object?> argumentsJson() => {
    'date': _isoDate(date),
    if (from != null) 'from': _isoMinute(from!),
  };

  factory ReplanCall.fromArguments(Map<String, Object?> j) => ReplanCall(
    date: _parseDateOnly(j, 'date'),
    from: _optionalUtcMinute(j, 'from'),
  );

  @override
  bool operator ==(Object other) =>
      other is ReplanCall && other.date == date && other.from == from;

  @override
  int get hashCode => Object.hash(date, from);
}

// ───────────────────── private parsing helpers ─────────────────────

Energy? _parseEnergy(Object? v) {
  if (v == null) return null;
  if (v is! String) {
    throw const ToolCallFormatException('"energy" must be a string');
  }
  for (final e in Energy.values) {
    if (e.name == v) return e;
  }
  throw ToolCallFormatException(
    '"energy" must be one of ${[for (final e in Energy.values) e.name]}',
  );
}

void _ensureMinute(String key, DateTime? t) {
  if (t == null) return;
  final u = t.toUtc();
  if (u.second != 0 || u.millisecond != 0 || u.microsecond != 0) {
    throw ToolCallFormatException('"$key" must be aligned to the minute');
  }
}

bool _isDateOnly(DateTime t) =>
    !t.isUtc &&
    t.hour == 0 &&
    t.minute == 0 &&
    t.second == 0 &&
    t.millisecond == 0 &&
    t.microsecond == 0;

String _isoDate(DateTime t) {
  String p(int n, [int width = 2]) => n.toString().padLeft(width, '0');
  return '${p(t.year, 4)}-${p(t.month)}-${p(t.day)}';
}

/// Parses `"YYYY-MM-DD"` into a local [DateTime] at midnight. Rejects
/// strings with a time component or non-integer parts.
DateTime _parseDateOnly(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw ToolCallFormatException('"$key" must be a YYYY-MM-DD string');
  }
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
  if (m == null) {
    throw ToolCallFormatException('"$key" must be formatted YYYY-MM-DD');
  }
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final date = DateTime(y, mo, d);
  // Catch impossible dates like 2026-02-31 that DateTime rolls over.
  if (date.year != y || date.month != mo || date.day != d) {
    throw ToolCallFormatException('"$key" is not a real calendar date');
  }
  return date;
}
