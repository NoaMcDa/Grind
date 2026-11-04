import 'package:flutter_test/flutter_test.dart';
import 'package:grind/l10n/detect_language.dart';

void main() {
  group('detectLanguageFromText', () {
    test('plain English phrase returns "en"', () {
      expect(detectLanguageFromText('add a walk tomorrow'), 'en');
    });

    test('plain Hebrew phrase returns "he"', () {
      expect(detectLanguageFromText('תוסיף הליכה מחר'), 'he');
    });

    test('single Hebrew word still returns "he"', () {
      expect(detectLanguageFromText('שלום'), 'he');
    });

    test('short English greeting still returns "en"', () {
      expect(detectLanguageFromText('hi'), 'en');
    });

    test('digits and punctuation only fall back', () {
      expect(detectLanguageFromText('09:00 - 09:25'), 'en');
      expect(detectLanguageFromText('09:00 - 09:25', fallback: 'he'), 'he');
    });

    test('empty string falls back', () {
      expect(detectLanguageFromText(''), 'en');
      expect(detectLanguageFromText('', fallback: 'he'), 'he');
    });

    test('whitespace only falls back', () {
      expect(detectLanguageFromText('   \n\t'), 'en');
      expect(detectLanguageFromText('   \n\t', fallback: 'he'), 'he');
    });

    test('Hebrew with a bare English brand name picks Hebrew', () {
      // "shopping at Super"
      expect(detectLanguageFromText('קניות ב-Super'), 'he');
    });

    test('English with one Hebrew word picks English', () {
      // majority Latin letters
      expect(detectLanguageFromText('remind me about שבת at 18:00'), 'en');
    });

    test('Hebrew sentence with numbers and times picks Hebrew', () {
      expect(detectLanguageFromText('קבע ריצה 20 דק מחר ב-07:30'), 'he');
    });

    test('equal letter counts fall back to default', () {
      // Three Hebrew letters, three Latin letters.
      expect(detectLanguageFromText('abc שלם'), 'en');
      expect(detectLanguageFromText('abc שלם', fallback: 'he'), 'he');
    });

    test('Hebrew niqqud and gershayim do not swing the count', () {
      // All niqqud / gershayim — no Hebrew letters, no Latin letters.
      expect(detectLanguageFromText('ְֱֲֳִֵֶַָֹֻּׁׂ״׳'), 'en');
      expect(detectLanguageFromText('ְֱֲֳִֵֶַָֹֻּׁׂ״׳', fallback: 'he'), 'he');
    });

    test('non-Latin non-Hebrew letters (Cyrillic, Arabic) fall back', () {
      // Arabic "hello"
      expect(detectLanguageFromText('مرحبا'), 'en');
      // Cyrillic "привет"
      expect(detectLanguageFromText('привет'), 'en');
    });

    test('emoji only falls back', () {
      expect(detectLanguageFromText('🎉✨'), 'en');
    });

    test('digits attached to Hebrew do not flip the result', () {
      expect(detectLanguageFromText('3 משימות'), 'he');
    });
  });

  group('countScriptLetters', () {
    test('counts Hebrew letters and ignores niqqud', () {
      // The word "שָׁלוֹם" has 4 Hebrew letters plus niqqud.
      expect(
        countScriptLetters('שָׁלוֹם'),
        const ScriptLetterCounts(hebrew: 4, latin: 0),
      );
    });

    test('counts Latin letters and ignores digits', () {
      // walk (4) + min (3) = 7 Latin letters; the "20" is ignored.
      expect(
        countScriptLetters('walk 20 min'),
        const ScriptLetterCounts(hebrew: 0, latin: 7),
      );
    });

    test('mixed content counts both sides', () {
      expect(
        countScriptLetters('קניות ב-Super'),
        const ScriptLetterCounts(hebrew: 6, latin: 5),
      );
    });

    test('empty string yields zero counts', () {
      expect(
        countScriptLetters(''),
        const ScriptLetterCounts(hebrew: 0, latin: 0),
      );
    });

    test('value equality and hashCode work', () {
      expect(
        const ScriptLetterCounts(hebrew: 1, latin: 2),
        const ScriptLetterCounts(hebrew: 1, latin: 2),
      );
      expect(
        const ScriptLetterCounts(hebrew: 1, latin: 2).hashCode,
        const ScriptLetterCounts(hebrew: 1, latin: 2).hashCode,
      );
    });
  });
}
