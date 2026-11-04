import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/voice/voice.dart';

void main() {
  group('classifyVoiceInputError', () {
    group('speech_to_text codes', () {
      test('error_permission classifies to permissionDenied', () {
        final result = classifyVoiceInputError('error_permission');
        expect(result.kind, VoiceInputErrorKind.permissionDenied);
      });

      test('error_no_match classifies to noSpeech', () {
        expect(
          classifyVoiceInputError('error_no_match').kind,
          VoiceInputErrorKind.noSpeech,
        );
      });

      test('error_speech_timeout classifies to speechTimeout', () {
        expect(
          classifyVoiceInputError('error_speech_timeout').kind,
          VoiceInputErrorKind.speechTimeout,
        );
      });

      test('error_language_not_supported classifies to languageUnavailable', () {
        expect(
          classifyVoiceInputError('error_language_not_supported').kind,
          VoiceInputErrorKind.languageUnavailable,
        );
      });

      test('error_network and error_network_timeout both classify to network', () {
        expect(
          classifyVoiceInputError('error_network').kind,
          VoiceInputErrorKind.network,
        );
        expect(
          classifyVoiceInputError('error_network_timeout').kind,
          VoiceInputErrorKind.network,
        );
      });

      test('error_server and error_too_many_requests classify to serverBusy', () {
        expect(
          classifyVoiceInputError('error_server').kind,
          VoiceInputErrorKind.serverBusy,
        );
        expect(
          classifyVoiceInputError('error_too_many_requests').kind,
          VoiceInputErrorKind.serverBusy,
        );
      });

      test('error_busy and error_audio classify to recognizerBusy', () {
        expect(
          classifyVoiceInputError('error_busy').kind,
          VoiceInputErrorKind.recognizerBusy,
        );
        expect(
          classifyVoiceInputError('error_audio').kind,
          VoiceInputErrorKind.recognizerBusy,
        );
      });

      test('error_client is unknown — nothing actionable to tell the user', () {
        expect(
          classifyVoiceInputError('error_client').kind,
          VoiceInputErrorKind.unknown,
        );
      });
    });

    group('Web Speech API codes', () {
      test('not-allowed classifies to permissionDenied', () {
        expect(
          classifyVoiceInputError('not-allowed').kind,
          VoiceInputErrorKind.permissionDenied,
        );
      });

      test('no-speech classifies to noSpeech', () {
        expect(
          classifyVoiceInputError('no-speech').kind,
          VoiceInputErrorKind.noSpeech,
        );
      });

      test('language-not-supported classifies to languageUnavailable', () {
        expect(
          classifyVoiceInputError('language-not-supported').kind,
          VoiceInputErrorKind.languageUnavailable,
        );
      });

      test('network classifies to network', () {
        expect(
          classifyVoiceInputError('network').kind,
          VoiceInputErrorKind.network,
        );
      });

      test('service-not-allowed classifies to serverBusy', () {
        expect(
          classifyVoiceInputError('service-not-allowed').kind,
          VoiceInputErrorKind.serverBusy,
        );
      });

      test('audio-capture classifies to recognizerBusy', () {
        expect(
          classifyVoiceInputError('audio-capture').kind,
          VoiceInputErrorKind.recognizerBusy,
        );
      });

      test('bad-grammar classifies to noSpeech', () {
        // Nothing the user can act on; we treat it as "I didn't catch
        // that" so the composer re-arms the mic.
        expect(
          classifyVoiceInputError('bad-grammar').kind,
          VoiceInputErrorKind.noSpeech,
        );
      });

      test('aborted classifies to unknown — a user-initiated stop is not an error', () {
        // The caller is expected to check for cancellation before
        // classifying; if an aborted code leaks through we show the
        // generic apology rather than a misleading snackbar.
        expect(
          classifyVoiceInputError('aborted').kind,
          VoiceInputErrorKind.unknown,
        );
      });
    });

    group('fallbacks and robustness', () {
      test('null classifies to unknown', () {
        expect(
          classifyVoiceInputError(null).kind,
          VoiceInputErrorKind.unknown,
        );
      });

      test('empty string classifies to unknown', () {
        expect(
          classifyVoiceInputError('').kind,
          VoiceInputErrorKind.unknown,
        );
      });

      test('whitespace-only classifies to unknown', () {
        expect(
          classifyVoiceInputError('   ').kind,
          VoiceInputErrorKind.unknown,
        );
      });

      test('unrecognised codes classify to unknown', () {
        expect(
          classifyVoiceInputError('error_kittens').kind,
          VoiceInputErrorKind.unknown,
        );
      });

      test('is case-insensitive', () {
        expect(
          classifyVoiceInputError('ERROR_PERMISSION').kind,
          VoiceInputErrorKind.permissionDenied,
        );
        expect(
          classifyVoiceInputError('Not-Allowed').kind,
          VoiceInputErrorKind.permissionDenied,
        );
      });

      test('tolerates hyphen/underscore difference between the two vocabularies', () {
        // The same classification whether a caller spells the code
        // with the plugin's underscores or the Web API's hyphens.
        expect(
          classifyVoiceInputError('error-permission').kind,
          classifyVoiceInputError('error_permission').kind,
        );
        expect(
          classifyVoiceInputError('no_speech').kind,
          classifyVoiceInputError('no-speech').kind,
        );
      });

      test('trims surrounding whitespace', () {
        expect(
          classifyVoiceInputError('  error_permission  ').kind,
          VoiceInputErrorKind.permissionDenied,
        );
      });
    });

    group('classifyVoiceInputErrorKind', () {
      test('returns the same kind as the full classifier', () {
        for (final code in const [
          'error_permission',
          'error_no_match',
          'network',
          'not-allowed',
          null,
          '',
          'bogus',
        ]) {
          expect(
            classifyVoiceInputErrorKind(code),
            classifyVoiceInputError(code).kind,
          );
        }
      });
    });
  });

  group('VoiceInputErrorMessage', () {
    test('every kind has non-empty EN and HE copy', () {
      for (final kind in VoiceInputErrorKind.values) {
        // Trigger a lookup for each kind through at least one code
        // that maps to it; use a representative sample.
        final representative = _representativeCode(kind);
        final message = classifyVoiceInputError(representative);
        expect(message.kind, kind, reason: 'representative for ${kind.name}');
        expect(message.en, isNotEmpty, reason: '${kind.name} EN');
        expect(message.he, isNotEmpty, reason: '${kind.name} HE');
      }
    });

    test('EN copy is ASCII and HE copy is actually Hebrew', () {
      final hebrew = RegExp(r'[֐-׿]');
      for (final kind in VoiceInputErrorKind.values) {
        final message = classifyVoiceInputError(_representativeCode(kind));
        expect(
          hebrew.hasMatch(message.he),
          isTrue,
          reason: '${kind.name} HE should contain Hebrew',
        );
        expect(
          hebrew.hasMatch(message.en),
          isFalse,
          reason: '${kind.name} EN should not contain Hebrew',
        );
      }
    });

    test('EN and HE copy differ for every kind', () {
      for (final kind in VoiceInputErrorKind.values) {
        final message = classifyVoiceInputError(_representativeCode(kind));
        expect(message.en, isNot(message.he), reason: kind.name);
      }
    });

    test('forLocale picks HE for he/he-IL and EN for everything else', () {
      const message = VoiceInputErrorMessage(
        kind: VoiceInputErrorKind.permissionDenied,
        en: 'en-copy',
        he: 'he-copy',
      );
      expect(message.forLocale('he'), 'he-copy');
      expect(message.forLocale('he-IL'), 'he-copy');
      expect(message.forLocale('HE-IL'), 'he-copy');
      expect(message.forLocale('en'), 'en-copy');
      expect(message.forLocale('en-US'), 'en-copy');
      expect(message.forLocale(''), 'en-copy');
      expect(message.forLocale('fr-FR'), 'en-copy');
    });

    test('equality distinguishes by kind, EN and HE', () {
      const a = VoiceInputErrorMessage(
        kind: VoiceInputErrorKind.network,
        en: 'x',
        he: 'y',
      );
      const b = VoiceInputErrorMessage(
        kind: VoiceInputErrorKind.network,
        en: 'x',
        he: 'y',
      );
      const c = VoiceInputErrorMessage(
        kind: VoiceInputErrorKind.network,
        en: 'x',
        he: 'z',
      );
      const d = VoiceInputErrorMessage(
        kind: VoiceInputErrorKind.unknown,
        en: 'x',
        he: 'y',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
    });

    test('toString names the kind and both lines', () {
      final message = classifyVoiceInputError('error_permission');
      final str = message.toString();
      expect(str, contains('permissionDenied'));
      expect(str, contains(message.en));
      expect(str, contains(message.he));
    });

    test('permissionDenied copy mentions the microphone', () {
      // The composer leads the user into the permission flow from this
      // message, so the word has to be in both languages.
      final message = classifyVoiceInputError('error_permission');
      expect(message.en.toLowerCase(), contains('microphone'));
      expect(message.he, contains('מיקרופון'));
    });
  });
}

/// Pick one code that maps to [kind]. Kept close to the test so a new
/// kind forces the author to think about which code represents it.
String _representativeCode(VoiceInputErrorKind kind) => switch (kind) {
  VoiceInputErrorKind.permissionDenied => 'error_permission',
  VoiceInputErrorKind.noSpeech => 'error_no_match',
  VoiceInputErrorKind.speechTimeout => 'error_speech_timeout',
  VoiceInputErrorKind.languageUnavailable => 'error_language_not_supported',
  VoiceInputErrorKind.network => 'error_network',
  VoiceInputErrorKind.serverBusy => 'error_server',
  VoiceInputErrorKind.recognizerBusy => 'error_busy',
  VoiceInputErrorKind.unknown => 'something_unknown',
};
