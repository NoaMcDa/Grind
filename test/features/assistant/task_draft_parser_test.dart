import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/features/assistant/assistant.dart';

void main() {
  // A fixed "now" so weekday/tomorrow logic is deterministic.
  // 2026-11-04 is a Wednesday at 09:00 local.
  final now = DateTime(2026, 11, 4, 9, 0);
  const parser = TaskDraftParser();

  group('EN capture', () {
    test('canonical: gym tomorrow 7am, 45 min', () {
      final d = parser.parse('gym tomorrow 7am, 45 min', now: now);
      expect(d.title.toLowerCase(), 'gym');
      expect(d.date, '2026-11-05');
      expect(d.time, '07:00');
      expect(d.durationMinutes, 45);
      expect(d.energy, Energy.light);
    });

    test('today with 24h time', () {
      final d = parser.parse('call mom today 19:00', now: now);
      expect(d.title.toLowerCase(), 'call mom');
      expect(d.date, '2026-11-04');
      expect(d.time, '19:00');
    });

    test('duration "1 hour 30 min"', () {
      final d = parser.parse('write thesis 1 hour 30 min', now: now);
      expect(d.durationMinutes, 90);
      expect(d.energy, Energy.deep);
    });

    test('duration "1h30m"', () {
      final d = parser.parse('study calculus 1h30m', now: now);
      expect(d.durationMinutes, 90);
    });

    test('duration "half an hour"', () {
      final d = parser.parse('meditation half an hour tomorrow', now: now);
      expect(d.durationMinutes, 30);
      expect(d.date, '2026-11-05');
    });

    test('tonight → today 20:00', () {
      final d = parser.parse('dinner tonight', now: now);
      expect(d.date, '2026-11-04');
      expect(d.time, '20:00');
    });

    test('bare weekday — next occurrence', () {
      // Today is Wed; next Friday = 2 days ahead.
      final d = parser.parse('yoga friday 6pm', now: now);
      expect(d.date, '2026-11-06');
      expect(d.time, '18:00');
    });

    test('next monday jumps a full week', () {
      // Today is Wed. Normal "monday" would be 5 days out (Nov 9).
      // "next monday" means the following week (Nov 16).
      final d = parser.parse('groceries next monday', now: now);
      expect(d.date, '2026-11-16');
    });

    test('at 7 + "tonight" nudges to PM', () {
      final d = parser.parse('gym tonight at 7', now: now);
      expect(d.date, '2026-11-04');
      expect(d.time, '19:00');
    });

    test('plain "at 7" (morning) stays AM when no evening hint', () {
      final d = parser.parse('standup at 7 tomorrow', now: now);
      expect(d.date, '2026-11-05');
      expect(d.time, '07:00');
    });

    test('in 3 days', () {
      final d = parser.parse('renew passport in 3 days', now: now);
      expect(d.date, '2026-11-07');
    });

    test('in 2 weeks', () {
      final d = parser.parse('renew passport in 2 weeks', now: now);
      expect(d.date, '2026-11-18');
    });

    test('in 1 week', () {
      final d = parser.parse('follow up in 1 week', now: now);
      expect(d.date, '2026-11-11');
    });

    test('in a week', () {
      final d = parser.parse('follow up in a week', now: now);
      expect(d.date, '2026-11-11');
    });

    test('in 2 months', () {
      final d = parser.parse('quarterly review in 2 months', now: now);
      expect(d.date, '2027-01-04');
    });

    test('in a month clamps to last day when needed', () {
      // "in a month" from Jan 31 must not overflow into March.
      final jan31 = DateTime(2027, 1, 31, 9);
      final d = parser.parse('rotate certs in a month', now: jan31);
      expect(d.date, '2027-02-28');
    });

    test('every day → daily RRULE', () {
      final d = parser.parse('meditation every day 10 min', now: now);
      expect(d.recurrenceRrule, contains('FREQ=DAILY'));
      expect(d.durationMinutes, 10);
    });

    test('every monday → weekly BYDAY=MO', () {
      final d = parser.parse('team sync every monday 9am 30 min', now: now);
      expect(d.recurrenceRrule, contains('FREQ=WEEKLY'));
      expect(d.recurrenceRrule, contains('BYDAY=MO'));
      expect(d.time, '09:00');
    });

    test('weekdays preset', () {
      final d = parser.parse('journal every weekday 7am', now: now);
      expect(d.recurrenceRrule, contains('FREQ=WEEKLY'));
      expect(d.recurrenceRrule, contains('BYDAY=MO,TU,WE,TH,FR'));
    });

    test('no explicit date and time already past → bump to tomorrow', () {
      // now is 09:00; "run at 7am" would already be in the past.
      final d = parser.parse('run at 7am', now: now);
      expect(d.date, '2026-11-05');
      expect(d.time, '07:00');
    });

    test('no date, future time, no bump', () {
      final d = parser.parse('coffee at 11am', now: now);
      expect(d.date, '2026-11-04');
      expect(d.time, '11:00');
    });

    test('no date and no time → date is null', () {
      final d = parser.parse('buy a notebook', now: now);
      expect(d.date, isNull);
      expect(d.time, isNull);
      expect(d.title.toLowerCase(), 'buy notebook');
    });

    test('12-hour pm', () {
      final d = parser.parse('standup today 2:30pm', now: now);
      expect(d.time, '14:30');
    });

    test('deep hint sets energy', () {
      final d = parser.parse('focus work tomorrow 9am 90 min', now: now);
      expect(d.energy, Energy.deep);
    });

    test('empty input throws', () {
      expect(() => parser.parse('', now: now), throwsFormatException);
      expect(() => parser.parse('   ', now: now), throwsFormatException);
    });
  });

  group('HE capture', () {
    test('canonical HE: מחר ב-7 חדר כושר 45 דקות', () {
      final d = parser.parse(
        'חדר כושר מחר ב-7 45 דקות',
        now: now,
        locale: 'he',
      );
      expect(d.date, '2026-11-05');
      expect(d.time, '07:00');
      expect(d.durationMinutes, 45);
      expect(d.title, contains('חדר כושר'));
    });

    test('היום בשעה 19:00', () {
      final d = parser.parse(
        'לקרוא ספר היום בשעה 19:00',
        now: now,
        locale: 'he',
      );
      expect(d.date, '2026-11-04');
      expect(d.time, '19:00');
    });

    test('הערב — today 20:00', () {
      final d = parser.parse('ארוחת ערב עם סבתא הערב', now: now, locale: 'he');
      expect(d.date, '2026-11-04');
      expect(d.time, '20:00');
    });

    test('מחרתיים', () {
      final d = parser.parse('רופא שיניים מחרתיים', now: now, locale: 'he');
      expect(d.date, '2026-11-06');
    });

    test('ביום שישי', () {
      // Wed → Fri = 2 days ahead.
      final d = parser.parse('יוגה ביום שישי', now: now, locale: 'he');
      expect(d.date, '2026-11-06');
    });

    test('בעוד 3 ימים', () {
      final d = parser.parse('לחדש דרכון בעוד 3 ימים', now: now, locale: 'he');
      expect(d.date, '2026-11-07');
    });

    test('בעוד שבוע → +7 days', () {
      final d = parser.parse('לחדש דרכון בעוד שבוע', now: now, locale: 'he');
      expect(d.date, '2026-11-11');
    });

    test('בעוד שבועיים → +14 days', () {
      final d = parser.parse('לחדש דרכון בעוד שבועיים', now: now, locale: 'he');
      expect(d.date, '2026-11-18');
    });

    test('בעוד 3 שבועות → +21 days', () {
      final d = parser.parse('חופש בעוד 3 שבועות', now: now, locale: 'he');
      expect(d.date, '2026-11-25');
    });

    test('בעוד חודש → +1 month', () {
      final d = parser.parse('מנוי בעוד חודש', now: now, locale: 'he');
      expect(d.date, '2026-12-04');
    });

    test('בעוד חודשיים → +2 months', () {
      final d = parser.parse('ביקורת בעוד חודשיים', now: now, locale: 'he');
      expect(d.date, '2027-01-04');
    });

    test('שעה וחצי', () {
      final d = parser.parse('לרוץ מחר שעה וחצי', now: now, locale: 'he');
      expect(d.durationMinutes, 90);
    });

    test('חצי שעה', () {
      final d = parser.parse('מדיטציה מחר ב-7 חצי שעה', now: now, locale: 'he');
      expect(d.durationMinutes, 30);
    });

    test('כל יום → daily RRULE', () {
      final d = parser.parse('מדיטציה כל יום 10 דקות', now: now, locale: 'he');
      expect(d.recurrenceRrule, contains('FREQ=DAILY'));
    });

    test('ב-7 with evening hint → PM', () {
      final d = parser.parse('ריצה הערב ב-7', now: now, locale: 'he');
      expect(d.time, '19:00');
    });
  });

  group('if-then first action (EN)', () {
    test('trailing if-then clause is extracted and stripped from title', () {
      final d = parser.parse(
        'gym tomorrow 7am 45 min, if alarm rings then lace up',
        now: now,
      );
      expect(d.title.toLowerCase(), 'gym');
      expect(d.date, '2026-11-05');
      expect(d.time, '07:00');
      expect(d.durationMinutes, 45);
      expect(d.firstAction, 'If alarm rings, then lace up');
    });

    test('comma between if-clause and then is preserved in output', () {
      final d = parser.parse(
        "thesis tomorrow 90 min, if it's 17:00, then pack your bag",
        now: now,
      );
      expect(d.firstAction, "If it's 17:00, then pack your bag");
      // The 17:00 inside the clause must NOT become the task time.
      expect(d.time, isNull);
      expect(d.durationMinutes, 90);
    });

    test('bare "if ... then ..." without punctuation', () {
      final d = parser.parse(
        'review tomorrow if lunch is over then open the notebook',
        now: now,
      );
      expect(d.firstAction, 'If lunch is over, then open the notebook');
      expect(d.title.toLowerCase(), 'review');
      expect(d.date, '2026-11-05');
    });

    test('no if-then → firstAction is null', () {
      final d = parser.parse('gym tomorrow 7am', now: now);
      expect(d.firstAction, isNull);
    });

    test('"wife" / "then" false positives do not trigger', () {
      // "if" is a word; "wife" has "if" inside but no word boundary.
      // Also, "then" alone (no "if") is not enough.
      final d = parser.parse('call wife then relax', now: now);
      expect(d.firstAction, isNull);
      expect(d.title.toLowerCase(), contains('wife'));
    });
  });

  group('if-then first action (HE)', () {
    test('"אם ... אז ..." is extracted', () {
      final d = parser.parse(
        'חדר כושר מחר ב-7, אם המתיחה נעימה אז לצאת לריצה',
        now: now,
        locale: 'he',
      );
      expect(d.firstAction, 'אם המתיחה נעימה, אז לצאת לריצה');
      expect(d.date, '2026-11-05');
      expect(d.time, '07:00');
      expect(d.title, contains('חדר כושר'));
    });

    test('time inside the condition is not taken as schedule', () {
      final d = parser.parse(
        'לפתוח את התזה מחר אם השעה 17:00, אז לארוז תיק',
        now: now,
        locale: 'he',
      );
      expect(d.firstAction, 'אם השעה 17:00, אז לארוז תיק');
      expect(d.time, isNull);
      expect(d.date, '2026-11-05');
    });

    test('no "אז" marker → firstAction is null', () {
      final d = parser.parse('לקרוא ספר אם יש זמן', now: now, locale: 'he');
      expect(d.firstAction, isNull);
    });
  });
}
