import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/hard_mode_shield/hard_mode_shield.dart';

void main() {
  group('HardModeSelection', () {
    test('defaults to off with no tokens', () {
      final s = HardModeSelection();
      expect(s.enabled, isFalse);
      expect(s.applicationTokens, isEmpty);
      expect(s.isActive, isFalse);
      expect(s.shieldedCount, 0);
    });

    test('empty is the same as the default constructor', () {
      expect(HardModeSelection.empty, HardModeSelection());
      expect(HardModeSelection.empty.isActive, isFalse);
    });

    test('isActive needs both the switch on and at least one token', () {
      expect(
        HardModeSelection(enabled: true, applicationTokens: const []).isActive,
        isFalse,
      );
      expect(
        HardModeSelection(
          enabled: false,
          applicationTokens: const ['a'],
        ).isActive,
        isFalse,
      );
      expect(
        HardModeSelection(
          enabled: true,
          applicationTokens: const ['a'],
        ).isActive,
        isTrue,
      );
    });

    test('shieldedCount counts the tokens', () {
      final s = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b', 'c'],
      );
      expect(s.shieldedCount, 3);
    });

    test('applicationTokens is unmodifiable', () {
      final s = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a'],
      );
      expect(() => s.applicationTokens.add('b'), throwsUnsupportedError);
    });

    test('changes to the source list do not leak in', () {
      final mutable = <String>['a', 'b'];
      final s = HardModeSelection(enabled: true, applicationTokens: mutable);
      mutable.add('c');
      expect(s.applicationTokens, ['a', 'b']);
    });

    test('copyWith keeps the other field', () {
      final s = HardModeSelection(
        enabled: true,
        applicationTokens: const ['a', 'b'],
      );
      expect(s.copyWith(enabled: false).applicationTokens, ['a', 'b']);
      expect(s.copyWith(applicationTokens: const ['x']).enabled, isTrue);
    });

    test('equality is by value, including token order', () {
      final a = HardModeSelection(
        enabled: true,
        applicationTokens: const ['x', 'y'],
      );
      final b = HardModeSelection(
        enabled: true,
        applicationTokens: const ['x', 'y'],
      );
      final reordered = HardModeSelection(
        enabled: true,
        applicationTokens: const ['y', 'x'],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == reordered, isFalse);
    });

    test('a different enabled flag is not equal', () {
      final on = HardModeSelection(
        enabled: true,
        applicationTokens: const ['x'],
      );
      final off = HardModeSelection(
        enabled: false,
        applicationTokens: const ['x'],
      );
      expect(on == off, isFalse);
    });

    test('toJson/fromJson round-trips through dart:convert', () {
      final s = HardModeSelection(
        enabled: true,
        applicationTokens: const ['token-a', 'token-b'],
      );
      final roundTripped = HardModeSelection.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
      );
      expect(roundTripped, s);
    });

    test('fromJson reads the empty default when keys are missing', () {
      expect(HardModeSelection.fromJson(const {}), HardModeSelection.empty);
    });

    test('fromJson rejects a non-bool enabled', () {
      expect(
        () => HardModeSelection.fromJson(const {'enabled': 'yes'}),
        throwsFormatException,
      );
    });

    test('fromJson rejects a non-list applicationTokens', () {
      expect(
        () => HardModeSelection.fromJson(const {'applicationTokens': 'a,b'}),
        throwsFormatException,
      );
    });

    test('fromJson rejects a non-string token inside the list', () {
      expect(
        () => HardModeSelection.fromJson(const {
          'applicationTokens': ['a', 1],
        }),
        throwsFormatException,
      );
    });
  });
}
