import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/l10n/bidi.dart';

void main() {
  group('Bidi.isolate', () {
    test('wraps text in FSI..PDI by default', () {
      expect(Bidi.isolate('John'), '⁨John⁩');
    });

    test('uses LRI when direction is ltr', () {
      expect(Bidi.isolate('John', direction: TextDirection.ltr), '⁦John⁩');
    });

    test('uses RLI when direction is rtl', () {
      expect(Bidi.isolate('שלום', direction: TextDirection.rtl), '⁧שלום⁩');
    });

    test('leaves the empty string alone', () {
      expect(Bidi.isolate(''), '');
      expect(Bidi.isolate('', direction: TextDirection.ltr), '');
    });
  });

  group('Bidi.hasHebrew / hasLatin', () {
    test('detects Hebrew letters', () {
      expect(Bidi.hasHebrew('שלום'), isTrue);
      expect(Bidi.hasHebrew('hello'), isFalse);
      expect(Bidi.hasHebrew('15:00'), isFalse);
    });

    test('detects Latin letters', () {
      expect(Bidi.hasLatin('John'), isTrue);
      expect(Bidi.hasLatin('שלום'), isFalse);
      expect(Bidi.hasLatin('15:00'), isFalse);
    });
  });

  group('Bidi.firstStrong', () {
    test('Hebrew paragraph is RTL', () {
      expect(Bidi.firstStrong('פגישה עם John'), TextDirection.rtl);
    });

    test('English paragraph is LTR', () {
      expect(Bidi.firstStrong('Meeting with דני'), TextDirection.ltr);
    });

    test('digits-only falls through to LTR', () {
      expect(Bidi.firstStrong('15:00'), TextDirection.ltr);
    });

    test('empty string falls through to LTR', () {
      expect(Bidi.firstStrong(''), TextDirection.ltr);
    });
  });

  group('Bidi.wrapLatinRuns', () {
    test('wraps a single Latin word', () {
      expect(Bidi.wrapLatinRuns('פגישה עם John'), 'פגישה עם ⁨John⁩');
    });

    test('wraps multiple Latin and digit runs', () {
      expect(
        Bidi.wrapLatinRuns('פגישה עם John ב-15:00'),
        'פגישה עם ⁨John⁩ ב-⁨15:00⁩',
      );
    });

    test('keeps a clock time as one run', () {
      // "15:00" contains an inner connector (":"), so the whole span
      // sits inside a single isolate — not two separate digit isolates.
      final out = Bidi.wrapLatinRuns('ב-15:00');
      expect(out, 'ב-⁨15:00⁩');
      expect('⁨'.allMatches(out).length, 1);
    });

    test('does not swallow trailing punctuation', () {
      // Trailing punctuation inside what would otherwise look like a
      // run must sit outside the isolate so the paragraph-level
      // punctuation stays at the paragraph level.
      expect(Bidi.wrapLatinRuns('John.'), '⁨John⁩.');
      expect(Bidi.wrapLatinRuns('John, '), '⁨John⁩, ');
    });

    test('returns the original string when no LTR runs are present', () {
      const only = 'שלום עולם';
      expect(identical(Bidi.wrapLatinRuns(only), only), isTrue);
    });

    test('leaves empty strings alone', () {
      expect(Bidi.wrapLatinRuns(''), '');
    });

    test('an all-Latin string ends up in a single isolate', () {
      expect(Bidi.wrapLatinRuns('Hello world'), '⁨Hello⁩ ⁨world⁩');
    });

    test('nothing in a wrapped string leaks across isolates', () {
      final out = Bidi.wrapLatinRuns('a שלום b');
      // Every ⁨ must be matched by a ⁩ before the next ⁨.
      var depth = 0;
      for (final r in out.runes) {
        if (r == 0x2068) depth++;
        if (r == 0x2069) depth--;
        expect(depth, inInclusiveRange(0, 1));
      }
      expect(depth, 0);
    });
  });

  group('Bidi constants', () {
    test('match the Unicode code points', () {
      expect(Bidi.fsi.codeUnitAt(0), 0x2068);
      expect(Bidi.pdi.codeUnitAt(0), 0x2069);
      expect(Bidi.lri.codeUnitAt(0), 0x2066);
      expect(Bidi.rli.codeUnitAt(0), 0x2067);
      expect(Bidi.lrm.codeUnitAt(0), 0x200E);
      expect(Bidi.rlm.codeUnitAt(0), 0x200F);
    });
  });
}
