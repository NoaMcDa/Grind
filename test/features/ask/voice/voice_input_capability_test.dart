import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/voice/voice.dart';

void main() {
  group('classifyVoiceInputCapability', () {
    group('hidden cases', () {
      test('returns unsupportedPlatform when the native service is absent', () {
        final cap = classifyVoiceInputCapability(
          isWeb: false,
          serviceAvailable: false,
        );
        expect(cap, VoiceInputCapability.unsupportedPlatform);
      });

      test('returns unsupportedBrowser when the web service is absent', () {
        final cap = classifyVoiceInputCapability(
          isWeb: true,
          serviceAvailable: false,
        );
        expect(cap, VoiceInputCapability.unsupportedBrowser);
      });

      test(
        'service absence wins over a granted permission on the native side',
        () {
          // A granted permission does not rescue a build without a
          // recognizer: the button must still hide.
          final cap = classifyVoiceInputCapability(
            isWeb: false,
            serviceAvailable: false,
            permission: MicPermissionStatus.granted,
          );
          expect(cap, VoiceInputCapability.unsupportedPlatform);
        },
      );

      test(
        'service absence wins over a granted permission on the web side',
        () {
          final cap = classifyVoiceInputCapability(
            isWeb: true,
            serviceAvailable: false,
            permission: MicPermissionStatus.granted,
          );
          expect(cap, VoiceInputCapability.unsupportedBrowser);
        },
      );

      test('service absence wins over a denied permission too', () {
        final cap = classifyVoiceInputCapability(
          isWeb: false,
          serviceAvailable: false,
          permission: MicPermissionStatus.denied,
        );
        expect(cap, VoiceInputCapability.unsupportedPlatform);
      });
    });

    group('permission cases', () {
      test('returns permissionDenied when the user revoked access', () {
        final cap = classifyVoiceInputCapability(
          isWeb: false,
          serviceAvailable: true,
          permission: MicPermissionStatus.denied,
        );
        expect(cap, VoiceInputCapability.permissionDenied);
      });

      test(
        'returns permissionPending when the permission has not been asked',
        () {
          final cap = classifyVoiceInputCapability(
            isWeb: false,
            serviceAvailable: true,
            permission: MicPermissionStatus.undetermined,
          );
          expect(cap, VoiceInputCapability.permissionPending);
        },
      );

      test('permission state applies on the web too', () {
        final cap = classifyVoiceInputCapability(
          isWeb: true,
          serviceAvailable: true,
          permission: MicPermissionStatus.denied,
        );
        expect(cap, VoiceInputCapability.permissionDenied);
      });
    });

    group('available cases', () {
      test('returns available with a granted permission', () {
        final cap = classifyVoiceInputCapability(
          isWeb: false,
          serviceAvailable: true,
          permission: MicPermissionStatus.granted,
        );
        expect(cap, VoiceInputCapability.available);
      });

      test('returns available when the permission is notApplicable', () {
        // The default for tests and surfaces that do not need to probe
        // the OS permission.
        final cap = classifyVoiceInputCapability(
          isWeb: false,
          serviceAvailable: true,
        );
        expect(cap, VoiceInputCapability.available);
      });

      test('returns available on the web with a granted permission', () {
        final cap = classifyVoiceInputCapability(
          isWeb: true,
          serviceAvailable: true,
          permission: MicPermissionStatus.granted,
        );
        expect(cap, VoiceInputCapability.available);
      });
    });
  });

  group('VoiceInputCapability.shouldShowButton', () {
    test('true for available, permissionPending and permissionDenied', () {
      expect(VoiceInputCapability.available.shouldShowButton, isTrue);
      expect(VoiceInputCapability.permissionPending.shouldShowButton, isTrue);
      expect(VoiceInputCapability.permissionDenied.shouldShowButton, isTrue);
    });

    test('false for the hidden cases', () {
      expect(
        VoiceInputCapability.unsupportedPlatform.shouldShowButton,
        isFalse,
      );
      expect(VoiceInputCapability.unsupportedBrowser.shouldShowButton, isFalse);
    });
  });

  group('VoiceInputCapability.isUsable', () {
    test('true only when a tap can start or trigger the mic prompt', () {
      expect(VoiceInputCapability.available.isUsable, isTrue);
      expect(VoiceInputCapability.permissionPending.isUsable, isTrue);
    });

    test('false for the disabled and hidden cases', () {
      expect(VoiceInputCapability.permissionDenied.isUsable, isFalse);
      expect(VoiceInputCapability.unsupportedPlatform.isUsable, isFalse);
      expect(VoiceInputCapability.unsupportedBrowser.isUsable, isFalse);
    });
  });

  group('VoiceInputCapability.isHidden', () {
    test('true only for the unsupported-* cases', () {
      expect(VoiceInputCapability.unsupportedPlatform.isHidden, isTrue);
      expect(VoiceInputCapability.unsupportedBrowser.isHidden, isTrue);
    });

    test('false for every case the composer renders a button in', () {
      expect(VoiceInputCapability.available.isHidden, isFalse);
      expect(VoiceInputCapability.permissionPending.isHidden, isFalse);
      expect(VoiceInputCapability.permissionDenied.isHidden, isFalse);
    });

    test('isHidden and shouldShowButton are exact opposites', () {
      for (final cap in VoiceInputCapability.values) {
        expect(
          cap.isHidden,
          !cap.shouldShowButton,
          reason:
              'capability $cap must be either hidden or shown, '
              'not both and not neither',
        );
      }
    });
  });

  group('decision table coverage', () {
    test('every (isWeb, serviceAvailable, permission) combination maps', () {
      // Pin the whole decision table so a future tweak in the
      // classifier surfaces as a test change, not a silent regression.
      final table = <(bool, bool, MicPermissionStatus), VoiceInputCapability>{
        // Service absent -> hidden per platform, permission ignored.
        (false, false, MicPermissionStatus.notApplicable):
            VoiceInputCapability.unsupportedPlatform,
        (false, false, MicPermissionStatus.granted):
            VoiceInputCapability.unsupportedPlatform,
        (false, false, MicPermissionStatus.undetermined):
            VoiceInputCapability.unsupportedPlatform,
        (false, false, MicPermissionStatus.denied):
            VoiceInputCapability.unsupportedPlatform,
        (true, false, MicPermissionStatus.notApplicable):
            VoiceInputCapability.unsupportedBrowser,
        (true, false, MicPermissionStatus.granted):
            VoiceInputCapability.unsupportedBrowser,
        (true, false, MicPermissionStatus.undetermined):
            VoiceInputCapability.unsupportedBrowser,
        (true, false, MicPermissionStatus.denied):
            VoiceInputCapability.unsupportedBrowser,
        // Service present -> permission drives the outcome.
        (false, true, MicPermissionStatus.notApplicable):
            VoiceInputCapability.available,
        (false, true, MicPermissionStatus.granted):
            VoiceInputCapability.available,
        (false, true, MicPermissionStatus.undetermined):
            VoiceInputCapability.permissionPending,
        (false, true, MicPermissionStatus.denied):
            VoiceInputCapability.permissionDenied,
        (true, true, MicPermissionStatus.notApplicable):
            VoiceInputCapability.available,
        (true, true, MicPermissionStatus.granted):
            VoiceInputCapability.available,
        (true, true, MicPermissionStatus.undetermined):
            VoiceInputCapability.permissionPending,
        (true, true, MicPermissionStatus.denied):
            VoiceInputCapability.permissionDenied,
      };
      for (final entry in table.entries) {
        final (isWeb, serviceAvailable, permission) = entry.key;
        expect(
          classifyVoiceInputCapability(
            isWeb: isWeb,
            serviceAvailable: serviceAvailable,
            permission: permission,
          ),
          entry.value,
          reason:
              'isWeb=$isWeb, serviceAvailable=$serviceAvailable, '
              'permission=$permission',
        );
      }
    });
  });
}
