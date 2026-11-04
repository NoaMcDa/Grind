import 'dart:ui' show Locale;

import 'ask_intent.dart';

/// A pre-seeded Ask Pip chip: a short label a user can tap on the composer
/// to send a canonical turn to the assistant.
///
/// Each chip is paired with the [AskIntent] its label resolves to under the
/// intent classifier in `ask_intent.dart`, so the composer can route a tap
/// without re-classifying (and a test keeps the two in step). Pip's quick
/// prompts in EN and HE live in [quickPromptsFor]; nothing here reaches
/// the network or the clock.
class AskQuickPrompt {
  const AskQuickPrompt(this.label, this.intent);

  /// What the chip reads. Already tone- and locale-appropriate; never
  /// trimmed, lower-cased or re-punctuated by the renderer.
  final String label;

  /// The canonical intent the label resolves to. Round-tripped through
  /// `classifyAskPrompt(label, locale: …)` in the test, so the two tables
  /// never drift.
  final AskIntent intent;

  @override
  bool operator ==(Object other) =>
      other is AskQuickPrompt && other.label == label && other.intent == intent;

  @override
  int get hashCode => Object.hash(label, intent);

  @override
  String toString() => 'AskQuickPrompt("$label", $intent)';
}

/// The chips shown on the Ask Pip composer, in display order, for the
/// given [locale]. Only `he` is treated as Hebrew; every other language
/// (including a null locale) returns the English catalog. The lists are
/// `const` and may be rendered directly — the caller does not need to
/// cache them.
///
/// The three chips cover the top of the epic #40 funnel: the quick-prompt
/// entry point (`planMyDay`), the deterministic explainer (`explainPlan`
/// from #106), and the "where am I" nudge (`whatsNext`). Follow-ups about
/// a specific task (`whyTaskHere`, `whyTaskNotPlaced`, `whenTaskStarts`)
/// are free-text only — they name a task, which no fixed chip can.
List<AskQuickPrompt> quickPromptsFor(Locale? locale) {
  final lang = (locale?.languageCode ?? 'en') == 'he' ? 'he' : 'en';
  return lang == 'he' ? _he : _en;
}

const List<AskQuickPrompt> _en = [
  AskQuickPrompt('Plan my day', AskIntent.planMyDay),
  AskQuickPrompt('Explain the plan', AskIntent.explainPlan),
  AskQuickPrompt("What's next?", AskIntent.whatsNext),
];

const List<AskQuickPrompt> _he = [
  AskQuickPrompt('תכנן לי את היום', AskIntent.planMyDay),
  AskQuickPrompt('הסבר לי את התוכנית', AskIntent.explainPlan),
  AskQuickPrompt('מה הבא?', AskIntent.whatsNext),
];
