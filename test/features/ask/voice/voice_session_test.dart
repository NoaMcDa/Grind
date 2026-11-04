import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/voice/voice.dart';

/// A programmable fake [VoiceInputService] the tests drive by hand. Each
/// test pushes partial/final transcripts or an error onto the controller
/// through [emit], [emitFinal] or [emitError]; the controller under test
/// only sees a stream it cannot distinguish from the real thing.
class _FakeVoiceService implements VoiceInputService {
  _FakeVoiceService({
    this.isAvailable = true,
    this.supportedLocales = const ['en-US', 'he-IL'],
  });

  @override
  final bool isAvailable;

  @override
  final List<String> supportedLocales;

  StreamController<VoiceTranscript>? _controller;
  int startCount = 0;
  int stopCount = 0;
  String? lastLocale;

  @override
  Stream<VoiceTranscript> start({required String locale}) {
    startCount += 1;
    lastLocale = locale;
    _controller = StreamController<VoiceTranscript>();
    return _controller!.stream;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    final c = _controller;
    _controller = null;
    if (c != null && !c.isClosed) {
      await c.close();
    }
  }

  void emit(String text) =>
      _controller!.add(VoiceTranscript.partial(text));

  void emitFinal(String text) {
    _controller!.add(VoiceTranscript.finalResult(text));
    _controller!.close();
    _controller = null;
  }

  void emitError(Object error) {
    _controller!.addError(error);
    _controller = null;
  }

  void closeWithoutFinal() {
    _controller!.close();
    _controller = null;
  }
}

void main() {
  group('VoiceSessionController', () {
    test('idle before start', () {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      expect(controller.state.phase, VoiceSessionPhase.idle);
      expect(controller.state.text, isEmpty);
      expect(controller.state.locale, isNull);
      expect(controller.isAvailable, isTrue);
    });

    test('start negotiates locale and transitions to listening', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      final seen = <VoiceSessionState>[];
      final sub = controller.stream.listen(seen.add);
      addTearDown(sub.cancel);

      final locale = await controller.start('he');

      expect(locale, 'he-IL');
      expect(service.startCount, 1);
      expect(service.lastLocale, 'he-IL');
      expect(controller.state.phase, VoiceSessionPhase.listening);
      expect(controller.state.locale, 'he-IL');
      expect(seen.single.phase, VoiceSessionPhase.listening);
    });

    test('partial transcripts update text without leaving listening',
        () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      final seen = <VoiceSessionState>[];
      final sub = controller.stream.listen(seen.add);
      addTearDown(sub.cancel);

      service.emit('go to');
      service.emit('go to the');
      await Future<void>.delayed(Duration.zero);

      expect(seen.map((s) => s.phase).toSet(), {VoiceSessionPhase.listening});
      expect(seen.map((s) => s.text).toList(), ['go to', 'go to the']);
      expect(controller.state.isListening, isTrue);
      expect(controller.state.text, 'go to the');
    });

    test('final transcript commits and closes the session', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      final seen = <VoiceSessionState>[];
      final sub = controller.stream.listen(seen.add);
      addTearDown(sub.cancel);

      service.emit('go to the');
      service.emitFinal('go to the gym');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.phase, VoiceSessionPhase.committed);
      expect(controller.state.hasFinalTranscript, isTrue);
      expect(controller.state.text, 'go to the gym');
      expect(seen.last.phase, VoiceSessionPhase.committed);
      expect(seen.last.text, 'go to the gym');
    });

    test('stop while listening transitions to cancelled', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      service.emit('partial');
      await Future<void>.delayed(Duration.zero);

      await controller.stop();

      expect(controller.state.phase, VoiceSessionPhase.cancelled);
      expect(controller.state.text, isEmpty);
      expect(controller.state.locale, 'en-US');
      expect(service.stopCount, 1);
    });

    test('stop when idle is a no-op', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.stop();

      expect(controller.state.phase, VoiceSessionPhase.idle);
      expect(service.stopCount, 1);
    });

    test('recognizer error surfaces as error state', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      service.emitError(const VoiceInputUnavailable('mic denied'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.phase, VoiceSessionPhase.error);
      expect(controller.state.error, isA<VoiceInputUnavailable>());
      expect(controller.state.error!.reason, 'mic denied');
      expect(controller.state.locale, 'en-US');
    });

    test('unknown error type is wrapped as VoiceInputUnavailable', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      service.emitError(StateError('kaboom'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.phase, VoiceSessionPhase.error);
      expect(controller.state.error, isA<VoiceInputUnavailable>());
      expect(controller.state.error!.reason, contains('kaboom'));
    });

    test('stream closing silently rolls back to cancelled', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      service.closeWithoutFinal();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.phase, VoiceSessionPhase.cancelled);
    });

    test('unavailable service errors on start and never opens the stream',
        () async {
      final service = _FakeVoiceService(
        isAvailable: false,
        supportedLocales: const [],
      );
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      final locale = await controller.start('en');

      expect(locale, isNull);
      expect(controller.state.phase, VoiceSessionPhase.error);
      expect(controller.state.error, isA<VoiceInputUnavailable>());
      expect(service.startCount, 0);
    });

    test('no supported locale match errors without opening the stream',
        () async {
      final service = _FakeVoiceService(supportedLocales: const ['en-US']);
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      final locale = await controller.start('fr-FR');

      expect(locale, isNull);
      expect(controller.state.phase, VoiceSessionPhase.error);
      expect(service.startCount, 0);
    });

    test('reset drops back to idle from any terminal phase', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      service.emitFinal('done');
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.phase, VoiceSessionPhase.committed);

      controller.reset();
      expect(controller.state.phase, VoiceSessionPhase.idle);
      expect(controller.state.text, isEmpty);
      expect(controller.state.locale, isNull);
      expect(controller.state.error, isNull);
    });

    test('double start cancels the earlier session', () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);
      addTearDown(controller.dispose);

      await controller.start('en');
      service.emit('first');
      await Future<void>.delayed(Duration.zero);

      await controller.start('he');

      expect(service.startCount, 2);
      expect(controller.state.phase, VoiceSessionPhase.listening);
      expect(controller.state.locale, 'he-IL');
      expect(controller.state.text, isEmpty);
    });

    test('dispose closes the state stream and ignores further events',
        () async {
      final service = _FakeVoiceService();
      final controller = VoiceSessionController(service);

      await controller.start('en');
      await controller.dispose();

      expect(service.stopCount, greaterThanOrEqualTo(1));
      // A second start after dispose is a no-op; nothing throws.
      expect(await controller.start('en'), isNull);
    });

    test('state equality ignores identity but tracks phase and text', () {
      const a = VoiceSessionState(
        phase: VoiceSessionPhase.listening,
        text: 'hi',
        locale: 'en-US',
      );
      const b = VoiceSessionState(
        phase: VoiceSessionPhase.listening,
        text: 'hi',
        locale: 'en-US',
      );
      const c = VoiceSessionState(
        phase: VoiceSessionPhase.listening,
        text: 'ho',
        locale: 'en-US',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
