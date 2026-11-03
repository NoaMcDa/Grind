import 'package:grind/core/domain/domain.dart' show Energy;

import '../../../l10n/l10n.dart';
import '../scheduler/time_math.dart' show hm;
import 'day_draft.dart';

/// Pip's 2–3 sentence read of a `DayDraft`. Pure: no clock, no network, no
/// LLM. The assistant layer will swap this for a model later (see epic
/// #40); this is the deterministic fallback and the golden for the model
/// to beat, and reads straight from the reasons the scheduler already
/// wrote. EN and HE strings live in the `planExplain…` ARB keys.
class PlanExplanation {
  const PlanExplanation(this.sentences);

  /// Each sentence stands on its own and ends with its own punctuation,
  /// so the caller may join with a space or render them as a list.
  final List<String> sentences;

  /// The sentences joined with a single space.
  String get text => sentences.join(' ');

  @override
  String toString() => 'PlanExplanation($sentences)';
}

/// The reason string the scheduler writes when a deep block lands inside
/// a configured focus window. Used to detect "focus work today" without
/// running the scheduler again.
const _focusWindowReason = 'your focus window';

/// Reads [draft] in Pip's tone (EN or HE from [l]). Three cases, picked
/// from the draft itself — the explainer never invents times or titles,
/// and never says "overdue" or "missed" (see `docs/tone-guide.md`):
///
/// 1. Nothing to place: a single warm one-liner (free time → "day is
///    yours"; no free time → "tomorrow is a fresh page").
/// 2. Only unplaced tasks (nothing fit): one sentence that names the
///    count and says they can wait.
/// 3. A real plan: a header, then a range line with count, first and last
///    clock times, and total planned duration; and a third sentence that
///    is either "deep work in your focus window" (preferred when the
///    scheduler put a deep block there), the later-day note (open tasks
///    with no deadline today, from `DayDraft.laterCount`), or the "didn't
///    fit" note (tasks due today still in `DayDraft.unplaced`). Capped at
///    three sentences.
PlanExplanation explainDayDraft({
  required DayDraft draft,
  required AppLocalizations l,
}) {
  if (draft.items.isEmpty && draft.unplaced.isEmpty) {
    return PlanExplanation([
      draft.freeMinutes == 0 ? l.planExplainNoTime : l.planExplainNothing,
    ]);
  }

  if (draft.items.isEmpty) {
    return PlanExplanation([l.planExplainUnplacedOnly(draft.unplaced.length)]);
  }

  final first = draft.items.first.start;
  final last = draft.items.last.end;
  final sentences = <String>[
    l.planExplainHeader,
    l.planExplainBlocks(
      draft.items.length,
      hm(first),
      hm(last),
      _duration(l, draft.plannedMinutes),
    ),
  ];

  final focus = draft.items.any(
    (i) =>
        i.energy == Energy.deep && i.reasons.contains(_focusWindowReason),
  );
  if (focus) {
    sentences.add(l.planExplainFocus);
  } else if (draft.laterCount > 0) {
    sentences.add(l.draftLater(draft.laterCount));
  } else if (draft.unplaced.isNotEmpty) {
    sentences.add(l.planExplainUnplacedExtra(draft.unplaced.length));
  }

  return PlanExplanation(sentences);
}

/// "45 min" or "2 h" (half-hour rounded) in the app language. Mirrors the
/// helper in `day_draft_sheet.dart`; not shared to avoid pulling a
/// Material import into the explainer.
String _duration(AppLocalizations l, int minutes) {
  if (minutes < 60) return l.commonMinutes(minutes);
  final h = (minutes / 30).round() / 2;
  return l.planHoursShort(h == h.roundToDouble() ? '${h.toInt()}' : '$h');
}
