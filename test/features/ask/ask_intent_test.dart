import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/ask_intent.dart';

AskIntentMatch _en(String s) =>
    classifyAskPrompt(s, locale: const Locale('en'));
AskIntentMatch _he(String s) =>
    classifyAskPrompt(s, locale: const Locale('he'));

void main() {
  group('empty, unknown and fallback', () {
    test('empty and whitespace are unknown', () {
      expect(_en('').intent, AskIntent.unknown);
      expect(_en('   ').intent, AskIntent.unknown);
      expect(_en('\n\t').intent, AskIntent.unknown);
    });

    test('free chat that names nothing specific is unknown', () {
      expect(_en('hey pip').intent, AskIntent.unknown);
      expect(_en("i'm behind on my thesis, help").intent, AskIntent.unknown);
      expect(_he('היי פיפ').intent, AskIntent.unknown);
    });

    test('no locale defaults to the English phrase table', () {
      expect(classifyAskPrompt('plan my day').intent, AskIntent.planMyDay);
      expect(classifyAskPrompt('מה הבא').intent, AskIntent.unknown);
    });

    test('an unknown match carries no task reference', () {
      final m = _en('hello');
      expect(m.intent, AskIntent.unknown);
      expect(m.taskReference, isNull);
    });
  });

  group('planMyDay (English)', () {
    test('Ask Pip quick-prompt copy matches', () {
      expect(_en('Plan my day').intent, AskIntent.planMyDay);
      expect(_en('plan my day').intent, AskIntent.planMyDay);
      expect(_en('Plan my day!').intent, AskIntent.planMyDay);
      expect(_en('plan my day?').intent, AskIntent.planMyDay);
    });

    test('other common phrasings reach planMyDay', () {
      expect(_en('plan today').intent, AskIntent.planMyDay);
      expect(_en('plan the day').intent, AskIntent.planMyDay);
      expect(_en('draft my day').intent, AskIntent.planMyDay);
      expect(_en('schedule today').intent, AskIntent.planMyDay);
      expect(_en('what should i do today').intent, AskIntent.planMyDay);
      expect(_en("what's my day look like").intent, AskIntent.planMyDay);
    });
  });

  group('planMyDay (Hebrew)', () {
    test('imperative forms reach planMyDay', () {
      expect(_he('תכנן לי את היום').intent, AskIntent.planMyDay);
      expect(_he('תכננו לי את היום').intent, AskIntent.planMyDay);
      expect(_he('תכנן את היום').intent, AskIntent.planMyDay);
      expect(_he('תכנן יום').intent, AskIntent.planMyDay);
      expect(_he('תכנן לי את היום שלי').intent, AskIntent.planMyDay);
    });

    test('questions reach planMyDay', () {
      expect(_he('איך היום שלי נראה').intent, AskIntent.planMyDay);
      expect(_he('מה כדאי לי היום').intent, AskIntent.planMyDay);
    });
  });

  group('explainPlan', () {
    test('English explainers reach explainPlan', () {
      expect(_en('explain the plan').intent, AskIntent.explainPlan);
      expect(_en('explain my plan').intent, AskIntent.explainPlan);
      expect(_en('explain the day').intent, AskIntent.explainPlan);
      expect(_en('walk me through my plan').intent, AskIntent.explainPlan);
      expect(_en('walk me through today').intent, AskIntent.explainPlan);
      expect(_en('break down the plan').intent, AskIntent.explainPlan);
      expect(
        _en('why does my day look like this').intent,
        AskIntent.explainPlan,
      );
    });

    test('Hebrew explainers reach explainPlan', () {
      expect(_he('הסבר לי את התוכנית').intent, AskIntent.explainPlan);
      expect(_he('ספר לי על התוכנית').intent, AskIntent.explainPlan);
      expect(_he('הסבר את היום').intent, AskIntent.explainPlan);
    });
  });

  group('whatsNext', () {
    test('English quick-prompt copy matches', () {
      expect(_en("What's next?").intent, AskIntent.whatsNext);
      expect(_en('whats next').intent, AskIntent.whatsNext);
      expect(_en('what is up next').intent, AskIntent.whatsNext);
      expect(_en("what's after this?").intent, AskIntent.whatsNext);
    });

    test('Hebrew phrases match', () {
      expect(_he('מה הבא').intent, AskIntent.whatsNext);
      expect(_he('מה עכשיו').intent, AskIntent.whatsNext);
      expect(_he('מה אחרי זה').intent, AskIntent.whatsNext);
    });
  });

  group('whyTaskHere with a task reference', () {
    test('English "why is the gym so late" extracts gym', () {
      final m = _en('Why is the gym so late?');
      expect(m.intent, AskIntent.whyTaskHere);
      expect(m.taskReference, 'gym');
    });

    test('English "why is reading in the evening" extracts reading', () {
      final m = _en('why is reading in the evening');
      expect(m.intent, AskIntent.whyTaskHere);
      expect(m.taskReference, 'reading');
    });

    test('English "why is the call at 15:00" extracts call', () {
      final m = _en('why is the call at 15:00');
      expect(m.intent, AskIntent.whyTaskHere);
      expect(m.taskReference, 'call');
    });

    test('Hebrew "למה הגים כל כך מאוחר" extracts גים', () {
      final m = _he('למה הגים כל כך מאוחר');
      expect(m.intent, AskIntent.whyTaskHere);
      expect(m.taskReference, 'גים');
    });

    test('Hebrew "למה הקריאה בערב" extracts קריאה', () {
      final m = _he('למה הקריאה בערב');
      expect(m.intent, AskIntent.whyTaskHere);
      expect(m.taskReference, 'קריאה');
    });
  });

  group('whyTaskNotPlaced with a task reference', () {
    test("English \"why isn't X on today\" extracts X", () {
      final m = _en("Why isn't the gym on today?");
      expect(m.intent, AskIntent.whyTaskNotPlaced);
      expect(m.taskReference, 'gym');
    });

    test('English "why is X not on the plan" extracts X', () {
      final m = _en('why is reading not on the plan');
      expect(m.intent, AskIntent.whyTaskNotPlaced);
      expect(m.taskReference, 'reading');
    });

    test('English "where is X" extracts X', () {
      final m = _en('where is the thesis');
      expect(m.intent, AskIntent.whyTaskNotPlaced);
      expect(m.taskReference, 'thesis');
    });

    test('Hebrew "למה X לא בתוכנית" extracts X', () {
      final m = _he('למה הגים לא בתוכנית');
      expect(m.intent, AskIntent.whyTaskNotPlaced);
      expect(m.taskReference, 'גים');
    });

    test('Hebrew "איפה X" extracts X', () {
      final m = _he('איפה הקריאה');
      expect(m.intent, AskIntent.whyTaskNotPlaced);
      expect(m.taskReference, 'קריאה');
    });
  });

  group('whenTaskStarts with a task reference', () {
    test('English "when does X start" extracts X', () {
      final m = _en('When does the gym start?');
      expect(m.intent, AskIntent.whenTaskStarts);
      expect(m.taskReference, 'gym');
    });

    test('English "when is X" extracts X', () {
      final m = _en('when is reading');
      expect(m.intent, AskIntent.whenTaskStarts);
      expect(m.taskReference, 'reading');
    });

    test('English "what time is X" extracts X', () {
      final m = _en('what time is the call');
      expect(m.intent, AskIntent.whenTaskStarts);
      expect(m.taskReference, 'call');
    });

    test('Hebrew "מתי X מתחיל" extracts X', () {
      final m = _he('מתי הגים מתחיל');
      expect(m.intent, AskIntent.whenTaskStarts);
      expect(m.taskReference, 'גים');
    });

    test('Hebrew "מתי X" extracts X', () {
      final m = _he('מתי הקריאה');
      expect(m.intent, AskIntent.whenTaskStarts);
      expect(m.taskReference, 'קריאה');
    });
  });

  group('rule ordering', () {
    test(
      '"why is X not on today" goes to whyTaskNotPlaced, not whyTaskHere',
      () {
        expect(
          _en('why is reading not on today').intent,
          AskIntent.whyTaskNotPlaced,
        );
        expect(
          _en("why isn't reading on today").intent,
          AskIntent.whyTaskNotPlaced,
        );
      },
    );

    test('"why is X in the morning" stays whyTaskHere', () {
      final m = _en('why is reading in the morning');
      expect(m.intent, AskIntent.whyTaskHere);
      expect(m.taskReference, 'reading');
    });

    test('"when is X" does not swallow a whyTaskHere phrasing', () {
      expect(_en('why is reading so late').intent, AskIntent.whyTaskHere);
    });
  });

  group('normalization', () {
    test('case and trailing punctuation are ignored', () {
      expect(_en('PLAN MY DAY').intent, AskIntent.planMyDay);
      expect(_en('Plan my day!!!').intent, AskIntent.planMyDay);
      expect(_en('  plan my day  ').intent, AskIntent.planMyDay);
    });

    test('runs of whitespace collapse', () {
      expect(_en('plan   my   day').intent, AskIntent.planMyDay);
    });

    test('a leading article is trimmed from the task reference', () {
      expect(_en('why is the gym so late').taskReference, 'gym');
      expect(_en('why is a call at 15:00').taskReference, 'call');
      expect(_en('why is my thesis so late').taskReference, 'thesis');
    });

    test('a Hebrew prefix ה is trimmed from the task reference', () {
      expect(_he('למה הגים כל כך מאוחר').taskReference, 'גים');
      expect(_he('איפה הקריאה').taskReference, 'קריאה');
    });
  });

  group('AskIntentMatch value semantics', () {
    test('equal intents with equal task references are equal', () {
      const a = AskIntentMatch(AskIntent.whyTaskHere, taskReference: 'gym');
      const b = AskIntentMatch(AskIntent.whyTaskHere, taskReference: 'gym');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different task references are not equal', () {
      const a = AskIntentMatch(AskIntent.whyTaskHere, taskReference: 'gym');
      const b = AskIntentMatch(AskIntent.whyTaskHere, taskReference: 'call');
      expect(a, isNot(b));
    });

    test('const unknown match has no task reference', () {
      const m = AskIntentMatch.unknown();
      expect(m.intent, AskIntent.unknown);
      expect(m.taskReference, isNull);
    });
  });
}
