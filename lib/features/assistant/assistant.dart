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
library;

export 'task_draft.dart';
export 'task_draft_parser.dart';
export 'task_draft_resolver.dart';
