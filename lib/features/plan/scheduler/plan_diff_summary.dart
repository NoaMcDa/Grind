import '../../../l10n/l10n.dart';
import 'replan.dart' show PlanDiff;

/// Pip's one- or two-sentence read of a [PlanDiff]. Pure: no clock, no
/// network, no LLM. The assistant layer in epic #40 can route a free-text
/// "what changed?" turn to this when the scheduler has just produced a
/// re-plan — the diff is the source of truth, and this layer only renders
/// counts in Pip's tone. It never names tasks or times, so it is safe to
/// call even when the chat view is slightly stale.
class PlanDiffSummary {
  const PlanDiffSummary(this.sentences);

  /// Each sentence stands on its own and ends with its own punctuation, so
  /// the caller may join with a space or render them as a list.
  final List<String> sentences;

  /// The sentences joined with a single space.
  String get text => sentences.join(' ');

  @override
  String toString() => 'PlanDiffSummary($sentences)';
}

/// Reads [diff] in Pip's tone (EN or HE from [l]) and produces at most two
/// sentences. Two cases:
///
/// 1. The diff is empty: a single warm "nothing shifted" line.
/// 2. The diff has moves, placements or removals: one sentence per
///    category in the order moved → added → removed, capped at two — if
///    all three fire the least-impactful (removed) drops. See the
///    `planDiff…` ARB keys for the exact plural forms.
///
/// Counts come from the diff's own lists; the summary never invents times
/// or titles, and it never says "late" or "missed" (see
/// `docs/tone-guide.md`).
PlanDiffSummary summarizePlanDiff({
  required PlanDiff diff,
  required AppLocalizations l,
}) {
  if (diff.isEmpty) return PlanDiffSummary([l.planDiffNothing]);
  final sentences = <String>[];
  if (diff.moved.isNotEmpty) {
    sentences.add(l.planDiffMoved(diff.moved.length));
  }
  if (diff.added.isNotEmpty && sentences.length < 2) {
    sentences.add(l.planDiffAdded(diff.added.length));
  }
  if (diff.removed.isNotEmpty && sentences.length < 2) {
    sentences.add(l.planDiffRemoved(diff.removed.length));
  }
  return PlanDiffSummary(sentences);
}
