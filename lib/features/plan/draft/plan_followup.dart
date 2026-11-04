import '../../../l10n/l10n.dart';
import '../plan_reasons_l10n.dart' show localizePlanReason;
import '../scheduler/time_math.dart' show hm;
import 'day_draft.dart';

/// One canonical follow-up question a user may ask Pip about a `DayDraft`.
///
/// Each kind is answered deterministically — no LLM, no clock, no network —
/// by reading straight from the reasons the scheduler wrote. The assistant
/// layer (epic #40) maps a free-text user turn to one of these; this module
/// turns it into a short EN or HE answer in Pip's tone. The explainer in
/// `plan_explainer.dart` produces the opening summary; this one answers the
/// follow-ups ("why is the gym so late?", "why isn't X on the plan?",
/// "when does X start?").
sealed class PlanQuestion {
  const PlanQuestion();
}

/// "Why is {task} where it is?" — covers "why is the gym so late?",
/// "why so early?", "why at that time?". Answered from the placed block's
/// own reasons.
class WhyTaskHere extends PlanQuestion {
  const WhyTaskHere(this.taskId);

  final String taskId;
}

/// "Why isn't {task} in today's plan?" — answered from the task's row in
/// `DayDraft.unplaced`. If the task *is* placed, the answer redirects to
/// the placement time.
class WhyTaskNotPlaced extends PlanQuestion {
  const WhyTaskNotPlaced(this.taskId);

  final String taskId;
}

/// "When does {task} start?" — the start and end times of the placed
/// block, or a one-liner if the task did not fit or is not on the draft.
class WhenTaskStarts extends PlanQuestion {
  const WhenTaskStarts(this.taskId);

  final String taskId;
}

/// Pip's one- or two-sentence read of a `PlanQuestion`. Each sentence ends
/// with its own punctuation, so the caller may join with a space or render
/// them as a list.
class PlanAnswer {
  const PlanAnswer(this.sentences);

  final List<String> sentences;

  /// The sentences joined with a single space.
  String get text => sentences.join(' ');

  @override
  String toString() => 'PlanAnswer($sentences)';
}

/// Reads [draft] in Pip's tone (EN or HE from [l]) and answers [question]
/// from its reason data alone. Never invents times, titles or reasons; the
/// task's title is implicit from the question the caller already asked,
/// so the answer refers to it as "it" / "that one". Returns at most two
/// sentences. Unknown task ids read as "not on today's plan" — a safe
/// fallback that keeps the tone even when the chat layer is stale.
PlanAnswer answerPlanQuestion({
  required DayDraft draft,
  required PlanQuestion question,
  required AppLocalizations l,
}) {
  switch (question) {
    case WhyTaskHere(:final taskId):
      final placed = _placedOf(draft, taskId);
      if (placed != null) {
        final reasons = _localizedReasons(l, placed.reasons);
        if (reasons.isEmpty) {
          return PlanAnswer([l.followupHereNoReason(hm(placed.start))]);
        }
        return PlanAnswer([l.followupHereAt(hm(placed.start), reasons)]);
      }
      final unplaced = _unplacedReason(l, draft, taskId);
      if (unplaced != null) {
        return PlanAnswer([unplaced]);
      }
      return PlanAnswer([l.followupUnknown]);

    case WhyTaskNotPlaced(:final taskId):
      final unplaced = _unplacedReason(l, draft, taskId);
      if (unplaced != null) {
        return PlanAnswer([unplaced]);
      }
      final placed = _placedOf(draft, taskId);
      if (placed != null) {
        return PlanAnswer([l.followupAlreadyPlaced(hm(placed.start))]);
      }
      return PlanAnswer([l.followupUnknown]);

    case WhenTaskStarts(:final taskId):
      final placed = _placedOf(draft, taskId);
      if (placed != null) {
        return PlanAnswer([l.followupWhen(hm(placed.start), hm(placed.end))]);
      }
      if (_isUnplaced(draft, taskId)) {
        return PlanAnswer([l.followupNotFitBare]);
      }
      return PlanAnswer([l.followupUnknown]);
  }
}

DraftItem? _placedOf(DayDraft draft, String taskId) {
  for (final i in draft.items) {
    if (i.taskId == taskId) return i;
  }
  return null;
}

bool _isUnplaced(DayDraft draft, String taskId) =>
    draft.unplaced.any((u) => u.taskId == taskId);

/// The "that one did not fit today" sentence, with the localized unplaced
/// reason when the scheduler wrote one, or the bare version otherwise.
/// Returns null when [taskId] is not in `draft.unplaced`.
String? _unplacedReason(AppLocalizations l, DayDraft draft, String taskId) {
  for (final u in draft.unplaced) {
    if (u.taskId == taskId) {
      final reason = u.reason.trim();
      if (reason.isEmpty) return l.followupNotFitBare;
      return l.followupNotFit(localizePlanReason(l, reason));
    }
  }
  return null;
}

/// Joins the scheduler's reasons with a comma, after localizing each. Drops
/// duplicates and empty fragments. Capped at three so the answer stays
/// short: that mirrors the per-block cap the scheduler itself observes.
String _localizedReasons(AppLocalizations l, List<String> reasons) {
  final seen = <String>{};
  final out = <String>[];
  for (final r in reasons) {
    final t = localizePlanReason(l, r).trim();
    if (t.isEmpty || !seen.add(t)) continue;
    out.add(t);
    if (out.length == 3) break;
  }
  return out.join(', ');
}
