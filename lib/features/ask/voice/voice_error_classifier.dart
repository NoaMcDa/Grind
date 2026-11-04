/// Classify a raw voice-recognizer failure code into a small, stable
/// kind and a one-line user-facing message in both app languages (#43).
///
/// The native `speech_to_text` plugin (iOS/Android) and the browser's
/// Web Speech API both signal failures as short string codes —
/// `error_permission`, `error_network`, `not-allowed`, `no-speech`, … —
/// that the Ask composer cannot show directly: half of them are
/// Android-flavoured internals, none of them are localised, and some of
/// them are the same failure under two spellings. Throwing those strings
/// into a snackbar would read like a stack trace.
///
/// This module is the pure-Dart mapping between the two vocabularies.
/// It never touches a plugin, a channel or a locale ARB — a later slice
/// moves the strings into the ARB files when the composer wires them up
/// — so the classifier works the same on iOS, on web and in tests. The
/// value object it returns pairs the classified [VoiceInputErrorKind]
/// with a short EN and HE line the composer can show as-is.
library;

/// The handful of failure categories the Ask composer distinguishes.
///
/// Why these and not more? Each kind maps to a different thing the
/// composer does next: a permission flow, a "keep the mic shut" hint,
/// a "try again" nudge, a fall-back to typing, or a plain apology. Any
/// finer split would be noise to the user; any coarser split and the
/// composer could not tell `error_permission` from a dropped network.
enum VoiceInputErrorKind {
  /// The user's microphone permission is off, or the OS refused it for
  /// this build. The composer leads the user into the permission flow.
  permissionDenied,

  /// The recognizer heard nothing, or heard nothing it could match.
  /// The composer re-arms the mic button and asks the user to try
  /// again; nothing is wrong with the device.
  noSpeech,

  /// The recognizer gave up waiting for the user to start speaking.
  /// Behaviourally the same as [noSpeech] from the user's point of view
  /// but the composer surfaces a slightly different hint so a user who
  /// hesitated once does not wonder what they did wrong.
  speechTimeout,

  /// The recognizer's locale is not one the device can serve (iOS has
  /// not downloaded the on-device model, or the browser does not offer
  /// that language). The composer suggests switching app language or
  /// typing instead; retrying with the same locale will not help.
  languageUnavailable,

  /// The recognizer backend is offline or unreachable. Rare on iOS,
  /// where recognition is on-device, and common on web browsers that
  /// still proxy through a server.
  network,

  /// The recognizer backend rejected the session — quota, rate-limit
  /// or upstream server fault. The composer asks the user to try again
  /// later.
  serverBusy,

  /// The mic is held by another app, another instance of ours, or an
  /// `error_audio`-style capture failure. The composer asks the user
  /// to close whatever else is listening.
  recognizerBusy,

  /// Any other failure the composer cannot act on. The composer shows
  /// a generic apology and keeps the typed text intact.
  unknown,
}

/// A classified voice-input error paired with the short one-line EN and
/// HE copy the composer shows. Every instance is a compile-time
/// constant so the classifier is allocation-free on the hot path.
///
/// The composer picks a language with [forLocale]; tests read [en] and
/// [he] directly to pin the copy without caring about locale negotiation.
class VoiceInputErrorMessage {
  const VoiceInputErrorMessage({
    required this.kind,
    required this.en,
    required this.he,
  });

  /// Which bucket the raw recognizer code fell into.
  final VoiceInputErrorKind kind;

  /// One-line English line fit for a snackbar or an inline hint under
  /// the composer. Short on purpose — the composer has little room.
  final String en;

  /// One-line Hebrew counterpart, with the same intent as [en]. Any
  /// future copy change keeps the two sides in step.
  final String he;

  /// Pick the EN or HE line for a BCP-47-ish locale tag. Anything that
  /// is not Hebrew falls back to English, including an empty string —
  /// the same fallback [VoicePermissionCopy] uses.
  String forLocale(String locale) =>
      locale.toLowerCase().startsWith('he') ? he : en;

  @override
  bool operator ==(Object other) =>
      other is VoiceInputErrorMessage &&
      other.kind == kind &&
      other.en == en &&
      other.he == he;

  @override
  int get hashCode => Object.hash(kind, en, he);

  @override
  String toString() => 'VoiceInputErrorMessage(${kind.name}: "$en" / "$he")';
}

/// The one-line copy for each kind. Kept beside the enum so adding a
/// new kind forces the author to add its EN and HE lines in the same
/// place.
const Map<VoiceInputErrorKind, VoiceInputErrorMessage> _messages = {
  VoiceInputErrorKind.permissionDenied: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.permissionDenied,
    en: "Grind can't hear you — microphone access is off.",
    he: 'אין ל-Grind גישה למיקרופון.',
  ),
  VoiceInputErrorKind.noSpeech: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.noSpeech,
    en: "I didn't catch that. Try again.",
    he: 'לא הצלחתי לשמוע. נסה שוב.',
  ),
  VoiceInputErrorKind.speechTimeout: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.speechTimeout,
    en: 'Tap the mic and speak when you are ready.',
    he: 'הקש על המיקרופון ודבר כשתהיה מוכן.',
  ),
  VoiceInputErrorKind.languageUnavailable: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.languageUnavailable,
    en: 'Voice input is not available in this language yet.',
    he: 'קלט קולי לא זמין בשפה הזו כרגע.',
  ),
  VoiceInputErrorKind.network: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.network,
    en: 'Voice input needs a connection right now.',
    he: 'קלט קולי דורש חיבור לרשת כרגע.',
  ),
  VoiceInputErrorKind.serverBusy: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.serverBusy,
    en: 'Voice input is busy. Try again in a moment.',
    he: 'קלט קולי עמוס. נסה שוב בעוד רגע.',
  ),
  VoiceInputErrorKind.recognizerBusy: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.recognizerBusy,
    en: 'The microphone is in use by another app.',
    he: 'המיקרופון בשימוש על ידי אפליקציה אחרת.',
  ),
  VoiceInputErrorKind.unknown: VoiceInputErrorMessage(
    kind: VoiceInputErrorKind.unknown,
    en: "Voice input didn't work. Type instead?",
    he: 'קלט קולי לא עבד. אולי להקליד במקום?',
  ),
};

/// Classify a raw voice-recognizer failure code.
///
/// Handles both vocabularies the Ask composer can see:
/// * `speech_to_text` on iOS/Android emits `error_permission`,
///   `error_network`, `error_no_match`, `error_speech_timeout`,
///   `error_server`, `error_too_many_requests`, `error_busy`,
///   `error_audio`, `error_client` and `error_language_not_supported`.
/// * The Web Speech API emits `not-allowed`, `service-not-allowed`,
///   `no-speech`, `audio-capture`, `network`, `aborted`, `bad-grammar`
///   and `language-not-supported`.
///
/// Matching is case-insensitive and tolerant of both underscore and
/// hyphen separators so a code copied from either side classifies to
/// the same kind. A `null`, empty or unrecognised code classifies to
/// [VoiceInputErrorKind.unknown]; an `aborted` code (the user cancelled
/// the session themselves) also classifies to unknown so the caller
/// does not accidentally show a snackbar for a user-initiated stop —
/// the caller should check for cancellation before classifying.
VoiceInputErrorMessage classifyVoiceInputError(String? code) {
  final kind = _kindFor(_normalize(code));
  return _messages[kind]!;
}

/// The classified kind for a raw code, without the copy. Useful for
/// callers that only want to switch on the kind.
VoiceInputErrorKind classifyVoiceInputErrorKind(String? code) =>
    _kindFor(_normalize(code));

/// Lowercase, trim and collapse `-`/`_` so `error_no_match`, `no-match`
/// and `NoMatch` all land on the same lookup key.
String _normalize(String? code) {
  if (code == null) return '';
  final lowered = code.toLowerCase().trim();
  if (lowered.isEmpty) return '';
  return lowered.replaceAll('-', '_');
}

VoiceInputErrorKind _kindFor(String code) {
  switch (code) {
    case 'error_permission':
    case 'permission':
    case 'permission_denied':
    case 'not_allowed':
      return VoiceInputErrorKind.permissionDenied;

    case 'error_no_match':
    case 'no_match':
    case 'no_speech':
    case 'bad_grammar':
      return VoiceInputErrorKind.noSpeech;

    case 'error_speech_timeout':
    case 'speech_timeout':
      return VoiceInputErrorKind.speechTimeout;

    case 'error_language_not_supported':
    case 'language_not_supported':
      return VoiceInputErrorKind.languageUnavailable;

    case 'error_network':
    case 'error_network_timeout':
    case 'network':
    case 'network_timeout':
      return VoiceInputErrorKind.network;

    case 'error_server':
    case 'error_too_many_requests':
    case 'service_not_allowed':
    case 'too_many_requests':
      return VoiceInputErrorKind.serverBusy;

    case 'error_busy':
    case 'error_audio':
    case 'audio_capture':
    case 'busy':
      return VoiceInputErrorKind.recognizerBusy;

    default:
      return VoiceInputErrorKind.unknown;
  }
}
