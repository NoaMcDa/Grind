import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/plan/plan_l10n.dart';
import 'package:grind/features/plan/plan_reasons_l10n.dart';
import 'package:grind/l10n/l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final he = lookupAppLocalizations(const Locale('he'));

  test('known scheduler templates round-trip in English', () {
    const same = [
      'you placed this here',
      'your focus window',
      'due today',
      'due tomorrow',
      'due Thursday',
      'part of Thesis',
      'first 45 of 90 min',
      'next 45 of 90 min',
      'last 30 of 90 min',
      'earliest free 25-minute gap',
      "earliest free 25-minute gap before today's deadline",
      'earliest free 25-minute gap before the Thursday deadline',
      'the due date has passed, want to pick a new one?',
      'focus blocks are full this week',
      'focus blocks are full before the Friday deadline',
      'only 30 of 60 min fit before tomorrow\'s deadline',
      'no free 45-minute slot this week',
      'no free 45-minute slot before Nov 12',
      'this one is already done',
      'no free gap before the end of the week',
    ];
    for (final r in same) {
      expect(localizePlanReason(en, r), r, reason: r);
    }
  });

  test('Hebrew renders the templates; unknown reasons pass through', () {
    expect(localizePlanReason(he, 'your focus window'), 'חלון הפוקוס שלך');
    expect(localizePlanReason(he, 'due tomorrow'), 'יעד: מחר');
    expect(localizePlanReason(he, 'due Thursday'), 'יעד: יום חמישי');
    expect(
      localizePlanReason(he, 'first 45 of 90 min'),
      'הראשון: 45 מתוך 90 דק׳',
    );
    expect(
      localizePlanReason(he, 'no free 45-minute slot this week'),
      'אין חלון פנוי של 45 דקות השבוע',
    );
    expect(
      localizePlanReason(he, 'no free 45-minute slot before Nov 12'),
      'אין חלון פנוי של 45 דקות לפני 12 בנוב׳',
    );
    expect(
      localizePlanReason(he, 'unknown reason text'),
      'unknown reason text',
    );
  });

  test('re-plan diff reasons round-trip in English', () {
    const same = [
      // Move reasons from `_moveReason` in `replan.dart`.
      'that time has passed',
      'your hours changed',
      'an earlier slot opened up',
      "reshuffled around today's changes",
      'Team sync now takes that time',
      'All-hands on deck now takes that time',
      'you put Dentist there',
      'you put Call mom there',
      'made room for Essay outline',
      'made room for Read paper',
      // Removal reasons from `_removalReason` in `replan.dart`.
      'no longer on your list',
      'done, nice work',
      'skipped for now',
      'no longer fits this week',
    ];
    for (final r in same) {
      expect(localizePlanReason(en, r), r, reason: r);
    }
  });

  test('re-plan diff reasons render in Hebrew', () {
    expect(localizePlanReason(he, 'that time has passed'), 'הזמן הזה כבר עבר');
    expect(
      localizePlanReason(he, 'your hours changed'),
      'שעות העבודה שלך השתנו',
    );
    expect(
      localizePlanReason(he, 'an earlier slot opened up'),
      'התפנה חלון מוקדם יותר',
    );
    expect(
      localizePlanReason(he, "reshuffled around today's changes"),
      'סידרתי מחדש סביב השינויים של היום',
    );
    expect(
      localizePlanReason(he, 'Team sync now takes that time'),
      'עכשיו Team sync בשעה הזאת',
    );
    expect(
      localizePlanReason(he, 'you put Dentist there'),
      'שמת שם את Dentist',
    );
    expect(
      localizePlanReason(he, 'made room for Essay outline'),
      'פיניתי מקום לEssay outline',
    );
    expect(
      localizePlanReason(he, 'no longer on your list'),
      'כבר לא ברשימה שלך',
    );
    expect(localizePlanReason(he, 'done, nice work'), 'סיימת, יפה');
    expect(localizePlanReason(he, 'skipped for now'), 'דילוג לעת עתה');
    expect(localizePlanReason(he, 'no longer fits this week'), 'לא נכנס השבוע');
  });

  test('diff move reasons from the scheduler map through localization', () {
    // Verbatim strings produced by `_moveReason` and `_removalReason` in
    // `lib/features/plan/scheduler/replan.dart`. Guards against a future
    // reason string diverging from what `localizePlanReason` recognizes.
    final movedByEvent = 'Team sync now takes that time';
    final newlyPinned = 'you put Dentist there';
    final madeRoom = 'made room for Essay outline';
    expect(localizePlanReason(en, movedByEvent), movedByEvent);
    expect(localizePlanReason(en, newlyPinned), newlyPinned);
    expect(localizePlanReason(en, madeRoom), madeRoom);
    // The parameterized templates must not collapse one into another.
    expect(
      localizePlanReason(he, newlyPinned),
      isNot(equals(localizePlanReason(he, madeRoom))),
    );
    expect(
      localizePlanReason(he, movedByEvent),
      isNot(equals(localizePlanReason(he, newlyPinned))),
    );
  });

  test('capacity pieces use ICU plurals', () {
    expect(
      planCapacityLine(en, freeMinutes: 90, plannedMinutes: 45),
      '1.5 h free · 45 min planned',
    );
    expect(
      planCapacityLine(he, freeMinutes: 14 * 60, plannedMinutes: 9 * 60),
      '14 ש׳ פנויות · 9 ש׳ מתוכננות',
    );
    expect(he.planApplied(1), 'בוצע. לדבר אחד יש מקום עכשיו.');
    expect(en.planApplied(0), 'All set, nothing needed moving.');
    expect(en.planReplanKept(3), '3 things you placed yourself stay put.');
  });
}
