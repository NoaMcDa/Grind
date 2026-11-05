/// Per-message language guess for the Ask Pip assistant.
///
/// The user's app language sets the default reply language (#44), but a
/// single message can still ride against that default — a Hebrew-app user
/// typing "add a 20 min walk tomorrow" expects an English confirmation,
/// and vice versa. This helper is the per-message auto-detect that sits
/// on top of the app-language default.
///
/// The rule is deliberately simple: count the strong letters on each
/// side and let the majority win. Hebrew letters live in U+0590..U+05FF,
/// Basic Latin letters in A-Z / a-z. Digits, punctuation and whitespace
/// are weak under UAX #9 and never swing the result here either — a
/// clock time like `09:00` carries no language signal of its own.
///
/// When neither side has any letters the [fallback] value is returned.
/// The default fallback is `'en'`, matching the rest of Grind's l10n.
library;

/// Guesses the language of [text] and returns an ISO 639-1 code.
///
/// Returns `'he'` when Hebrew letters strictly outnumber Latin letters,
/// `'en'` when Latin letters strictly outnumber Hebrew letters, and
/// [fallback] on a tie or when [text] has no letters at all.
///
/// Mixed content (e.g. `'קניות ב-Super'`) picks the side with more
/// letters; ASCII digits, punctuation and whitespace are ignored.
String detectLanguageFromText(String text, {String fallback = 'en'}) {
  final counts = countScriptLetters(text);
  if (counts.hebrew > counts.latin) return 'he';
  if (counts.latin > counts.hebrew) return 'en';
  return fallback;
}

/// Letter tallies returned by [countScriptLetters]. Exposed for callers
/// that need more than the one-letter-code answer, e.g. to flag a
/// genuinely bilingual message.
class ScriptLetterCounts {
  const ScriptLetterCounts({required this.hebrew, required this.latin});

  final int hebrew;
  final int latin;

  @override
  bool operator ==(Object other) =>
      other is ScriptLetterCounts &&
      other.hebrew == hebrew &&
      other.latin == latin;

  @override
  int get hashCode => Object.hash(hebrew, latin);

  @override
  String toString() => 'ScriptLetterCounts(hebrew: $hebrew, latin: $latin)';
}

/// Count the Hebrew and Basic-Latin letters in [text]. Everything else —
/// digits, whitespace, Hebrew punctuation (geresh, gershayim), ASCII
/// punctuation, emoji — is ignored.
ScriptLetterCounts countScriptLetters(String text) {
  if (text.isEmpty) {
    return const ScriptLetterCounts(hebrew: 0, latin: 0);
  }
  var hebrew = 0;
  var latin = 0;
  for (final r in text.runes) {
    if (_isHebrewLetter(r)) {
      hebrew++;
    } else if (_isLatinLetter(r)) {
      latin++;
    }
  }
  return ScriptLetterCounts(hebrew: hebrew, latin: latin);
}

// Hebrew letters only — U+05D0..U+05EA. The rest of the Hebrew block
// (U+0590..U+05FF) is cantillation marks, niqqud and punctuation that
// carries no language signal on its own and could inflate the count.
bool _isHebrewLetter(int r) => r >= 0x05D0 && r <= 0x05EA;

bool _isLatinLetter(int r) =>
    (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);
