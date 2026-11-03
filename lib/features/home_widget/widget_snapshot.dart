import 'dart:convert';

/// The payload the iOS home-screen widget reads through the App Group
/// (#23). Pure data: the iOS extension and App Intents call this app's
/// snapshot writer; the writer encodes it to one JSON string the widget's
/// `TimelineProvider` decodes on each refresh.
///
/// Why one bundle: WidgetKit only reads the App Group once per timeline
/// refresh and reading several keys multiplies that cost. The small and
/// medium widgets both need "next reminder" and "momentum", so one record
/// is cheaper than two.
///
/// The schema is versioned so a widget built from an older app version
/// (users update the app and the widget separately) can refuse to render
/// unknown shapes instead of guessing.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.writtenAt,
    this.nextReminder,
    required this.momentum,
    this.schema = schemaVersion,
  });

  /// Bumped with every breaking change. Readers that see a higher number
  /// show "Open Grind" instead of a stale "up next".
  static const schemaVersion = 1;

  /// When the writer saved this snapshot (UTC). The widget shows "a few
  /// minutes ago" from it and can treat an old snapshot as missing.
  final DateTime writtenAt;

  /// The soonest task reminder in the plan, or null when the plan has none
  /// (no open tasks with a due time, or only prompts and the weekly recap).
  final WidgetReminder? nextReminder;

  /// The momentum meter at write time.
  final WidgetMomentum momentum;

  final int schema;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'writtenAt': writtenAt.toUtc().toIso8601String(),
    if (nextReminder != null) 'nextReminder': nextReminder!.toJson(),
    'momentum': momentum.toJson(),
  };

  /// JSON ready for `home_widget.saveWidgetData` (iOS slice). Stable string
  /// form: a widget that saw the same bytes last run can skip reloading.
  String encode() => jsonEncode(toJson());

  /// Returns null when the payload is missing, unreadable, or written by a
  /// newer app. The widget shows a fallback instead of throwing.
  static WidgetSnapshot? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return null;
      final schema = map['schema'];
      if (schema is! int || schema > schemaVersion) return null;
      final writtenAt = DateTime.tryParse(map['writtenAt'] as String? ?? '');
      if (writtenAt == null) return null;
      final reminder = WidgetReminder._tryDecode(map['nextReminder']);
      final momentum = WidgetMomentum._tryDecode(map['momentum']);
      if (momentum == null) return null;
      return WidgetSnapshot(
        writtenAt: writtenAt.toUtc(),
        nextReminder: reminder,
        momentum: momentum,
        schema: schema,
      );
    } on FormatException {
      return null;
    }
  }
}

/// One task reminder, trimmed to what the small and medium widgets show.
///
/// [taskId] is what the Done and Start-focus App Intents hand back to the
/// app, so the task can be completed or a focus session started by id — the
/// widget never writes to the store itself.
class WidgetReminder {
  const WidgetReminder({
    required this.taskId,
    required this.notificationId,
    required this.fireAt,
    required this.title,
    required this.body,
    this.canComplete = true,
    this.canStartFocus = true,
  });

  final String taskId;

  /// Matches the id the notification scheduler uses, so a tap on the
  /// widget's Done button can cancel the pending notification too.
  final String notificationId;

  /// When the reminder fires (UTC).
  final DateTime fireAt;
  final String title;

  /// If-then line (or the smart-snooze offer after two snoozes, #12).
  final String body;

  /// Both default to true; a smart-snooze reminder drops them because its
  /// actions are "Tonight / Tomorrow" instead.
  final bool canComplete;
  final bool canStartFocus;

  Map<String, Object?> toJson() => {
    'taskId': taskId,
    'notificationId': notificationId,
    'fireAt': fireAt.toUtc().toIso8601String(),
    'title': title,
    'body': body,
    'canComplete': canComplete,
    'canStartFocus': canStartFocus,
  };

  static WidgetReminder? _tryDecode(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final taskId = raw['taskId'];
    final notificationId = raw['notificationId'];
    final title = raw['title'];
    final body = raw['body'];
    final fireAt = DateTime.tryParse(raw['fireAt'] as String? ?? '');
    if (taskId is! String ||
        notificationId is! String ||
        title is! String ||
        body is! String ||
        fireAt == null) {
      return null;
    }
    return WidgetReminder(
      taskId: taskId,
      notificationId: notificationId,
      fireAt: fireAt.toUtc(),
      title: title,
      body: body,
      canComplete: raw['canComplete'] as bool? ?? true,
      canStartFocus: raw['canStartFocus'] as bool? ?? true,
    );
  }
}

/// Momentum, trimmed to what the meter needs: a 0..100 value, the three-
/// band level name, and the 7-day activity strip the medium widget draws.
class WidgetMomentum {
  const WidgetMomentum({
    required this.value,
    required this.level,
    required this.showedUpDays,
    required this.dayCounts,
  });

  /// 0..100, same scale as [EffortScore.value].
  final double value;

  /// `quiet`, `steady` or `strong` (the [MomentumLevel] name).
  final String level;

  /// Distinct days with any effort in the last 7.
  final int showedUpDays;

  /// Effort events per day, oldest first (7 entries).
  final List<int> dayCounts;

  Map<String, Object?> toJson() => {
    'value': value,
    'level': level,
    'showedUpDays': showedUpDays,
    'dayCounts': dayCounts,
  };

  static WidgetMomentum? _tryDecode(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final value = (raw['value'] as num?)?.toDouble();
    final level = raw['level'];
    final showedUpDays = raw['showedUpDays'];
    final counts = raw['dayCounts'];
    if (value == null ||
        level is! String ||
        showedUpDays is! int ||
        counts is! List) {
      return null;
    }
    return WidgetMomentum(
      value: value,
      level: level,
      showedUpDays: showedUpDays,
      dayCounts: [for (final c in counts) (c as num).toInt()],
    );
  }
}
