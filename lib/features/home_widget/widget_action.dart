import 'dart:convert';

/// A tap on an interactive button in the iOS home-screen widget, encoded
/// so it can cross the extension boundary (#23).
///
/// WidgetKit's App Intents buttons run in a tiny widget target that has
/// no access to the task store — the widget hands one of these to the
/// Flutter app (through the App Group or a deep link) and the app does
/// the write. Every payload names a specific task because the widget
/// shows one next reminder at a time; a payload with no target would be
/// a silent no-op.
///
/// A `kind` discriminator keeps the shape forward-compatible: a widget
/// built from a newer app version can dispatch a kind an older app does
/// not know, and [tryDecode] returns null instead of crashing the intent.
///
/// This is pure data. The dispatcher that turns a payload into a task
/// update (complete the task, start a focus session) lives in a later
/// slice alongside the native widget target.
sealed class WidgetAction {
  const WidgetAction();

  /// The task the button is acting on. Every current kind targets one.
  String get taskId;

  Map<String, Object?> toJson();

  /// Stable string form for the App Group value or a deep-link parameter.
  String encode() => jsonEncode(toJson());

  /// Null when the payload is missing, malformed, or of an unknown kind.
  /// The caller opens the home screen rather than throwing — the user's
  /// tap must not look like it did nothing when the app can't act on it.
  static WidgetAction? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return null;
      final taskId = map['taskId'];
      if (taskId is! String || taskId.isEmpty) return null;
      return switch (map['kind']) {
        'taskDone' => WidgetActionTaskDone(taskId: taskId),
        'startFocus' => WidgetActionStartFocus(taskId: taskId),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }
}

/// "Done" on the next-reminder row: mark the task done and cancel its
/// pending reminder. Matches `NotificationAction.done` from the lock
/// screen so the dispatcher can share one code path.
class WidgetActionTaskDone extends WidgetAction {
  const WidgetActionTaskDone({required this.taskId});

  @override
  final String taskId;

  @override
  Map<String, Object?> toJson() => {'kind': 'taskDone', 'taskId': taskId};

  @override
  bool operator ==(Object other) =>
      other is WidgetActionTaskDone && other.taskId == taskId;

  @override
  int get hashCode => Object.hash('taskDone', taskId);
}

/// "Start focus" on the next-reminder row: open the app and start a focus
/// session on the task. Matches `NotificationAction.startFocus`.
class WidgetActionStartFocus extends WidgetAction {
  const WidgetActionStartFocus({required this.taskId});

  @override
  final String taskId;

  @override
  Map<String, Object?> toJson() => {'kind': 'startFocus', 'taskId': taskId};

  @override
  bool operator ==(Object other) =>
      other is WidgetActionStartFocus && other.taskId == taskId;

  @override
  int get hashCode => Object.hash('startFocus', taskId);
}
