import 'package:flutter/foundation.dart';

/// Lifecycle state of an entry in the [AssistantActionLog].
///
/// An action is [applied] at the moment the executor commits a tool
/// call the user confirmed, and flips to [undone] when the user hits
/// undo on it. A new entry is never created for the undo itself —
/// the status just changes in place so the ring buffer still holds
/// one row per user-visible change.
enum AssistantActionStatus { applied, undone }

/// One entry in the assistant's audit log of client-side tool calls
/// (#42).
///
/// Every tool call the user confirms through Ask Pip is appended as
/// an [AssistantAction]. The [inverseDescriptor] is structured data
/// that *describes* how to undo the change (e.g. `{"kind": "deleteTask",
/// "taskId": "t-1"}`) — it is not the executor itself. A sibling
/// slice looks up the descriptor's `kind` and runs the matching undo
/// against the real repositories.
///
/// Instances are immutable; mutate the log by appending or by calling
/// [AssistantActionLog.markUndone], never the entry in place.
@immutable
class AssistantAction {
  AssistantAction({
    required this.id,
    required this.timestamp,
    required this.toolName,
    required this.inverseDescriptor,
    required this.humanLabel,
    this.status = AssistantActionStatus.applied,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must be non-empty');
    }
    if (toolName.isEmpty) {
      throw ArgumentError.value(toolName, 'toolName', 'must be non-empty');
    }
    if (humanLabel.isEmpty) {
      throw ArgumentError.value(humanLabel, 'humanLabel', 'must be non-empty');
    }
    if (!timestamp.isUtc) {
      throw ArgumentError.value(timestamp, 'timestamp', 'must be UTC');
    }
    _validateInverseDescriptor(inverseDescriptor);
  }

  /// Stable identifier (a UUID or similar). Used to look the entry up
  /// again from the undo button.
  final String id;

  /// When the executor applied the tool call. Must be UTC — the log
  /// is a technical audit record, not a localized "activity feed".
  final DateTime timestamp;

  /// Which tool produced this entry, as its [ToolCall.name] (see #109).
  /// Kept as a plain [String] so the log does not depend on the typed
  /// schema module.
  final String toolName;

  /// A serializable description of how to undo this action. The
  /// executor dispatches on its `kind` field at undo time. Validated
  /// in [AssistantAction] construction:
  ///
  /// - must contain a non-empty `kind` [String];
  /// - every value must be a JSON-primitive (null, bool, num, String,
  ///   list or map of the same) so it can be persisted later without
  ///   surprises.
  final Map<String, Object?> inverseDescriptor;

  /// Short, already-localized sentence the UI shows for the row
  /// (e.g. "Scheduled Gym · 09:00–09:25"). Keep it to a line.
  final String humanLabel;

  /// Whether the change is still in effect or has been undone.
  final AssistantActionStatus status;

  /// Returns a copy with the fields passed overridden. Unset fields
  /// keep their current values; passing `null` for a non-nullable
  /// field is a no-op.
  AssistantAction copyWith({
    String? id,
    DateTime? timestamp,
    String? toolName,
    Map<String, Object?>? inverseDescriptor,
    String? humanLabel,
    AssistantActionStatus? status,
  }) {
    return AssistantAction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      toolName: toolName ?? this.toolName,
      inverseDescriptor: inverseDescriptor ?? this.inverseDescriptor,
      humanLabel: humanLabel ?? this.humanLabel,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AssistantAction &&
      other.id == id &&
      other.timestamp == timestamp &&
      other.toolName == toolName &&
      other.humanLabel == humanLabel &&
      other.status == status &&
      _mapEquals(other.inverseDescriptor, inverseDescriptor);

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    toolName,
    humanLabel,
    status,
    _mapHash(inverseDescriptor),
  );

  @override
  String toString() =>
      'AssistantAction(id: $id, tool: $toolName, status: ${status.name})';

  /// Serializes this entry as a JSON-shaped map so a later persistence
  /// layer can round-trip the audit log without knowing its internals.
  ///
  /// Shape: `{"id", "timestamp", "toolName", "inverseDescriptor",
  /// "humanLabel", "status"}` where `timestamp` is an ISO-8601 UTC
  /// string (trailing `Z`) and `status` is the enum's
  /// [AssistantActionStatus.name]. The [inverseDescriptor] is copied
  /// through as-is — it was already validated as JSON-serializable at
  /// construction time.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'timestamp': _formatIsoUtc(timestamp),
    'toolName': toolName,
    'inverseDescriptor': inverseDescriptor,
    'humanLabel': humanLabel,
    'status': status.name,
  };

  /// Parses a JSON-shaped map produced by [toJson] back into an
  /// [AssistantAction]. Throws [AssistantActionFormatException] on any
  /// missing field, wrong type or value that fails the same checks
  /// the constructor enforces (empty strings, non-UTC timestamp,
  /// descriptor without a non-empty `kind`, non-JSON values).
  ///
  /// Unknown top-level fields are ignored so a newer writer can add
  /// optional metadata without breaking older readers.
  static AssistantAction fromJson(Object? json) {
    if (json is! Map) {
      throw const AssistantActionFormatException(
        'AssistantAction JSON must be an object',
      );
    }
    final j = json.cast<String, Object?>();
    try {
      return AssistantAction(
        id: _requireNonEmptyString(j, 'id'),
        timestamp: _requireUtcIso(j, 'timestamp'),
        toolName: _requireNonEmptyString(j, 'toolName'),
        inverseDescriptor: _requireDescriptor(j, 'inverseDescriptor'),
        humanLabel: _requireNonEmptyString(j, 'humanLabel'),
        status: _parseStatus(j['status']),
      );
    } on ArgumentError catch (e) {
      // Constructor invariants fire after the per-field parse succeeds
      // (e.g. an inverseDescriptor whose `kind` is the empty string).
      // Re-wrap as the typed exception so callers only have to catch
      // one thing.
      throw AssistantActionFormatException(
        e.message?.toString() ?? 'invalid AssistantAction payload',
      );
    }
  }
}

/// Thrown by [AssistantAction.fromJson] when the payload is malformed
/// — missing a required field, carrying the wrong type, or violating
/// the same invariants the constructor enforces.
///
/// Carries just a message; the caller logs it and either drops the
/// row or surfaces a one-line "couldn't restore an action" chip.
@immutable
class AssistantActionFormatException implements Exception {
  const AssistantActionFormatException(this.message);
  final String message;
  @override
  String toString() => 'AssistantActionFormatException: $message';
}

/// In-memory ring buffer of [AssistantAction]s, newest first. Fires
/// listeners on every [append], [markUndone] and [clear] so the UI
/// row (and the undo button) can rebuild.
///
/// Deliberately storage-agnostic — no Drift, no SharedPreferences.
/// This slice is the data model; a later sibling wires persistence
/// if the audit log needs to survive restarts.
class AssistantActionLog extends ChangeNotifier {
  /// [capacity] is the maximum number of entries kept at once;
  /// appending past it drops the oldest entry.
  AssistantActionLog({this.capacity = 20})
    : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of entries. Older entries are discarded on
  /// [append] once the log exceeds this count.
  final int capacity;

  final List<AssistantAction> _entries = <AssistantAction>[];

  /// All entries in the log, newest first. The returned list is an
  /// unmodifiable snapshot — mutate the log through its methods.
  List<AssistantAction> get entries => List.unmodifiable(_entries);

  /// Current number of entries, 0 through [capacity].
  int get length => _entries.length;

  /// True when the log holds no entries.
  bool get isEmpty => _entries.isEmpty;

  /// True when the log has at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Appends [action] to the front of the log. Throws [ArgumentError]
  /// when an entry with the same id already exists — ids are the
  /// handle the undo button uses and must stay unique.
  ///
  /// When the log exceeds [capacity] the oldest entry is dropped.
  /// Listeners fire once per append.
  void append(AssistantAction action) {
    if (_entries.any((a) => a.id == action.id)) {
      throw ArgumentError.value(
        action.id,
        'action.id',
        'an entry with this id is already in the log',
      );
    }
    _entries.insert(0, action);
    if (_entries.length > capacity) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  /// Flips the entry with [id] to [AssistantActionStatus.undone].
  ///
  /// Returns `true` when an entry was changed, `false` when the id
  /// is not present or already undone. Listeners fire only when the
  /// state actually changes, so an idempotent undo is cheap.
  bool markUndone(String id) {
    if (id.isEmpty) return false;
    final idx = _entries.indexWhere((a) => a.id == id);
    if (idx < 0) return false;
    final current = _entries[idx];
    if (current.status == AssistantActionStatus.undone) return false;
    _entries[idx] = current.copyWith(status: AssistantActionStatus.undone);
    notifyListeners();
    return true;
  }

  /// Returns the entry with [id], or `null` when it is not in the
  /// log (either never appended or dropped past [capacity]).
  AssistantAction? byId(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Removes every entry. Listeners fire only when the log was not
  /// already empty.
  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}

// ───────────────────────── serialization helpers ─────────────────────────

/// ISO-8601 UTC string with a trailing `Z`, preserving seconds and
/// milliseconds so a timestamp round-trips without loss.
String _formatIsoUtc(DateTime t) => t.toUtc().toIso8601String();

String _requireNonEmptyString(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw AssistantActionFormatException('"$key" must be a non-empty string');
  }
  return v;
}

DateTime _requireUtcIso(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.isEmpty) {
    throw AssistantActionFormatException(
      '"$key" must be an ISO-8601 timestamp string',
    );
  }
  final DateTime parsed;
  try {
    parsed = DateTime.parse(v);
  } on FormatException {
    throw AssistantActionFormatException(
      '"$key" is not a valid ISO-8601 timestamp',
    );
  }
  if (!parsed.isUtc) {
    throw AssistantActionFormatException(
      '"$key" must be a UTC timestamp (trailing "Z" or explicit "+00:00")',
    );
  }
  return parsed;
}

Map<String, Object?> _requireDescriptor(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! Map) {
    throw AssistantActionFormatException('"$key" must be a JSON object');
  }
  // Rebuild as Map<String, Object?> so the constructor's downstream
  // validation sees the exact declared type (not Map<dynamic, dynamic>).
  final out = <String, Object?>{};
  for (final entry in v.entries) {
    final k = entry.key;
    if (k is! String) {
      throw AssistantActionFormatException('"$key" map keys must be strings');
    }
    out[k] = entry.value;
  }
  return out;
}

AssistantActionStatus _parseStatus(Object? v) {
  if (v == null) return AssistantActionStatus.applied;
  if (v is! String || v.isEmpty) {
    throw const AssistantActionFormatException(
      '"status" must be "applied" or "undone" when set',
    );
  }
  for (final s in AssistantActionStatus.values) {
    if (s.name == v) return s;
  }
  throw AssistantActionFormatException(
    '"status" must be one of ${[for (final s in AssistantActionStatus.values) s.name]}',
  );
}

// ───────────────────────── validation helpers ─────────────────────────

/// Validates a candidate inverse descriptor: must carry a non-empty
/// `kind` string and must be JSON-serializable. Throws
/// [ArgumentError] on any violation so construction fails fast at
/// the site of the bug.
void _validateInverseDescriptor(Map<String, Object?> descriptor) {
  final kind = descriptor['kind'];
  if (kind is! String || kind.isEmpty) {
    throw ArgumentError.value(
      descriptor,
      'inverseDescriptor',
      'must carry a non-empty "kind" string',
    );
  }
  _requireJsonValue(descriptor, 'inverseDescriptor');
}

/// Walks [value] and throws [ArgumentError] when any node is not one
/// of null, bool, num, String, [List] of the same, or
/// `Map<String, Object?>` of the same. The [path] is used in the
/// error message so a nested violation points to its key.
void _requireJsonValue(Object? value, String path) {
  if (value == null || value is bool || value is num || value is String) {
    return;
  }
  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      _requireJsonValue(value[i], '$path[$i]');
    }
    return;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ArgumentError.value(
          key,
          path,
          'map keys must be strings in a JSON-serializable descriptor',
        );
      }
      _requireJsonValue(entry.value, '$path.$key');
    }
    return;
  }
  throw ArgumentError.value(
    value,
    path,
    'descriptor values must be JSON-serializable '
    '(null, bool, num, String, List, or Map<String, Object?>)',
  );
}

// ───────────────────────── equality helpers ─────────────────────────

bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    if (!_deepEquals(entry.value, b[entry.key])) return false;
  }
  return true;
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (!_deepEquals(entry.value, b[entry.key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

int _mapHash(Map<String, Object?> m) {
  // Entry order is not meaningful; XOR per-entry hashes to stay
  // order-independent and cheap.
  var h = 0;
  for (final entry in m.entries) {
    h ^= Object.hash(entry.key, _valueHash(entry.value));
  }
  return h;
}

int _valueHash(Object? v) {
  if (v is Map) {
    var h = 0;
    for (final e in v.entries) {
      h ^= Object.hash(e.key, _valueHash(e.value));
    }
    return h;
  }
  if (v is List) {
    return Object.hashAll(v.map(_valueHash));
  }
  return v.hashCode;
}
