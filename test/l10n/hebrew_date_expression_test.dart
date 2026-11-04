import 'package:flutter_test/flutter_test.dart';
import 'package:grind/l10n/hebrew_date_expression.dart';

void main() {
  // Monday 2026-04-20 at 09:00 local. Dates stay inside a single month
  // so a "בעוד N ימים" delta lands cleanly on the same calendar page.
  final now = DateTime(2026, 4, 20, 9, 0);

  group('parseHebrewDateExpression — day keywords', () {
    test('"היום" without a time returns midnight today', () {
      final r = parseHebrewDateExpression('היום', now: now);
      expect(r, isNotNull);
      expect(r!.resolved, DateTime(2026, 4, 20));
      expect(r.dayKeyword, 'היום');
      expect(r.time, isNull);
      expect(r.deltaMinutes, isNull);
    });

    test('"מחר" without a time returns midnight tomorrow', () {
      final r = parseHebrewDateExpression('מחר', now: now);
      expect(r!.resolved, DateTime(2026, 4, 21));
      expect(r.dayKeyword, 'מחר');
    });

    test('"מחרתיים" returns midnight two days out', () {
      final r = parseHebrewDateExpression('מחרתיים', now: now);
      expect(r!.resolved, DateTime(2026, 4, 22));
      expect(r.dayKeyword, 'מחרתיים');
    });

    test('"מחרתיים" is not swallowed as "מחר"', () {
      final r = parseHebrewDateExpression('מחרתיים ב-10', now: now);
      expect(r!.dayKeyword, 'מחרתיים');
      expect(r.resolved, DateTime(2026, 4, 22, 10));
    });

    test('"מחר ב-7" combines keyword and time', () {
      final r = parseHebrewDateExpression('מחר ב-7', now: now);
      expect(r!.resolved, DateTime(2026, 4, 21, 7));
      expect(r.time, const HebrewTimeOfDay(7, 0));
    });

    test('"מחר ב-7:30" picks the explicit minute', () {
      final r = parseHebrewDateExpression('מחר ב-7:30', now: now);
      expect(r!.resolved, DateTime(2026, 4, 21, 7, 30));
      expect(r.time, const HebrewTimeOfDay(7, 30));
    });

    test('"היום בשעה 20:30" combines keyword and 24h time', () {
      final r = parseHebrewDateExpression('היום בשעה 20:30', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 20, 30));
      expect(r.time, const HebrewTimeOfDay(20, 30));
    });

    test('"מחר בשעה 7" with no colon still parses', () {
      final r = parseHebrewDateExpression('מחר בשעה 7', now: now);
      expect(r!.resolved, DateTime(2026, 4, 21, 7));
    });

    test('"הערב" implies 20:00 today', () {
      final r = parseHebrewDateExpression('הערב', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 20));
      expect(r.time, const HebrewTimeOfDay(20, 0));
      expect(r.dayKeyword, 'הערב');
    });

    test('"הלילה" implies 21:00 today', () {
      final r = parseHebrewDateExpression('הלילה', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 21));
      expect(r.time, const HebrewTimeOfDay(21, 0));
    });

    test('an explicit time wins over "הערב"\'s implied 20:00', () {
      final r = parseHebrewDateExpression('הערב בשעה 22', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 22));
      expect(r.time, const HebrewTimeOfDay(22, 0));
    });

    test('"בבוקר" implies 09:00 today', () {
      final r = parseHebrewDateExpression('בבוקר', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 9));
    });

    test('"בצהריים" implies 12:00 today', () {
      final r = parseHebrewDateExpression('בצהריים', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 12));
    });

    test('out-of-range hour rejects the time, keeps the day', () {
      // "ב-25" is not a valid hour; the time is dropped and the day
      // keyword survives on its own at midnight.
      final r = parseHebrewDateExpression('מחר ב-25', now: now);
      expect(r, isNotNull);
      expect(r!.resolved, DateTime(2026, 4, 21));
      expect(r.time, isNull);
    });
  });

  group('parseHebrewDateExpression — relative deltas', () {
    test('"בעוד 20 דקות" adds 20 minutes to now', () {
      final r = parseHebrewDateExpression('בעוד 20 דקות', now: now);
      expect(r, isNotNull);
      expect(r!.resolved, DateTime(2026, 4, 20, 9, 20));
      expect(r.deltaMinutes, 20);
      expect(r.dayKeyword, isNull);
      expect(r.time, isNull);
    });

    test('"בעוד שעה" adds one hour', () {
      final r = parseHebrewDateExpression('בעוד שעה', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 10));
      expect(r.deltaMinutes, 60);
    });

    test('"בעוד שעתיים" adds two hours', () {
      final r = parseHebrewDateExpression('בעוד שעתיים', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 11));
      expect(r.deltaMinutes, 120);
    });

    test('"בעוד חצי שעה" adds 30 minutes', () {
      final r = parseHebrewDateExpression('בעוד חצי שעה', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 9, 30));
      expect(r.deltaMinutes, 30);
    });

    test('"בעוד רבע שעה" adds 15 minutes', () {
      final r = parseHebrewDateExpression('בעוד רבע שעה', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 9, 15));
      expect(r.deltaMinutes, 15);
    });

    test('"בעוד שעה וחצי" adds 90 minutes', () {
      final r = parseHebrewDateExpression('בעוד שעה וחצי', now: now);
      expect(r!.resolved, DateTime(2026, 4, 20, 10, 30));
      expect(r.deltaMinutes, 90);
    });

    test('"בעוד 3 ימים" adds three days', () {
      final r = parseHebrewDateExpression('בעוד 3 ימים', now: now);
      expect(r!.resolved, DateTime(2026, 4, 23, 9));
      expect(r.deltaMinutes, 3 * 24 * 60);
    });

    test('"בעוד יומיים" adds two days', () {
      final r = parseHebrewDateExpression('בעוד יומיים', now: now);
      expect(r!.resolved, DateTime(2026, 4, 22, 9));
      expect(r.deltaMinutes, 2 * 24 * 60);
    });

    test('"בעוד שבוע" adds seven days', () {
      final r = parseHebrewDateExpression('בעוד שבוע', now: now);
      expect(r!.resolved, DateTime(2026, 4, 27, 9));
      expect(r.deltaMinutes, 7 * 24 * 60);
    });

    test('"בעוד שבועיים" adds fourteen days', () {
      final r = parseHebrewDateExpression('בעוד שבועיים', now: now);
      expect(r!.resolved, DateTime(2026, 5, 4, 9));
      expect(r.deltaMinutes, 14 * 24 * 60);
    });

    test('a relative phrase ignores any day keyword in the tail', () {
      // "בעוד" wins over the trailing "היום" — the relative delta is
      // the strong signal, and the stray "היום" is noise to ignore.
      final r = parseHebrewDateExpression('בעוד שעה היום', now: now);
      expect(r!.deltaMinutes, 60);
      expect(r.dayKeyword, isNull);
    });
  });

  group('parseHebrewDateExpression — null / edge cases', () {
    test('empty input returns null', () {
      expect(parseHebrewDateExpression('', now: now), isNull);
    });

    test('whitespace-only input returns null', () {
      expect(parseHebrewDateExpression('   \n\t', now: now), isNull);
    });

    test('phrase without a date or delta returns null', () {
      expect(parseHebrewDateExpression('שלום עולם', now: now), isNull);
    });

    test('a pure time with no day keyword returns null', () {
      // The caller should feed it to a time-only parser; this function
      // reports "nothing anchored" instead of inventing a date.
      expect(parseHebrewDateExpression('ב-7', now: now), isNull);
    });

    test('"בעוד" without a unit returns null', () {
      expect(parseHebrewDateExpression('בעוד', now: now), isNull);
    });

    test('trailing full stop and spaces are ignored', () {
      final r = parseHebrewDateExpression('  מחר ב-7.  ', now: now);
      expect(r!.resolved, DateTime(2026, 4, 21, 7));
    });

    test('mid-word match is rejected (keyword is not a substring)', () {
      // "ההיום" is not "היום"; the leading extra letter must not match.
      final r = parseHebrewDateExpression('ההיום', now: now);
      expect(r, isNull);
    });
  });

  group('HebrewDateExpression and HebrewTimeOfDay value semantics', () {
    test('equal expressions compare and hash alike', () {
      final a = parseHebrewDateExpression('מחר ב-7', now: now);
      final b = parseHebrewDateExpression('מחר ב-7', now: now);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('HebrewTimeOfDay equality', () {
      expect(const HebrewTimeOfDay(7, 30), const HebrewTimeOfDay(7, 30));
      expect(
        const HebrewTimeOfDay(7, 30).hashCode,
        const HebrewTimeOfDay(7, 30).hashCode,
      );
      expect(
        const HebrewTimeOfDay(7, 30) == const HebrewTimeOfDay(7, 31),
        isFalse,
      );
    });

    test('HebrewTimeOfDay.toString is zero-padded', () {
      expect(
        const HebrewTimeOfDay(7, 5).toString(),
        'HebrewTimeOfDay(07:05)',
      );
    });
  });
}
