import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/ask_intent.dart';
import 'package:grind/features/ask/ask_quick_prompts.dart';

void main() {
  group('quickPromptsFor', () {
    test('English is the default when the locale is null', () {
      final en = quickPromptsFor(null);
      expect(en, quickPromptsFor(const Locale('en')));
      expect(en.map((p) => p.label), [
        'Plan my day',
        'Explain the plan',
        "What's next?",
      ]);
    });

    test('a non-Hebrew locale still gets the English catalog', () {
      expect(
        quickPromptsFor(const Locale('fr')),
        quickPromptsFor(const Locale('en')),
      );
      expect(
        quickPromptsFor(const Locale('de')),
        quickPromptsFor(const Locale('en')),
      );
    });

    test('Hebrew has its own catalog', () {
      final he = quickPromptsFor(const Locale('he'));
      expect(he.map((p) => p.label), [
        'תכנן לי את היום',
        'הסבר לי את התוכנית',
        'מה הבא?',
      ]);
      expect(he, isNot(equals(quickPromptsFor(const Locale('en')))));
    });

    test('each locale has three chips, each with a non-empty label', () {
      for (final locale in [const Locale('en'), const Locale('he')]) {
        final prompts = quickPromptsFor(locale);
        expect(prompts, hasLength(3));
        for (final p in prompts) {
          expect(p.label.trim(), isNotEmpty);
        }
      }
    });

    test('each catalog covers the three epic #40 entry intents', () {
      for (final locale in [const Locale('en'), const Locale('he')]) {
        final intents = quickPromptsFor(locale).map((p) => p.intent).toSet();
        expect(intents, {
          AskIntent.planMyDay,
          AskIntent.explainPlan,
          AskIntent.whatsNext,
        });
      }
    });
  });

  group('round-trip through the intent classifier', () {
    test('each English label classifies back to its paired intent', () {
      for (final p in quickPromptsFor(const Locale('en'))) {
        final match = classifyAskPrompt(p.label, locale: const Locale('en'));
        expect(
          match.intent,
          p.intent,
          reason: 'label "${p.label}" should classify to ${p.intent}',
        );
      }
    });

    test('each Hebrew label classifies back to its paired intent', () {
      for (final p in quickPromptsFor(const Locale('he'))) {
        final match = classifyAskPrompt(p.label, locale: const Locale('he'));
        expect(
          match.intent,
          p.intent,
          reason: 'label "${p.label}" should classify to ${p.intent}',
        );
      }
    });
  });

  group('AskQuickPrompt value semantics', () {
    test('equality and hashCode read the two fields', () {
      const a = AskQuickPrompt('Plan my day', AskIntent.planMyDay);
      const b = AskQuickPrompt('Plan my day', AskIntent.planMyDay);
      const c = AskQuickPrompt('Plan my day', AskIntent.explainPlan);
      const d = AskQuickPrompt("What's next?", AskIntent.planMyDay);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
    });

    test('toString carries the label and intent', () {
      const p = AskQuickPrompt('Plan my day', AskIntent.planMyDay);
      expect(p.toString(), contains('Plan my day'));
      expect(p.toString(), contains('planMyDay'));
    });
  });
}
