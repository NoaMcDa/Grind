import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  group('ModelPolicy.defaults', () {
    test('matches the epic rule: Haiku for capture and praise', () {
      expect(ModelPolicy.defaults.tierFor('capture'), ModelTier.haiku);
      expect(ModelPolicy.defaults.tierFor('praise'), ModelTier.haiku);
    });

    test('matches the epic rule: Sonnet for plan explanations', () {
      expect(ModelPolicy.defaults.tierFor('planExplanation'), ModelTier.sonnet);
    });

    test('covers exactly the three intents the gateway speaks today', () {
      expect(ModelPolicy.defaults.intents.toSet(), {
        'capture',
        'praise',
        'planExplanation',
      });
    });
  });

  group('ModelPolicy.tierFor', () {
    test('throws UnknownIntentException on an unknown key', () {
      expect(
        () => ModelPolicy.defaults.tierFor('refactorEverything'),
        throwsA(
          isA<UnknownIntentException>().having(
            (e) => e.intent,
            'intent',
            'refactorEverything',
          ),
        ),
      );
    });
  });

  group('ModelPolicy.tierForOr', () {
    test('returns the mapped tier when the intent is known', () {
      expect(
        ModelPolicy.defaults.tierForOr('capture', fallback: ModelTier.sonnet),
        ModelTier.haiku,
      );
    });

    test('returns the fallback on an unknown intent', () {
      expect(
        ModelPolicy.defaults.tierForOr('unknown', fallback: ModelTier.sonnet),
        ModelTier.sonnet,
      );
    });
  });

  group('ModelPolicy.knows', () {
    test('is true for mapped intents and false otherwise', () {
      expect(ModelPolicy.defaults.knows('capture'), isTrue);
      expect(ModelPolicy.defaults.knows('planExplanation'), isTrue);
      expect(ModelPolicy.defaults.knows('nope'), isFalse);
    });
  });

  group('ModelPolicy.withOverride', () {
    test('adds a new intent without touching the receiver', () {
      final original = ModelPolicy.defaults;
      final patched = original.withOverride('summarise', ModelTier.sonnet);
      expect(patched.tierFor('summarise'), ModelTier.sonnet);
      expect(original.knows('summarise'), isFalse);
    });

    test('overrides an existing intent', () {
      final policy = ModelPolicy.defaults.withOverride(
        'capture',
        ModelTier.sonnet,
      );
      expect(policy.tierFor('capture'), ModelTier.sonnet);
      // Siblings untouched.
      expect(policy.tierFor('praise'), ModelTier.haiku);
    });
  });

  group('ModelPolicy construction', () {
    test('copies the mapping so later caller mutations do not leak in', () {
      final live = <String, ModelTier>{'capture': ModelTier.haiku};
      final policy = ModelPolicy(live);
      live['capture'] = ModelTier.sonnet;
      expect(policy.tierFor('capture'), ModelTier.haiku);
    });

    test('two policies built from equal maps compare equal', () {
      final a = ModelPolicy({
        'capture': ModelTier.haiku,
        'planExplanation': ModelTier.sonnet,
      });
      final b = ModelPolicy({
        'planExplanation': ModelTier.sonnet,
        'capture': ModelTier.haiku,
      });
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('policies with different mappings are not equal', () {
      final a = ModelPolicy({'capture': ModelTier.haiku});
      final b = ModelPolicy({'capture': ModelTier.sonnet});
      expect(a, isNot(equals(b)));
    });
  });
}
