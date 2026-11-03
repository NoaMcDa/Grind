/// Assistant layer (#39): natural-language task capture.
///
/// Today this exports:
/// - [TaskDraft]: the structured output schema a captured phrase fills
///   (title, date, time, durationMinutes, energy, firstAction,
///   recurrence?), used by both the cloud path (#38) and the fallback.
/// - [TaskDraftParser]: the offline / opted-out regex + date-parser
///   fallback, so capture never breaks when the cloud assistant is off
///   or unreachable. Handles EN and the common HE phrases.
library;

export 'task_draft.dart';
export 'task_draft_parser.dart';
