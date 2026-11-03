import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import '../plan/plan_replan_sheet.dart' show scheduleTaskForMe;
import '../plan/plan_strings.dart';
import '../recurrence/providers.dart';
import '../recurrence/recurrence.dart';
import '../recurrence/recurrence_picker.dart';
import 'task_actions.dart';
import 'task_form.dart';
import 'task_providers.dart';
import 'tasks_strings.dart';

/// One task with Edit / Complete / Delete. Routed as `/task/:id` and also
/// pushed from the Today list.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  void _leave(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/today');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final ok = await showStickerSheet<bool>(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(TasksStrings.deleteTitle, style: AppText.display(size: 22)),
          const SizedBox(height: 6),
          Text(
            TasksStrings.deleteBody,
            style: AppText.body(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: TasksStrings.keep,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: TasksStrings.delete,
                  color: AppColors.pink,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final actions = ref.read(taskActionsProvider);
    // Toast first (the messenger outlives this route), then leave.
    await actions.deleteWithUndo(context, task);
    if (context.mounted) _leave(context);
  }

  /// Picks a repeat rule and writes it, or deletes it for "does not
  /// repeat". A series is anchored at `remindAt`, so a task without one
  /// gets its due time (or 09:00 on its day) as the anchor.
  Future<void> _editRecurrence(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ReminderRule? rule,
    Recurrence? current,
  ) async {
    final now = ref.read(clockProvider).now();
    final anchor = (task.remindAt ?? _defaultAnchor(task, now)).toLocal();
    final pick = await showRecurrencePicker(context, current, anchor: anchor);
    if (pick == null) return;
    final rules = ref.read(reminderRepositoryProvider);
    final utc = now.toUtc();
    final value = pick.value;
    if (value == null) {
      if (rule != null) await rules.delete(rule.id);
      return;
    }
    final rrule = value.toRRule();
    await rules.upsert(
      rule == null
          ? ReminderRule(
              id: 'rule-${task.id}',
              taskId: task.id,
              rrule: rrule,
              createdAt: utc,
              updatedAt: utc,
            )
          : rule.copyWith(rrule: rrule, updatedAt: utc),
    );
    if (task.remindAt == null) {
      await ref
          .read(taskActionsProvider)
          .save(task.copyWith(remindAt: anchor.toUtc()));
    }
  }

  static DateTime _defaultAnchor(Task task, DateTime now) {
    final due = task.dueAt?.toLocal();
    if (due != null && !(due.hour == 23 && due.minute == 59)) return due;
    final d = due ?? now.toLocal();
    return DateTime(d.year, d.month, d.day, 9);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskByIdProvider(taskId));
    final loading = ref.watch(tasksProvider).isLoading;
    final actions = ref.read(taskActionsProvider);

    Widget body;
    if (task == null) {
      body = loading
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(
              title: TasksStrings.notFound,
              body: '',
              actionLabel: TasksStrings.backToToday,
              onAction: () => context.go('/today'),
            );
    } else {
      body = _content(context, ref, task, actions);
    }

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Semantics(
                      button: true,
                      label: 'Back',
                      excludeSemantics: true,
                      onTap: () => _leave(context),
                      child: GestureDetector(
                        onTap: () => _leave(context),
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    Task task,
    TaskActions actions,
  ) {
    final due = task.dueAt?.toLocal();
    final dueHasTime = due != null && !(due.hour == 23 && due.minute == 59);
    final remind = task.remindAt?.toLocal();
    final done = task.isDone;
    final rule = ref.watch(ruleForTaskProvider(task.id)).valueOrNull;
    Recurrence? recurrence;
    if (rule != null) {
      try {
        recurrence = Recurrence.parse(rule.rrule);
      } on FormatException {
        recurrence = null;
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        SectionLabel(TasksStrings.detailTitle),
        const SizedBox(height: 4),
        Text(
          task.title,
          style: AppText.display(
            size: 26,
            height: 1.1,
          ).copyWith(decoration: done ? TextDecoration.lineThrough : null),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            task.energy == Energy.deep
                ? IconChip.deep(label: TasksStrings.deep, height: 28)
                : IconChip.light(label: TasksStrings.light, height: 28),
            Pill(label: TasksStrings.minutes(task.estimatedMinutes)),
            if (done) const Pill(label: 'Done', color: AppColors.mint),
          ],
        ),
        const SizedBox(height: 16),
        StickerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                TasksStrings.dueLabel,
                due == null
                    ? TasksStrings.noDate
                    : dueHasTime
                    ? '${TasksStrings.date(due)} · ${formatTime(due)}'
                    : TasksStrings.date(due),
              ),
              const SizedBox(height: 12),
              _field(
                TasksStrings.reminderTime,
                remind == null
                    ? '—'
                    : '${TasksStrings.date(remind)} · ${formatTime(remind)}',
              ),
              const SizedBox(height: 12),
              _field(
                TasksStrings.scheduledLabel,
                task.isScheduled
                    ? PlanStrings.slot(
                        task.scheduledStart!.toLocal(),
                        task.scheduledEnd!.toLocal(),
                      )
                    : TasksStrings.notScheduled,
              ),
              const SizedBox(height: 12),
              const SectionLabel(TasksStrings.repeatsLabel),
              const SizedBox(height: 2),
              RecurrenceSummaryChip(
                key: const Key('task-recurrence'),
                recurrence: recurrence,
                onTap: () =>
                    _editRecurrence(context, ref, task, rule, recurrence),
              ),
              if (task.firstAction != null) ...[
                const SizedBox(height: 12),
                _field(TasksStrings.firstActionLabel, task.firstAction!),
              ],
              if (task.notes != null) ...[
                const SizedBox(height: 12),
                _field(TasksStrings.notesLabel, task.notes!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        PillButton(
          label: done ? TasksStrings.reopen : TasksStrings.complete,
          color: done ? AppColors.card : AppColors.mint,
          display: true,
          fontSize: 16,
          onPressed: () => actions.toggle(context, task),
        ),
        if (!done) ...[
          const SizedBox(height: 10),
          PillButton(
            key: const Key('task-schedule-for-me'),
            label: PlanStrings.scheduleForMe,
            color: AppColors.lilac,
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => scheduleTaskForMe(context, ref, task.id),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: TasksStrings.edit,
                onPressed: () => showTaskSheet(context, existing: task),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: TasksStrings.delete,
                color: AppColors.pink,
                onPressed: () => _confirmDelete(context, ref, task),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel(label),
      const SizedBox(height: 2),
      Text(value, style: AppText.body()),
    ],
  );
}

/// "07:00" in local time.
String formatTime(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
