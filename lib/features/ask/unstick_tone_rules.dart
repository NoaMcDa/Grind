/// Tone rules for the "I'm stuck" helper (epic #41).
///
/// The assistant's response to *"I'm behind on my thesis, help"* must:
///   1. acknowledge what the user said,
///   2. offer one small next step,
///   3. carry no judgement, guilt or toxic praise.
///
/// This file formalises rule 3 as a shared per-feature banned-word list,
/// matching the pattern in `ReminderCopy.bannedWords` and
/// `PraisePool.bannedEn / bannedHe`.
///
/// The check is pure, synchronous, and has no Flutter or LLM dependency so:
///   * the offline fallback (#110) can validate its own canned copy,
///   * the LLM path (#38) can sanity-check model output before rendering
///     any pill button,
///   * unit tests can assert tone over any new "unstick" copy.
///
/// Rules follow `docs/tone-guide.md`:
///   * English is matched as whole words (case-insensitive).
///   * Hebrew is matched as substrings (common for Hebrew prefix letters).
///
/// Also enforces the "at most one exclamation mark, never for the small
/// step" rule: no `!!`, and the small-step rationale should carry no `!`
/// at all (callers pass `isSmallStep: true` for that stricter check).
library;

/// Banned English words for "unstick" output (whole-word, case-insensitive).
///
/// Overlaps with `PraisePool.bannedEn` by design, plus extras specific to
/// the "I'm stuck" path: toxic positivity and command verbs that undercut
/// the "no judgement" rule.
const _bannedEn = <String>[
  // Guilt and grading (shared with praise/reminders).
  'should',
  'must',
  'failed',
  'fail',
  'missed',
  'miss',
  'again',
  'you broke',
  'behind',
  'overdue',
  'lazy',
  'late',
  'forgot',
  // Toxic positivity / grading up. The small step is not "amazing".
  'amazing',
  'awesome',
  'great',
  'fantastic',
  'wonderful',
  'perfect',
  'incredible',
  // Commands that strip autonomy.
  'need to',
  'have to',
  'ought',
];

/// Banned Hebrew substrings for "unstick" output. Hebrew prefix letters
/// (ה, ש, ו, ב, כ, ל, מ) are routinely glued to the stem, so a substring
/// match is the right default — same choice as `reminder_copy.dart`.
const _bannedHe = <String>[
  // Guilt and grading.
  'צריך',
  'צריכה',
  'חייב',
  'חייבת',
  'כישלון',
  'נכשל',
  'פספס',
  'איחור',
  'שוב',
  // Toxic positivity. "מדהים" / "אדיר" are the common offenders.
  'מדהים',
  'אדיר',
  'מושלם',
];

/// One banned-word hit found by [UnstickToneRules.violations].
class ToneViolation {
  const ToneViolation({required this.word, required this.rule});

  /// The banned token that matched (lower-case for English).
  final String word;

  /// Which rule the word broke, for test failure reasons.
  final ToneRule rule;

  @override
  String toString() => '${rule.name}:"$word"';
}

/// Categories a line can fail on. Callers use these in test reasons.
enum ToneRule {
  /// Hit a word on the per-language banned list.
  bannedWord,

  /// Two or more exclamation marks ("!!").
  doubleBang,

  /// Any `!` in a line that was marked as the small step. The small step
  /// is where ADHD-adjacent users feel pressure; it stays flat.
  exclamationOnSmallStep,
}

/// Validator for "I'm stuck" copy (epic #41).
///
/// Call [violations] on both the acknowledgement line and each option's
/// title + rationale. When there are none, the copy is compliant.
abstract final class UnstickToneRules {
  /// Public view of the banned lists so tests and the LLM prompt (#38)
  /// can cite the same list. Lower-case English, raw Hebrew substrings.
  static const bannedWords = <String, List<String>>{
    'en': _bannedEn,
    'he': _bannedHe,
  };

  /// Finds every tone violation in [text]. [localeCode] picks which list
  /// to run; unknown locales fall back to English, matching the fallback
  /// used by the offline "I'm stuck" suggester.
  ///
  /// Set [isSmallStep] when [text] is the "first action" rationale (the
  /// line Pip says next to the two-minute pill): then any `!` is a
  /// violation, not just `!!`.
  static List<ToneViolation> violations(
    String text, {
    String localeCode = 'en',
    bool isSmallStep = false,
  }) {
    final out = <ToneViolation>[];
    final isHebrew = localeCode == 'he';
    final list = isHebrew ? _bannedHe : _bannedEn;

    if (isHebrew) {
      // Substring check: Hebrew words often carry prefix letters.
      for (final word in list) {
        if (text.contains(word)) {
          out.add(ToneViolation(word: word, rule: ToneRule.bannedWord));
        }
      }
    } else {
      final lower = text.toLowerCase();
      for (final word in list) {
        // Word boundary: works for single words and multi-word phrases
        // ("need to", "you broke"). RegExp special chars are not present
        // in any entry, so we use the raw string.
        final pattern = RegExp('\\b${RegExp.escape(word)}\\b');
        if (pattern.hasMatch(lower)) {
          out.add(ToneViolation(word: word, rule: ToneRule.bannedWord));
        }
      }
    }

    if (text.contains('!!')) {
      out.add(const ToneViolation(word: '!!', rule: ToneRule.doubleBang));
    }
    if (isSmallStep && text.contains('!')) {
      out.add(
        const ToneViolation(word: '!', rule: ToneRule.exclamationOnSmallStep),
      );
    }

    return out;
  }

  /// Convenience: true when [violations] returns no hits.
  static bool isCompliant(
    String text, {
    String localeCode = 'en',
    bool isSmallStep = false,
  }) => violations(
    text,
    localeCode: localeCode,
    isSmallStep: isSmallStep,
  ).isEmpty;
}
