// Regression / eval set for the offline capture parser (#39).
//
// A table of ~50 real-world phrases per language with the fields the
// parser is expected to emit. Each row becomes a test, so a regression
// in the fallback parser surfaces by phrase. Keep the table growing:
// when a user phrase slips through capture, add it here with the draft
// we want next time.
//
// The LLM path has its own (manual) evals; this file is the floor the
// product sits on and must keep green in CI.

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/features/assistant/assistant.dart';

void main() {
  // Deterministic "now": Wednesday 2026-11-04 at 09:00 local. Same anchor
  // as `task_draft_parser_test.dart`, so weekday and past-time-bump logic
  // is reproducible.
  final now = DateTime(2026, 11, 4, 9, 0);
  const parser = TaskDraftParser();

  group('EN eval set', () {
    for (final c in _enCases) {
      test(c.input, () => _check(parser, c, now, locale: 'en'));
    }

    test('covers at least 50 phrases', () {
      expect(_enCases.length, greaterThanOrEqualTo(50));
    });

    test('phrases are unique', () {
      final seen = <String>{};
      for (final c in _enCases) {
        expect(seen.add(c.input), isTrue, reason: 'duplicate: "${c.input}"');
      }
    });
  });

  group('HE eval set', () {
    for (final c in _heCases) {
      test(c.input, () => _check(parser, c, now, locale: 'he'));
    }

    test('covers at least 50 phrases', () {
      expect(_heCases.length, greaterThanOrEqualTo(50));
    });

    test('phrases are unique', () {
      final seen = <String>{};
      for (final c in _heCases) {
        expect(seen.add(c.input), isTrue, reason: 'duplicate: "${c.input}"');
      }
    });
  });
}

void _check(
  TaskDraftParser parser,
  _Case c,
  DateTime now, {
  required String locale,
}) {
  final d = parser.parse(c.input, now: now, locale: locale);
  if (c.date != null) {
    expect(d.date, c.date, reason: 'date for "${c.input}"');
  }
  if (c.noDate) {
    expect(d.date, isNull, reason: 'date for "${c.input}"');
  }
  if (c.time != null) {
    expect(d.time, c.time, reason: 'time for "${c.input}"');
  }
  if (c.noTime) {
    expect(d.time, isNull, reason: 'time for "${c.input}"');
  }
  if (c.duration != null) {
    expect(d.durationMinutes, c.duration, reason: 'duration for "${c.input}"');
  }
  if (c.energy != null) {
    expect(d.energy, c.energy, reason: 'energy for "${c.input}"');
  }
  for (final r in c.rruleContains) {
    expect(
      d.recurrenceRrule,
      isNotNull,
      reason: 'rrule missing for "${c.input}"',
    );
    expect(
      d.recurrenceRrule,
      contains(r),
      reason: 'rrule for "${c.input}" should contain "$r"',
    );
  }
  if (c.titleContains != null) {
    expect(
      d.title.toLowerCase(),
      contains(c.titleContains!.toLowerCase()),
      reason: 'title for "${c.input}"',
    );
  }
}

/// A row of the eval table. Only the fields a row explicitly names are
/// asserted — other fields are left to the parser's discretion so adding
/// a small heuristic later (e.g. an energy hint) does not retro-break the
/// table.
class _Case {
  const _Case({
    required this.input,
    this.date,
    this.time,
    this.duration,
    this.energy,
    this.rruleContains = const <String>[],
    this.titleContains,
    this.noDate = false,
    this.noTime = false,
  });

  /// The phrase fed to the parser.
  final String input;

  /// Expected `YYYY-MM-DD`; null skips the date check.
  final String? date;

  /// Expected `HH:MM`; null skips the time check.
  final String? time;

  /// Expected minutes; null skips the duration check.
  final int? duration;

  /// Expected energy; null skips the energy check.
  final Energy? energy;

  /// Substrings every one of which must appear in the rrule.
  final List<String> rruleContains;

  /// Case-insensitive title substring; null skips the title check.
  final String? titleContains;

  /// True asserts the draft has no date.
  final bool noDate;

  /// True asserts the draft has no time.
  final bool noTime;
}

// --------------------------------- EN ---------------------------------- //

const _enCases = <_Case>[
  // Canonical epic phrase.
  _Case(
    input: 'gym tomorrow 7am, 45 min',
    date: '2026-11-05',
    time: '07:00',
    duration: 45,
    energy: Energy.light,
    titleContains: 'gym',
  ),
  _Case(
    input: 'yoga friday 6pm',
    date: '2026-11-06',
    time: '18:00',
    titleContains: 'yoga',
  ),
  _Case(
    input: 'call mom today 19:00',
    date: '2026-11-04',
    time: '19:00',
    energy: Energy.light,
    titleContains: 'call mom',
  ),
  _Case(
    input: 'dinner tonight',
    date: '2026-11-04',
    time: '20:00',
    titleContains: 'dinner',
  ),
  _Case(
    // No explicit date; the time is already past today → bump to tomorrow.
    input: 'run at 7am',
    date: '2026-11-05',
    time: '07:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'coffee at 11am',
    date: '2026-11-04',
    time: '11:00',
    titleContains: 'coffee',
  ),
  _Case(
    input: 'groceries next monday',
    date: '2026-11-16',
    energy: Energy.light,
    titleContains: 'groceries',
  ),
  _Case(
    input: 'renew passport in 3 days',
    date: '2026-11-07',
    titleContains: 'renew passport',
  ),
  _Case(
    input: 'meditation every day 10 min',
    duration: 10,
    rruleContains: ['FREQ=DAILY'],
    titleContains: 'meditation',
  ),
  _Case(
    input: 'team sync every monday 9am 30 min',
    time: '09:00',
    duration: 30,
    rruleContains: ['FREQ=WEEKLY', 'BYDAY=MO'],
    titleContains: 'team sync',
  ),
  _Case(
    input: 'journal every weekday 7am',
    time: '07:00',
    rruleContains: ['FREQ=WEEKLY', 'BYDAY=MO,TU,WE,TH,FR'],
    titleContains: 'journal',
  ),
  _Case(
    input: 'standup today 2:30pm',
    date: '2026-11-04',
    time: '14:30',
    titleContains: 'standup',
  ),
  _Case(
    input: 'focus work tomorrow 9am 90 min',
    date: '2026-11-05',
    time: '09:00',
    duration: 90,
    energy: Energy.deep,
  ),
  _Case(
    input: 'buy a notebook',
    noDate: true,
    noTime: true,
    titleContains: 'buy notebook',
  ),
  _Case(
    input: 'walk the dog tomorrow morning',
    date: '2026-11-05',
    time: '09:00',
    energy: Energy.light,
    titleContains: 'dog',
  ),
  _Case(
    input: 'write chapter 3 tomorrow 2 hours',
    date: '2026-11-05',
    duration: 120,
    energy: Energy.deep,
  ),
  _Case(
    input: 'laundry saturday',
    date: '2026-11-07',
    energy: Energy.light,
    titleContains: 'laundry',
  ),
  _Case(
    input: 'study calculus wednesday 1 hour',
    date: '2026-11-04',
    duration: 60,
    energy: Energy.deep,
  ),
  _Case(
    input: 'call dentist tomorrow 10am',
    date: '2026-11-05',
    time: '10:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'deep work this friday 90 minutes',
    date: '2026-11-06',
    duration: 90,
    energy: Energy.deep,
  ),
  _Case(
    input: 'pick up kids at 3pm',
    date: '2026-11-04',
    time: '15:00',
    titleContains: 'kids',
  ),
  _Case(
    // "tonight" supplies the evening hint, then bare "at 7" is nudged PM.
    input: 'pay bills tonight at 7',
    date: '2026-11-04',
    time: '19:00',
    titleContains: 'pay bills',
  ),
  _Case(
    input: 'code review tomorrow 45 min',
    date: '2026-11-05',
    duration: 45,
    energy: Energy.deep,
  ),
  _Case(
    input: 'shopping saturday afternoon',
    date: '2026-11-07',
    time: '14:00',
    energy: Energy.light,
    titleContains: 'shopping',
  ),
  _Case(
    input: 'dentist appointment next tuesday 10am',
    date: '2026-11-17',
    time: '10:00',
    titleContains: 'dentist',
  ),
  _Case(
    input: 'haircut in 2 days',
    date: '2026-11-06',
    titleContains: 'haircut',
  ),
  _Case(
    input: 'errands sunday',
    date: '2026-11-08',
    energy: Energy.light,
    titleContains: 'errands',
  ),
  _Case(
    input: 'team retro next friday',
    date: '2026-11-13',
    titleContains: 'team retro',
  ),
  _Case(
    input: 'weekly review every sunday 30 min',
    duration: 30,
    rruleContains: ['FREQ=WEEKLY', 'BYDAY=SU'],
  ),
  _Case(
    input: 'monthly budget review monthly',
    rruleContains: ['FREQ=MONTHLY'],
  ),
  _Case(
    input: 'quick call at 2pm',
    date: '2026-11-04',
    time: '14:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'read chapter 4 half an hour tomorrow',
    date: '2026-11-05',
    duration: 30,
  ),
  _Case(
    input: 'evening walk',
    date: '2026-11-04',
    time: '19:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'lunch at noon',
    date: '2026-11-04',
    time: '12:00',
    titleContains: 'lunch',
  ),
  _Case(
    // midnight is 00:00; already past 09:00 today → bumps to tomorrow.
    input: 'midnight deployment',
    date: '2026-11-05',
    time: '00:00',
    titleContains: 'deployment',
  ),
  _Case(
    input: 'demo fri 10am',
    date: '2026-11-06',
    time: '10:00',
    titleContains: 'demo',
  ),
  _Case(
    input: 'gym tue 7am 45 min',
    date: '2026-11-10',
    time: '07:00',
    duration: 45,
    energy: Energy.light,
  ),
  _Case(
    input: 'focus block tomorrow 2 hours',
    date: '2026-11-05',
    duration: 120,
    energy: Energy.deep,
  ),
  _Case(
    input: 'call clients tomorrow at 11',
    date: '2026-11-05',
    time: '11:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'take vitamins every day',
    rruleContains: ['FREQ=DAILY'],
    titleContains: 'vitamins',
  ),
  _Case(
    input: 'update budget this friday 30 min',
    date: '2026-11-06',
    duration: 30,
    titleContains: 'update budget',
  ),
  _Case(
    input: 'send invoice tomorrow 9:00',
    date: '2026-11-05',
    time: '09:00',
    titleContains: 'send invoice',
  ),
  _Case(input: 'jog 6am tomorrow', date: '2026-11-05', time: '06:00'),
  _Case(
    input: 'evening yoga 30 min',
    date: '2026-11-04',
    time: '19:00',
    duration: 30,
    titleContains: 'yoga',
  ),
  _Case(
    input: 'pay rent in 5 days',
    date: '2026-11-09',
    titleContains: 'pay rent',
  ),
  _Case(
    input: 'pack suitcase tomorrow night',
    date: '2026-11-05',
    time: '21:00',
    titleContains: 'pack suitcase',
  ),
  _Case(
    input: 'sleep by 11pm',
    date: '2026-11-04',
    time: '23:00',
    titleContains: 'sleep',
  ),
  _Case(
    input: 'water the plants every day',
    rruleContains: ['FREQ=DAILY'],
    titleContains: 'water',
  ),
  _Case(
    input: 'quarterly review in 10 days',
    date: '2026-11-14',
    titleContains: 'quarterly review',
  ),
  _Case(
    input: 'daily standup 9am',
    time: '09:00',
    rruleContains: ['FREQ=DAILY'],
    titleContains: 'standup',
  ),
];

// --------------------------------- HE ---------------------------------- //

const _heCases = <_Case>[
  // Canonical epic phrase (Hebrew).
  _Case(
    input: 'חדר כושר מחר ב-7 45 דקות',
    date: '2026-11-05',
    time: '07:00',
    duration: 45,
    energy: Energy.light,
  ),
  _Case(input: 'לרוץ מחר שעה וחצי', date: '2026-11-05', duration: 90),
  _Case(input: 'ארוחת ערב עם סבתא הערב', date: '2026-11-04', time: '20:00'),
  _Case(input: 'רופא שיניים מחרתיים', date: '2026-11-06'),
  _Case(input: 'יוגה ביום שישי', date: '2026-11-06'),
  _Case(input: 'לחדש דרכון בעוד 3 ימים', date: '2026-11-07'),
  _Case(
    input: 'ריצה הערב ב-7',
    date: '2026-11-04',
    time: '19:00',
    energy: Energy.light,
  ),
  _Case(input: 'פגישה היום ב-10', date: '2026-11-04', time: '10:00'),
  _Case(
    input: 'מדיטציה כל יום 10 דקות',
    duration: 10,
    rruleContains: ['FREQ=DAILY'],
  ),
  _Case(input: 'לקרוא ספר היום בשעה 19:00', date: '2026-11-04', time: '19:00'),
  _Case(input: 'כביסה היום', date: '2026-11-04', energy: Energy.light),
  _Case(input: 'קניות מחר', date: '2026-11-05', energy: Energy.light),
  _Case(input: 'ישיבה היום 14:00', date: '2026-11-04', time: '14:00'),
  _Case(
    input: 'קוד מחר שעה וחצי בבוקר',
    date: '2026-11-05',
    time: '09:00',
    duration: 90,
    energy: Energy.deep,
  ),
  _Case(input: 'כתיבת תזה 2 שעות', duration: 120, energy: Energy.deep),
  _Case(
    // "חדר כושר" (gym) is kept unprefixed so the lightHint matches; the
    // "ל" particle on "לחדר" blocks the Hebrew word boundary today.
    input: 'ללכת חדר כושר מחר ב-6',
    date: '2026-11-05',
    time: '06:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'תזה מחר 90 דקות',
    date: '2026-11-05',
    duration: 90,
    energy: Energy.deep,
  ),
  _Case(
    input: 'פגישה עם המנהל ביום שלישי ב-15:00',
    date: '2026-11-10',
    time: '15:00',
  ),
  _Case(input: 'כביסה שישי', date: '2026-11-06', energy: Energy.light),
  _Case(
    input: 'הליכה כל יום',
    rruleContains: ['FREQ=DAILY'],
    energy: Energy.light,
  ),
  _Case(input: 'מדיטציה בוקר', time: '09:00'),
  _Case(
    input: 'קניות מחר בערב',
    date: '2026-11-05',
    time: '19:00',
    energy: Energy.light,
  ),
  _Case(input: 'פגישה עם רופא בעוד 5 ימים', date: '2026-11-09'),
  _Case(input: 'טיפול מחר ב-11:30', date: '2026-11-05', time: '11:30'),
  _Case(input: 'לרוץ ביום רביעי ב-6 בערב', date: '2026-11-04', time: '18:00'),
  _Case(
    input: 'ריצה מחרתיים בבוקר',
    date: '2026-11-06',
    time: '09:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'קוד 3 שעות היום',
    date: '2026-11-04',
    duration: 180,
    energy: Energy.deep,
  ),
  _Case(input: 'פגישה ביום חמישי 10:00', date: '2026-11-05', time: '10:00'),
  _Case(
    input: 'שיחה עם לקוח הערב',
    date: '2026-11-04',
    time: '20:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'לימודים אחה״צ שעתיים',
    time: '14:00',
    duration: 120,
    energy: Energy.deep,
  ),
  _Case(input: 'לפגוש חבר הערב ב-7', date: '2026-11-04', time: '19:00'),
  _Case(
    input: 'פגישת עבודה ב-14:00 היום',
    date: '2026-11-04',
    time: '14:00',
    energy: Energy.deep,
  ),
  _Case(input: 'קניות ביום ראשון', date: '2026-11-08', energy: Energy.light),
  _Case(input: 'ישיבת צוות בעוד 2 ימים', date: '2026-11-06'),
  _Case(
    input: 'פגישה עם הרופא ביום שני ב-9:30',
    date: '2026-11-09',
    time: '09:30',
  ),
  _Case(input: 'ריצה ביום שלישי', date: '2026-11-10', energy: Energy.light),
  _Case(input: 'לקנות חלב מחר', date: '2026-11-05'),
  _Case(
    input: 'תזה 90 דקות היום',
    date: '2026-11-04',
    duration: 90,
    energy: Energy.deep,
  ),
  _Case(input: 'ישיבה בשעה 10', date: '2026-11-04', time: '10:00'),
  _Case(input: 'פגישה חמישי ב-10', date: '2026-11-05', time: '10:00'),
  _Case(
    input: 'אימון ריצה הלילה',
    date: '2026-11-04',
    time: '21:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'קוד תזה מחר 2 שעות בבוקר',
    date: '2026-11-05',
    time: '09:00',
    duration: 120,
    energy: Energy.deep,
  ),
  _Case(input: 'ישיבה ביום שלישי הבא', date: '2026-11-17'),
  _Case(input: 'מדיטציה חצי שעה', duration: 30),
  _Case(input: 'ריצה רבע שעה', duration: 15, energy: Energy.light),
  _Case(input: 'פגישה מחר ב-9 בבוקר', date: '2026-11-05', time: '09:00'),
  _Case(input: 'לימודי חשבון ב-20:00 היום', date: '2026-11-04', time: '20:00'),
  _Case(
    input: 'קניות בקניון הערב',
    date: '2026-11-04',
    time: '20:00',
    energy: Energy.light,
  ),
  _Case(
    input: 'מחר ב-7 בערב ללכת חדר כושר 45 דקות',
    date: '2026-11-05',
    time: '19:00',
    duration: 45,
    energy: Energy.light,
  ),
  _Case(input: 'לקרוא ספר 30 דקות היום', date: '2026-11-04', duration: 30),
];
