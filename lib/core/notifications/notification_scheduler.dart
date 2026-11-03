import 'package:grind/core/core.dart';
import 'package:grind/features/reminders/reminder_copy.dart';
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

  /// Hebrew copy for the same prompts, gender-neutral (infinitive and
  /// plural-free forms), used when the app language is Hebrew.
  static const hebrewMorningTitle = 'בוקר טוב';
  static const hebrewMorningBody = 'מתאים לתכנן את היום ביחד?';
  static const hebrewEveningTitle = 'רגע של ערב';
  static const hebrewEveningBody = 'דקה אחת להציץ אחורה על היום?';

  /// Times and on/off from [Preferences] (null minutes = prompt off). The
  /// copy is this instance's, except that the English defaults become the
  /// Hebrew copy when `prefs.localeCode` is Hebrew.
  PromptSettings withPreferences(Preferences prefs) {
    final he = prefs.localeCode.toLowerCase().startsWith('he');
    const defaults = PromptSettings();
    bool isDefault(String own, String fallback) => own == fallback;
    return PromptSettings(
      morningEnabled: prefs.morningPromptMinutes != null,
      morningMinutes: prefs.morningPromptMinutes ?? morningMinutes,
      eveningEnabled: prefs.eveningPromptMinutes != null,
      eveningMinutes: prefs.eveningPromptMinutes ?? eveningMinutes,
      morningTitle: he && isDefault(morningTitle, defaults.morningTitle)
          ? hebrewMorningTitle
          : morningTitle,
      morningBody: he && isDefault(morningBody, defaults.morningBody)
          ? hebrewMorningBody
          : morningBody,
      eveningTitle: he && isDefault(eveningTitle, defaults.eveningTitle)
          ? hebrewEveningTitle
          : eveningTitle,
      eveningBody: he && isDefault(eveningBody, defaults.eveningBody)
          ? hebrewEveningBody
          : eveningBody,
    );
  }
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

  /// From this many snoozes on, a task's next reminder offers to move it
  /// instead of nagging (smart snooze, #12).
  static const smartSnoozeAfter = 2;

  /// Actions of a normal task reminder (category `GRIND_REMINDER`).
  static const reminderActions = [
    NotificationAction.done,
    NotificationAction.snooze,
    NotificationAction.startFocus,
  ];

  /// Actions of the smart-snooze variant (category `GRIND_RESCHEDULE`;
  /// "Pick a time" is a foreground action that opens `/task/<id>`).
  static const rescheduleActions = [
    NotificationAction.moveToTonight,
    NotificationAction.moveToTomorrow,
  ];

  /// When [task]'s reminder fires: `remindAt` when set. Otherwise, for a
  /// task with a due *time*, `dueAt - Preferences.defaultReminderLeadMinutes`.
  /// A date-only due (stored as local midnight or end of day, 23:59) gets
  /// no reminder of its own.
  static DateTime? reminderTimeFor(Task task, Preferences prefs) {
    final remindAt = task.remindAt;
    if (remindAt != null) return remindAt.toUtc();
    final due = task.dueAt;
    if (due == null) return null;
    final local = tz.TZDateTime.from(
      due.toUtc(),
      locationFor(prefs.timeZoneName),
    );
    final minute = local.hour * 60 + local.minute;
    if (minute == 0 || minute >= 23 * 60 + 59) return null;
    return due.toUtc().subtract(
      Duration(minutes: prefs.defaultReminderLeadMinutes),
    );
  }

  /// Title, body and actions of [task]'s reminder firing at [fireAt]: the
  /// if-then copy (#9), or the smart-snooze offer once the task was snoozed
  /// [smartSnoozeAfter] times (#12). Public so feature-supplied reminders
  /// (recurrence occurrences, #11) read exactly like plain ones.
  static ({String title, String body, List<NotificationAction> actions})
  copyFor(Task task, Preferences prefs, DateTime fireAt) {
    final smart = task.snoozeCount >= smartSnoozeAfter;
    final copy = smart
        ? ReminderCopy.reschedule(task, prefs)
        : ReminderCopy.build(task, prefs, at: fireAt);
    return (
      title: copy.title,
      body: copy.body,
      actions: smart ? rescheduleActions : reminderActions,
    );
  }

  /// True for the daily planning / evening review prompts (no task).
  static bool isPrompt(String notificationId) =>
      notificationId.startsWith(morningPrefix) ||
      notificationId.startsWith(eveningPrefix);

  /// [taskIdsWithRules]: tasks with a [ReminderRule]; their `remindAt` is
  /// skipped because the rule's occurrences arrive in [extra].
  static List<ScheduledNotification> plan({
    required List<Task> tasks,
    required Preferences prefs,
    required Clock clock,
    int horizonDays = 7,
    int cap = 50,
    List<ScheduledNotification> extra = const [],
    PromptSettings prompts = const PromptSettings(),
    Set<String> taskIdsWithRules = const {},
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
      if (task.status != TaskStatus.open || task.deletedAt != null) continue;
      // A recurring task's reminders come from its rule through [extra];
      // planning remindAt too would fire the first occurrence twice.
      if (taskIdsWithRules.contains(task.id)) continue;
      final remindAt = reminderTimeFor(task, prefs);
      if (remindAt == null || !inWindow(remindAt)) continue;
      final fireAt = _outOfQuietHours(remindAt, prefs, location);
      final copy = copyFor(task, prefs, fireAt);
      add(
        ScheduledNotification(
          id: taskNotificationId(task.id, fireAt),
          taskId: task.id,
          fireAt: fireAt,
          title: copy.title,
          body: copy.body,
          actions: copy.actions,
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

  static String _date(tz.TZDateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
