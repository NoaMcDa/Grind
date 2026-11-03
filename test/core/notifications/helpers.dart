import 'package:grind/core/core.dart';

final epoch = DateTime.utc(2026, 1, 1);

Task task(
  String id, {
  DateTime? remindAt,
  String? firstAction,
  String title = 'Task',
  TaskStatus status = TaskStatus.open,
}) => Task(
  id: id,
  title: title,
  remindAt: remindAt,
  firstAction: firstAction,
  status: status,
  createdAt: epoch,
  updatedAt: epoch,
);

/// Preferences with prompts out of the way of most tests.
const utcPrefs = Preferences(timeZoneName: 'UTC');
