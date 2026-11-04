import 'dart:async';

import 'voice_input_service.dart';

/// Which phase of a dictation session the composer is in.
///
/// The composer drives the mic button and the composer text from this:
/// * [idle] — the mic is dormant; the composer shows what the user typed.
/// * [listening] — the recognizer is open and partial transcripts stream
///   into [VoiceSessionState.text]; the composer previews that text, and
///   the user sees every change before anything is sent.
/// * [committed] — the recognizer handed back its final transcript; the
///   composer drops that text into the input so the user can review and
///   edit before pressing send. The session stays in this phase until
///   the caller resets it.
/// * [cancelled] — [VoiceSessionController.stop] was called before any
///   final transcript arrived; the composer discards whatever partial
///   text had accumulated.
/// * [error] — the recognizer errored out (no permission, no network,
///   unsupported locale, …); the composer surfaces [VoiceSessionState.error]
///   and keeps the typed text intact.
enum VoiceSessionPhase { idle, listening, committed, cancelled, error }

/// Immutable snapshot of a dictation session.
///
/// Every state transition builds a new instance; the controller never
/// mutates a state it already handed out so tests and widgets can hold
/// an old value for comparison.
class VoiceSessionState {
  const VoiceSessionState({
    required this.phase,
    this.text = '',
    this.locale,
    this.error,
  });

  /// The resting state the controller starts in and returns to after
  /// [VoiceSessionController.reset].
  const VoiceSessionState.idle()
    : phase = VoiceSessionPhase.idle,
      text = '',
      locale = null,
      error = null;

  final VoiceSessionPhase phase;

  /// The transcript so far. In [VoiceSessionPhase.listening] this is the
  /// latest partial; in [VoiceSessionPhase.committed] it is the final
  /// transcript the recognizer closed on; in every other phase it is
  /// the empty string.
  final String text;

  /// The BCP-47 locale the recognizer is using, when one was negotiated.
  /// `null` in [VoiceSessionPhase.idle] and [VoiceSessionPhase.error]
  /// when the error was raised before a locale was picked.
  final String? locale;

  /// Why the session is in [VoiceSessionPhase.error]. `null` in every
  /// other phase.
  final VoiceInputUnavailable? error;

  /// `true` when the user is currently dictating; the composer shows
  /// the listening indicator while this is on.
  bool get isListening => phase == VoiceSessionPhase.listening;

  /// `true` when a final transcript is ready for the composer to drop
  /// into the input; a widget listening for this edge pulls [text] and
  /// then calls [VoiceSessionController.reset].
  bool get hasFinalTranscript => phase == VoiceSessionPhase.committed;

  @override
  bool operator ==(Object other) =>
      other is VoiceSessionState &&
      other.phase == phase &&
      other.text == text &&
      other.locale == locale &&
      other.error?.reason == error?.reason;

  @override
  int get hashCode => Object.hash(phase, text, locale, error?.reason);

  @override
  String toString() {
    final buf = StringBuffer('VoiceSessionState(')..write(phase.name);
    if (locale != null) buf.write(', $locale');
    if (text.isNotEmpty) buf.write(', "$text"');
    if (error != null) buf.write(', error: ${error!.reason}');
    buf.write(')');
    return buf.toString();
  }
}

/// Pure-Dart state machine wrapping a [VoiceInputService] for the Ask
/// composer.
///
/// Owns one dictation session at a time: [start] negotiates a locale,
/// opens the recognizer, forwards partial transcripts into [state] and
/// flips to [VoiceSessionPhase.committed] when the recognizer closes.
/// [stop] cancels an in-flight session; [reset] drops back to idle so
/// the mic button can be tapped again.
///
/// The controller never touches a UI framework. Flutter widgets watch
/// [stream] (or ask the current [state]) and build from it; tests drive
/// [start] against a fake service and read [stream] to assert the
/// transitions.
class VoiceSessionController {
  VoiceSessionController(this._service)
    : _state = const VoiceSessionState.idle();

  final VoiceInputService _service;
  final StreamController<VoiceSessionState> _states =
      StreamController<VoiceSessionState>.broadcast();
  StreamSubscription<VoiceTranscript>? _subscription;
  VoiceSessionState _state;
  bool _disposed = false;

  /// The current snapshot. Reading this is safe before anyone has
  /// subscribed to [stream]; the initial value is
  /// [VoiceSessionState.idle].
  VoiceSessionState get state => _state;

  /// Broadcast of every state transition in order. The current [state]
  /// is NOT emitted on subscribe; callers that need it read [state] and
  /// then listen for the next change.
  Stream<VoiceSessionState> get stream => _states.stream;

  /// `true` when the wrapped service reports a working recognizer; the
  /// composer hides the mic button when this is `false`.
  bool get isAvailable => _service.isAvailable;

  /// Open the recognizer for [appLocale]. Returns the negotiated BCP-47
  /// tag on success, or `null` when either the service is unavailable
  /// or the user's language is not supported. On a successful start the
  /// controller transitions to [VoiceSessionPhase.listening]; on failure
  /// it transitions to [VoiceSessionPhase.error] and the returned value
  /// is `null`.
  ///
  /// Calling [start] while a previous session is still in flight cancels
  /// that session first, so a double-tap on the mic button is safe.
  Future<String?> start(String appLocale) async {
    if (_disposed) return null;
    final hadSubscription = _subscription != null;
    await _cancelSubscription();
    if (hadSubscription) {
      try {
        await _service.stop();
      } on Object {
        // Releasing the previous mic is best-effort; a start() that
        // follows a stuck recognizer still needs to try.
      }
    }

    if (!_service.isAvailable) {
      _emit(
        const VoiceSessionState(
          phase: VoiceSessionPhase.error,
          error: VoiceInputUnavailable(
            'voice input not available on this device',
          ),
        ),
      );
      return null;
    }

    final locale = negotiateLocale(
      appLocale: appLocale,
      supported: _service.supportedLocales,
    );
    if (locale == null) {
      _emit(
        const VoiceSessionState(
          phase: VoiceSessionPhase.error,
          error: VoiceInputUnavailable(
            'no recognizer locale matches the app language',
          ),
        ),
      );
      return null;
    }

    _emit(
      VoiceSessionState(phase: VoiceSessionPhase.listening, locale: locale),
    );

    _subscription = _service
        .start(locale: locale)
        .listen(
          (tick) => _onTranscript(tick, locale),
          onError: (Object error, StackTrace _) => _onError(error, locale),
          onDone: () => _onDone(locale),
          cancelOnError: true,
        );

    return locale;
  }

  /// Cancel an in-flight session. No-op when the controller is idle or
  /// already in a terminal phase; the controller transitions to
  /// [VoiceSessionPhase.cancelled] only when it was still listening.
  Future<void> stop() async {
    if (_disposed) return;
    final wasListening = _state.phase == VoiceSessionPhase.listening;
    await _cancelSubscription();
    try {
      await _service.stop();
    } on Object {
      // The composer does not care why a recognizer refused to stop; a
      // best-effort cancel is enough and the next start() will re-arm.
    }
    if (wasListening) {
      _emit(
        VoiceSessionState(
          phase: VoiceSessionPhase.cancelled,
          locale: _state.locale,
        ),
      );
    }
  }

  /// Drop back to [VoiceSessionPhase.idle]. Call after the composer has
  /// dropped a committed transcript into the input, dismissed an error
  /// toast, or otherwise handled the session's end state.
  void reset() {
    if (_disposed) return;
    _emit(const VoiceSessionState.idle());
  }

  /// Release resources. After this the controller cannot be reused;
  /// construct a new one if the composer is re-mounted.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _cancelSubscription();
    try {
      await _service.stop();
    } on Object {
      // Nothing useful the composer can do with a late stop failure.
    }
    await _states.close();
  }

  void _onTranscript(VoiceTranscript tick, String locale) {
    if (_disposed) return;
    if (tick.isFinal) {
      _emit(
        VoiceSessionState(
          phase: VoiceSessionPhase.committed,
          text: tick.text,
          locale: locale,
        ),
      );
      _subscription = null;
    } else {
      _emit(
        VoiceSessionState(
          phase: VoiceSessionPhase.listening,
          text: tick.text,
          locale: locale,
        ),
      );
    }
  }

  void _onError(Object error, String locale) {
    if (_disposed) return;
    final wrapped = error is VoiceInputUnavailable
        ? error
        : VoiceInputUnavailable(error.toString());
    _emit(
      VoiceSessionState(
        phase: VoiceSessionPhase.error,
        locale: locale,
        error: wrapped,
      ),
    );
    _subscription = null;
  }

  void _onDone(String locale) {
    if (_disposed) return;
    // The stream closed without a final transcript (e.g. the recognizer
    // timed out while the user was silent). Treat it as a cancellation
    // so the composer hands focus back to the user's typed text.
    if (_state.phase == VoiceSessionPhase.listening) {
      _emit(
        VoiceSessionState(
          phase: VoiceSessionPhase.cancelled,
          locale: locale,
        ),
      );
    }
    _subscription = null;
  }

  void _emit(VoiceSessionState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  Future<void> _cancelSubscription() async {
    final sub = _subscription;
    _subscription = null;
    if (sub != null) {
      await sub.cancel();
    }
  }
}
