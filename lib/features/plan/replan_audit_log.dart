import 'package:flutter/foundation.dart';

import 'scheduler/scheduler.dart';

/// In-memory ring buffer of [ReplanAuditEntry]s, newest first. Fires
/// listeners on every [append] and [clear] so a "recent re-plans" row
/// in the UI can rebuild.
///
/// Mirrors `AssistantActionLog` (#42) so the two audit surfaces behave
/// the same way for the user: newest on top, a fixed cap, dedup by id.
/// Lives outside the pure scheduler core (which is storage- and
/// Flutter-free, see `scheduler/README.md`) so composing
/// `ReplanAuditEntry` (#178) into a mutable log does not drag
/// [ChangeNotifier] through that boundary.
///
/// Deliberately storage-agnostic — no Drift, no SharedPreferences.
/// This slice is the data model; a later sibling wires persistence if
/// the log needs to survive restarts. The epic (#18) only asks that
/// each re-plan show a reason; a short recent-history row is a
/// natural next step that this buffer already feeds.
class ReplanAuditLog extends ChangeNotifier {
  /// [capacity] is the maximum number of entries kept at once;
  /// appending past it drops the oldest entry.
  ReplanAuditLog({this.capacity = 20})
    : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of entries. Older entries are discarded on
  /// [append] once the log exceeds this count.
  final int capacity;

  final List<ReplanAuditEntry> _entries = <ReplanAuditEntry>[];

  /// All entries in the log, newest first. The returned list is an
  /// unmodifiable snapshot — mutate the log through its methods.
  List<ReplanAuditEntry> get entries => List.unmodifiable(_entries);

  /// Current number of entries, 0 through [capacity].
  int get length => _entries.length;

  /// True when the log holds no entries.
  bool get isEmpty => _entries.isEmpty;

  /// True when the log has at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// The most recent entry, or `null` when the log is empty.
  ReplanAuditEntry? get latest => _entries.isEmpty ? null : _entries.first;

  /// Appends [entry] to the front of the log. Throws [ArgumentError]
  /// when an entry with the same id already exists — ids are the
  /// handle a future "show the diff for this re-plan" link uses and
  /// must stay unique.
  ///
  /// When the log exceeds [capacity] the oldest entry is dropped.
  /// Listeners fire once per append.
  void append(ReplanAuditEntry entry) {
    if (_entries.any((e) => e.id == entry.id)) {
      throw ArgumentError.value(
        entry.id,
        'entry.id',
        'an entry with this id is already in the log',
      );
    }
    _entries.insert(0, entry);
    if (_entries.length > capacity) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  /// Returns the entry with [id], or `null` when it is not in the
  /// log (either never appended or dropped past [capacity]).
  ReplanAuditEntry? byId(String id) {
    if (id.isEmpty) return null;
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Removes every entry. Listeners fire only when the log was not
  /// already empty, so clearing an empty log is cheap.
  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}
