import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:grind/core/core.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/notifications/time_zones.dart';

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

  /// Encouraging second lines. Hebrew is written in gender-neutral forms
  /// (infinitives, past tense second person, which is spelled the same).
  static const _pool = <String, List<String>>{
    'en': [
      '25 minutes is enough to start.',
      'Small steps count.',
      'Just the first step. Pip has the rest.',
      'Starting is the hard part, and you are here.',
      'Five minutes in, it gets easier.',
      'One page is a fine start.',
      'Pip has the timer ready.',
      'No need to finish, just begin.',
      'You picked this step for a reason.',
      'Little by little adds up.',
      'Open it and see how it feels.',
      'A quick start beats a perfect plan.',
      'Pip is cheering for you.',
      'Ten focused minutes go a long way.',
      'Begin small, keep it light.',
      'This moment is yours.',
      'Momentum starts with one move.',
      'Easy does it. Start where you are.',
      'Future you will be glad.',
      'Ready when you are.',
    ],
    'he': [
      'עשרים וחמש דקות מספיקות כדי להתחיל.',
      'גם צעד קטן נחשב.',
      'רק הצעד הראשון. פיפ דואג לשאר.',
      'להתחיל זה החלק הקשה, וכבר הגעת.',
      'אחרי חמש דקות זה נהיה קל יותר.',
      'עמוד אחד זו התחלה מצוינת.',
      'פיפ כבר הכין את הטיימר.',
      'מספיק להתחיל. לסיים זה בונוס.',
      'בחרת את הצעד הזה מסיבה טובה.',
      'לאט לאט זה מצטבר.',
      'פשוט לפתוח ולראות איך זה מרגיש.',
      'התחלה מהירה עדיפה על תוכנית מושלמת.',
      'פיפ מעודד אותך.',
      'עשר דקות של ריכוז עושות הרבה.',
      'להתחיל בקטן ובקלילות.',
      'הרגע הזה שלך.',
      'תנופה מתחילה בתנועה אחת.',
      'בנחת. מתחילים מאיפה שנמצאים.',
      'התחלה קטנה עכשיו, הקלה גדולה אחר כך.',
      'פיפ כאן, מתי שנוח.',
    ],
  };

  static const _fallbackTitle = 'Grind';

  /// Pip's smart-snooze offer (#12).
  static const _moveOffer = <String, String>{
    'en': 'Want to move this instead?',
    'he': 'רוצה להזיז את זה?',
  };

  static String _moveLine(String lang, String title) => lang == 'he'
      ? 'אפשר למצוא ל"$title" רגע נוח יותר.'
      : '"$title" can have a calmer moment.';

  /// Language codes with copy. Anything else falls back to English.
  static Iterable<String> get languages => _pool.keys;

  /// The encouraging lines for [languageCode].
  static List<String> pool(String languageCode) =>
      _pool[_lang(languageCode)] ?? _pool['en']!;

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
    return ReminderText(
      title: _fallbackTitle,
      headline: _moveOffer[lang]!,
      line: _moveLine(lang, task.title.trim()),
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
