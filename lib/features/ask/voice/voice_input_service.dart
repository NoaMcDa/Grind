/// Natural-language voice capture for the Ask composer (#43).
///
/// A thin platform bridge: iOS uses on-device `speech_to_text` (a later
/// slice wires the native side), the web uses the Web Speech API where
/// present, and every other surface — tests, Android, desktop, iOS when
/// the user turned the mic permission off — falls back to the stub,
/// which reports [isAvailable] as false and refuses [start].
///
/// Everything a caller needs to show the mic button correctly lives
/// behind this interface: the reactive partial/final transcript stream,
/// the supported locales for negotiation, and whether speech is wired
/// up at all on this device. The transcript is handed back as text; the
/// Ask composer runs it through the same capture path as typed input
/// (#39) so the user always sees the words before sending.
abstract interface class VoiceInputService {
  /// `true` when a real recognizer is present and the user can be asked
  /// to speak. Call sites hide the mic button when this is `false` so
  /// web Safari and desktop never show a dead affordance.
  bool get isAvailable;

  /// BCP-47 locale tags this recognizer accepts, in a stable order. The
  /// composer picks one with [negotiateLocale] against the user's app
  /// language; an empty list means voice is not available.
  List<String> get supportedLocales;

  /// Begin listening. [locale] is a BCP-47 tag picked by the caller
  /// with [negotiateLocale]. Yields [VoiceTranscript] values as the
  /// user speaks: zero or more [VoiceTranscript.partial] values and
  /// exactly one [VoiceTranscript.isFinal] value when the recognizer
  /// commits, after which the stream closes.
  ///
  /// Throws [VoiceInputUnavailable] when [isAvailable] is `false` or
  /// the OS refuses the microphone.
  Stream<VoiceTranscript> start({required String locale});

  /// Cancels an in-flight [start]. Safe to call when nothing is
  /// listening. The caller still sees the stream close.
  Future<void> stop();
}

/// One transcript tick from the recognizer. [text] holds what the
/// user has said so far. [isFinal] marks the last tick in the stream;
/// everything before it is a partial, mutable guess.
class VoiceTranscript {
  const VoiceTranscript(this.text, {required this.isFinal});

  /// A partial, still-changing transcript the composer can preview.
  const VoiceTranscript.partial(String text) : this(text, isFinal: false);

  /// The recognizer's committed transcript. The stream closes after.
  const VoiceTranscript.finalResult(String text) : this(text, isFinal: true);

  /// What the user has said so far, in the recognizer's locale.
  final String text;

  /// `true` for the committed transcript; `false` for every partial
  /// tick before it.
  final bool isFinal;

  @override
  bool operator ==(Object other) =>
      other is VoiceTranscript &&
      other.text == text &&
      other.isFinal == isFinal;

  @override
  int get hashCode => Object.hash(text, isFinal);

  @override
  String toString() =>
      'VoiceTranscript(${isFinal ? 'final' : 'partial'}: $text)';
}

/// Thrown by [VoiceInputService.start] when the recognizer is missing,
/// the mic permission was denied or the user's locale is not one of
/// [VoiceInputService.supportedLocales].
class VoiceInputUnavailable implements Exception {
  const VoiceInputUnavailable(this.reason);
  final String reason;

  @override
  String toString() => 'VoiceInputUnavailable: $reason';
}

/// No-op recognizer used for tests, web Safari, Android, desktop and
/// any iOS build where the native plugin is not wired up yet. Reports
/// [isAvailable] as `false`, keeps [supportedLocales] empty, and
/// [start] fails with [VoiceInputUnavailable] rather than returning a
/// silent stream — so a misconfigured call site surfaces loudly in
/// tests instead of looking like a user who said nothing.
class StubVoiceInputService implements VoiceInputService {
  const StubVoiceInputService();

  @override
  bool get isAvailable => false;

  @override
  List<String> get supportedLocales => const [];

  @override
  Stream<VoiceTranscript> start({required String locale}) =>
      Stream<VoiceTranscript>.error(
        const VoiceInputUnavailable('voice input not available on this device'),
      );

  @override
  Future<void> stop() async {}
}

/// Pick the recognizer locale that matches the user's app language
/// best. Matching is BCP-47 case-insensitive and tolerant of the
/// language-only shorthand `he`/`en` the Grind preferences store, as
/// well as the region-tagged `he-IL`/`en-US` the native recognizers
/// report.
///
/// Returns the first [supported] locale whose base language matches
/// [appLocale], preferring an exact tag match over the base-language
/// match. Returns `null` when nothing matches, which the caller treats
/// as "voice not available in this language".
String? negotiateLocale({
  required String appLocale,
  required List<String> supported,
}) {
  if (supported.isEmpty) return null;
  final target = appLocale.toLowerCase().replaceAll('_', '-');
  final targetBase = target.split('-').first;
  String? baseMatch;
  for (final tag in supported) {
    final lower = tag.toLowerCase().replaceAll('_', '-');
    if (lower == target) return tag;
    if (baseMatch == null && lower.split('-').first == targetBase) {
      baseMatch = tag;
    }
  }
  return baseMatch;
}

/// Short permission copy and the privacy note shown next to the mic
/// button. Kept with the abstraction so every VoiceInputService
/// implementation ships the same strings; a later slice moves these
/// into the ARB files once the composer wires them in.
///
/// These are intentionally terse: the mic button is a small target and
/// the privacy note has to fit under the composer in both languages.
abstract final class VoicePermissionCopy {
  /// English permission prompt rationale.
  static const permissionEn =
      'Grind needs the microphone to hear you speak a task. '
      'Speech stays on your device.';

  /// Hebrew permission prompt rationale.
  static const permissionHe =
      'Grind צריך את המיקרופון כדי לשמוע אותך אומר משימה. '
      'הדיבור נשאר במכשיר שלך.';

  /// English privacy footnote under the composer.
  static const privacyNoteEn =
      'Voice recognition runs on your device. Nothing is sent to the cloud.';

  /// Hebrew privacy footnote under the composer.
  static const privacyNoteHe =
      'זיהוי הדיבור רץ על המכשיר שלך. שום דבר לא נשלח לענן.';

  /// Pick the EN or HE permission rationale for a BCP-47-ish locale
  /// tag. Anything that is not Hebrew falls back to English, including
  /// an empty string.
  static String permissionFor(String locale) =>
      locale.toLowerCase().startsWith('he') ? permissionHe : permissionEn;

  /// Pick the EN or HE privacy footnote for a BCP-47-ish locale tag.
  static String privacyNoteFor(String locale) =>
      locale.toLowerCase().startsWith('he') ? privacyNoteHe : privacyNoteEn;
}
