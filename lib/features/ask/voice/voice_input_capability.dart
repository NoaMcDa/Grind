/// Pure-Dart platform/browser gate for the composer's mic button (#43).
///
/// The Ask composer needs more than a yes/no when it decides what to
/// render for the mic:
///
/// * On Firefox, on any desktop or iOS build before the native
///   `speech_to_text` wiring, and on a non-secure web context, the
///   button is **hidden** entirely — there is no recognizer to attach
///   to and showing a dead affordance would just confuse people.
/// * On an iOS build where the user flipped the microphone permission
///   off in Settings the button stays **visible but disabled**, and
///   the composer shows a one-line "turn it back on" hint; hiding it
///   would make it look like the feature vanished.
/// * On a build where the permission has not been asked yet the
///   button is live and tapping it kicks off the OS permission flow.
/// * On a fully-wired build with the permission granted the button is
///   live.
///
/// This classifier is the pure-Dart gate that turns the signals the
/// composer already has — is this web, does the active
/// [VoiceInputService] report `isAvailable`, what does the OS say
/// about the microphone permission — into a single enum the widget
/// can switch on. It never touches a plugin or a channel, so it works
/// the same on iOS, web and in tests; the platform probes live at the
/// call site.
library;

/// How the composer should render its mic affordance on this surface.
///
/// Used as the output of [classifyVoiceInputCapability]. The widget
/// layer uses [shouldShowButton] / [isUsable] to pick its visual
/// treatment; a test can also assert the exact enum to pin the
/// decision table.
enum VoiceInputCapability {
  /// Full speech recognition is wired up and permitted. Show the mic
  /// button; tapping it opens a dictation session.
  available,

  /// The recognizer is wired up on this surface but the user has not
  /// been asked for microphone access yet. Show the mic button; the
  /// first tap triggers the OS permission prompt.
  permissionPending,

  /// The user revoked microphone access in iOS Settings (or an
  /// equivalent prompt on the web). Show the mic button in a muted,
  /// disabled state with a hint that links to Settings — hiding it
  /// would make the feature look missing.
  permissionDenied,

  /// This platform has no recognizer wired up — Android, desktop, and
  /// any iOS build before the native `speech_to_text` slice lands.
  /// Hide the mic button; there is nothing to tap.
  unsupportedPlatform,

  /// This browser does not expose a Web Speech API — Firefox at the
  /// time of writing, every non-secure context, and any WebKit build
  /// before Safari 14.1. Hide the mic button; the hint about picking
  /// a different browser is up to the surrounding UI if it wants one.
  unsupportedBrowser;

  /// `true` when the composer should render the mic button at all.
  /// Hidden cases map to `false`; both permission states still show
  /// the button so the user can discover the feature.
  bool get shouldShowButton =>
      this == available ||
      this == permissionPending ||
      this == permissionDenied;

  /// `true` when a tap starts a dictation session right now. The
  /// permission-pending case still returns `true` because the OS
  /// prompt is part of the normal start path — the session kicks off
  /// once the user grants access. The disabled, denied and hidden
  /// cases return `false`.
  bool get isUsable => this == available || this == permissionPending;

  /// `true` when a capability indicates "the device has no recognizer"
  /// rather than "the user turned it off". Call sites use it to decide
  /// whether a hint belongs in the UI (permission cases) or whether
  /// the button just disappears (hidden cases).
  bool get isHidden =>
      this == unsupportedPlatform || this == unsupportedBrowser;
}

/// What the OS currently reports about the microphone permission.
///
/// Mirrors the three states every mobile OS and the Web Speech API
/// agree on, plus a fourth [notApplicable] for surfaces where the
/// recognizer never needs to ask (the web before the user opts in to
/// the API, and every test that does not inject a permission probe).
///
/// Classifier input only — the real permission check lives behind a
/// plugin and is wired up in a later slice.
enum MicPermissionStatus {
  /// The user granted the microphone permission. The recognizer may
  /// open the mic without a prompt.
  granted,

  /// The user has not been asked yet. The recognizer may open the mic
  /// but the OS will put a prompt in front of the first attempt.
  undetermined,

  /// The user denied the permission (or revoked it later in Settings).
  /// Opening the mic will fail; the composer has to send them to
  /// Settings to flip it back on.
  denied,

  /// The permission state is irrelevant on this surface — e.g. the
  /// web before the Web Speech API is available, or a test that only
  /// cares about the platform gate.
  notApplicable,
}

/// Decide what the composer should do about its mic button on this
/// surface.
///
/// The caller passes the signals it already has:
///
/// * [isWeb] — whether the app is running in a browser. Used only to
///   split the hidden case into [VoiceInputCapability.unsupportedBrowser]
///   (web) vs [VoiceInputCapability.unsupportedPlatform] (native).
/// * [serviceAvailable] — the active [VoiceInputService.isAvailable]
///   value. The classifier trusts this: when it is `false`, voice is
///   hidden regardless of the permission.
/// * [permission] — the OS-reported microphone permission. Defaults
///   to [MicPermissionStatus.notApplicable], which treats the button
///   as live as long as the service is wired up; call sites that
///   know the permission should pass it so the denied case surfaces.
///
/// Returns the matching [VoiceInputCapability]. Pure function: no
/// plugins, no channels, no side effects.
VoiceInputCapability classifyVoiceInputCapability({
  required bool isWeb,
  required bool serviceAvailable,
  MicPermissionStatus permission = MicPermissionStatus.notApplicable,
}) {
  if (!serviceAvailable) {
    return isWeb
        ? VoiceInputCapability.unsupportedBrowser
        : VoiceInputCapability.unsupportedPlatform;
  }
  switch (permission) {
    case MicPermissionStatus.denied:
      return VoiceInputCapability.permissionDenied;
    case MicPermissionStatus.undetermined:
      return VoiceInputCapability.permissionPending;
    case MicPermissionStatus.granted:
    case MicPermissionStatus.notApplicable:
      return VoiceInputCapability.available;
  }
}
