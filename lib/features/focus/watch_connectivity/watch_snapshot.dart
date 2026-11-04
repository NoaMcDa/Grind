import 'dart:convert';

/// The payload a paired Apple Watch reads through the shared App Group for
/// its complication and the session screen (#46). Pure data: the phone-side
/// writer encodes it to one JSON string the watchOS target decodes on each
/// complication refresh and when it opens the session view.
///
/// Why one bundle: the watch wakes briefly, so each wake should read one
/// key and move on. The small complication needs "next reminder" and a
/// momentum badge; the session screen reuses the same record for the
/// if-then first step, so one blob is cheaper than three.
///
/// The schema is versioned so a watchOS target built from an older app
/// version can refuse to render unknown shapes instead of guessing — users
/// update the app and the watch extension separately.
///
/// This type lives next to [WatchConnectivityService] on purpose. The
/// method-channel service drives live session start/stop; this snapshot is
/// the slow-moving data the complication reads between events, and both
/// sides of the watch bridge are now in one folder.
class WatchSnapshot {
  const WatchSnapshot({
    required this.writtenAt,
    this.nextReminder,
    required this.momentum,
    this.schema = schemaVersion,
  });

  /// Bumped with every breaking change. A newer schema than the watch knows
  /// about is treated as "no snapshot" so the complication falls back to
  /// "Open Grind" instead of showing a stale line.
  static const schemaVersion = 1;

  /// When the phone wrote this snapshot (UTC). The complication shows "a
  /// few minutes ago" from it and can treat a very old snapshot as missing.
  final DateTime writtenAt;

  /// The soonest reminder on the plan, trimmed for the complication, or
  /// null when the plan has none right now.
  final WatchReminder? nextReminder;

  /// Just enough momentum for the dot or tick next to the reminder: a 0..100
  /// value and the level name. The watch does not render the 7-day strip
  /// the home widget shows, so dayCounts are deliberately left out.
  final WatchMomentum momentum;

  final int schema;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'writtenAt': writtenAt.toUtc().toIso8601String(),
    if (nextReminder != null) 'nextReminder': nextReminder!.toJson(),
    'momentum': momentum.toJson(),
  };

  /// Stable JSON ready for the App Group writer. Two equal snapshots encode
  /// to the same bytes so the watch can skip a redraw when nothing changed.
  String encode() => jsonEncode(toJson());

  /// Returns null when the payload is missing, unreadable, or written by a
  /// newer app than the watch target. The complication shows a fallback
  /// instead of throwing.
  static WatchSnapshot? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return null;
      final schema = map['schema'];
      if (schema is! int || schema > schemaVersion) return null;
      final writtenAt = DateTime.tryParse(map['writtenAt'] as String? ?? '');
      if (writtenAt == null) return null;
      final reminder = WatchReminder._tryDecode(map['nextReminder']);
      final momentum = WatchMomentum._tryDecode(map['momentum']);
      if (momentum == null) return null;
      return WatchSnapshot(
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

/// One reminder, trimmed to what the complication and the session screen
/// show on a watch face.
///
/// [taskId] is what the "Start focus 25 min" shortcut and the Pip session
/// screen hand back to the phone through [WatchConnectivityService], so the
/// focus session can start by id — the watch never writes to the task
/// store itself.
///
/// [ifThen] is the task's if-then first step ("open the thesis file"). The
/// watch shows it on the Pip screen as a one-line cue; it is null when the
/// task has no first action set.
class WatchReminder {
  const WatchReminder({
    required this.taskId,
    required this.fireAt,
    required this.title,
    this.ifThen,
  });

  final String taskId;

  /// When the reminder fires (UTC).
  final DateTime fireAt;

  /// The task's short title, as shown in the plan.
  final String title;

  /// The if-then first step ("open the thesis file"), or null when the task
  /// has none. Separate from [title] so the complication can drop it when
  /// space is tight and the Pip screen can still show it.
  final String? ifThen;

  Map<String, Object?> toJson() => {
    'taskId': taskId,
    'fireAt': fireAt.toUtc().toIso8601String(),
    'title': title,
    if (ifThen != null) 'ifThen': ifThen,
  };

  static WatchReminder? _tryDecode(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final taskId = raw['taskId'];
    final title = raw['title'];
    final fireAt = DateTime.tryParse(raw['fireAt'] as String? ?? '');
    if (taskId is! String || title is! String || fireAt == null) return null;
    final ifThen = raw['ifThen'];
    return WatchReminder(
      taskId: taskId,
      fireAt: fireAt.toUtc(),
      title: title,
      ifThen: ifThen is String ? ifThen : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WatchReminder &&
      other.taskId == taskId &&
      other.fireAt == fireAt &&
      other.title == title &&
      other.ifThen == ifThen;

  @override
  int get hashCode => Object.hash(taskId, fireAt, title, ifThen);
}

/// Momentum, trimmed to what the complication needs: a 0..100 value and
/// the three-band level name ("quiet", "steady", "strong"). The home
/// widget's 7-day activity strip is deliberately dropped — a watch face
/// has no room to draw it.
class WatchMomentum {
  const WatchMomentum({required this.value, required this.level});

  /// 0..100, same scale as the home widget uses.
  final double value;

  /// `quiet`, `steady` or `strong`.
  final String level;

  Map<String, Object?> toJson() => {'value': value, 'level': level};

  static WatchMomentum? _tryDecode(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final rawValue = raw['value'];
    final level = raw['level'];
    if (rawValue is! num || level is! String) return null;
    return WatchMomentum(value: rawValue.toDouble(), level: level);
  }

  @override
  bool operator ==(Object other) =>
      other is WatchMomentum && other.value == value && other.level == level;

  @override
  int get hashCode => Object.hash(value, level);
}
