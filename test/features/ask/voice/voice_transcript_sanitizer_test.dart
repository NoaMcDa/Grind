import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/voice/voice.dart';

void main() {
  group('sanitizeVoiceTranscript', () {
    group('whitespace', () {
      test('empty input returns empty string', () {
        expect(sanitizeVoiceTranscript(''), isEmpty);
      });

      test('whitespace-only input returns empty string', () {
        expect(sanitizeVoiceTranscript('   \t\n '), isEmpty);
      });

      test('trims leading and trailing whitespace', () {
        expect(sanitizeVoiceTranscript('  go to the gym  '), 'Go to the gym');
      });

      test('collapses internal whitespace runs to a single space', () {
        expect(sanitizeVoiceTranscript('go    to  the   gym'), 'Go to the gym');
      });

      test('collapses non-breaking spaces and tabs the same way', () {
        // U+00A0 NBSP and tab both count as whitespace to the sanitizer.
        expect(sanitizeVoiceTranscript('go to\tthe gym'), 'Go to the gym');
      });
    });

    group('bidi marks', () {
      test('strips LTR/RTL marks', () {
        // U+200E LEFT-TO-RIGHT MARK, U+200F RIGHT-TO-LEFT MARK.
        expect(sanitizeVoiceTranscript('‎go to ‏the gym'), 'Go to the gym');
      });

      test('strips embedding and isolate controls', () {
        // U+202A LRE, U+2069 POP DIRECTIONAL ISOLATE.
        expect(sanitizeVoiceTranscript('‪go to the gym⁩'), 'Go to the gym');
      });

      test('input of only bidi marks and whitespace returns empty', () {
        expect(sanitizeVoiceTranscript('‎‏  ⁩'), isEmpty);
      });
    });

    group('leading filler, English', () {
      test('drops a bare "um"', () {
        expect(sanitizeVoiceTranscript('um go to the gym'), 'Go to the gym');
      });

      test('drops "uh,"', () {
        expect(
          sanitizeVoiceTranscript('uh, remind me at seven'),
          'Remind me at seven',
        );
      });

      test('drops "hmm" case-insensitively', () {
        expect(sanitizeVoiceTranscript('Hmm plan my day'), 'Plan my day');
      });

      test('drops at most one filler', () {
        // The second "uh" is left alone so a user who dictated two
        // fillers on purpose still sees the second one.
        expect(sanitizeVoiceTranscript('um uh plan my day'), 'Uh plan my day');
      });

      test('does not eat a word that starts like a filler', () {
        // "umbrella" must stay whole; "erratic" too.
        expect(sanitizeVoiceTranscript('umbrella at four'), 'Umbrella at four');
        expect(sanitizeVoiceTranscript('erratic weather'), 'Erratic weather');
      });

      test('does not eat "oh" / "like" / "so" (real sentence starters)', () {
        expect(sanitizeVoiceTranscript('oh plan tomorrow'), 'Oh plan tomorrow');
        expect(
          sanitizeVoiceTranscript('so schedule a run'),
          'So schedule a run',
        );
      });

      test('a transcript that is nothing but a filler collapses to empty', () {
        expect(sanitizeVoiceTranscript('um'), isEmpty);
        expect(sanitizeVoiceTranscript('uh,'), isEmpty);
      });
    });

    group('leading filler, Hebrew', () {
      test('drops a bare Hebrew filler for he locale', () {
        expect(
          sanitizeVoiceTranscript('אה תזכיר לי מחר', locale: 'he-IL'),
          'תזכיר לי מחר',
        );
      });

      test('drops "אהה,"', () {
        expect(
          sanitizeVoiceTranscript('אהה, קבע ישיבה', locale: 'he'),
          'קבע ישיבה',
        );
      });

      test('leaves "אם" and "אמא" alone (real Hebrew words)', () {
        // "אם" means "if"/"mother"; "אמא" means "mom". Neither is a
        // filler, both must survive the pass.
        expect(
          sanitizeVoiceTranscript('אם אשכח תזכיר לי', locale: 'he-IL'),
          'אם אשכח תזכיר לי',
        );
        expect(
          sanitizeVoiceTranscript('אמא שלי מתקשרת', locale: 'he-IL'),
          'אמא שלי מתקשרת',
        );
      });

      test('EN fillers are not stripped when the locale is Hebrew', () {
        // A speaker who dictates English into a Hebrew session should
        // see the English kept intact — the recognizer locale decides.
        expect(
          sanitizeVoiceTranscript('um go to the gym', locale: 'he-IL'),
          'Um go to the gym',
        );
      });

      test('HE fillers are not stripped when the locale is English', () {
        expect(
          sanitizeVoiceTranscript('אה תזכיר', locale: 'en-US'),
          'אה תזכיר',
        );
      });
    });

    group('trailing punctuation', () {
      test('drops a trailing period', () {
        expect(sanitizeVoiceTranscript('go to the gym.'), 'Go to the gym');
      });

      test('drops a trailing comma', () {
        expect(sanitizeVoiceTranscript('go to the gym,'), 'Go to the gym');
      });

      test('keeps trailing "?" and "!"', () {
        expect(
          sanitizeVoiceTranscript('what is on tomorrow?'),
          'What is on tomorrow?',
        );
        expect(sanitizeVoiceTranscript('stop everything!'), 'Stop everything!');
      });

      test('only one terminal character is stripped', () {
        // "wait..." keeps the two remaining dots so the user's
        // ellipsis is preserved.
        expect(sanitizeVoiceTranscript('wait...'), 'Wait..');
      });

      test('drops trailing period on a Hebrew transcript', () {
        expect(
          sanitizeVoiceTranscript('תזכיר לי מחר.', locale: 'he-IL'),
          'תזכיר לי מחר',
        );
      });
    });

    group('capitalization', () {
      test('capitalizes the first ASCII letter', () {
        expect(sanitizeVoiceTranscript('plan my day'), 'Plan my day');
      });

      test('leaves a non-ASCII leading character alone', () {
        // Hebrew has no case; the transcript must match exactly.
        expect(
          sanitizeVoiceTranscript('תזכיר לי', locale: 'he-IL'),
          'תזכיר לי',
        );
      });

      test('leaves a digit-leading transcript alone', () {
        expect(sanitizeVoiceTranscript('7am gym'), '7am gym');
      });

      test('does not lowercase existing capitals mid-string', () {
        expect(
          sanitizeVoiceTranscript('email John about PR'),
          'Email John about PR',
        );
      });
    });

    group('end-to-end', () {
      test('combines whitespace, filler and trailing period in one pass', () {
        expect(
          sanitizeVoiceTranscript('  um,   plan my    day.  '),
          'Plan my day',
        );
      });

      test('combines bidi strip, filler and punctuation for Hebrew', () {
        expect(
          sanitizeVoiceTranscript('‏ אה, תזכיר לי מחר. ', locale: 'he-IL'),
          'תזכיר לי מחר',
        );
      });

      test('locale defaults to English when none is provided', () {
        expect(sanitizeVoiceTranscript('um go'), 'Go');
      });

      test('a sentence with none of the targeted noise is unchanged', () {
        expect(sanitizeVoiceTranscript('Plan my day'), 'Plan my day');
      });
    });
  });
}
