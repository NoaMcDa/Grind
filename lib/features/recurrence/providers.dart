import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notification_sync.dart';

import 'recurrence_notifications.dart';

/// The recurrence rule of a task, live; null for one-time reminders.
final ruleForTaskProvider = StreamProvider.family<ReminderRule?, String>(
  (ref, taskId) => ref
      .watch(reminderRepositoryProvider)
      .watchAll()
      .map((rules) => rules.where((r) => r.taskId == taskId).firstOrNull),
);

/// Pass to `NotificationSync(extra: ref.watch(recurrenceExtraProvider))`.
final recurrenceExtraProvider = Provider<ExtraNotifications>(
  (ref) => recurrenceExtraNotifications(
    ref.watch(reminderRepositoryProvider),
    horizonDays: 7,
    clock: ref.watch(clockProvider),
  ),
);
