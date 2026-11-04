import 'voice_input_service.dart';

/// Web fallback for [VoiceInputService].
///
/// The real wiring to the browser's Web Speech API lands in a later
/// slice. This service already carries the right surface: construct it
/// with [supportsSpeechApi] = `false` (the default) when the browser
/// does not expose `window.SpeechRecognition` or `webkitSpeechRecognition`
/// — Firefox, every WebKit before Safari 14.1, and any build served
/// without a secure context — and the mic button hides itself the same
/// way as on desktop. When the next slice injects `true` the locale list
/// is ready and [start] will route to the Web Speech bridge.
///
/// Why not just use [StubVoiceInputService] on the web? Because a
/// real build has to tell "the browser does not support it" apart
/// from "the user's phone has no mic plugin": the composer shows a
/// friendly hint in the first case, and does nothing special in the
/// second. Keeping the web class even while it is effectively a stub
/// makes that path explicit.
class WebVoiceInputService implements VoiceInputService {
  const WebVoiceInputService({this.supportsSpeechApi = false});

  /// `true` when the browser exposes a Web Speech API. The later slice
  /// that wires the real recognizer injects this from a `dart:html`
  /// probe behind a conditional import; tests pass the value directly.
  final bool supportsSpeechApi;

  @override
  bool get isAvailable => supportsSpeechApi;

  /// The BCP-47 tags the Web Speech API accepts for Grind's two app
  /// languages. The real recognizer may advertise more; the composer
  /// only needs to pick from these.
  @override
  List<String> get supportedLocales =>
      supportsSpeechApi ? const ['en-US', 'he-IL'] : const [];

  @override
  Stream<VoiceTranscript> start({required String locale}) {
    if (!supportsSpeechApi) {
      return Stream<VoiceTranscript>.error(
        const VoiceInputUnavailable(
          'web speech api is not available in this browser',
        ),
      );
    }
    // The browser bridge lands in a later slice (#43 iOS/web wiring).
    // Fail loudly so a premature call site surfaces in tests rather
    // than looking like a user who said nothing.
    return Stream<VoiceTranscript>.error(
      const VoiceInputUnavailable('web speech api wiring is not yet landed'),
    );
  }

  @override
  Future<void> stop() async {}
}
