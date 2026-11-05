/// Classifies what the current browser can do with Web Push, so Settings and
/// `WebNotificationService` can show the right copy and gate the subscribe
/// flow (`docs/web/push-limits.md`, issue #47).
///
/// The actual environment flags are read later from Dart via `package:web` or
/// `dart:js_interop`: `serviceWorker`, `'PushManager' in window`, the iOS
/// standalone media query, `Notification.permission`. Keeping the classifier
/// here as pure Dart lets the Settings page, the tests and the (future) JS
/// bridge agree on one decision table without pulling browser types into
/// anything that isn't the browser.
///
/// The output buckets mirror the four sections in `docs/web/push-limits.md`:
///
///   - `ready`              → "Push works here" (offer the toggle; after
///                           permission is granted, this is also the state
///                           used while subscribed).
///   - `needsInstall`       → "Push would work after installing" — iOS Safari
///                           16.4+ in a regular tab. The only install path
///                           on iOS is Share > Add to Home Screen, so the
///                           page shows instructions, not a button.
///   - `unsupported`        → `PushManager` missing, iOS < 16.4, in-app
///                           browser, private window, etc.
///   - `permissionDenied`   → user has turned reminders off for the site;
///                           link to the browser's site-permissions page.
library;

/// A point-in-time snapshot of the browser flags the classifier reads. The
/// caller fills every field; `null` is reserved for "we could not determine
/// this" (e.g. user-agent parsing failed), so the classifier can be strict.
class WebPushEnvironment {
  const WebPushEnvironment({
    required this.hasServiceWorker,
    required this.hasPushManager,
    required this.isIosSafari,
    required this.iosMajorVersion,
    required this.isStandalonePwa,
    required this.notificationPermission,
  });

  /// True when `window.navigator.serviceWorker` exists. A service worker is
  /// the only way to deliver a notification while the tab is closed.
  final bool hasServiceWorker;

  /// True when `'PushManager' in window`. Separate from [hasServiceWorker]
  /// because Safari exposes `serviceWorker` far earlier than `PushManager`
  /// and in-app browsers sometimes expose one but not the other.
  final bool hasPushManager;

  /// True when the user agent is Safari on iOS or iPadOS. Needed because the
  /// iOS gate (installed-PWA + 16.4+) only applies on that platform.
  final bool isIosSafari;

  /// The major iOS / iPadOS version, or null when it could not be parsed.
  /// Everything below 16 cannot subscribe; 16.4 is the first version with
  /// Web Push in an installed PWA. A null value is treated as too old.
  final int? iosMajorVersion;

  /// True when the page is running as an installed PWA — either
  /// `matchMedia('(display-mode: standalone)').matches` or, on iOS, the
  /// legacy `navigator.standalone` boolean. Push subscription on iOS Safari
  /// requires this; on other browsers it is informational.
  final bool isStandalonePwa;

  /// Snapshot of `Notification.permission`. `null` means the API itself is
  /// missing (the DOM has no `Notification` global), which collapses to
  /// [WebPushCapability.unsupported].
  final WebNotificationPermission? notificationPermission;

  @override
  bool operator ==(Object other) =>
      other is WebPushEnvironment &&
      other.hasServiceWorker == hasServiceWorker &&
      other.hasPushManager == hasPushManager &&
      other.isIosSafari == isIosSafari &&
      other.iosMajorVersion == iosMajorVersion &&
      other.isStandalonePwa == isStandalonePwa &&
      other.notificationPermission == notificationPermission;

  @override
  int get hashCode => Object.hash(
    hasServiceWorker,
    hasPushManager,
    isIosSafari,
    iosMajorVersion,
    isStandalonePwa,
    notificationPermission,
  );

  @override
  String toString() =>
      'WebPushEnvironment(serviceWorker: $hasServiceWorker, '
      'pushManager: $hasPushManager, iosSafari: $isIosSafari, '
      'iosMajor: $iosMajorVersion, standalone: $isStandalonePwa, '
      'permission: $notificationPermission)';
}

/// The three values `Notification.permission` can hold, with `null` on the
/// [WebPushEnvironment] standing in for "the API is missing entirely".
enum WebNotificationPermission { granted, denied, defaultPrompt }

/// The four Settings states derived from a [WebPushEnvironment]. Each value
/// maps to one block of copy in `docs/web/push-limits.md`.
enum WebPushCapability {
  /// Push works in this browser and the user has not explicitly denied it.
  /// Also the state while the user is already subscribed — Settings reads
  /// the toggle state separately.
  ready,

  /// iOS Safari 16.4+ in a regular tab. The user needs to install the PWA
  /// from the Share menu first. There is no `beforeinstallprompt` on iOS,
  /// so Settings shows instructions, not a button.
  needsInstall,

  /// The browser cannot deliver background notifications at all: no
  /// `PushManager`, iOS below 16.4, an in-app browser, a private window.
  /// Settings shows the "What this means" link and the Today card keeps
  /// doing the work.
  unsupported,

  /// The user (or the browser, in private mode) turned the permission off.
  /// Re-prompting is not allowed; link to site settings.
  permissionDenied;

  /// Decision table. Order matters:
  ///
  ///   1. If the Notification API itself is missing, nothing above matters
  ///      — bucket as [unsupported].
  ///   2. A `denied` permission always wins, even on an otherwise capable
  ///      browser, because re-prompt is blocked and the user has to flip it
  ///      in site settings.
  ///   3. No service worker or no `PushManager` → [unsupported].
  ///   4. On iOS Safari, subscribe only works in an installed PWA on 16.4+.
  ///      iOS 16.4+ in a tab → [needsInstall]; anything older → [unsupported].
  ///   5. Otherwise → [ready].
  static WebPushCapability from(WebPushEnvironment env) {
    final permission = env.notificationPermission;
    if (permission == null) return WebPushCapability.unsupported;
    if (permission == WebNotificationPermission.denied) {
      return WebPushCapability.permissionDenied;
    }
    if (!env.hasServiceWorker || !env.hasPushManager) {
      return WebPushCapability.unsupported;
    }
    if (env.isIosSafari) {
      final major = env.iosMajorVersion;
      if (major == null || major < 16) {
        return WebPushCapability.unsupported;
      }
      // 16.0–16.3 has no `PushManager`, but if the snapshot claims it does
      // treat it as a browser bug and still require 16.4. The snapshot's
      // `iosMajorVersion` is coarse (major only), so 16.0–16.3 ride along
      // with 16.4+; that is acceptable because the `PushManager` check above
      // would have already rejected 16.0–16.3 in the real world.
      if (!env.isStandalonePwa) return WebPushCapability.needsInstall;
    }
    return WebPushCapability.ready;
  }

  /// True when the Settings toggle should be offered. The "offer" copy
  /// differs between [ready] and [needsInstall]; this is just the predicate
  /// for "something the user can act on now or soon".
  bool get canSubscribeNow => this == WebPushCapability.ready;
}
