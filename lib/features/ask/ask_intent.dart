import 'dart:ui' show Locale;

/// A canonical intent recognized on a free-text Ask Pip prompt about the
/// day's plan. The classifier recognizes English and Hebrew phrasings and
/// routes them to one of these cases; a `taskReference` is captured for the
/// intents that name a specific task.
///
/// The intents mirror the sub-deliverables of epic #40: `planMyDay` for the
/// quick-prompt entry point, `explainPlan` for the deterministic plan
/// explainer, and `whyTaskHere` / `whyTaskNotPlaced` / `whenTaskStarts` for
/// the three canonical follow-up questions over the plan's reason data.
enum AskIntent {
  planMyDay,
  explainPlan,
  whyTaskHere,
  whyTaskNotPlaced,
  whenTaskStarts,
  whatsNext,
  unknown,
}

/// The result of classifying a free-text Ask Pip prompt.
///
/// [taskReference] is a short, already-trimmed phrase taken from the prompt
/// that names a task (for the `why…` and `when…` intents). The caller
/// matches it against the day's tasks by title with its own heuristic.
class AskIntentMatch {
  const AskIntentMatch(this.intent, {this.taskReference});

  const AskIntentMatch.unknown()
    : intent = AskIntent.unknown,
      taskReference = null;

  final AskIntent intent;
  final String? taskReference;

  @override
  bool operator ==(Object other) =>
      other is AskIntentMatch &&
      other.intent == intent &&
      other.taskReference == taskReference;

  @override
  int get hashCode => Object.hash(intent, taskReference);

  @override
  String toString() => taskReference == null
      ? 'AskIntentMatch($intent)'
      : 'AskIntentMatch($intent, "$taskReference")';
}

/// Routes a free-text Ask Pip prompt to a canonical [AskIntent].
///
/// Pure, deterministic and offline: a fallback for the assistant gateway so
/// the quick prompts and the free-text input bar reach the right handler
/// even when the model is unavailable, and a golden the model has to beat.
///
/// [locale] picks the phrase table. Only `he` is treated as Hebrew; every
/// other language uses the English table. When the prompt is empty or
/// matches no phrase, [AskIntent.unknown] is returned; the caller can then
/// route to the model or ignore the input.
AskIntentMatch classifyAskPrompt(String prompt, {Locale? locale}) {
  final cleaned = _normalize(prompt);
  if (cleaned.isEmpty) return const AskIntentMatch.unknown();

  final lang = (locale?.languageCode ?? 'en') == 'he' ? 'he' : 'en';
  final rules = lang == 'he' ? _heRules : _enRules;
  for (final r in rules) {
    final m = r.pattern.firstMatch(cleaned);
    if (m == null) continue;
    if (!r.extractsTask) return AskIntentMatch(r.intent);
    final ref = _extractRef(m, lang);
    if (ref == null) return AskIntentMatch(r.intent);
    return AskIntentMatch(r.intent, taskReference: ref);
  }
  return const AskIntentMatch.unknown();
}

String _normalize(String s) {
  // Collapse runs of whitespace and strip trailing sentence punctuation
  // so "Plan my day!" and "plan my day" match the same rule.
  final lower = s.toLowerCase().trim();
  final squeezed = lower.replaceAll(RegExp(r'\s+'), ' ');
  return squeezed.replaceAll(RegExp(r'[?!.,:;]+$'), '').trim();
}

String? _extractRef(Match m, String lang) {
  if (m.groupCount < 1) return null;
  final raw = m.group(1);
  if (raw == null) return null;
  var trimmed = raw.trim();
  // Drop a leading article so "the gym" and "gym" normalize the same way.
  final article = lang == 'he'
      ? RegExp(r'^(ה)')
      : RegExp(r'^(the|a|an|my) ');
  trimmed = trimmed.replaceFirst(article, '').trim();
  // Trailing punctuation inside a captured group can leak from loose
  // patterns; strip it so the caller gets a clean task name.
  trimmed = trimmed.replaceAll(RegExp(r'[?!.,:;]+$'), '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _Rule {
  const _Rule(this.pattern, this.intent, {this.extractsTask = false});
  final RegExp pattern;
  final AskIntent intent;

  /// When true, capture group 1 of [pattern] is the task reference.
  final bool extractsTask;
}

// English phrase table. Rules are tried in order; the first match wins, so
// the more specific pattern goes first (`why isn't …` before `why is …`).
// All grouping is non-capturing except for group 1, which is the task
// reference for rules that set [extractsTask].
final List<_Rule> _enRules = [
  // whatsNext
  _Rule(RegExp(r"^what'?s next\b"), AskIntent.whatsNext),
  _Rule(RegExp(r'^what is up next\b'), AskIntent.whatsNext),
  _Rule(RegExp(r"^what'?s up next\b"), AskIntent.whatsNext),
  _Rule(RegExp(r"^what'?s after this\b"), AskIntent.whatsNext),

  // planMyDay
  _Rule(
    RegExp(r'^(?:plan|draft|schedule) (?:my |the )?(?:day|today)\b'),
    AskIntent.planMyDay,
  ),
  _Rule(RegExp(r'^plan today for me\b'), AskIntent.planMyDay),
  _Rule(RegExp(r'^what should i do today\b'), AskIntent.planMyDay),
  _Rule(RegExp(r"^what'?s my day look like\b"), AskIntent.planMyDay),

  // explainPlan
  _Rule(
    RegExp(r'^explain (?:the |my )?(?:plan|day|schedule)\b'),
    AskIntent.explainPlan,
  ),
  _Rule(
    RegExp(r'^walk me through (?:my |the )?(?:plan|day|schedule|today)\b'),
    AskIntent.explainPlan,
  ),
  _Rule(
    RegExp(r'^break down (?:my |the )?(?:plan|day|schedule)\b'),
    AskIntent.explainPlan,
  ),
  _Rule(RegExp(r'^why does my day look like this\b'), AskIntent.explainPlan),

  // whyTaskNotPlaced — before whyTaskHere, which would otherwise match.
  _Rule(
    RegExp(r"^why isn'?t (.+?) (?:on|in) (?:today|the plan|my plan)\b"),
    AskIntent.whyTaskNotPlaced,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^why is (.+?) not (?:on|in) (?:today|the plan|my plan)\b'),
    AskIntent.whyTaskNotPlaced,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^where is (.+?)(?: today)?$'),
    AskIntent.whyTaskNotPlaced,
    extractsTask: true,
  ),

  // whyTaskHere
  _Rule(
    RegExp(r'^why is (.+?) (?:so )?(?:late|early)$'),
    AskIntent.whyTaskHere,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^why is (.+?) (?:at|in|before|after) '),
    AskIntent.whyTaskHere,
    extractsTask: true,
  ),

  // whenTaskStarts — after the `why …` patterns.
  _Rule(
    RegExp(r'^when does (.+?) (?:start|begin)\b'),
    AskIntent.whenTaskStarts,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^when is (.+?)$'),
    AskIntent.whenTaskStarts,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^what time (?:is|does) (.+?)$'),
    AskIntent.whenTaskStarts,
    extractsTask: true,
  ),
];

// Hebrew phrase table. Hebrew past-tense second person is spelled the same
// for all genders (see `docs/tone-guide.md`), so the imperatives here keep
// the masculine form that reads as neutral; alternative suffixes are
// matched optionally. Task reference extraction trims a leading `ה` so
// "הגים" and "גים" normalize alike. `\b` is not used in these patterns
// because the regex engine's word boundary is ASCII-only — `(?: |$)` or an
// explicit space is used instead.
final List<_Rule> _heRules = [
  // whatsNext
  _Rule(RegExp(r'^מה הבא(?: |$)'), AskIntent.whatsNext),
  _Rule(RegExp(r'^מה עכשיו(?: |$)'), AskIntent.whatsNext),
  _Rule(RegExp(r'^מה אחרי זה(?: |$)'), AskIntent.whatsNext),

  // planMyDay
  _Rule(
    RegExp(r'^(?:תכנן|תכנני|תכננו)(?: לי)?(?: את)? היום שלי(?: |$)'),
    AskIntent.planMyDay,
  ),
  _Rule(
    RegExp(r'^(?:תכנן|תכנני|תכננו)(?: לי)?(?: את)? (?:ה)?יום(?: |$)'),
    AskIntent.planMyDay,
  ),
  _Rule(RegExp(r'^מה (?:כדאי|אני צריכ).* היום(?: |$)'), AskIntent.planMyDay),
  _Rule(RegExp(r'^איך היום שלי נראה(?: |$)'), AskIntent.planMyDay),

  // explainPlan
  _Rule(
    RegExp(
      r'^(?:הסבר|הסברי|הסברו)(?: לי)?(?: את)? (?:ה)?(?:תוכנית|יום)(?: |$)',
    ),
    AskIntent.explainPlan,
  ),
  _Rule(
    RegExp(
      r'^(?:ספר|ספרי|ספרו)(?: לי)?(?: על)? (?:ה)?(?:תוכנית|יום)(?: |$)',
    ),
    AskIntent.explainPlan,
  ),

  // whyTaskNotPlaced — before whyTaskHere.
  _Rule(
    RegExp(r'^למה (.+?) לא ב(?:תוכנית|יום|היום)(?: |$)'),
    AskIntent.whyTaskNotPlaced,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^איפה (.+?)$'),
    AskIntent.whyTaskNotPlaced,
    extractsTask: true,
  ),

  // whyTaskHere
  _Rule(
    RegExp(r'^למה (.+?) (?:כל כך )?מאוחר$'),
    AskIntent.whyTaskHere,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^למה (.+?) (?:כל כך )?מוקדם$'),
    AskIntent.whyTaskHere,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^למה (.+?) ב(?:בוקר|צהריים|ערב|לילה)$'),
    AskIntent.whyTaskHere,
    extractsTask: true,
  ),

  // whenTaskStarts
  _Rule(
    RegExp(r'^מתי (.+?) (?:מתחיל|מתחילה|מתחילים)(?: |$)'),
    AskIntent.whenTaskStarts,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^באיזו שעה (.+?)$'),
    AskIntent.whenTaskStarts,
    extractsTask: true,
  ),
  _Rule(
    RegExp(r'^מתי (.+?)$'),
    AskIntent.whenTaskStarts,
    extractsTask: true,
  ),
];
