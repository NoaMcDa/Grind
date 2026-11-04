import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/unstick/static_unstick_suggester.dart';
import 'package:grind/features/ask/unstick/unstick_option.dart';

void main() {
  group('StaticUnstickSuggester (en)', () {
    const suggester = StaticUnstickSuggester();

    test('long task leads with split into two shorter blocks', () {
      final options = suggester.suggestFor(estimatedMinutes: 90);

      expect(options, isNotEmpty);
      expect(options.first.kind, UnstickKind.split);
      expect(options.first.parameters['chunks'], 2);
      final chunk = options.first.parameters['chunkMinutes'] as int;
      expect(chunk, inInclusiveRange(20, 45));
      expect(options.length, inInclusiveRange(1, 3));
      // Always offers firstAction as a safe small step.
      expect(options.map((o) => o.kind), contains(UnstickKind.firstAction));
    });

    test('short task does not offer split, leads with first action', () {
      final options = suggester.suggestFor(estimatedMinutes: 20);

      expect(options.map((o) => o.kind), isNot(contains(UnstickKind.split)));
      expect(options.map((o) => o.kind), isNot(contains(UnstickKind.shorten)));
      expect(options.first.kind, UnstickKind.firstAction);
    });

    test('overdue task adds reschedule and never exceeds three options', () {
      final options = suggester.suggestFor(
        estimatedMinutes: 90,
        overdueBy: const Duration(days: 2),
      );

      expect(options.length, 3);
      expect(options.map((o) => o.kind), contains(UnstickKind.reschedule));
      expect(options.last.kind, UnstickKind.firstAction);
    });

    test('not-overdue long task does not include reschedule', () {
      final options = suggester.suggestFor(estimatedMinutes: 90);

      expect(
        options.map((o) => o.kind),
        isNot(contains(UnstickKind.reschedule)),
      );
    });

    test('rationales are praise- and judgement-free', () {
      final options = suggester.suggestFor(estimatedMinutes: 90);
      const banned = ['great', 'awesome', 'amazing', 'should', 'must', '!'];

      for (final option in options) {
        final lower = option.humanRationale.toLowerCase();
        for (final word in banned) {
          expect(
            lower.contains(word),
            isFalse,
            reason: '"$word" in rationale "${option.humanRationale}"',
          );
        }
      }
    });

    test('suggester is deterministic', () {
      final a = suggester.suggestFor(
        estimatedMinutes: 60,
        overdueBy: const Duration(days: 1),
      );
      final b = suggester.suggestFor(
        estimatedMinutes: 60,
        overdueBy: const Duration(days: 1),
      );
      expect(a, b);
    });

    test('acknowledgement is one short line', () {
      expect(suggester.acknowledgement, isNotEmpty);
      expect(suggester.acknowledgement.contains('\n'), isFalse);
      expect(suggester.acknowledgement.length, lessThan(80));
    });
  });

  group('StaticUnstickSuggester (he)', () {
    const suggester = StaticUnstickSuggester(localeCode: 'he');

    test('Hebrew locale returns Hebrew copy', () {
      final options = suggester.suggestFor(estimatedMinutes: 90);
      // Hebrew characters live in the U+0590..U+05FF block.
      final hebrew = RegExp(r'[֐-׿]');
      expect(hebrew.hasMatch(suggester.acknowledgement), isTrue);
      for (final option in options) {
        expect(hebrew.hasMatch(option.title), isTrue);
        expect(hebrew.hasMatch(option.humanRationale), isTrue);
      }
    });

    test('unknown locale falls back to English', () {
      const fallback = StaticUnstickSuggester(localeCode: 'fr');
      expect(fallback.acknowledgement, UnstickTone.acknowledgeEn);
    });
  });

  group('UnstickOption JSON', () {
    test('round-trips through toJson/fromJson', () {
      const option = UnstickOption(
        kind: UnstickKind.split,
        title: 'Two short blocks',
        humanRationale: 'Easier to start.',
        parameters: {'chunkMinutes': 25, 'chunks': 2},
      );

      final decoded = UnstickOption.fromJson(option.toJson());
      expect(decoded, option);
    });

    test('fromJson rejects malformed input', () {
      expect(UnstickOption.fromJson(null), isNull);
      expect(UnstickOption.fromJson('nope'), isNull);
      expect(UnstickOption.fromJson({'kind': 'split'}), isNull);
    });
  });
}
