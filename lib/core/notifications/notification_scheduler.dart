import 'package:grind/core/core.dart';
import 'package:timezone/timezone.dart' as tz;

import 'time_zones.dart';

/// Times and placeholder copy for the two daily prompts. Invitations, never
/// commands (RESEARCH.md Part 2B, "Notification tone"). The phase 1 epics own
/// the final copy and the settings UI.
class PromptSettings {
  const PromptSettings({
    this.morningEnabled = true,
    this.morningMinutes = 8 * 60,
    this.eveningEnabled = true,
    this.eveningMinutes = 20 * 60 + 30,
    this.morningTitle = 'Good morning',
    this.morningBody = 'Want to plan the day together?',
    this.eveningTitle = 'Evening check-in',
    this.eveningBody = 'One minute to look back on today?',
  });

  final bool morningEnabled;

  /// Local minutes after midnight (default 08:00).
  final int morningMinutes;
  final bool eveningEnabled;

  /// Local minutes after midnight (default 20:30).
  final int eveningMinutes;
  final String morningTitle;
  final String morningBody;
  final String eveningTitle;
  final String eveningBody;

  /// Times and on/off from [Preferences] (null minutes = prompt off),
  /// keeping this instance's copy.
  PromptSettings withPreferences(Preferences prefs) => PromptSettings(
    morningEnabled: prefs.morningPromptMinutes != null,
    morningMinutes: prefs.morningPromptMinutes ?? morningMinutes,
    eveningEnabled: prefs.eveningPromptMinutes != null,
    eveningMinutes: prefs.eveningPromptMinutes ?? eveningMinutes,
    morningTitle: morningTitle,
    morningBody: morningBody,
    eveningTitle: eveningTitle,
    eveningBody: eveningBody,
  );
}

/// Pure planning of the pending notification set. No plugin, no I/O: given
/// tasks, preferences and a clock it returns what should be pending, sorted
/// by [ScheduledNotification.fireAt] and trimmed to `cap`, keeping the
/// soonest.
///
/// See docs/adr/0003-notifications.md for the 64-slot strategy.
abstract final class NotificationScheduler {
  static const taskPrefix = 'task:';
  static const morningPrefix = 'prompt:morning:';
  static const eveningPrefix = 'prompt:evening:';

  /// `task:<taskId>:<fireAt epoch minutes>`.
  static String taskNotificationId(String taskId, DateTime fireAt) =>
      '$taskPrefix$taskId:${fireAt.millisecondsSinceEpoch ~/ 60000}';

  /// True for the daily planning / evening review prompts (no task).
  static bool isPrompt(String notificationId) =>
      notificationId.startsWith(morningPrefix) ||
      notificationId.startsWith(eveningPrefix);

  static List<ScheduledNotification> plan({
    required List<Task> tasks,
    required Preferences prefs,
    required Clock clock,
    int horizonDays = 7,
    int cap = 50,
    List<ScheduledNotification> extra = const [],
    PromptSettings prompts = const PromptSettings(),
  }) {
    final location = locationFor(prefs.timeZoneName);
    final now = clock.now().toUtc();
    final end = now.add(Duration(days: horizonDays));
    bool inWindow(DateTime t) => t.isAfter(now) && t.isBefore(end);

    final out = <ScheduledNotification>[];
    final seen = <String>{};
    void add(ScheduledNotification n) {
      if (seen.add(n.id)) out.add(n);
    }

    for (final task in tasks) {
      final remindAt = task.remindAt?.toUtc();
      if (task.status != TaskStatus.open || task.deletedAt != null) continue;
      if (remindAt == null || !inWindow(remindAt)) continue;
      final fireAt = _outOfQuietHours(remindAt, prefs, location);
      add(
        ScheduledNotification(
          id: taskNotificationId(task.id, fireAt),
          taskId: task.id,
          fireAt: fireAt,
          title: _titleFor(task),
          body: _bodyFor(task, tz.TZDateTime.from(fireAt, location)),
        ),
      );
    }

    // Recurrence occurrences (#11) and other feature-supplied reminders.
    for (final n in extra) {
      final at = n.fireAt.toUtc();
      if (!inWindow(at)) continue;
      final fireAt = _outOfQuietHours(at, prefs, location);
      add(
        fireAt == at
            ? n
            : ScheduledNotification(
                id: n.id,
                taskId: n.taskId,
                fireAt: fireAt,
                title: n.title,
                body: n.body,
                actions: n.actions,
              ),
      );
    }

    // One morning and one evening prompt per local day in the horizon.
    final today = tz.TZDateTime.from(now, location);
    for (var d = 0; d <= horizonDays; d++) {
      final day = tz.TZDateTime(
        location,
        today.year,
        today.month,
        today.day + d,
      );
      final date = _date(day);
      void prompt(
        bool on,
        int minutes,
        String prefix,
        String title,
        String body,
      ) {
        if (!on) return;
        final at = tz.TZDateTime(
          location,
          day.year,
          day.month,
          day.day,
          minutes ~/ 60,
          minutes % 60,
        ).toUtc();
        if (!inWindow(at)) return;
        add(
          ScheduledNotification(
            id: '$prefix$date',
            taskId: '',
            fireAt: _outOfQuietHours(at, prefs, location),
            title: title,
            body: body,
            actions: const [],
          ),
        );
      }

      prompt(
        prompts.morningEnabled,
        prompts.morningMinutes,
        morningPrefix,
        prompts.morningTitle,
        prompts.morningBody,
      );
      prompt(
        prompts.eveningEnabled,
        prompts.eveningMinutes,
        eveningPrefix,
        prompts.eveningTitle,
        prompts.eveningBody,
      );
    }

    out.sort((a, b) {
      final c = a.fireAt.compareTo(b.fireAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return out.length <= cap ? out : out.sublist(0, cap);
  }

  /// Moves [utc] to the end of the quiet hours when it falls inside them.
  static DateTime _outOfQuietHours(
    DateTime utc,
    Preferences prefs,
    tz.Location location,
  ) {
    final quiet = prefs.quietHours;
    if (quiet == null) return utc;
    final local = tz.TZDateTime.from(utc, location);
    final minute = local.hour * 60 + local.minute;
    if (minute < quiet.startMinutes || minute >= quiet.endMinutes) return utc;
    return tz.TZDateTime(
      location,
      local.year,
      local.month,
      local.day,
      quiet.endMinutes ~/ 60,
      quiet.endMinutes % 60,
    ).toUtc();
  }

  static String _titleFor(Task task) =>
      _step(task) == null ? 'Grind' : task.title;

  /// If-then form when there is a first action ("07:00 — open the thesis
  /// file."), otherwise the task title.
  static String _bodyFor(Task task, tz.TZDateTime local) {
    final step = _step(task);
    if (step == null) return task.title;
    final hm = '${_two(local.hour)}:${_two(local.minute)}';
    final stop = RegExp(r'[.!?]$').hasMatch(step) ? '' : '.';
    return '$hm — $step$stop';
  }

  static String? _step(Task task) {
    final s = task.firstAction?.trim();
    return s == null || s.isEmpty ? null : s;
  }

  static String _date(tz.TZDateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
