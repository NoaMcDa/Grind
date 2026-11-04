import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/hard_mode_shield/hard_mode_shield.dart';

void main() {
  group('HardModeStatus', () {
    test('off has no shielded count and no flags set', () {
      final s = HardModeStatus.off;
      expect(s.phase, HardModePhase.off);
      expect(s.shieldedCount, 0);
      expect(s.isShielding, isFalse);
      expect(s.needsAuthorization, isFalse);
    });

    test('unauthorized reads as needing authorization, not shielding', () {
      final s = HardModeStatus.unauthorized;
      expect(s.phase, HardModePhase.unauthorized);
      expect(s.shieldedCount, 0);
      expect(s.isShielding, isFalse);
      expect(s.needsAuthorization, isTrue);
    });

    test('authorizedIdle has no shielded count and is not shielding', () {
      final s = HardModeStatus.authorizedIdle;
      expect(s.phase, HardModePhase.authorizedIdle);
      expect(s.shieldedCount, 0);
      expect(s.isShielding, isFalse);
      expect(s.needsAuthorization, isFalse);
    });

    test('shielded(N) carries the count and flips isShielding', () {
      final s = HardModeStatus.shielded(3);
      expect(s.phase, HardModePhase.shielded);
      expect(s.shieldedCount, 3);
      expect(s.isShielding, isTrue);
      expect(s.needsAuthorization, isFalse);
    });

    test('shielded with zero or fewer apps is rejected in debug', () {
      expect(() => HardModeStatus.shielded(0), throwsA(isA<AssertionError>()));
      expect(() => HardModeStatus.shielded(-1), throwsA(isA<AssertionError>()));
    });

    group('fromSelection', () {
      test('off when the selection is disabled, whatever the auth', () {
        const disabled = HardModeSelection.empty;
        expect(
          HardModeStatus.fromSelection(disabled, authorized: false),
          HardModeStatus.off,
        );
        expect(
          HardModeStatus.fromSelection(disabled, authorized: true),
          HardModeStatus.off,
        );
      });

      test(
        'off when the switch is off, even when the user already picked apps',
        () {
          final picked = HardModeSelection(
            enabled: false,
            applicationTokens: const ['a', 'b'],
          );
          expect(
            HardModeStatus.fromSelection(picked, authorized: true),
            HardModeStatus.off,
          );
        },
      );

      test('unauthorized when enabled but not authorized', () {
        final enabled = HardModeSelection(
          enabled: true,
          applicationTokens: const ['a'],
        );
        expect(
          HardModeStatus.fromSelection(enabled, authorized: false),
          HardModeStatus.unauthorized,
        );
      });

      test('authorizedIdle when enabled and authorized with no tokens', () {
        final enabled = HardModeSelection(enabled: true);
        expect(
          HardModeStatus.fromSelection(enabled, authorized: true),
          HardModeStatus.authorizedIdle,
        );
      });

      test('shielded(N) when enabled, authorized and N tokens are picked', () {
        final enabled = HardModeSelection(
          enabled: true,
          applicationTokens: const ['a', 'b', 'c'],
        );
        final status = HardModeStatus.fromSelection(enabled, authorized: true);
        expect(status.phase, HardModePhase.shielded);
        expect(status.shieldedCount, 3);
        expect(status, HardModeStatus.shielded(3));
      });
    });

    test('equality is by phase and count', () {
      expect(HardModeStatus.off, HardModeStatus.off);
      expect(HardModeStatus.off.hashCode, HardModeStatus.off.hashCode);
      expect(HardModeStatus.shielded(2), HardModeStatus.shielded(2));
      expect(
        HardModeStatus.shielded(2).hashCode,
        HardModeStatus.shielded(2).hashCode,
      );
      expect(HardModeStatus.shielded(2) == HardModeStatus.shielded(3), isFalse);
      expect(HardModeStatus.off == HardModeStatus.authorizedIdle, isFalse);
    });

    test('toString names the phase and count', () {
      expect(HardModeStatus.off.toString(), contains('off'));
      expect(HardModeStatus.shielded(5).toString(), contains('shielded'));
      expect(HardModeStatus.shielded(5).toString(), contains('5'));
    });
  });
}
