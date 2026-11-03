import 'dart:convert';

import 'package:grind/core/core.dart';

/// iOS category of a normal task reminder: Done / Snooze 15 / Start focus.
const grindReminderCategory = 'GRIND_REMINDER';

/// iOS category of the smart-snooze variant (#12), used once a task has
/// been snoozed twice: Tonight / Tomorrow / Pick a time.
const grindRescheduleCategory = 'GRIND_RESCHEDULE';

/// Action identifiers shared by the iOS category, the payload codec and the
/// background handler.
const actionIdDone = 'done';
const actionIdSnooze = 'snooze';
const actionIdStartFocus = 'start_focus';
const actionIdMoveToTonight = 'move_tonight';
const actionIdMoveToTomorrow = 'move_tomorrow';

/// "Pick a time" on the reschedule category. It has the `foreground`
/// option, so it opens the app; it deliberately decodes to no
/// [NotificationAction] and is handled like a body tap (open `/task/<id>`).
const actionIdPickTime = 'pick_time';

/// The iOS category for a notification's [actions]: none for prompts, the
/// reschedule category when it offers a move, the reminder category
/// otherwise.
String? categoryFor(List<NotificationAction> actions) {
  if (actions.isEmpty) return null;
  final moves =
      actions.contains(NotificationAction.moveToTonight) ||
      actions.contains(NotificationAction.moveToTomorrow);
  return moves ? grindRescheduleCategory : grindReminderCategory;
}

String actionIdFor(NotificationAction action) => switch (action) {
  NotificationAction.done => actionIdDone,
  NotificationAction.snooze => actionIdSnooze,
  NotificationAction.startFocus => actionIdStartFocus,
  NotificationAction.moveToTonight => actionIdMoveToTonight,
  NotificationAction.moveToTomorrow => actionIdMoveToTomorrow,
};

NotificationAction? actionFromId(String? id) => switch (id) {
  actionIdDone => NotificationAction.done,
  actionIdSnooze => NotificationAction.snooze,
  actionIdStartFocus => NotificationAction.startFocus,
  actionIdMoveToTonight => NotificationAction.moveToTonight,
  actionIdMoveToTomorrow => NotificationAction.moveToTomorrow,
  _ => null,
};

/// Payload carried by every platform notification: `{taskId, notificationId}`.
String encodePayload(ScheduledNotification n) =>
    jsonEncode({'taskId': n.taskId, 'notificationId': n.id});

/// What a platform reported, before it is turned into a
/// [NotificationResponse]. Plain data so it can cross isolates and be
/// written to the pending-responses journal.
class RawNotificationResponse {
  const RawNotificationResponse({this.platformId, this.actionId, this.payload});

  final int? platformId;
  final String? actionId;
  final String? payload;

  Map<String, Object?> toJson() => {
    'platformId': platformId,
    'actionId': actionId,
    'payload': payload,
  };

  factory RawNotificationResponse.fromJson(Map<String, Object?> json) =>
      RawNotificationResponse(
        platformId: json['platformId'] as int?,
        actionId: json['actionId'] as String?,
        payload: json['payload'] as String?,
      );

  /// Null when the payload is missing or not ours.
  NotificationResponse? decode() {
    final p = payload;
    if (p == null || p.isEmpty) return null;
    try {
      final map = jsonDecode(p);
      if (map is! Map) return null;
      final id = map['notificationId'];
      final taskId = map['taskId'];
      if (id is! String || taskId is! String) return null;
      return NotificationResponse(
        notificationId: id,
        taskId: taskId,
        action: actionFromId(actionId),
      );
    } on FormatException {
      return null;
    }
  }
}

/// Stable positive 31-bit id for a string id (FNV-1a). The plugin needs
/// ints; collisions inside one batch are resolved by probing in the caller.
int platformIdFor(String id) {
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode(id)) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
