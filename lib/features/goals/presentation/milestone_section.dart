import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/core.dart';
import '../../../core/util/duration_input.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/widgets.dart';
import '../../tasks/day_bounds.dart' show zoneLocationProvider, zoneWall;
import '../domain/goal_record.dart';
import '../domain/milestone_plan.dart';
import '../goal_providers.dart';
import 'goal_l10n.dart';
import 'goal_widgets.dart';

/// The milestone block of the goal screen (#25): milestones reached,
/// the next one, the goal's next scheduled task, and one card per
/// milestone with its weekly tasks. A milestone whose date passed while
/// open shows as "Moved" with a new date one tap away; never as missed.
class GoalMilestoneSection extends ConsumerWidget {
  const GoalMilestoneSection({super.key, required this.goal});

  final GoalRecord goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final plan = ref.watch(goalMilestonePlanProvider(goal.id));
    final location = ref.watch(zoneLocationProvider);
    final next = plan.next;
    final nextTask = plan.nextTask;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StickerCard(
          shadow: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(l.goalsNextTask),
              const SizedBox(height: 4),
              if (nextTask == null)
                Text(
                  l.goalsNextTaskNone,
                  style: AppText.body(color: AppColors.muted),
                )
              else ...[
                Text(
                  nextTask.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bold(),
                ),
                const SizedBox(height: 2),
                Text(
                  _when(context, nextTask.scheduledStart!, location),
                  style: AppText.body(size: 13, color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(l.goalsMilestones),
        const SizedBox(height: 8),
        if (plan.total == 0)
          Text(
            l.goalsMilestonesEmpty,
            style: AppText.body(color: AppColors.muted),
          )
        else ...[
          StickerCard(
            shadow: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.goalsMilestonesProgress(plan.done, plan.total),
                  style: AppText.bold(),
                ),
                const SizedBox(height: 8),
                MomentumMeter(
                  value: plan.fraction,
                  height: 14,
                  segments: const [AppColors.mint],
                  semanticLabel: l.goalsMilestones,
                ),
                if (next != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    next.milestone.dueAt == null
                        ? l.goalsMilestoneNextNoDate(next.milestone.title)
                        : l.goalsMilestoneNextLine(
                            next.milestone.title,
                            milestoneDate(
                              l,
                              next.suggestedDueAt ?? next.milestone.dueAt!,
                              location,
                            ),
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 14, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final (i, v) in plan.items.indexed) ...[
            _MilestoneCard(
              goal: goal,
              view: v,
              location: location,
              canMoveUp: i > 0,
              canMoveDown: i < plan.items.length - 1,
            ),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 4),
        PillButton(
          label: l.goalsMilestoneAdd,
          icon: const Icon(Icons.flag_outlined),
          onPressed: () => showMilestoneSheet(context, goalId: goal.id),
        ),
      ],
    );
  }

  String _when(BuildContext context, DateTime start, tz.Location location) {
    final wall = zoneWall(start, location);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(wall));
    return context.l10n.goalsNextTaskWhen(context.l10n.goalDay(wall), time);
  }
}

/// "Dec 31" for a stored milestone date, in the user's zone.
String milestoneDate(AppLocalizations l, DateTime utc, tz.Location location) =>
    l.goalDay(zoneWall(utc, location));

class _MilestoneCard extends ConsumerWidget {
  const _MilestoneCard({
    required this.goal,
    required this.view,
    required this.location,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  final GoalRecord goal;
  final MilestoneView view;
  final tz.Location location;
  final bool canMoveUp;
  final bool canMoveDown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final m = view.milestone;
    final done = m.isDone;
    final actions = ref.read(milestoneActionsProvider);
    final suggested = view.suggestedDueAt;
    final sub = [
      if (view.moved)
        l.goalsMilestoneMoved
      else if (m.dueAt != null)
        l.goalsByDate(milestoneDate(l, m.dueAt!, location))
      else
        l.goalsMilestoneNoDate,
      if (view.tasks.isNotEmpty)
        l.goalsMilestoneTasksCount(view.tasksDone, view.tasks.length),
    ].join(' · ');

    return StickerCard(
      shadow: 0,
      radius: AppRadii.row,
      color: done ? AppColors.lilac : AppColors.card,
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CheckDot(
                checked: done,
                label: m.title,
                onTap: () async {
                  final next = await actions.toggleDone(m);
                  if (next.isDone && context.mounted) {
                    showPipToast(
                      context,
                      context.l10n.goalsMilestoneReachedToast(m.title),
                    );
                  }
                },
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: '${l.goalsMilestoneOptions}: ${m.title}',
                  excludeSemantics: true,
                  onTap: () => showMilestoneSheet(
                    context,
                    goalId: m.goalId,
                    existing: m,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showMilestoneSheet(
                      context,
                      goalId: m.goalId,
                      existing: m,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bold().copyWith(
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _IconTap(
                icon: Icons.keyboard_arrow_up,
                label: '${l.goalsMilestoneMoveUp}: ${m.title}',
                onTap: canMoveUp ? () => actions.reorder(m, -1) : null,
              ),
              _IconTap(
                icon: Icons.keyboard_arrow_down,
                label: '${l.goalsMilestoneMoveDown}: ${m.title}',
                onTap: canMoveDown ? () => actions.reorder(m, 1) : null,
              ),
            ],
          ),
          if (suggested != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 4),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: AppColors.sun.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppStroke.borderThin,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.goalsMilestoneMovedBody(
                        milestoneDate(l, suggested, location),
                      ),
                      style: AppText.body(size: 14),
                    ),
                    const SizedBox(height: 8),
                    PillButton(
                      label: l.goalsMilestoneMoveAccept(
                        milestoneDate(l, suggested, location),
                      ),
                      icon: const Icon(Icons.event_available_outlined),
                      color: AppColors.sun,
                      shadow: 0,
                      onPressed: () async {
                        await actions.acceptMove(m);
                        if (context.mounted) {
                          showPipToast(
                            context,
                            context.l10n.goalsMilestoneMovedToast(
                              milestoneDate(context.l10n, suggested, location),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          for (final t in view.tasks)
            _MilestoneTaskRow(
              task: t,
              // Through the goal actions, so a linked-tasks metric and the
              // goal's last progress move too.
              onToggle: () => ref
                  .read(goalActionsProvider)
                  .toggleTask(
                    goal,
                    t,
                    ref.read(goalLinkedTasksProvider(goal.id)),
                  ),
              onUnlink: () => actions.unlinkTask(t),
            ),
          if (!done)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: PillButton(
                  label: l.goalsMilestoneAddTask,
                  icon: const Icon(Icons.add),
                  shadow: 0,
                  fontSize: 13,
                  onPressed: () => showMilestoneTaskSheet(context, m),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneTaskRow extends StatelessWidget {
  const _MilestoneTaskRow({
    required this.task,
    required this.onToggle,
    required this.onUnlink,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 20),
    child: Row(
      children: [
        _CheckDot(
          checked: task.isDone,
          label: task.title,
          size: 20,
          onTap: onToggle,
        ),
        Expanded(
          child: Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 14).copyWith(
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        _IconTap(
          icon: Icons.link_off,
          label: '${context.l10n.goalsUnlink} ${task.title}',
          onTap: onUnlink,
          size: 18,
        ),
      ],
    ),
  );
}

/// A round 44 px check target.
class _CheckDot extends StatelessWidget {
  const _CheckDot({
    required this.checked,
    required this.label,
    required this.onTap,
    this.size = 24,
  });

  final bool checked;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: checked,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? AppColors.mint : AppColors.card,
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.borderThin,
              ),
            ),
            child: checked
                ? Icon(Icons.check, size: size * 0.66, color: AppColors.ink)
                : null,
          ),
        ),
      ),
    ),
  );
}

class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 22,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.square(
        dimension: 44,
        child: Icon(
          icon,
          size: size,
          color: onTap == null ? AppColors.rule : AppColors.muted,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- sheets

/// The new-milestone sheet, or the edit sheet (with delete) for [existing].
Future<void> showMilestoneSheet(
  BuildContext context, {
  required String goalId,
  Milestone? existing,
}) async {
  final toast = await showStickerSheet<String>(
    context,
    (_) => MilestoneFormSheet(goalId: goalId, existing: existing),
  );
  if (toast != null && context.mounted) showPipToast(context, toast);
}

class MilestoneFormSheet extends ConsumerStatefulWidget {
  const MilestoneFormSheet({super.key, required this.goalId, this.existing});

  final String goalId;
  final Milestone? existing;

  @override
  ConsumerState<MilestoneFormSheet> createState() => _MilestoneFormState();
}

class _MilestoneFormState extends ConsumerState<MilestoneFormSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );

  /// The picked calendar date (y/m/d only), in the user's zone.
  DateTime? _date;
  bool _showErrors = false;
  bool _confirmDelete = false;

  @override
  void initState() {
    super.initState();
    final due = widget.existing?.dueAt;
    if (due != null) {
      final w = zoneWall(due, ref.read(zoneLocationProvider));
      _date = DateTime(w.year, w.month, w.day);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _titleMissing => _title.text.trim().isEmpty;

  Future<void> _save() async {
    setState(() => _showErrors = true);
    if (_titleMissing) return;
    final actions = ref.read(milestoneActionsProvider);
    final d = _date;
    final dueAt = d == null
        ? null
        : endOfLocalDay(d, ref.read(zoneLocationProvider));
    final existing = widget.existing;
    if (existing == null) {
      await actions.add(
        goalId: widget.goalId,
        title: _title.text.trim(),
        dueAt: dueAt,
      );
    } else {
      await actions.edit(existing, title: _title.text.trim(), dueAt: dueAt);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final message = context.l10n.goalsMilestoneDeleted;
    await ref.read(milestoneActionsProvider).delete(existing);
    if (mounted) Navigator.of(context).pop(message);
  }

  Future<void> _pickDate() async {
    final now = zoneWall(
      ref.read(clockProvider).now(),
      ref.read(zoneLocationProvider),
    );
    final today = DateTime(now.year, now.month, now.day);
    final base = _date ?? today;
    final picked = await showStickerDatePicker(
      context,
      initialDate: base,
      firstDate: base.isBefore(today) ? base : today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final editing = widget.existing != null;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? l.goalsMilestoneEdit : l.goalsMilestoneNew,
            style: AppText.display(size: 22),
          ),
          const SizedBox(height: 12),
          StickerTextField(
            controller: _title,
            autofocus: !editing,
            label: l.goalsMilestoneTitleLabel,
            hint: l.goalsMilestoneTitleHint,
            errorText: _showErrors && _titleMissing
                ? l.goalsMilestoneTitleRequired
                : null,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 14),
          SectionLabel(l.goalsMilestoneDateLabel),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoicePill(
                label: _date == null ? l.tasksPickDate : l.goalDay(_date!),
                icon: Icons.calendar_today_outlined,
                selected: _date != null,
                onTap: _pickDate,
              ),
              if (_date != null)
                ChoicePill(
                  label: l.commonClear,
                  icon: Icons.close,
                  selected: false,
                  onTap: () => setState(() => _date = null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_confirmDelete) ...[
            Text(l.goalsMilestoneDeleteTitle, style: AppText.bold()),
            const SizedBox(height: 2),
            Text(
              l.goalsMilestoneDeleteBody,
              style: AppText.body(size: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: l.goalsKeep,
                    onPressed: () => setState(() => _confirmDelete = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: l.commonDelete,
                    color: AppColors.pink,
                    onPressed: _delete,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: l.commonCancel,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: l.commonSave,
                    color: AppColors.violet,
                    textColor: Colors.white,
                    display: true,
                    fontSize: 16,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
            if (editing) ...[
              const SizedBox(height: 10),
              PillButton(
                label: l.commonDelete,
                color: AppColors.pink,
                shadow: 0,
                onPressed: () => setState(() => _confirmDelete = true),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The "add a task for this milestone" sheet.
Future<void> showMilestoneTaskSheet(BuildContext context, Milestone m) async {
  final toast = await showStickerSheet<String>(
    context,
    (_) => MilestoneTaskSheet(milestone: m),
  );
  if (toast != null && context.mounted) showPipToast(context, toast);
}

class MilestoneTaskSheet extends ConsumerStatefulWidget {
  const MilestoneTaskSheet({super.key, required this.milestone});

  final Milestone milestone;

  @override
  ConsumerState<MilestoneTaskSheet> createState() => _MilestoneTaskState();
}

class _MilestoneTaskState extends ConsumerState<MilestoneTaskSheet> {
  static const _estimates = [15, 30, 60, 90];

  final _title = TextEditingController();
  MilestoneTaskWeek _week = MilestoneTaskWeek.thisWeek;
  int _minutes = 30;
  bool _showErrors = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _titleMissing => _title.text.trim().isEmpty;

  Future<void> _save() async {
    setState(() => _showErrors = true);
    if (_titleMissing) return;
    final message = context.l10n.goalsMilestoneTaskAdded;
    await ref
        .read(milestoneActionsProvider)
        .addTask(
          widget.milestone,
          title: _title.text.trim(),
          estimatedMinutes: _minutes,
          week: _week,
        );
    if (mounted) Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.goalsMilestoneTaskSheetTitle(widget.milestone.title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(size: 22),
          ),
          const SizedBox(height: 12),
          StickerTextField(
            controller: _title,
            autofocus: true,
            label: l.tasksTitleLabel,
            hint: l.goalsMilestoneTaskHint,
            errorText: _showErrors && _titleMissing
                ? l.goalsMilestoneTitleRequired
                : null,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 14),
          SectionLabel(l.goalsMilestoneWeekLabel),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              ChoicePill(
                label: l.goalsMilestoneThisWeek,
                selected: _week == MilestoneTaskWeek.thisWeek,
                onTap: () => setState(() => _week = MilestoneTaskWeek.thisWeek),
              ),
              ChoicePill(
                label: l.goalsMilestoneNextWeek,
                selected: _week == MilestoneTaskWeek.nextWeek,
                onTap: () => setState(() => _week = MilestoneTaskWeek.nextWeek),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionLabel(l.goalsMilestoneEstimateLabel),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final m in _estimates)
                ChoicePill(
                  label: formatDuration(m, l),
                  selected: _minutes == m,
                  onTap: () => setState(() => _minutes = m),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: l.commonCancel,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: l.commonSave,
                  color: AppColors.violet,
                  textColor: Colors.white,
                  display: true,
                  fontSize: 16,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
