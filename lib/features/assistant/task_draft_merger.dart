import 'task_draft.dart';

/// Merges one [TaskDraft] onto another so the chat capture flow can
/// accept follow-up edits without losing context.
///
/// Typical use on the Ask composer (#39): the user types "gym tomorrow"
/// and gets a draft, then types "7am, 45 min" to add detail. The second
/// phrase parses to its own [TaskDraft] (with the time and duration set
/// and the title fallback), which this merger folds back onto the first
/// draft so the task card shows every field the user mentioned so far.
///
/// The merger is deliberately additive — overlay fills in what base
/// left blank, and replaces what base already had when the overlay
/// speaks on it. Clearing a field is an explicit UI gesture, not a
/// merge, so overlay's `null` values are treated as "say nothing" and
/// leave the base field as-is.
///
/// Pure Dart with no notion of time, zone, locale or language. Order
/// matters: [merge] is not commutative — the second argument wins on
/// conflicts. Pass drafts in the chat's chronological order so the
/// newest edit has the last word.
class TaskDraftMerger {
  const TaskDraftMerger._();

  /// Returns a new draft that takes every field from [base], then
  /// overwrites each field the [overlay] actually provided (i.e. the
  /// field is non-null on [overlay]).
  ///
  /// [TaskDraft.title] is required on both sides and always comes from
  /// [overlay] — the overlay is treated as the fresh statement of what
  /// the task is.
  static TaskDraft merge(TaskDraft base, TaskDraft overlay) => TaskDraft(
    title: overlay.title,
    date: overlay.date ?? base.date,
    time: overlay.time ?? base.time,
    durationMinutes: overlay.durationMinutes ?? base.durationMinutes,
    energy: overlay.energy ?? base.energy,
    firstAction: overlay.firstAction ?? base.firstAction,
    recurrenceRrule: overlay.recurrenceRrule ?? base.recurrenceRrule,
  );

  /// Folds [drafts] left-to-right with [merge].
  ///
  /// Convenience for a chat thread that holds a sequence of edits.
  /// Returns the single draft unchanged when the list has one entry;
  /// throws [ArgumentError] on an empty list since a merger must
  /// produce a draft and a draft requires a title.
  static TaskDraft mergeAll(List<TaskDraft> drafts) {
    if (drafts.isEmpty) {
      throw ArgumentError.value(
        drafts,
        'drafts',
        'TaskDraftMerger.mergeAll needs at least one draft',
      );
    }
    var acc = drafts.first;
    for (var i = 1; i < drafts.length; i++) {
      acc = merge(acc, drafts[i]);
    }
    return acc;
  }
}
