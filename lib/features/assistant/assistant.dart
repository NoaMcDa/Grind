/// Assistant layer (#39): natural-language task capture.
///
/// Today this exports:
/// - [TaskDraft]: the structured output schema a captured phrase fills
///   (title, date, time, durationMinutes, energy, firstAction,
///   recurrence?), used by both the cloud path (#38) and the fallback.
/// - [TaskDraftParser]: the offline / opted-out regex + date-parser
///   fallback, so capture never breaks when the cloud assistant is off
///   or unreachable. Handles EN and the common HE phrases.
/// - [TaskDraftResolver]: turns a confirmed draft into a persist-ready
///   [Task] (and parsed [Recurrence] when the draft repeats) in the
///   user's zone, so the Ask composer's "Add" can hand the task to the
///   repository.
/// - [TaskDraftPreview]: one-line EN/HE summary of a draft for the chat
///   task card, so the user confirms with one tap.
/// - [TaskDraftDiff]: which fields changed between two drafts, used by
///   the chat edit flow to show what the user's edit did.
/// - [TaskDraftMerger]: folds a follow-up draft's fields onto an earlier
///   one so the chat capture keeps context across edits.
library;

export 'task_draft.dart';
export 'task_draft_diff.dart';
export 'task_draft_merger.dart';
export 'task_draft_parser.dart';
export 'task_draft_preview.dart';
export 'task_draft_resolver.dart';
