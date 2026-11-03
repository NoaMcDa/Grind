import 'package:flutter/widgets.dart';

/// UI strings of the reminders feature, until the integrator moves them
/// into `lib/l10n/*.arb` (see docs/plans/ownership.md, "Strings").
///
/// The notification copy itself (if-then lines, the move offer) lives in
/// `ReminderCopy`, because it is also built outside any widget tree.
class RemindersStrings {
  const RemindersStrings._({
    required this.reminderNow,
    required this.done,
    required this.snooze15,
    required this.startFocus,
    required this.niceStart,
    required this.happyDance,
    required String Function(String time) seeYouAt,
    required this.snoozeHint,
    required this.undo,
    required this.tonight,
    required this.tomorrow,
    required this.pickATime,
  }) : _seeYouAt = seeYouAt;

  /// Card label: "REMINDER · NOW".
  final String reminderNow;
  final String done;
  final String snooze15;
  final String startFocus;

  /// Done state title and line.
  final String niceStart;
  final String happyDance;
  final String Function(String time) _seeYouAt;

  /// Snoozed state hint under "See you at 7:15".
  final String snoozeHint;
  final String undo;

  /// Smart-snooze buttons (#12).
  final String tonight;
  final String tomorrow;
  final String pickATime;

  /// Snoozed state title: "See you at 7:15".
  String seeYouAt(String time) => _seeYouAt(time);

  static final en = RemindersStrings._(
    reminderNow: 'REMINDER · NOW',
    done: 'Done',
    snooze15: 'Snooze 15',
    startFocus: 'Start focus',
    niceStart: 'Nice start!',
    happyDance: 'Pip is doing a little happy dance.',
    seeYouAt: (t) => 'See you at $t',
    snoozeHint: 'Snooze again and Pip will offer to move it instead.',
    undo: 'Undo',
    tonight: 'Tonight',
    tomorrow: 'Tomorrow',
    pickATime: 'Pick a time',
  );

  static final he = RemindersStrings._(
    reminderNow: 'תזכורת · עכשיו',
    done: 'בוצע',
    snooze15: 'עוד 15 דק׳',
    startFocus: 'להתחיל ריכוז',
    niceStart: 'התחלה יפה!',
    happyDance: 'פיפ רוקד ריקוד שמח קטן.',
    seeYouAt: (t) => 'נתראה ב־$t',
    snoozeHint: 'עוד דחייה אחת, ופיפ יציע להזיז את זה במקום.',
    undo: 'ביטול',
    tonight: 'הערב',
    tomorrow: 'מחר',
    pickATime: 'לבחור שעה',
  );

  static RemindersStrings forLanguage(String code) =>
      code.toLowerCase().startsWith('he') ? he : en;

  /// Strings for the app locale (English without a [Localizations]).
  static RemindersStrings of(BuildContext context) =>
      forLanguage(Localizations.maybeLocaleOf(context)?.languageCode ?? 'en');
}
