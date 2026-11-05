/// A bucketed, enum-shaped read of a scheduler reason string.
///
/// The pure scheduler core (see `scheduler/planner.dart`,
/// `scheduler/replan.dart` and `DayDraft._reorderedReasons` in
/// `draft/day_draft.dart`) writes short English reason strings next to
/// every placement and every re-plan move.
/// `plan_reasons_l10n.dart` turns one of those strings into a localized
/// sentence; this module does the orthogonal job of collapsing many reason
/// templates into a small, stable set of categories.
///
/// Categories are what the assistant layer (epic #40) needs for higher-level
/// reads over a `DayDraft` — picking the one most notable reason for the plan
/// explainer's trailer, grouping reasons when answering "why is X where it
/// is?", and telling a "we moved it because of the calendar" from a "we moved
/// it because the hours changed" in the re-plan diff summary. The classifier
/// stays pure, deterministic and locale-free; it reads the scheduler's own
/// English templates and never looks at a user-supplied free-form string
/// beyond returning [ReasonCategory.other] for it.
library;

/// Which family of reasons a scheduler string belongs to. Values are stable;
/// new templates added to the scheduler map to existing buckets where they
/// fit and get a new bucket only when they carry a distinct meaning.
enum ReasonCategory {
  /// "you placed this here" — the user pinned the block, the scheduler did
  /// not pick its time.
  pinnedByUser,

  /// "your focus window" — a deep block lands inside a configured focus
  /// window. Positive: the block earned its slot.
  focusWindow,

  /// "keeps your focus window clear" — a shallow block was placed where it
  /// is so a future focus window stays free. Different from
  /// [focusWindow] because nothing deep landed here.
  focusClear,

  /// "due today", "due tomorrow", "due Wednesday", "due Nov 12" — the
  /// task's deadline shaped the placement. The block fit; the pressure
  /// rose from the due date, not from a lack of room.
  deadline,

  /// "earliest free 25-minute gap before today's deadline",
  /// "focus blocks are full before Thursday's deadline",
  /// "only 30 of 60 min fit this week",
  /// "no free 45-minute slot before Nov 12",
  /// "no free gap before the end of the week" — the deadline left no room
  /// or forced a specific slot. Used on both placed blocks (the deadline
  /// picked the slot) and unplaced tasks (the deadline is why nothing fit).
  deadlinePressure,

  /// "part of {goal}" — the block belongs to a goal with real importance.
  partOfGoal,

  /// "first 45 of 90 min", "next 45 of 90 min", "last 30 of 90 min" — the
  /// block is one chunk of a splittable task. Mentioned alongside another
  /// category in the scheduler's own output; the classifier returns this
  /// only when the string is purely the chunk label.
  chunk,

  /// "earliest free 25-minute gap", "fills a 20-minute gap" — the block
  /// took the first free gap of the right size with no deadline pressure
  /// and nothing else to say. The soft default; a "nothing special, it
  /// just fit here" marker.
  gapFit,

  /// "in the order you chose" — a draft reorder kept this block's stable
  /// reasons but gave it this marker in place of a slot-specific one (see
  /// `DayDraft._reorderedReasons`).
  userOrder,

  /// "the due date has passed, want to pick a new one?",
  /// "this one is already done" — the scheduler surfaced a task-state
  /// issue rather than a placement reason.
  taskState,

  /// Re-plan diff move reasons from `_moveReason` in `replan.dart`:
  /// "that time has passed", "your hours changed",
  /// "an earlier slot opened up", "reshuffled around today's changes",
  /// "you put {title} there", "made room for {title}",
  /// "{title} now takes that time".
  replanMove,

  /// Re-plan diff removal reasons from `_removalReason` in `replan.dart`:
  /// "no longer on your list", "done, nice work", "skipped for now",
  /// "no longer fits this week".
  replanRemove,

  /// Anything else — a user-supplied free-form reason, an unknown template,
  /// an empty or whitespace string. The caller should fall back to showing
  /// the string verbatim and not key off this value.
  other,
}

/// Collapses a scheduler reason string into a [ReasonCategory]. Pure and
/// deterministic. The input is the same shape `localizePlanReason` takes
/// (the scheduler's English template, trimmed); whitespace around the
/// string is tolerated. Unknown strings return [ReasonCategory.other].
ReasonCategory categorizePlanReason(String reason) {
  final r = reason.trim();
  if (r.isEmpty) return ReasonCategory.other;

  // Exact-match templates first — the common case.
  switch (r) {
    case 'you placed this here':
      return ReasonCategory.pinnedByUser;
    case 'your focus window':
      return ReasonCategory.focusWindow;
    case 'keeps your focus window clear':
      return ReasonCategory.focusClear;
    case 'in the order you chose':
      return ReasonCategory.userOrder;
    case 'the due date has passed, want to pick a new one?':
    case 'this one is already done':
      return ReasonCategory.taskState;
    case 'no free gap before the end of the week':
      return ReasonCategory.deadlinePressure;
    // Re-plan diff: move reasons.
    case 'that time has passed':
    case 'your hours changed':
    case 'an earlier slot opened up':
    case "reshuffled around today's changes":
      return ReasonCategory.replanMove;
    // Re-plan diff: removal reasons.
    case 'no longer on your list':
    case 'done, nice work':
    case 'skipped for now':
    case 'no longer fits this week':
      return ReasonCategory.replanRemove;
  }

  // Parameterized placement templates. Deadline-pressure patterns are
  // checked before the plain "earliest free" fallback so the "before X"
  // variant does not read as a plain gap fit.
  if (_matches(r, _dueRe)) return ReasonCategory.deadline;
  if (_matches(r, _partOfRe)) return ReasonCategory.partOfGoal;
  if (_matches(r, _chunkRe)) return ReasonCategory.chunk;
  if (_matches(r, _gapBeforeRe) ||
      _matches(r, _focusFullRe) ||
      _matches(r, _onlyFitRe) ||
      _matches(r, _noSlotRe)) {
    return ReasonCategory.deadlinePressure;
  }
  if (_matches(r, _earliestGapRe) || _matches(r, _fillsGapRe)) {
    return ReasonCategory.gapFit;
  }

  // Parameterized re-plan diff templates. "{title} now takes that time",
  // "you put {title} there" and "made room for {title}" capture a free-form
  // title, so they are checked last — otherwise a goal titled "that time"
  // or a user reason containing those words could trip them.
  if (_matches(r, _youPutRe) ||
      _matches(r, _madeRoomRe) ||
      _matches(r, _nowTakesRe)) {
    return ReasonCategory.replanMove;
  }

  return ReasonCategory.other;
}

bool _matches(String s, RegExp re) => re.firstMatch(s) != null;

// Mirrors the templates handled in `plan_reasons_l10n.dart`; kept as
// top-level finals so each pattern compiles once.
final _dueRe = RegExp(r'^due .+$');
final _partOfRe = RegExp(r'^part of .+$');
final _chunkRe = RegExp(r'^(?:first|next|last) \d+ of \d+ min$');
final _earliestGapRe = RegExp(r'^earliest free \d+-minute gap$');
final _gapBeforeRe = RegExp(r'^earliest free \d+-minute gap before .+$');
final _fillsGapRe = RegExp(r'^fills a \d+-minute gap$');
final _focusFullRe = RegExp(r'^focus blocks are full .+$');
final _onlyFitRe = RegExp(r'^only \d+ of \d+ min fit .+$');
final _noSlotRe = RegExp(r'^no free \d+-minute slot .+$');
final _youPutRe = RegExp(r'^you put .+ there$');
final _madeRoomRe = RegExp(r'^made room for .+$');
final _nowTakesRe = RegExp(r'^.+ now takes that time$');
