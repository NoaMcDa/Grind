import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/voice/voice.dart';

void main() {
  group('StubVoiceInputService', () {
    const stub = StubVoiceInputService();

    test('reports unavailable and empty locales', () {
      expect(stub.isAvailable, isFalse);
      expect(stub.supportedLocales, isEmpty);
    });

    test('start yields VoiceInputUnavailable', () async {
      await expectLater(
        stub.start(locale: 'en-US'),
        emitsError(isA<VoiceInputUnavailable>()),
      );
    });

    test('stop is safe to call without an in-flight session', () async {
      await stub.stop();
      await stub.stop();
    });
  });

  group('WebVoiceInputService', () {
    test('reports unavailable when the browser lacks the API', () {
      const web = WebVoiceInputService();
      expect(web.isAvailable, isFalse);
      expect(web.supportedLocales, isEmpty);
    });

    test('exposes EN and HE locales when the API is present', () {
      const web = WebVoiceInputService(supportsSpeechApi: true);
      expect(web.isAvailable, isTrue);
      expect(web.supportedLocales, ['en-US', 'he-IL']);
    });

    test('start errors when the API is absent', () async {
      const web = WebVoiceInputService();
      await expectLater(
        web.start(locale: 'en-US'),
        emitsError(
          isA<VoiceInputUnavailable>().having(
            (e) => e.reason,
            'reason',
            contains('web speech api'),
          ),
        ),
      );
    });

    test(
      'start errors with a wiring-pending reason when the API is present',
      () async {
        // The real recognizer lands in a later slice; until then the web
        // service refuses rather than returning a silent stream.
        const web = WebVoiceInputService(supportsSpeechApi: true);
        await expectLater(
          web.start(locale: 'en-US'),
          emitsError(isA<VoiceInputUnavailable>()),
        );
      },
    );
  });

  group('VoiceTranscript', () {
    test('partial and final factories set isFinal correctly', () {
      const p = VoiceTranscript.partial('go to');
      const f = VoiceTranscript.finalResult('go to the gym');
      expect(p.isFinal, isFalse);
      expect(f.isFinal, isTrue);
      expect(p.text, 'go to');
      expect(f.text, 'go to the gym');
    });

    test('equality distinguishes by text and isFinal', () {
      const a = VoiceTranscript('x', isFinal: true);
      const b = VoiceTranscript('x', isFinal: true);
      const c = VoiceTranscript('x', isFinal: false);
      const d = VoiceTranscript('y', isFinal: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
    });

    test('toString names the kind and the text', () {
      expect(
        const VoiceTranscript.partial('run').toString(),
        contains('partial'),
      );
      expect(const VoiceTranscript.partial('run').toString(), contains('run'));
      expect(
        const VoiceTranscript.finalResult('run').toString(),
        contains('final'),
      );
    });
  });

  group('negotiateLocale', () {
    const tags = ['en-US', 'he-IL', 'en-GB'];

    test('returns null when nothing is supported', () {
      expect(negotiateLocale(appLocale: 'en', supported: const []), isNull);
    });

    test('prefers an exact tag match', () {
      expect(negotiateLocale(appLocale: 'en-GB', supported: tags), 'en-GB');
    });

    test('falls back to a base-language match for the shorthand', () {
      // Grind preferences store 'en' and 'he'; both must negotiate.
      expect(negotiateLocale(appLocale: 'en', supported: tags), 'en-US');
      expect(negotiateLocale(appLocale: 'he', supported: tags), 'he-IL');
    });

    test('is case-insensitive and tolerates underscores', () {
      expect(negotiateLocale(appLocale: 'HE_IL', supported: tags), 'he-IL');
      expect(negotiateLocale(appLocale: 'EN-us', supported: tags), 'en-US');
    });

    test('returns null when the language is not offered', () {
      expect(negotiateLocale(appLocale: 'fr-FR', supported: tags), isNull);
    });

    test('exact match wins over an earlier base-language match', () {
      // Base en would match 'en-US' first, but 'en-GB' is the exact
      // tag asked for and must win.
      expect(negotiateLocale(appLocale: 'en-GB', supported: tags), 'en-GB');
    });
  });

  group('VoicePermissionCopy', () {
    test('EN and HE permission rationales are distinct and non-empty', () {
      expect(VoicePermissionCopy.permissionEn, isNotEmpty);
      expect(VoicePermissionCopy.permissionHe, isNotEmpty);
      expect(
        VoicePermissionCopy.permissionEn,
        isNot(VoicePermissionCopy.permissionHe),
      );
    });

    test('Hebrew strings are actually Hebrew, English strings are ASCII', () {
      final hebrew = RegExp(r'[֐-׿]');
      expect(hebrew.hasMatch(VoicePermissionCopy.permissionHe), isTrue);
      expect(hebrew.hasMatch(VoicePermissionCopy.privacyNoteHe), isTrue);
      expect(hebrew.hasMatch(VoicePermissionCopy.permissionEn), isFalse);
      expect(hebrew.hasMatch(VoicePermissionCopy.privacyNoteEn), isFalse);
    });

    test('permissionFor picks the language from the locale tag', () {
      expect(
        VoicePermissionCopy.permissionFor('he'),
        VoicePermissionCopy.permissionHe,
      );
      expect(
        VoicePermissionCopy.permissionFor('he-IL'),
        VoicePermissionCopy.permissionHe,
      );
      expect(
        VoicePermissionCopy.permissionFor('en'),
        VoicePermissionCopy.permissionEn,
      );
      expect(
        VoicePermissionCopy.permissionFor('en-US'),
        VoicePermissionCopy.permissionEn,
      );
    });

    test('privacyNoteFor picks the language from the locale tag', () {
      expect(
        VoicePermissionCopy.privacyNoteFor('he'),
        VoicePermissionCopy.privacyNoteHe,
      );
      expect(
        VoicePermissionCopy.privacyNoteFor('en-US'),
        VoicePermissionCopy.privacyNoteEn,
      );
    });

    test('unknown locales fall back to English', () {
      expect(
        VoicePermissionCopy.permissionFor(''),
        VoicePermissionCopy.permissionEn,
      );
      expect(
        VoicePermissionCopy.privacyNoteFor('fr-FR'),
        VoicePermissionCopy.privacyNoteEn,
      );
    });

    test('privacy notes mention that speech stays on the device', () {
      // Covers the privacy claim in both languages so future copy
      // changes keep the promise.
      expect(
        VoicePermissionCopy.privacyNoteEn.toLowerCase(),
        contains('device'),
      );
      // Hebrew text contains the word "device" (מכשיר).
      expect(VoicePermissionCopy.privacyNoteHe, contains('מכשיר'));
    });
  });
}
