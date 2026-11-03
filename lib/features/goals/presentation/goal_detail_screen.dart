import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/widgets.dart';
import '../domain/goal_area.dart';
import '../domain/goal_metric.dart';
import '../domain/goal_progress.dart';
import '../domain/goal_record.dart';
import '../goal_providers.dart';
import '../goals_strings.dart';
import 'goal_form.dart';
import 'goal_widgets.dart';

/// One goal: metric ring with +1 / edit count, details, linked tasks.
/// Routed as `/goals/:id`.
///
/// [onAddTask] creates a new task for the goal (the integrator wires it to
/// the task sheet with `goalId` preset); the "New task" button is hidden
/// while it is null. "Link a task" works on its own.
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId, this.onAddTask});

  final String goalId;
  final void Function(BuildContext context, GoalRecord goal)? onAddTask;

  void _leave(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/goals');
    }
  }

  void _cheer(BuildContext context, GoalRecord goal, GoalMilestone? m) {
    if (!context.mounted) return;
    showPipToast(
      context,
      m == null ? GoalsStrings.counted : GoalsStrings.milestone(m, goal.title),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalByIdProvider(goalId));
    final loading = ref.watch(goalsProvider).isLoading;

    Widget body;
    if (goal == null) {
      body = loading
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(
              title: GoalsStrings.notFound,
              body: '',
              actionLabel: GoalsStrings.backToGoals,
              onAction: () => context.go('/goals'),
            );
    } else {
      body = _content(context, ref, goal);
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
                      label: GoalsStrings.back,
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

  Widget _content(BuildContext context, WidgetRef ref, GoalRecord goal) {
    final progress = ref.watch(goalProgressProvider(goal.id));
    final linked = ref.watch(goalLinkedTasksProvider(goal.id));
    final actions = ref.read(goalActionsProvider);
    final area = GoalArea.resolve(goal.area);
    final color = area?.color ?? AppColors.violet;
    final metric = goal.finite;
    final manual = metric?.source == MetricSource.manual;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 32),
      children: [
        SectionLabel(GoalsStrings.horizon(goal.horizon)),
        const SizedBox(height: 4),
        Text(goal.title, style: AppText.display(size: 26, height: 1.1)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (area != null) GoalAreaChip(area: area, height: 28),
            Pill(
              label:
                  '${GoalsStrings.importanceLabel} '
                  '${GoalsStrings.importanceValue(goal.importance)}',
              height: 28,
            ),
            GoalStatusPill(goal: goal, progress: progress),
          ],
        ),
        const SizedBox(height: 16),
        StickerCard(
          child: metric == null
              ? Text(
                  GoalsStrings.noMetric,
                  style: AppText.body(color: AppColors.muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GoalProgressRing(
                          fraction: progress.fraction,
                          centerLabel: '${progress.percent}%',
                          color: color,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${progress.current} / ${progress.target}',
                                style: AppText.display(size: 28),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                progress.unit,
                                style: AppText.bold(color: AppColors.muted),
                              ),
                              if (!manual) ...[
                                const SizedBox(height: 6),
                                Text(
                                  GoalsStrings.linkedCountHint,
                                  style: AppText.body(
                                    size: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (manual) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: GoalsStrings.plusOneLabel(progress.unit),
                              child: PillButton(
                                label: GoalsStrings.plusOne,
                                icon: const Icon(Icons.add),
                                color: AppColors.mint,
                                display: true,
                                fontSize: 16,
                                onPressed: () async {
                                  final m = await actions.increment(goal);
                                  if (context.mounted) _cheer(context, goal, m);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PillButton(
                              label: GoalsStrings.editCount,
                              onPressed: () => _editCount(context, ref, goal),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        StickerCard(
          shadow: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                GoalsStrings.targetDateLabel,
                goal.targetDate == null
                    ? GoalsStrings.noTargetDate
                    : GoalsStrings.date(goal.targetDate!),
              ),
              if (goal.notes != null) ...[
                const SizedBox(height: 12),
                _field(GoalsStrings.notesLabel, goal.notes!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel(GoalsStrings.linkedTasks),
        const SizedBox(height: 8),
        if (linked.isEmpty)
          Text(
            GoalsStrings.noLinkedTasks,
            style: AppText.body(color: AppColors.muted),
          )
        else
          for (final t in linked) ...[
            _LinkedTaskRow(
              task: t,
              onToggle: () async {
                final m = await actions.toggleTask(goal, t, linked);
                if (m != null && context.mounted) _cheer(context, goal, m);
              },
              onUnlink: () => actions.linkTask(t, null),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: GoalsStrings.linkTask,
                icon: const Icon(Icons.link),
                onPressed: () => _pickTask(context, ref, goal),
              ),
            ),
            if (onAddTask != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: GoalsStrings.newTask,
                  icon: const Icon(Icons.add),
                  color: AppColors.sun,
                  onPressed: () => onAddTask!(context, goal),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        PillButton(
          label: goal.status == GoalStatus.done
              ? GoalsStrings.reopen
              : GoalsStrings.markDone,
          color: goal.status == GoalStatus.done
              ? AppColors.card
              : AppColors.violet,
          textColor: goal.status == GoalStatus.done
              ? AppColors.ink
              : Colors.white,
          display: true,
          fontSize: 16,
          onPressed: () async {
            final wasDone = goal.status == GoalStatus.done;
            await actions.setStatus(
              goal,
              wasDone ? GoalStatus.active : GoalStatus.done,
            );
            if (!wasDone && context.mounted) {
              _cheer(context, goal, GoalMilestone.completed);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: GoalsStrings.edit,
                onPressed: () => showGoalSheet(context, existing: goal),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: GoalsStrings.delete,
                color: AppColors.pink,
                onPressed: () => _confirmDelete(context, ref, goal),
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

  Future<void> _editCount(
    BuildContext context,
    WidgetRef ref,
    GoalRecord goal,
  ) async {
    final m = goal.finite;
    if (m == null) return;
    final count = await showStickerSheet<int>(
      context,
      (_) => _CountSheet(initial: m.current, unit: m.unit),
    );
    if (count == null || !context.mounted) return;
    final milestone = await ref.read(goalActionsProvider).setCount(goal, count);
    if (milestone != null && context.mounted) {
      _cheer(context, goal, milestone);
    }
  }

  Future<void> _pickTask(
    BuildContext context,
    WidgetRef ref,
    GoalRecord goal,
  ) async {
    final all = ref.read(tasksProvider).valueOrNull ?? const <Task>[];
    final candidates = all
        .where((t) => t.deletedAt == null && !t.isDone && t.goalId == null)
        .toList();
    final picked = await showStickerSheet<Task>(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(GoalsStrings.pickTask, style: AppText.display(size: 22)),
          const SizedBox(height: 12),
          if (candidates.isEmpty)
            Text(
              GoalsStrings.noTasksToLink,
              style: AppText.body(color: AppColors.muted),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final t in candidates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PillButton(
                        label: t.title,
                        shadow: 0,
                        onPressed: () => Navigator.of(ctx).pop(t),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(goalActionsProvider).linkTask(picked, goal.id);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GoalRecord goal,
  ) async {
    final ok = await showStickerSheet<bool>(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(GoalsStrings.deleteTitle, style: AppText.display(size: 22)),
          const SizedBox(height: 6),
          Text(
            GoalsStrings.deleteBody,
            style: AppText.body(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: GoalsStrings.keep,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: GoalsStrings.delete,
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
    await ref.read(goalActionsProvider).delete(goal);
    if (context.mounted) {
      showPipToast(context, GoalsStrings.deleted);
      _leave(context);
    }
  }
}

class _LinkedTaskRow extends StatelessWidget {
  const _LinkedTaskRow({
    required this.task,
    required this.onToggle,
    required this.onUnlink,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    return StickerCard(
      shadow: 0,
      radius: AppRadii.row,
      color: done ? AppColors.lilac : AppColors.card,
      padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            checked: done,
            label: task.title,
            excludeSemantics: true,
            onTap: onToggle,
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.mint : AppColors.card,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppStroke.borderThin,
                      ),
                    ),
                    child: done
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.ink,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.bold().copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '${GoalsStrings.unlink} ${task.title}',
            excludeSemantics: true,
            onTap: onUnlink,
            child: GestureDetector(
              onTap: onUnlink,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.square(
                dimension: 44,
                child: Icon(Icons.link_off, size: 20, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountSheet extends StatefulWidget {
  const _CountSheet({required this.initial, required this.unit});

  final int initial;
  final String unit;

  @override
  State<_CountSheet> createState() => _CountSheetState();
}

class _CountSheetState extends State<_CountSheet> {
  late final TextEditingController _c = TextEditingController(
    text: '${widget.initial}',
  );
  bool _invalid = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    final v = int.tryParse(_c.text.trim());
    if (v == null || v < 0) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(GoalsStrings.editCount, style: AppText.display(size: 22)),
      const SizedBox(height: 12),
      StickerTextField(
        controller: _c,
        autofocus: true,
        label: widget.unit.isEmpty
            ? GoalsStrings.countLabel
            : '${GoalsStrings.countLabel} (${widget.unit})',
        errorText: _invalid ? GoalsStrings.countInvalid : null,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: PillButton(
              label: GoalsStrings.cancel,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PillButton(
              label: GoalsStrings.save,
              color: AppColors.violet,
              textColor: Colors.white,
              onPressed: _save,
            ),
          ),
        ],
      ),
    ],
  );
}
