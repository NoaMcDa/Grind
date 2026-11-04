import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/unstick_tone_rules.dart';

void main() {
  group('UnstickToneRules.violations (en)', () {
    test('neutral acknowledgement passes', () {
      expect(
        UnstickToneRules.violations("That's a lot. Let's make it smaller."),
        isEmpty,
      );
    });

    test('praise words trip a bannedWord violation', () {
      for (final word in ['amazing', 'awesome', 'great', 'perfect']) {
        final vs = UnstickToneRules.violations('That is $word.');
        expect(vs, isNotEmpty, reason: word);
        expect(vs.first.rule, ToneRule.bannedWord);
        expect(vs.first.word, word);
      }
    });

    test('command verbs trip a bannedWord violation', () {
      for (final line in [
        'You should start now.',
        'You must do the first step.',
        'You need to pick one.',
        'You have to try.',
      ]) {
        expect(
          UnstickToneRules.violations(line),
          isNotEmpty,
          reason: line,
        );
      }
    });

    test('guilt words trip a bannedWord violation', () {
      for (final line in [
        'You are behind.',
        'The task is overdue.',
        'You missed it.',
        "You've failed again.",
      ]) {
        expect(
          UnstickToneRules.violations(line),
          isNotEmpty,
          reason: line,
        );
      }
    });

    test('whole-word match: "late" does not match "later"', () {
      // "later" is allowed; "late" alone is not.
      expect(UnstickToneRules.violations('Pick it up later today.'), isEmpty);
      expect(UnstickToneRules.violations('You are late.'), isNotEmpty);
    });

    test('match is case-insensitive', () {
      expect(UnstickToneRules.violations('AWESOME job'), isNotEmpty);
      expect(UnstickToneRules.violations('Should'), isNotEmpty);
    });

    test('double bang is a separate violation', () {
      final vs = UnstickToneRules.violations('Nice!!');
      expect(vs.map((v) => v.rule), contains(ToneRule.doubleBang));
    });

    test('single "!" is allowed by default', () {
      // The tone guide allows one exclamation for big wins. Only the
      // small-step line gets the stricter rule.
      expect(
        UnstickToneRules.violations('Take a breath!'),
        isEmpty,
      );
    });

    test('small step forbids any "!"', () {
      final vs = UnstickToneRules.violations(
        'Just the first step!',
        isSmallStep: true,
      );
      expect(vs.map((v) => v.rule), contains(ToneRule.exclamationOnSmallStep));
    });
  });

  group('UnstickToneRules.violations (he)', () {
    test('neutral Hebrew acknowledgement passes', () {
      expect(
        UnstickToneRules.violations(
          'זה הרבה. בוא נעשה את זה קטן יותר.',
          localeCode: 'he',
        ),
        isEmpty,
      );
    });

    test('Hebrew substring match catches prefixed forms', () {
      // Direct hit and a prefix-glued form both trip the substring check.
      for (final line in ['אתה צריך להתחיל.', 'שצריך לעשות עכשיו.']) {
        final vs = UnstickToneRules.violations(line, localeCode: 'he');
        expect(vs, isNotEmpty, reason: line);
        expect(vs.first.rule, ToneRule.bannedWord);
      }
    });

    test('toxic Hebrew praise is caught', () {
      for (final word in ['מדהים', 'אדיר', 'מושלם']) {
        expect(
          UnstickToneRules.violations('$word!', localeCode: 'he'),
          isNotEmpty,
          reason: word,
        );
      }
    });

    test('Hebrew double-bang also trips', () {
      final vs = UnstickToneRules.violations('יופי!!', localeCode: 'he');
      expect(vs.map((v) => v.rule), contains(ToneRule.doubleBang));
    });
  });

  group('UnstickToneRules.isCompliant', () {
    test('mirrors violations.isEmpty', () {
      expect(UnstickToneRules.isCompliant("Let's make it smaller."), isTrue);
      expect(UnstickToneRules.isCompliant('Great job!'), isFalse);
    });

    test('unknown locale falls back to English rules', () {
      // 'fr' is not registered; English list runs. "awesome" trips.
      expect(
        UnstickToneRules.isCompliant('awesome', localeCode: 'fr'),
        isFalse,
      );
    });
  });

  group('UnstickToneRules.bannedWords', () {
    test('exposes both language lists non-empty', () {
      expect(UnstickToneRules.bannedWords['en'], isNotEmpty);
      expect(UnstickToneRules.bannedWords['he'], isNotEmpty);
    });

    test('English list is all lower-case', () {
      for (final word in UnstickToneRules.bannedWords['en']!) {
        expect(word, word.toLowerCase(), reason: word);
      }
    });
  });
}
