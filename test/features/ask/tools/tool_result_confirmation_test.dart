import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/tools/tool_result_confirmation.dart';
import 'package:grind/l10n/l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final he = lookupAppLocalizations(const Locale('he'));

  // Local-time helper for compact ranges in these tests.
  ScheduledRange r(int sh, int sm, int eh, int em) => ScheduledRange(
    DateTime(2026, 11, 4, sh, sm),
    DateTime(2026, 11, 4, eh, em),
  );

  group('formatToolConfirmation (en)', () {
    test('empty ranges render the plain "Done." sentence', () {
      expect(formatToolConfirmation(en, const []), 'Done.');
    });

    test('a single range omits the list connector', () {
      expect(formatToolConfirmation(en, [r(9, 0, 9, 25)]), 'Done: 09:00–09:25');
    });

    test('two ranges use the "and" connector (no serial comma)', () {
      expect(
        formatToolConfirmation(en, [r(9, 0, 9, 25), r(15, 0, 15, 25)]),
        'Done: 09:00–09:25 and 15:00–15:25',
      );
    });

    test('three ranges serialize with comma + "and"', () {
      expect(
        formatToolConfirmation(en, [
          r(9, 0, 9, 25),
          r(11, 30, 12, 0),
          r(15, 0, 15, 25),
        ]),
        'Done: 09:00–09:25, 11:30–12:00 and 15:00–15:25',
      );
    });

    test('ranges past noon stay zero-padded', () {
      expect(
        formatToolConfirmation(en, [r(0, 5, 0, 30), r(23, 50, 23, 55)]),
        'Done: 00:05–00:30 and 23:50–23:55',
      );
    });
  });

  group('formatToolConfirmation (he)', () {
    test('empty renders the Hebrew confirmation', () {
      expect(formatToolConfirmation(he, const []), 'בוצע.');
    });

    test('two ranges use the Hebrew "ו-" connector', () {
      expect(
        formatToolConfirmation(he, [r(9, 0, 9, 25), r(15, 0, 15, 25)]),
        'בוצע: 09:00–09:25 ו-15:00–15:25',
      );
    });

    test('three ranges use comma + "ו-"', () {
      expect(
        formatToolConfirmation(he, [
          r(9, 0, 9, 25),
          r(11, 30, 12, 0),
          r(15, 0, 15, 25),
        ]),
        'בוצע: 09:00–09:25, 11:30–12:00 ו-15:00–15:25',
      );
    });
  });

  group('ScheduledRange value semantics', () {
    test('equal ranges compare equal and share a hashCode', () {
      final a = ScheduledRange(
        DateTime(2026, 11, 4, 9, 0),
        DateTime(2026, 11, 4, 9, 25),
      );
      final b = ScheduledRange(
        DateTime(2026, 11, 4, 9, 0),
        DateTime(2026, 11, 4, 9, 25),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different ranges are not equal', () {
      final a = ScheduledRange(
        DateTime(2026, 11, 4, 9, 0),
        DateTime(2026, 11, 4, 9, 25),
      );
      final b = ScheduledRange(
        DateTime(2026, 11, 4, 9, 0),
        DateTime(2026, 11, 4, 9, 30),
      );
      expect(a == b, isFalse);
    });
  });
}
