import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/widgets.dart';
import '../../companion/celebration_bus.dart' show CelebrationHost;
import '../domain/goal_area.dart';
import '../domain/goal_metric.dart';
import '../domain/goal_progress.dart';
import '../domain/goal_record.dart';
import '../goal_providers.dart';
import '../../../l10n/l10n.dart';
import 'goal_l10n.dart';
import 'goal_form.dart';
import 'goal_widgets.dart';
import 'metric_trend.dart';
import 'milestone_section.dart';

/// One goal: metric ring with +1 / edit count, details, linked tasks, the
/// next scheduled task and milestones with their weekly tasks (#25).
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
    // In the app the CelebrationHost cheers for a quota hit or a completed
    // goal (confetti + praise line, via goalMilestoneEventsProvider); a
    // second toast would queue behind it.
    if ((m == GoalMilestone.metricHit || m == GoalMilestone.completed) &&
        CelebrationHost.isPresent(context)) {
      return;
    }
    showPipToast(
      context,
      m == null
          ? context.l10n.goalsCounted
          : context.l10n.goalMilestone(m, goal.title),
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
              title: context.l10n.goalsNotFound,
              body: '',
              actionLabel: context.l10n.goalsBackToGoals,
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
                      label: context.l10n.commonBack,
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
    // Milestone tasks show under their milestone, not twice.
    final plan = ref.watch(goalMilestonePlanProvider(goal.id));
    final underMilestones = {
      for (final v in plan.items)
        for (final t in v.tasks) t.id,
    };
    final shown = [
      for (final t in linked)
        if (!underMilestones.contains(t.id)) t,
    ];
    final actions = ref.read(goalActionsProvider);
    final area = GoalArea.resolve(goal.area);
    final color = area?.color ?? AppColors.violet;
    final metric = goal.finite;
    final manual = metric?.source == MetricSource.manual;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 32),
      children: [
        SectionLabel(context.l10n.goalHorizon(goal.horizon)),
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
                  '${context.l10n.goalsImportanceLabel} '
                  '${context.l10n.goalsImportanceValue(goal.importance)}',
              height: 28,
            ),
            GoalStatusPill(goal: goal, progress: progress),
          ],
        ),
        const SizedBox(height: 16),
        if (goal.recurring case final rec?)
          ..._recurring(context, ref, goal, rec, progress, color)
        else
          StickerCard(
            child: metric == null
                ? Text(
                    context.l10n.goalsNoMetric,
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
                                    context.l10n.goalsLinkedCountHint,
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
                                label: context.l10n.goalAddOne(progress.unit),
                                child: PillButton(
                                  label: '+1',
                                  icon: const Icon(Icons.add),
                                  color: AppColors.mint,
                                  display: true,
                                  fontSize: 16,
                                  onPressed: () async {
                                    final m = await actions.increment(goal);
                                    if (context.mounted) {
                                      _cheer(context, goal, m);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PillButton(
                                label: context.l10n.goalsEditCount,
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
                context.l10n.goalsTargetDateLabel,
                goal.targetDate == null
                    ? context.l10n.goalsNoTargetDate
                    : context.l10n.goalDate(goal.targetDate!),
              ),
              if (goal.notes != null) ...[
                const SizedBox(height: 12),
                _field(context.l10n.tasksNotesLabel, goal.notes!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(context.l10n.goalsLinkedTasks),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Text(
            context.l10n.goalsNoLinkedTasks,
            style: AppText.body(color: AppColors.muted),
          )
        else
          for (final t in shown) ...[
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
                label: context.l10n.goalsLinkTask,
                icon: const Icon(Icons.link),
                onPressed: () => _pickTask(context, ref, goal),
              ),
            ),
            if (onAddTask != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: context.l10n.tasksNewTask,
                  icon: const Icon(Icons.add),
                  color: AppColors.sun,
                  onPressed: () => onAddTask!(context, goal),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        GoalMilestoneSection(goal: goal),
        const SizedBox(height: 24),
        PillButton(
          label: goal.status == GoalStatus.done
              ? context.l10n.goalsReopen
              : context.l10n.goalsMarkDone,
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
                label: context.l10n.edit,
                onPressed: () => showGoalSheet(context, existing: goal),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: context.l10n.commonDelete,
                color: AppColors.pink,
                onPressed: () => _confirmDelete(context, ref, goal),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _recurring(
    BuildContext context,
    WidgetRef ref,
    GoalRecord goal,
    RecurringMetric metric,
    GoalProgress progress,
    Color color,
  ) {
    final l = context.l10n;
    final actions = ref.read(goalActionsProvider);
    final history = ref.watch(goalHistoryProvider(goal.id));
    final tracked = history.where((p) => p.tracked).length;
    final hit = history.where((p) => p.hit).length;
    return [
      StickerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GoalProgressRing(
                  fraction: progress.fraction,
                  centerLabel: '${progress.current}/${progress.target}',
                  color: color,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.goalPeriodLine(
                          progress.current,
                          progress.target,
                          progress.unit,
                          metric.period,
                        ),
                        style: AppText.display(size: 20, height: 1.15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.goalsRecurringCountHint,
                        style: AppText.body(size: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: l.goalAddOne(progress.unit),
                    child: PillButton(
                      label: '+1',
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
                    label: l.goalsUndoTick,
                    onPressed: () async {
                      final ok = await actions.undoTick(goal);
                      if (ok && context.mounted) {
                        showPipToast(context, context.l10n.goalsTickUndone);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      StickerCard(
        shadow: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(l.goalTrendTitle(metric.period)),
            const SizedBox(height: 10),
            MetricTrend(history: history),
            const SizedBox(height: 10),
            Text(
              l.goalsTrendSummary(hit, tracked),
              style: AppText.bold(size: 14),
            ),
            const SizedBox(height: 2),
            Text(
              l.goalsTrendQuietNote,
              style: AppText.body(size: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ];
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
          Text(context.l10n.goalsPickTask, style: AppText.display(size: 22)),
          const SizedBox(height: 12),
          if (candidates.isEmpty)
            Text(
              context.l10n.goalsNoTasksToLink,
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
          Text(context.l10n.goalsDeleteTitle, style: AppText.display(size: 22)),
          const SizedBox(height: 6),
          Text(
            context.l10n.goalsDeleteBody,
            style: AppText.body(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: context.l10n.goalsKeep,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: context.l10n.commonDelete,
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
      showPipToast(context, context.l10n.goalsDeleted);
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
            label: '${context.l10n.goalsUnlink} ${task.title}',
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
      Text(context.l10n.goalsEditCount, style: AppText.display(size: 22)),
      const SizedBox(height: 12),
      StickerTextField(
        controller: _c,
        autofocus: true,
        label: widget.unit.isEmpty
            ? context.l10n.goalsCountLabel
            : '${context.l10n.goalsCountLabel} (${widget.unit})',
        errorText: _invalid ? context.l10n.goalsCountInvalid : null,
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
              label: context.l10n.commonCancel,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PillButton(
              label: context.l10n.commonSave,
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
