import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/hard_mode_shield/hard_mode_shield.dart';

void main() {
  group('HardModeSelectionDiff', () {
    test('empty when selections are identical', () {
      final s = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b'],
      );
      final diff = HardModeSelectionDiff.between(s, s);
      expect(diff.isEmpty, isTrue);
      expect(diff.isNotEmpty, isFalse);
      expect(diff.enabledChanged, isFalse);
      expect(diff.tokensChanged, isFalse);
      expect(diff.requiresReinstall, isFalse);
      expect(diff.addedTokens, isEmpty);
      expect(diff.removedTokens, isEmpty);
      expect(diff, HardModeSelectionDiff.empty);
    });

    test('empty when comparing two HardModeSelection.empty', () {
      final diff = HardModeSelectionDiff.between(
        HardModeSelection.empty,
        HardModeSelection.empty,
      );
      expect(diff, HardModeSelectionDiff.empty);
    });

    test('reports the enabled flag flipping on', () {
      final before = HardModeSelection(
        enabled: false,
        applicationTokens: const ['a'],
      );
      final after = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a'],
      );
      final diff = HardModeSelectionDiff.between(before, after);
      expect(diff.enabledChanged, isTrue);
      expect(diff.tokensChanged, isFalse);
      expect(diff.isNotEmpty, isTrue);
      expect(diff.requiresReinstall, isTrue);
      expect(diff.addedTokens, isEmpty);
      expect(diff.removedTokens, isEmpty);
    });

    test('reports the enabled flag flipping off', () {
      final before = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a'],
      );
      final after = HardModeSelection(
        enabled: false,
        applicationTokens: const ['a'],
      );
      final diff = HardModeSelectionDiff.between(before, after);
      expect(diff.enabledChanged, isTrue);
      expect(diff.requiresReinstall, isTrue);
    });

    test('reports added tokens', () {
      final before = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a'],
      );
      final after = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b', 'c'],
      );
      final diff = HardModeSelectionDiff.between(before, after);
      expect(diff.enabledChanged, isFalse);
      expect(diff.addedTokens, {'b', 'c'});
      expect(diff.removedTokens, isEmpty);
      expect(diff.tokensChanged, isTrue);
      expect(diff.requiresReinstall, isTrue);
    });

    test('reports removed tokens', () {
      final before = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b', 'c'],
      );
      final after = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a'],
      );
      final diff = HardModeSelectionDiff.between(before, after);
      expect(diff.addedTokens, isEmpty);
      expect(diff.removedTokens, {'b', 'c'});
      expect(diff.tokensChanged, isTrue);
      expect(diff.requiresReinstall, isTrue);
    });

    test('reports additions and removals together', () {
      final before = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b'],
      );
      final after = HardModeSelection(
        enabled: true,
        applicationTokens: const ['b', 'c'],
      );
      final diff = HardModeSelectionDiff.between(before, after);
      expect(diff.addedTokens, {'c'});
      expect(diff.removedTokens, {'a'});
      expect(diff.tokensChanged, isTrue);
    });

    test('token reorder with the same set is empty', () {
      final before = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b', 'c'],
      );
      final after = HardModeSelection(
        enabled: true,
        applicationTokens: const ['c', 'b', 'a'],
      );
      final diff = HardModeSelectionDiff.between(before, after);
      expect(diff, HardModeSelectionDiff.empty);
      expect(diff.requiresReinstall, isFalse);
    });

    test('duplicate tokens in a list are collapsed by the set view', () {
      final before = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'a', 'b'],
      );
      final after = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b'],
      );
      final diff = HardModeSelectionDiff.between(before, after);
      expect(diff, HardModeSelectionDiff.empty);
    });

    test('turning on with a fresh selection adds every token', () {
      final diff = HardModeSelectionDiff.between(
        HardModeSelection.empty,
        HardModeSelection(enabled: true, applicationTokens: const ['a', 'b']),
      );
      expect(diff.enabledChanged, isTrue);
      expect(diff.addedTokens, {'a', 'b'});
      expect(diff.removedTokens, isEmpty);
      expect(diff.requiresReinstall, isTrue);
    });

    test('turning off and clearing removes every token', () {
      final diff = HardModeSelectionDiff.between(
        HardModeSelection(enabled: true, applicationTokens: const ['a', 'b']),
        HardModeSelection.empty,
      );
      expect(diff.enabledChanged, isTrue);
      expect(diff.addedTokens, isEmpty);
      expect(diff.removedTokens, {'a', 'b'});
      expect(diff.requiresReinstall, isTrue);
    });

    test('addedTokens and removedTokens are unmodifiable', () {
      final diff = HardModeSelectionDiff.between(
        HardModeSelection(enabled: true, applicationTokens: const ['a']),
        HardModeSelection(enabled: true, applicationTokens: const ['b']),
      );
      expect(() => diff.addedTokens.add('x'), throwsUnsupportedError);
      expect(() => diff.removedTokens.add('x'), throwsUnsupportedError);
    });

    test('equality is by enabled flag plus token sets', () {
      final before = HardModeSelection(
        enabled: false,
        applicationTokens: const [],
      );
      final a = HardModeSelectionDiff.between(
        before,
        HardModeSelection(enabled: true, applicationTokens: const ['x', 'y']),
      );
      final b = HardModeSelectionDiff.between(
        before,
        HardModeSelection(enabled: true, applicationTokens: const ['y', 'x']),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final c = HardModeSelectionDiff.between(
        before,
        HardModeSelection(enabled: true, applicationTokens: const ['x']),
      );
      expect(a, isNot(equals(c)));
    });

    test('toString describes what changed, or "empty"', () {
      final empty = HardModeSelectionDiff.between(
        HardModeSelection.empty,
        HardModeSelection.empty,
      );
      expect(empty.toString(), 'HardModeSelectionDiff(empty)');

      final flip = HardModeSelectionDiff.between(
        HardModeSelection.empty,
        HardModeSelection(enabled: true, applicationTokens: const ['a']),
      );
      expect(flip.toString(), contains('enabledChanged'));
      expect(flip.toString(), contains('added: 1'));

      final remove = HardModeSelectionDiff.between(
        HardModeSelection(enabled: true, applicationTokens: const ['a', 'b']),
        HardModeSelection(enabled: true, applicationTokens: const ['a']),
      );
      expect(remove.toString(), contains('removed: 1'));
      expect(remove.toString(), isNot(contains('enabledChanged')));
    });

    test('HardModeSelectionDiff.empty is the zero value', () {
      expect(HardModeSelectionDiff.empty.isEmpty, isTrue);
      expect(HardModeSelectionDiff.empty.enabledChanged, isFalse);
      expect(HardModeSelectionDiff.empty.addedTokens, isEmpty);
      expect(HardModeSelectionDiff.empty.removedTokens, isEmpty);
      expect(HardModeSelectionDiff.empty.requiresReinstall, isFalse);
    });
  });
}
