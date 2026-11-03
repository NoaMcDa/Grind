import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/core.dart';
import '../../widgets/pip_toast.dart';
import '../recurrence/occurrence_completion.dart';
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

  /// Completes the current occurrence of a recurring task: the series moves
  /// on to its next occurrence (and loses this occurrence's slot), or is
  /// done when none is left. Null when [t] does not repeat.
  Future<Task?> completeRecurring(Task t) async {
    final anchor = t.remindAt;
    if (anchor == null) return null;
    final rule = await _ref.read(reminderRepositoryProvider).getForTask(t.id);
    if (rule == null) return null;
    final prefs = await _ref.read(preferencesRepositoryProvider).get();
    var next = completeOccurrence(
      task: t,
      rule: rule,
      occurrenceAt: anchor,
      timeZoneName: prefs.timeZoneName,
      now: _now,
    );
    if (!next.isDone) {
      next = next.copyWith(
        scheduledStart: null,
        scheduledEnd: null,
        lockedStart: false,
      );
    }
    await _repo.upsert(next);
    return next;
  }

  /// Toggle done; completing shows an undo toast. On a recurring task,
  /// "done" completes this occurrence only.
  Future<void> toggle(BuildContext context, Task t) async {
    final done = !t.isDone;
    if (done) {
      final next = await completeRecurring(t);
      if (next != null) {
        if (!context.mounted) return;
        showPipToast(
          context,
          next.isDone ? TasksStrings.markedDone : TasksStrings.nextOneSet,
          actionLabel: TasksStrings.undo,
          onAction: () => _repo.upsert(t),
        );
        return;
      }
    }
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
