import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:grind/core/core.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/notifications/time_zones.dart';
import '../../l10n/app_localizations.dart';

/// Copy of one reminder, shared by the notification and the Today card.
class ReminderText {
  const ReminderText({
    required this.title,
    required this.headline,
    required this.line,
  });

  /// Notification title.
  final String title;

  /// The if-then part: "07:00 — open the thesis file." (or the task title).
  final String headline;

  /// The encouraging second line (or Pip's offer to move the task).
  final String line;

  /// Notification body: headline and line.
  String get body => line.isEmpty ? headline : '$headline $line';
}

/// If-then reminder copy (#9): `"<HH:mm> — <firstAction>. <line>"`, with an
/// encouraging second line from a pool, rotated per task and day.
///
/// Tone: invitations, never guilt (RESEARCH.md Part 1C). [bannedWords] is
/// enforced over the whole pool by a test.
abstract final class ReminderCopy {
  /// Words no reminder line may contain, per language (lower case; checked
  /// as substrings for Hebrew, whole words for English).
  static const bannedWords = <String, List<String>>{
    'en': [
      'should',
      'failed',
      'fail',
      'again',
      'missed',
      'miss',
      'behind',
      'overdue',
      'lazy',
      'late',
      'must',
      'forgot',
    ],
    'he': ['שוב', 'פספס', 'נכשל', 'כישלון', 'צריך', 'צריכה', 'חייב', 'איחור'],
  };

  /// Encouraging second lines live in the ARB files (remindersLine01..20).
  static List<String> _lines(AppLocalizations l) => [
    l.remindersLine01,
    l.remindersLine02,
    l.remindersLine03,
    l.remindersLine04,
    l.remindersLine05,
    l.remindersLine06,
    l.remindersLine07,
    l.remindersLine08,
    l.remindersLine09,
    l.remindersLine10,
    l.remindersLine11,
    l.remindersLine12,
    l.remindersLine13,
    l.remindersLine14,
    l.remindersLine15,
    l.remindersLine16,
    l.remindersLine17,
    l.remindersLine18,
    l.remindersLine19,
    l.remindersLine20,
  ];

  /// Strings for [languageCode]; usable outside any widget tree.
  static AppLocalizations _l10n(String languageCode) =>
      lookupAppLocalizations(Locale(_lang(languageCode)));

  static const _fallbackTitle = 'Grind';

  /// Language codes with copy. Anything else falls back to English.
  static Iterable<String> get languages => const ['en', 'he'];

  /// The encouraging lines for [languageCode].
  static List<String> pool(String languageCode) => _lines(_l10n(languageCode));

  /// Copy for the reminder of [task] firing at [at] (defaults to
  /// `task.remindAt`, else now). The time is shown in the user's zone.
  static ReminderText build(
    Task task,
    Preferences prefs, {
    Locale? locale,
    DateTime? at,
  }) {
    final lang = _lang(locale?.languageCode ?? prefs.localeCode);
    final location = locationFor(prefs.timeZoneName);
    final when = tz.TZDateTime.from(
      (at ?? task.remindAt ?? DateTime.now()).toUtc(),
      location,
    );
    final line = encouragement(task.id, when, languageCode: lang);
    final step = _step(task);
    if (step == null) {
      return ReminderText(
        title: _fallbackTitle,
        headline: _sentence(task.title),
        line: line,
      );
    }
    final hm = '${_two(when.hour)}:${_two(when.minute)}';
    return ReminderText(
      title: task.title,
      headline: '$hm — ${_sentence(step)}',
      line: line,
    );
  }

  /// The smart-snooze variant, used once a task was snoozed twice. Never
  /// mentions the snoozes.
  static ReminderText reschedule(
    Task task,
    Preferences prefs, {
    Locale? locale,
  }) {
    final lang = _lang(locale?.languageCode ?? prefs.localeCode);
    final l = _l10n(lang);
    return ReminderText(
      title: _fallbackTitle,
      headline: l.remindersMoveOffer,
      line: l.remindersMoveLine(task.title.trim()),
    );
  }

  /// The pool line for [taskId] on the local day of [localDay].
  ///
  /// Deterministic: a per-task offset plus 7 steps per day, modulo the pool
  /// size (20). 7 is coprime with 20, so one task sees all 20 lines before
  /// any repeats, and never the same line within 5 days.
  static String encouragement(
    String taskId,
    DateTime localDay, {
    String languageCode = 'en',
  }) {
    final lines = pool(languageCode);
    final day =
        DateTime.utc(
          localDay.year,
          localDay.month,
          localDay.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final index = (_hash(taskId) + day * 7) % lines.length;
    return lines[index];
  }

  static String _lang(String code) {
    final c = code.toLowerCase();
    if (c.startsWith('he') || c.startsWith('iw')) return 'he';
    return 'en';
  }

  static String? _step(Task task) {
    final s = task.firstAction?.trim();
    return s == null || s.isEmpty ? null : s;
  }

  static String _sentence(String s) {
    final t = s.trim();
    return RegExp(r'[.!?]$').hasMatch(t) ? t : '$t.';
  }

  static int _hash(String s) {
    var h = 0x811c9dc5;
    for (final u in utf8.encode(s)) {
      h ^= u;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
