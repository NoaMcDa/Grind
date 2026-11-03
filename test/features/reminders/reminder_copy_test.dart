import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';
import 'package:grind/features/reminders/reminder_copy.dart';

final _epoch = DateTime.utc(2026, 1, 1);

Task _task(String id, {String title = 'Thesis', String? firstAction}) => Task(
  id: id,
  title: title,
  firstAction: firstAction,
  remindAt: DateTime.utc(2026, 11, 3, 5), // 07:00 in Asia/Jerusalem
  createdAt: _epoch,
  updatedAt: _epoch,
);

void main() {
  setUpAll(ensureTimeZones);
  const prefs = Preferences(timeZoneName: 'Asia/Jerusalem');

  group('pool', () {
    test('about 20 lines per language, English and Hebrew', () {
      expect(ReminderCopy.languages, containsAll(['en', 'he']));
      for (final lang in ReminderCopy.languages) {
        final pool = ReminderCopy.pool(lang);
        expect(pool.length, inInclusiveRange(18, 24), reason: lang);
        expect(pool.toSet(), hasLength(pool.length), reason: 'no duplicates');
        for (final line in pool) {
          expect(line.length, lessThan(60), reason: line);
          expect(line.trim(), line);
        }
      }
      final hebrew = RegExp(r'[֐-׿]');
      expect(ReminderCopy.pool('he').every(hebrew.hasMatch), isTrue);
      expect(ReminderCopy.pool('en').any(hebrew.hasMatch), isFalse);
    });

    test('no banned word anywhere, including the move offer', () {
      final all = <String, List<String>>{
        for (final lang in ReminderCopy.languages)
          lang: [
            ...ReminderCopy.pool(lang),
            ReminderCopy.reschedule(
              _task('x'),
              prefs,
              locale: Locale(lang),
            ).body,
          ],
      };
      for (final MapEntry(key: lang, value: lines) in all.entries) {
        final banned = [
          ...ReminderCopy.bannedWords['en']!,
          ...ReminderCopy.bannedWords[lang]!,
        ];
        for (final line in lines) {
          final lower = line.toLowerCase();
          for (final word in banned) {
            final hit = RegExp(r'[a-z]').hasMatch(word)
                ? RegExp('\\b$word\\b').hasMatch(lower)
                : lower.contains(word);
            expect(hit, isFalse, reason: '"$line" contains "$word"');
          }
        }
      }
      expect(
        ReminderCopy.bannedWords['en'],
        containsAll(['should', 'failed', 'again', 'missed']),
      );
    });

    test('rotation is deterministic and never repeats within 5 days', () {
      for (final id in ['a', 'thesis', 'gym-123', 'x' * 40]) {
        final days = [
          for (var d = 0; d < 40; d++)
            ReminderCopy.encouragement(id, DateTime(2026, 11, 1 + d)),
        ];
        for (var i = 0; i + 5 <= days.length; i++) {
          expect(days.sublist(i, i + 5).toSet(), hasLength(5), reason: id);
        }
        expect(
          ReminderCopy.encouragement(id, DateTime(2026, 11, 1)),
          days.first,
        );
      }
      // Different tasks on the same day usually differ.
      final today = {
        for (final id in ['a', 'b', 'c', 'd', 'e', 'f'])
          ReminderCopy.encouragement(id, DateTime(2026, 11, 3)),
      };
      expect(today.length, greaterThan(1));
    });
  });

  group('build', () {
    test('if-then form with a first action, in the user zone', () {
      final copy = ReminderCopy.build(
        _task('a', firstAction: 'open the thesis file'),
        prefs,
      );
      expect(copy.title, 'Thesis');
      expect(copy.headline, '07:00 — open the thesis file.');
      expect(ReminderCopy.pool('en'), contains(copy.line));
      expect(copy.body, '${copy.headline} ${copy.line}');
    });

    test('keeps the first action\'s own punctuation', () {
      final copy = ReminderCopy.build(
        _task('a', firstAction: 'lace up!'),
        prefs,
      );
      expect(copy.headline, '07:00 — lace up!');
    });

    test('without a first action: the task title plus a line', () {
      final copy = ReminderCopy.build(
        _task('b', title: 'Call mum', firstAction: '  '),
        prefs,
      );
      expect(copy.title, 'Grind');
      expect(copy.headline, 'Call mum.');
      expect(copy.body, startsWith('Call mum. '));
    });

    test('Hebrew from the locale or the preferences', () {
      final t = _task('a', firstAction: 'לפתוח את קובץ התזה');
      final viaLocale = ReminderCopy.build(
        t,
        prefs,
        locale: const Locale('he'),
      );
      final viaPrefs = ReminderCopy.build(t, prefs.copyWith(localeCode: 'he'));
      for (final copy in [viaLocale, viaPrefs]) {
        expect(copy.headline, '07:00 — לפתוח את קובץ התזה.');
        expect(ReminderCopy.pool('he'), contains(copy.line));
      }
    });

    test('the move offer names the task and never the snoozes', () {
      final en = ReminderCopy.reschedule(_task('a'), prefs);
      expect(en.headline, 'Want to move this instead?');
      expect(en.body, contains('Thesis'));
      expect(en.body.toLowerCase(), isNot(contains('snooz')));
      final he = ReminderCopy.reschedule(
        _task('a', title: 'תזה'),
        prefs,
        locale: const Locale('he'),
      );
      expect(he.body, contains('תזה'));
    });
  });
}
