/// Pure-Dart scrub pass for raw recognizer output before the Ask
/// composer previews it to the user (#43).
///
/// Speech recognizers make life easy for a voice assistant and harder
/// for a text input: they capitalize ad-hoc, sprinkle terminal periods,
/// and frequently leak the user's "um"/"uh" or Hebrew "אה" at the head.
/// Dropping the raw string into a `TextField` surfaces that noise and
/// forces every user to clean it up by hand before pressing send —
/// which would make the dictated path noticeably worse than typing.
///
/// This module is the floor the composer sits on: a single pure
/// function the [VoiceSessionController] can run against each partial
/// and final transcript. It never touches a plugin, a channel or a
/// locale ARB — it is pure Dart so it works the same on iOS,
/// web and in tests, and it works in both locales Grind supports.
///
/// Behaviour, in order:
///
/// * Strip LTR/RTL marks and other invisible Unicode direction
///   controls recognizers occasionally emit when switching from Hebrew
///   to English in one utterance.
/// * Collapse runs of whitespace to a single space and trim the ends.
/// * Drop a single leading filler word in the transcript's language
///   (EN `um`/`uh`/`er`/`eh`/`hmm`; HE `אה`/`אם`/`אמא` is intentionally
///   left alone — it is also a noun — and the HE list stays conservative
///   with the clear fillers `אהה` and `אמממ`-style elongations).
/// * Drop a single trailing `.` or `,` that iOS Speech appends on
///   commit; `?` and `!` are kept because the user asked for emphasis.
/// * Capitalize the first ASCII letter when the transcript starts with
///   one; Hebrew-leading transcripts are left exactly as the recognizer
///   produced them (there is no case in Hebrew).
///
/// Tests under `test/features/ask/voice/voice_transcript_sanitizer_test.dart`
/// pin each of these rules in both languages.
library;

/// Clean a raw recognizer transcript for display in the composer.
///
/// [locale] is the BCP-47 tag [VoiceSessionController] negotiated for
/// the current session (`en-US`, `he-IL`, `en`, `he`, …). The sanitizer
/// only looks at the base language to choose the filler table; every
/// other rule is locale-independent so a slightly-off locale tag still
/// produces reasonable output.
///
/// Returns the cleaned transcript. An empty or whitespace-only input
/// returns the empty string.
String sanitizeVoiceTranscript(String raw, {String locale = 'en'}) {
  if (raw.isEmpty) return '';

  final withoutBidi = _stripBidiMarks(raw);
  final collapsed = _collapseWhitespace(withoutBidi);
  if (collapsed.isEmpty) return '';

  final isHebrew = locale.toLowerCase().startsWith('he');
  final withoutFiller = _stripLeadingFiller(collapsed, isHebrew: isHebrew);
  if (withoutFiller.isEmpty) return '';

  final withoutTrailingPunct = _stripTrailingPunctuation(withoutFiller);
  if (withoutTrailingPunct.isEmpty) return '';

  return _capitalizeFirstAscii(withoutTrailingPunct);
}

/// BCP-47 agnostic whitespace collapse: every run of Unicode whitespace
/// becomes one ASCII space, and leading/trailing whitespace is dropped.
/// Dart's `\s` already matches the non-breaking space and other Unicode
/// whitespace characters Safari sometimes injects on web.
String _collapseWhitespace(String s) =>
    s.replaceAll(RegExp(r'\s+'), ' ').trim();

/// The bidirectional formatting characters iOS/web recognizers may leak
/// into the transcript when the user dictates mixed Hebrew+English. They
/// are invisible but break string equality in tests and look like extra
/// characters to downstream regexes, so the sanitizer strips them first.
///
/// U+200E LEFT-TO-RIGHT MARK, U+200F RIGHT-TO-LEFT MARK, U+202A..U+202E
/// the LRE/RLE/PDF/LRO/RLO embedding set, U+2066..U+2069 the isolate set.
String _stripBidiMarks(String s) =>
    s.replaceAll(RegExp(r'[‎‏‪-‮⁦-⁩]'), '');

/// EN fillers the user did not mean to dictate. Each is paired with an
/// optional trailing `,` so `"um, go to the gym"` becomes `"go to the gym"`.
/// Kept intentionally short — `oh`, `like` and `so` are real words at
/// the start of a sentence and must not be eaten.
const List<String> _fillersEn = [
  'um',
  'uh',
  'er',
  'eh',
  'hmm',
  'hm',
  'uhh',
  'umm',
];

/// HE fillers the user did not mean to dictate. `אה` on its own is the
/// clearest filler; `אהה` and multi-letter elongations are included to
/// cover how the recognizer transcribes drawn-out versions. Deliberately
/// does not include `אם` (meaning "if"/"mother") or `אמא` (mother) which
/// have real meanings.
const List<String> _fillersHe = ['אה', 'אהה', 'אההה', 'אמממ', 'אממ'];

/// Drop at most one leading filler token from [s] in the transcript's
/// language. Only one is removed so a genuine sentence like
/// `"um uh go"` keeps `"uh go"` instead of being consumed whole — users
/// who dictated two fillers back-to-back probably meant one on purpose.
String _stripLeadingFiller(String s, {required bool isHebrew}) {
  final fillers = isHebrew ? _fillersHe : _fillersEn;
  for (final f in fillers) {
    // A filler only counts when it ends at a word boundary: a trailing
    // optional comma, then whitespace or the end of the string. That
    // way "umbrella" and "אהוב" keep their first word intact.
    final pattern = RegExp(
      '^${RegExp.escape(f)},?(?:\\s+|\$)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(s);
    if (match != null) {
      return s.substring(match.end);
    }
  }
  return s;
}

/// Drop a single terminal `.` or `,` that the recognizer added on
/// commit. Only one character is stripped: a user who really said
/// `"wait..."` keeps the two remaining dots, and `"stop!"` keeps its
/// bang because `!` and `?` are deliberate.
String _stripTrailingPunctuation(String s) {
  if (s.isEmpty) return s;
  final last = s.codeUnitAt(s.length - 1);
  // '.' is 0x2E, ',' is 0x2C.
  if (last == 0x2E || last == 0x2C) {
    return s.substring(0, s.length - 1).trimRight();
  }
  return s;
}

/// Capitalize the first character when it is an ASCII a-z letter. Dart's
/// `toUpperCase` is locale-aware for Latin but a no-op on Hebrew letters,
/// which is exactly what the composer wants — there is no case in Hebrew
/// and a casing pass against a non-ASCII leading character would add
/// nothing.
String _capitalizeFirstAscii(String s) {
  if (s.isEmpty) return s;
  final first = s.codeUnitAt(0);
  // 'a' is 0x61, 'z' is 0x7A.
  if (first >= 0x61 && first <= 0x7A) {
    return String.fromCharCode(first - 0x20) + s.substring(1);
  }
  return s;
}
