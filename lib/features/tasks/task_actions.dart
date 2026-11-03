import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/core.dart';
import '../../widgets/pip_toast.dart';
import 'tasks_strings.dart';

/// Create, complete and delete, shared by Today and the detail screen.
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  TaskRepository get _repo => _ref.read(taskRepositoryProvider);
  DateTime get _now => _ref.read(clockProvider).now().toUtc();

  /// A fresh task with the issue's defaults (30 min, light).
  Task create({
    required String title,
    DateTime? dueAt,
    DateTime? remindAt,
    int estimatedMinutes = 30,
    Energy energy = Energy.light,
    String? firstAction,
    String? notes,
  }) {
    final now = _now;
    return Task(
      id: const Uuid().v4(),
      title: title,
      dueAt: dueAt,
      remindAt: remindAt,
      estimatedMinutes: estimatedMinutes,
      energy: energy,
      firstAction: firstAction,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> save(Task t) => _repo.upsert(t.copyWith(updatedAt: _now));

  Future<void> setDone(Task t, bool done) {
    final now = _now;
    return _repo.upsert(
      t.copyWith(
        status: done ? TaskStatus.done : TaskStatus.open,
        completedAt: done ? now : null,
        updatedAt: now,
      ),
    );
  }

  /// Toggle done; completing shows an undo toast.
  Future<void> toggle(BuildContext context, Task t) async {
    final done = !t.isDone;
    await setDone(t, done);
    if (done && context.mounted) {
      showPipToast(
        context,
        TasksStrings.markedDone,
        actionLabel: TasksStrings.undo,
        onAction: () => setDone(t, false),
      );
    }
  }

  /// Soft-delete with an undo toast that restores the task.
  Future<void> deleteWithUndo(
    BuildContext context,
    Task t, {
    VoidCallback? onUndo,
  }) async {
    await _repo.delete(t.id);
    if (!context.mounted) return;
    showPipToast(
      context,
      TasksStrings.deleted,
      actionLabel: TasksStrings.undo,
      onAction: () {
        _repo.upsert(t);
        onUndo?.call();
      },
    );
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref));
