import 'dart:convert';

/// A Siri or Shortcuts App Intent (iOS) resolved to the typed payload the
/// Flutter app will execute (#23).
///
/// The native App Intents extension collects the parameters the user spoke
/// or picked in Shortcuts, serialises one of these records to JSON, and
/// hands it to the host app through the App Group (or a custom-scheme
/// deep link when the intent opens the app). The dispatcher that turns a
/// payload into a task write, a focus session, or a Plan-my-day run lives
/// alongside the native target in a later slice.
///
/// Why one sealed shape instead of three unrelated models: the three
/// intents share the same cross-process boundary and want the same
/// forward-compat story (an intent extension built from a newer app
/// version can produce a `kind` an older app does not know, and
/// [tryDecode] returns null instead of crashing the intent handler). A
/// `switch` on the sealed type is checked at compile time, so adding an
/// intent later also surfaces every dispatcher that must handle it.
///
/// Pure data. No plugin, no I/O; it round-trips through `jsonDecode`.
sealed class AppIntentPayload {
  const AppIntentPayload();

  /// The stable discriminator the encoded form carries.
  String get kind;

  Map<String, Object?> toJson();

  /// Stable string form for the App Group value or a deep-link parameter.
  /// Same bytes in, same bytes out: a dispatcher that saw this payload on
  /// the previous run can detect a replay.
  String encode() => jsonEncode(toJson());

  /// Null when the payload is missing, malformed, or of an unknown kind.
  /// The caller opens the home screen (or runs the fallback action)
  /// rather than throwing — the user's Siri phrase must not look like it
  /// did nothing when the app can't act on it.
  static AppIntentPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return null;
      return switch (map['kind']) {
        'addTask' => AppIntentAddTask._tryDecode(map),
        'startFocus' => AppIntentStartFocus._tryDecode(map),
        'planMyDay' => const AppIntentPlanMyDay(),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }
}

/// "Add task <title>" from Siri / Shortcuts. [title] is required and
/// trimmed; a blank title fails [tryDecode] because the dispatcher would
/// otherwise create a nameless row.
///
/// [notes] and [dueAt] are optional: Shortcuts can prompt for either
/// (e.g. "Add task with due date"), and the Siri phrase without a due
/// date leaves it null for the dispatcher to pick a default placement.
class AppIntentAddTask extends AppIntentPayload {
  AppIntentAddTask({required String title, this.notes, this.dueAt})
    : title = title.trim();

  final String title;
  final String? notes;

  /// UTC, matching the rest of the app's `DateTime` fields. The encoder
  /// writes an ISO-8601 UTC timestamp; the decoder tolerates any form
  /// `DateTime.parse` accepts and converts to UTC.
  final DateTime? dueAt;

  @override
  String get kind => 'addTask';

  @override
  Map<String, Object?> toJson() => {
    'kind': kind,
    'title': title,
    if (notes != null) 'notes': notes,
    if (dueAt != null) 'dueAt': dueAt!.toUtc().toIso8601String(),
  };

  static AppIntentAddTask? _tryDecode(Map<String, Object?> map) {
    final rawTitle = map['title'];
    if (rawTitle is! String) return null;
    final title = rawTitle.trim();
    if (title.isEmpty) return null;
    final notes = map['notes'];
    if (notes != null && notes is! String) return null;
    final rawDueAt = map['dueAt'];
    DateTime? dueAt;
    if (rawDueAt != null) {
      if (rawDueAt is! String) return null;
      final parsed = DateTime.tryParse(rawDueAt);
      if (parsed == null) return null;
      dueAt = parsed.toUtc();
    }
    return AppIntentAddTask(
      title: title,
      notes: notes as String?,
      dueAt: dueAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppIntentAddTask &&
      other.title == title &&
      other.notes == notes &&
      other.dueAt == dueAt;

  @override
  int get hashCode => Object.hash('addTask', title, notes, dueAt);
}

/// "Start focus [on <task>]" from Siri / Shortcuts. [taskId] is optional:
/// a bare "Start focus" starts a free focus session on nothing in
/// particular, while "Start focus on <task>" passes the picked id so the
/// dispatcher can attribute the minutes.
class AppIntentStartFocus extends AppIntentPayload {
  const AppIntentStartFocus({this.taskId});

  final String? taskId;

  @override
  String get kind => 'startFocus';

  @override
  Map<String, Object?> toJson() => {
    'kind': kind,
    if (taskId != null) 'taskId': taskId,
  };

  static AppIntentStartFocus? _tryDecode(Map<String, Object?> map) {
    final rawTaskId = map['taskId'];
    if (rawTaskId == null) return const AppIntentStartFocus();
    if (rawTaskId is! String || rawTaskId.isEmpty) return null;
    return AppIntentStartFocus(taskId: rawTaskId);
  }

  @override
  bool operator ==(Object other) =>
      other is AppIntentStartFocus && other.taskId == taskId;

  @override
  int get hashCode => Object.hash('startFocus', taskId);
}

/// "Plan my day" from Siri / Shortcuts. No parameters: the dispatcher
/// runs the same Plan-my-day flow the morning card uses.
class AppIntentPlanMyDay extends AppIntentPayload {
  const AppIntentPlanMyDay();

  @override
  String get kind => 'planMyDay';

  @override
  Map<String, Object?> toJson() => {'kind': kind};

  @override
  bool operator ==(Object other) => other is AppIntentPlanMyDay;

  @override
  int get hashCode => 'planMyDay'.hashCode;
}
