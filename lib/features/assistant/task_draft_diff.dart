import 'task_draft.dart';

/// The fields of a [TaskDraft] that a diff can report on.
///
/// Order mirrors the schema declaration in [TaskDraft] so a UI iterating
/// [TaskDraftDiff.changedFields] in enum order presents the changes
/// top-to-bottom the same way the task card lists them.
enum TaskDraftField {
  title,
  date,
  time,
  durationMinutes,
  energy,
  firstAction,
  recurrenceRrule,
}

/// A structural diff between two [TaskDraft]s — which fields changed
/// between a `before` and an `after` version of the same draft.
///
/// Used by the Ask-composer chat edit flow (#39): when the user confirms
/// an edit on the task card, we want to show a concise "you changed X
/// and Y" so the change feels visible before the one-tap "Add". The diff
/// is presentation-agnostic — the caller decides how to label each
/// [TaskDraftField] and in which language.
///
/// Setting a field (null → value), clearing it (value → null) and
/// replacing its value all count as a change. Only the seven fields of
/// [TaskDraftField] are compared; anything outside that set never
/// appears in the diff.
class TaskDraftDiff {
  const TaskDraftDiff._(this.changedFields);

  /// Returns the diff between [before] and [after]. The two drafts are
  /// compared field-by-field; a field is in [changedFields] exactly
  /// when its values differ (using `==`, matching how [TaskDraft]
  /// itself compares).
  factory TaskDraftDiff.between(TaskDraft before, TaskDraft after) {
    final changed = <TaskDraftField>{};
    if (before.title != after.title) {
      changed.add(TaskDraftField.title);
    }
    if (before.date != after.date) {
      changed.add(TaskDraftField.date);
    }
    if (before.time != after.time) {
      changed.add(TaskDraftField.time);
    }
    if (before.durationMinutes != after.durationMinutes) {
      changed.add(TaskDraftField.durationMinutes);
    }
    if (before.energy != after.energy) {
      changed.add(TaskDraftField.energy);
    }
    if (before.firstAction != after.firstAction) {
      changed.add(TaskDraftField.firstAction);
    }
    if (before.recurrenceRrule != after.recurrenceRrule) {
      changed.add(TaskDraftField.recurrenceRrule);
    }
    return TaskDraftDiff._(Set.unmodifiable(changed));
  }

  /// An empty diff — the two drafts matched on every compared field.
  static const TaskDraftDiff empty = TaskDraftDiff._(<TaskDraftField>{});

  /// The fields that differ between the two drafts, in declaration
  /// order of [TaskDraftField]. The set is unmodifiable.
  final Set<TaskDraftField> changedFields;

  /// True when no fields changed.
  bool get isEmpty => changedFields.isEmpty;

  /// True when at least one field changed.
  bool get isNotEmpty => changedFields.isNotEmpty;

  /// Number of fields that changed.
  int get length => changedFields.length;

  /// Whether [field] is one of the changed fields.
  bool contains(TaskDraftField field) => changedFields.contains(field);

  @override
  bool operator ==(Object other) =>
      other is TaskDraftDiff &&
      other.changedFields.length == changedFields.length &&
      other.changedFields.containsAll(changedFields);

  @override
  int get hashCode => Object.hashAllUnordered(changedFields);

  @override
  String toString() {
    if (changedFields.isEmpty) return 'TaskDraftDiff(empty)';
    final names = changedFields.map((f) => f.name).join(', ');
    return 'TaskDraftDiff($names)';
  }
}
