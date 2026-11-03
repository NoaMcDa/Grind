import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/core.dart';
import '../../widgets/pip_toast.dart';
import '../recurrence/occurrence_completion.dart';
import '../recurrence/occurrence_expander.dart';
import 'day_bounds.dart';
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
    String? goalId,
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
      goalId: goalId,
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

  /// Completes one occurrence of a recurring task: the rule's
  /// `lastCompletedAt` becomes the occurrence (UTC) and `remindAt` moves on
  /// to the next one for the notification scheduler, or the task is done
  /// when none is left (see [completeSeriesOccurrence]). Null when [t] does
  /// not repeat.
  ///
  /// [occurrenceAt] is the occurrence being completed (a Today row passes
  /// its own). Without it, the current one: the latest occurrence at or
  /// before now, or the anchor when the series has not started yet.
  Future<Task?> completeRecurring(Task t, {DateTime? occurrenceAt}) async {
    final anchor = t.remindAt;
    if (anchor == null) return null;
    final rules = _ref.read(reminderRepositoryProvider);
    final rule = await rules.getForTask(t.id);
    if (rule == null) return null;
    final prefs = await _ref.read(preferencesRepositoryProvider).get();
    final now = _now;
    final at =
        occurrenceAt ??
        _currentOccurrence(rule, anchor, now, prefs.timeZoneName) ??
        anchor;
    final progress = completeSeriesOccurrence(
      task: t,
      rule: rule,
      occurrenceAt: utcOf(at),
      timeZoneName: prefs.timeZoneName,
      now: now,
    );
    var next = _plainRemindAt(progress.task);
    if (!next.isDone) {
      next = next.copyWith(
        scheduledStart: null,
        scheduledEnd: null,
        lockedStart: false,
      );
    }
    await rules.upsert(progress.rule);
    await _repo.upsert(next);
    return next;
  }

  /// Takes back the completion of [occurrenceAt] (default: the last
  /// completed one): `lastCompletedAt` returns to the occurrence before it,
  /// or null (see [uncompleteSeriesOccurrence]). Null when [t] does not
  /// repeat or nothing was completed.
  Future<Task?> uncompleteRecurring(Task t, {DateTime? occurrenceAt}) async {
    final rules = _ref.read(reminderRepositoryProvider);
    final rule = await rules.getForTask(t.id);
    if (rule == null) return null;
    final at = occurrenceAt ?? rule.lastCompletedAt;
    if (at == null) return null;
    final prefs = await _ref.read(preferencesRepositoryProvider).get();
    final progress = uncompleteSeriesOccurrence(
      task: t,
      rule: rule,
      occurrenceAt: utcOf(at),
      timeZoneName: prefs.timeZoneName,
      now: _now,
    );
    final next = _plainRemindAt(progress.task);
    await rules.upsert(progress.rule);
    await _repo.upsert(next);
    return next;
  }

  static DateTime? _currentOccurrence(
    ReminderRule rule,
    DateTime anchor,
    DateTime now,
    String zone,
  ) {
    if (anchor.isAfter(now)) return null;
    final past = expandOccurrences(
      rule: rule.copyWith(leadMinutes: 0),
      anchor: anchor,
      from: anchor,
      to: now.add(const Duration(minutes: 1)),
      timeZoneName: zone,
    );
    return past.isEmpty ? null : utcOf(past.last);
  }

  /// The expander hands back `TZDateTime`s; store a plain UTC value.
  static Task _plainRemindAt(Task t) =>
      t.remindAt == null ? t : t.copyWith(remindAt: utcOf(t.remindAt!));

  /// Toggle done; completing shows an undo toast. On a recurring task,
  /// "done" completes one occurrence only ([occurrenceAt], see
  /// [completeRecurring]) and the series continues; on an occurrence that is
  /// already done ([isOccurrenceDone]) it takes that completion back
  /// ([uncompleteRecurring]).
  Future<void> toggle(
    BuildContext context,
    Task t, {
    DateTime? occurrenceAt,
  }) async {
    final rules = _ref.read(reminderRepositoryProvider);
    final rule = t.remindAt == null ? null : await rules.getForTask(t.id);
    if (rule != null) {
      final rowDone = occurrenceAt == null
          ? t.isDone
          : t.isDone || isOccurrenceDone(rule, occurrenceAt);
      if (rowDone) {
        if (await uncompleteRecurring(t, occurrenceAt: occurrenceAt) != null) {
          return;
        }
      } else {
        final next = await completeRecurring(t, occurrenceAt: occurrenceAt);
        if (next != null) {
          if (!context.mounted) return;
          showPipToast(
            context,
            next.isDone ? TasksStrings.markedDone : TasksStrings.nextOneSet,
            actionLabel: TasksStrings.undo,
            onAction: () async {
              await rules.upsert(rule);
              await _repo.upsert(t);
            },
          );
          return;
        }
      }
    }
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

  /// Soft-delete with an undo toast that restores the task. A recurrence
  /// rule goes with the task and comes back with the undo.
  Future<void> deleteWithUndo(
    BuildContext context,
    Task t, {
    VoidCallback? onUndo,
  }) async {
    final rules = _ref.read(reminderRepositoryProvider);
    final rule = await rules.getForTask(t.id);
    await _repo.delete(t.id);
    if (rule != null) await rules.delete(rule.id);
    if (!context.mounted) return;
    showPipToast(
      context,
      TasksStrings.deleted,
      actionLabel: TasksStrings.undo,
      onAction: () {
        _repo.upsert(t);
        if (rule != null) rules.upsert(rule);
        onUndo?.call();
      },
    );
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref));
