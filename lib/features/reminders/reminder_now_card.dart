import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../core/notifications/notification_router.dart';
import '../../core/notifications/notification_scheduler.dart';
import '../../core/notifications/time_zones.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/sticker_card.dart';
import '../recurrence/providers.dart';
import '../tasks/task_actions.dart';
import 'reminder_copy.dart';
import '../../l10n/l10n.dart';

/// What the reminder card shows.
enum ReminderCardState {
  /// Due now (or within the next two hours): Done / Snooze 15 / Start focus.
  open,

  /// Completed from the card or the notification: "Nice start!".
  done,

  /// Snoozed once: "See you at 7:15", with Undo.
  snoozed,

  /// Snoozed twice (smart snooze, #12): Tonight / Tomorrow / Pick a time.
  reschedule,
}

/// The reminder of the moment.
class CurrentReminder {
  const CurrentReminder({
    required this.task,
    required this.state,
    required this.fireAt,
  });

  final Task task;
  final ReminderCardState state;

  /// When the reminder fires (or fired), UTC.
  final DateTime fireAt;
}

/// Picks the reminder for the card: among tasks whose reminder is within
/// [window] of [now] (see [NotificationScheduler.reminderTimeFor]), the one
/// with the latest event at or before now — a reminder that fired, a
/// snooze, a completion — else the soonest upcoming one. Null when there
/// is none.
///
/// A recurring task (its rule in [rules]) whose `lastCompletedAt` is within
/// [window] counts as completed at the rule's `updatedAt`, so the card says
/// done even though the series task stays open for its next occurrence.
CurrentReminder? pickCurrentReminder(
  List<Task> tasks,
  Preferences prefs,
  DateTime now, {
  Duration window = const Duration(hours: 2),
  Map<String, ReminderRule> rules = const {},
}) {
  final utcNow = now.toUtc();
  final from = utcNow.subtract(window);
  final to = utcNow.add(window);
  bool inWindow(DateTime t) => !t.isBefore(from) && !t.isAfter(to);

  CurrentReminder? latest;
  DateTime? latestAt;
  CurrentReminder? upcoming;
  void consider(CurrentReminder c, DateTime? eventAt) {
    if (eventAt == null) {
      if (upcoming == null || c.fireAt.isBefore(upcoming!.fireAt)) {
        upcoming = c;
      }
      return;
    }
    if (latestAt == null || eventAt.isAfter(latestAt!)) {
      latest = c;
      latestAt = eventAt;
    }
  }

  for (final t in tasks) {
    if (t.deletedAt != null || t.status == TaskStatus.skipped) continue;
    final last = rules[t.id]?.lastCompletedAt?.toUtc();
    if (!t.isDone && last != null && inWindow(last)) {
      final u = rules[t.id]!.updatedAt.toUtc();
      final c = u.isAfter(utcNow) ? utcNow : u;
      if (!c.isBefore(from)) {
        consider(
          CurrentReminder(task: t, state: ReminderCardState.done, fireAt: last),
          c,
        );
      }
    }
    final at = NotificationScheduler.reminderTimeFor(t, prefs);
    if (at == null || !inWindow(at)) continue;
    if (t.isDone) {
      final c = t.completedAt?.toUtc();
      if (c == null || c.isBefore(from) || c.isAfter(utcNow)) continue;
      consider(
        CurrentReminder(task: t, state: ReminderCardState.done, fireAt: at),
        c,
      );
      continue;
    }
    final fired = !at.isAfter(utcNow);
    final state = t.snoozeCount >= NotificationScheduler.smartSnoozeAfter
        ? ReminderCardState.reschedule
        : t.snoozeCount > 0 && !fired
        ? ReminderCardState.snoozed
        : ReminderCardState.open;
    final c = CurrentReminder(task: t, state: state, fireAt: at);
    if (fired) {
      consider(c, at);
    } else if (state != ReminderCardState.open) {
      // A snooze happened at updatedAt; clamp a clock skew to now.
      final u = t.updatedAt.toUtc();
      consider(c, u.isAfter(utcNow) ? utcNow : u);
    } else {
      consider(c, null);
    }
  }
  return latest ?? upcoming;
}

/// The reminder due now / most recently fired, within ±2 h, for the Today
/// card. Recomputed when tasks or preferences change.
final currentReminderProvider = Provider<CurrentReminder?>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final prefs = ref.watch(preferencesProvider).valueOrNull;
  if (prefs == null) return null;
  final rules =
      ref.watch(reminderRulesProvider).valueOrNull ?? const <ReminderRule>[];
  return pickCurrentReminder(
    tasks,
    prefs,
    ref.watch(clockProvider).now(),
    rules: {
      for (final r in rules)
        if (r.deletedAt == null) r.taskId: r,
    },
  );
});

/// Applies the card's buttons exactly like the notification actions, so
/// iOS, web and the card behave the same. Not attached to the notification
/// stream (that is `notificationRouterProvider`'s job).
final reminderActionsProvider = Provider<NotificationRouter>((ref) {
  final router = NotificationRouter(
    tasks: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
    notifications: ref.watch(notificationServiceProvider),
    preferences: ref.watch(preferencesRepositoryProvider),
    reminders: ref.watch(reminderRepositoryProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Today's "REMINDER · NOW" card (#9, #10, #12). Renders nothing when no
/// reminder is near.
///
/// [onStartFocus] and [onPickTime] default to go_router navigation to
/// `/focus?taskId=<id>` and `/task/<id>`.
class ReminderNowCard extends ConsumerWidget {
  const ReminderNowCard({super.key, this.onStartFocus, this.onPickTime});

  final ValueChanged<String>? onStartFocus;
  final ValueChanged<String>? onPickTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentReminderProvider);
    final prefs = ref.watch(preferencesProvider).valueOrNull;
    if (current == null || prefs == null) return const SizedBox.shrink();
    final s = context.l10n;
    final locale = Localizations.maybeLocaleOf(context);
    final task = current.task;

    Future<void> act(NotificationAction action) => ref
        .read(reminderActionsProvider)
        .handle(
          NotificationResponse(
            notificationId: NotificationScheduler.taskNotificationId(
              task.id,
              current.fireAt,
            ),
            taskId: task.id,
            action: action,
          ),
        );

    void go(ValueChanged<String>? callback, String location) {
      if (callback != null) return callback(task.id);
      GoRouter.maybeOf(context)?.go(location);
    }

    switch (current.state) {
      case ReminderCardState.open:
        final copy = ReminderCopy.build(
          task,
          prefs,
          locale: locale,
          at: current.fireAt,
        );
        return _VioletCard(
          label: s.reminderNow.toUpperCase(),
          headline: copy.headline,
          line: copy.line,
          buttons: [
            _Button(
              flex: 10,
              label: s.done,
              color: AppColors.sun,
              onPressed: () => _done(ref, current, act),
            ),
            _Button(
              flex: 10,
              label: s.snooze15,
              onPressed: () {
                // Remember the task as it was, so Undo restores it exactly.
                ref.read(_snoozeUndoProvider.notifier).state = {
                  ...ref.read(_snoozeUndoProvider),
                  task.id: task,
                };
                act(NotificationAction.snooze);
              },
            ),
            _Button(
              flex: 13,
              label: s.startFocus,
              color: AppColors.mint,
              icon: const Icon(Icons.play_arrow),
              onPressed: () =>
                  go(onStartFocus, NotificationRouter.focusLocation(task.id)),
            ),
          ],
        );
      case ReminderCardState.reschedule:
        final copy = ReminderCopy.reschedule(task, prefs, locale: locale);
        return _VioletCard(
          label: s.reminderNow.toUpperCase(),
          headline: copy.headline,
          line: copy.line,
          buttons: [
            _Button(
              flex: 10,
              label: s.remindersTonight,
              color: AppColors.sun,
              onPressed: () => act(NotificationAction.moveToTonight),
            ),
            _Button(
              flex: 10,
              label: s.commonTomorrow,
              onPressed: () => act(NotificationAction.moveToTomorrow),
            ),
            _Button(
              flex: 13,
              label: s.remindersPickATime,
              color: AppColors.mint,
              onPressed: () =>
                  go(onPickTime, '/task/${Uri.encodeComponent(task.id)}'),
            ),
          ],
        );
      case ReminderCardState.done:
        return StickerCard(
          color: AppColors.sun,
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 40,
                color: AppColors.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.niceStart, style: AppText.display(size: 20)),
                    Text(s.pipHappyDance, style: AppText.body(size: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      case ReminderCardState.snoozed:
        final local = tz.TZDateTime.from(
          current.fireAt,
          locationFor(prefs.timeZoneName),
        );
        final time =
            '${local.hour.toString().padLeft(2, '0')}:'
            '${local.minute.toString().padLeft(2, '0')}';
        return StickerCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.seeYouAt(time), style: AppText.display(size: 20)),
                    Text(
                      s.snoozeAgainHint,
                      style: AppText.body(size: 14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PillButton(
                label: s.undo,
                color: AppColors.ground,
                shadow: 0,
                onPressed: () => _undoSnooze(ref, task),
              ),
            ],
          ),
        );
    }
  }

  /// Done: a recurring task completes the card's occurrence (recorded as
  /// the rule's `lastCompletedAt`, so the card turns to done); anything else
  /// goes through the notification action.
  Future<void> _done(
    WidgetRef ref,
    CurrentReminder current,
    Future<void> Function(NotificationAction) act,
  ) async {
    final actions = ref.read(taskActionsProvider);
    final next = await actions.completeRecurring(
      current.task,
      occurrenceAt: current.fireAt,
    );
    if (next == null) await act(NotificationAction.done);
  }

  /// Takes the last snooze back: the task as it was before the card's
  /// snooze when known, else 15 minutes earlier and one snooze fewer.
  Future<void> _undoSnooze(WidgetRef ref, Task task) {
    final now = ref.read(clockProvider).now().toUtc();
    final saved = ref.read(_snoozeUndoProvider)[task.id];
    ref.read(_snoozeUndoProvider.notifier).state = {
      ...ref.read(_snoozeUndoProvider),
    }..remove(task.id);
    final restored = saved != null && saved.snoozeCount == task.snoozeCount - 1
        ? task.copyWith(
            remindAt: saved.remindAt,
            snoozeCount: saved.snoozeCount,
            updatedAt: now,
          )
        : task.copyWith(
            remindAt: task.remindAt?.subtract(
              ref.read(reminderActionsProvider).snoozeBy,
            ),
            snoozeCount: task.snoozeCount > 0 ? task.snoozeCount - 1 : 0,
            updatedAt: now,
          );
    return ref.read(taskRepositoryProvider).upsert(restored);
  }
}

/// Tasks as they were before a snooze from the card, by id (for Undo).
final _snoozeUndoProvider = StateProvider<Map<String, Task>>((_) => const {});

class _Button {
  const _Button({
    required this.flex,
    required this.label,
    required this.onPressed,
    this.color = AppColors.card,
    this.icon,
  });

  final int flex;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Widget? icon;
}

class _VioletCard extends StatelessWidget {
  const _VioletCard({
    required this.label,
    required this.headline,
    required this.line,
    required this.buttons,
  });

  final String label;
  final String headline;
  final String line;
  final List<_Button> buttons;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      color: AppColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.sun,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(label, style: AppText.label(size: 12, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: AppText.display(size: 21, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(line, style: AppText.body(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  flex: buttons[i].flex,
                  child: PillButton(
                    label: buttons[i].label,
                    horizontalPadding: 8,
                    color: buttons[i].color,
                    icon: buttons[i].icon,
                    onPressed: buttons[i].onPressed,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
