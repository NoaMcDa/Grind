import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

/// Builds an environment with sensible defaults — a modern Chrome on
/// desktop with permission not yet granted — so each test only names the
/// field it cares about.
WebPushEnvironment env({
  bool hasServiceWorker = true,
  bool hasPushManager = true,
  bool isIosSafari = false,
  int? iosMajorVersion,
  bool isStandalonePwa = false,
  WebNotificationPermission? notificationPermission =
      WebNotificationPermission.defaultPrompt,
}) => WebPushEnvironment(
  hasServiceWorker: hasServiceWorker,
  hasPushManager: hasPushManager,
  isIosSafari: isIosSafari,
  iosMajorVersion: iosMajorVersion,
  isStandalonePwa: isStandalonePwa,
  notificationPermission: notificationPermission,
);

void main() {
  group('WebPushCapability.from', () {
    test('modern desktop Chrome lands on ready', () {
      expect(WebPushCapability.from(env()), WebPushCapability.ready);
    });

    test('granted permission still reads as ready, not a special bucket', () {
      expect(
        WebPushCapability.from(
          env(notificationPermission: WebNotificationPermission.granted),
        ),
        WebPushCapability.ready,
      );
    });

    test('a denied permission wins over an otherwise capable browser', () {
      // Chrome, SW + PushManager present, but the user turned it off.
      expect(
        WebPushCapability.from(
          env(notificationPermission: WebNotificationPermission.denied),
        ),
        WebPushCapability.permissionDenied,
      );
    });

    test(
      'a denied permission still wins on iOS Safari, in or out of PWA',
      () {
        for (final standalone in const [false, true]) {
          expect(
            WebPushCapability.from(
              env(
                isIosSafari: true,
                iosMajorVersion: 17,
                isStandalonePwa: standalone,
                notificationPermission: WebNotificationPermission.denied,
              ),
            ),
            WebPushCapability.permissionDenied,
            reason: 'denied overrides standalone=$standalone',
          );
        }
      },
    );

    test('missing Notification API collapses to unsupported', () {
      expect(
        WebPushCapability.from(env(notificationPermission: null)),
        WebPushCapability.unsupported,
      );
    });

    test('missing serviceWorker is unsupported', () {
      expect(
        WebPushCapability.from(env(hasServiceWorker: false)),
        WebPushCapability.unsupported,
      );
    });

    test('missing PushManager is unsupported', () {
      // The in-app browser case: SW present, PushManager absent.
      expect(
        WebPushCapability.from(env(hasPushManager: false)),
        WebPushCapability.unsupported,
      );
    });
  });

  group('WebPushCapability.from — iOS Safari gate', () {
    test('iOS 16.4+ in a regular tab needs install', () {
      expect(
        WebPushCapability.from(
          env(
            isIosSafari: true,
            iosMajorVersion: 16,
            isStandalonePwa: false,
          ),
        ),
        WebPushCapability.needsInstall,
      );
      expect(
        WebPushCapability.from(
          env(
            isIosSafari: true,
            iosMajorVersion: 17,
            isStandalonePwa: false,
          ),
        ),
        WebPushCapability.needsInstall,
      );
    });

    test('iOS 16.4+ as an installed PWA is ready', () {
      expect(
        WebPushCapability.from(
          env(
            isIosSafari: true,
            iosMajorVersion: 16,
            isStandalonePwa: true,
          ),
        ),
        WebPushCapability.ready,
      );
    });

    test('iOS 15 or earlier is unsupported, PWA or not', () {
      for (final standalone in const [false, true]) {
        expect(
          WebPushCapability.from(
            env(
              isIosSafari: true,
              iosMajorVersion: 15,
              isStandalonePwa: standalone,
            ),
          ),
          WebPushCapability.unsupported,
          reason: 'iOS 15 standalone=$standalone',
        );
      }
    });

    test('iOS with unknown version is treated as too old', () {
      expect(
        WebPushCapability.from(
          env(isIosSafari: true, iosMajorVersion: null),
        ),
        WebPushCapability.unsupported,
      );
    });

    test('iOS Safari without PushManager is unsupported, even when installed',
        () {
      // Matches iOS 16.0–16.3: the browser shim can claim standalone but has
      // no PushManager.
      expect(
        WebPushCapability.from(
          env(
            hasPushManager: false,
            isIosSafari: true,
            iosMajorVersion: 16,
            isStandalonePwa: true,
          ),
        ),
        WebPushCapability.unsupported,
      );
    });

    test('non-iOS browsers ignore the standalone flag', () {
      // Desktop Chrome — standalone is informational, not a gate.
      expect(
        WebPushCapability.from(env(isStandalonePwa: false)),
        WebPushCapability.ready,
      );
      expect(
        WebPushCapability.from(env(isStandalonePwa: true)),
        WebPushCapability.ready,
      );
    });
  });

  group('WebPushCapability.canSubscribeNow', () {
    test('true only for ready', () {
      expect(WebPushCapability.ready.canSubscribeNow, isTrue);
      expect(WebPushCapability.needsInstall.canSubscribeNow, isFalse);
      expect(WebPushCapability.unsupported.canSubscribeNow, isFalse);
      expect(WebPushCapability.permissionDenied.canSubscribeNow, isFalse);
    });
  });

  group('WebPushEnvironment value semantics', () {
    test('equal by value across every field', () {
      expect(env(), env());
      expect(env().hashCode, env().hashCode);
      expect(
        env(hasPushManager: false),
        isNot(env()),
      );
      expect(
        env(iosMajorVersion: 17),
        isNot(env(iosMajorVersion: 16)),
      );
      expect(
        env(notificationPermission: WebNotificationPermission.granted),
        isNot(env(notificationPermission: WebNotificationPermission.denied)),
      );
    });

    test('toString names each field for logs', () {
      final s = env(
        isIosSafari: true,
        iosMajorVersion: 17,
        isStandalonePwa: true,
      ).toString();
      expect(s, contains('iosSafari: true'));
      expect(s, contains('iosMajor: 17'));
      expect(s, contains('standalone: true'));
    });
  });
}
