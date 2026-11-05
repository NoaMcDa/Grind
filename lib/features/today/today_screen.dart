import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../l10n/l10n.dart';
import '../goals/domain/goal_area.dart';
import '../goals/goal_providers.dart';
import '../goals/presentation/goals_link_card.dart';
import '../goals/presentation/goal_widgets.dart';
import '../plan/plan_l10n.dart';
import '../reminders/reminder_now_card.dart';
import '../review/review.dart';
import '../tasks/day_bounds.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_form.dart';
import 'plan_my_day_card.dart';
import 'today_providers.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/momentum_meter.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

/// Reminders layer: the if-then reminder of the moment, momentum, up next.
///
/// [onStartFocus] and [onAdd] default to navigating with go_router.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key, this.onStartFocus, this.onAdd});

  final VoidCallback? onStartFocus;
  final VoidCallback? onAdd;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// Null lets the reminder card navigate with go_router (`/focus?taskId=`).
  ValueChanged<String>? get _startFocus {
    final custom = widget.onStartFocus;
    return custom == null ? null : (_) => custom();
  }

  /// Row keys ([TodayItem.key]) swiped away; hidden at once so the
  /// Dismissible leaves the tree before the repository stream catches up.
  /// Keyed per row (not per task id) so a done occurrence row and its series
  /// agree on identity.
  final Set<String> _hidden = {};

  void _add() => (widget.onAdd ?? () => showTaskSheet(context))();

  void _openSettings() => GoRouter.maybeOf(context)?.push('/settings');

  void _open(Task t) {
    // go_router.push so #/task/<id> lands in the URL and browser Back
    // closes just the detail instead of also skipping over Today. See #213.
    context.push('/task/${t.id}');
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref
        .watch(todayTasksProvider)
        .where((i) => !_hidden.contains(i.key))
        .toList();
    final location = ref.watch(zoneLocationProvider);
    final doneCount = tasks.where((t) => t.isDone).length;
    final top = MediaQuery.paddingOf(context).top;
    final l = context.l10n;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(20, 28 + top, 20, 120),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(
                        formatTodayLabel(l, ref.watch(todayDateProvider)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        greetingFor(
                          l,
                          ref.watch(clockProvider).now(),
                          ref.watch(zoneLocationProvider),
                        ),
                        style: AppText.display(height: 1.05),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  label: l.settingsTitle,
                  excludeSemantics: true,
                  onTap: _openSettings,
                  child: GestureDetector(
                    key: const Key('today-settings'),
                    onTap: _openSettings,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.settings_outlined,
                        color: AppColors.ink,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const PipAvatar(size: 58),
              ],
            ),
            const SizedBox(height: 18),
            // Mornings only, while nothing is scheduled today yet.
            const PlanMyDayCard(),
            ReminderNowCard(onStartFocus: _startFocus),
            // Shows only after the evening prompt time, once per day.
            EveningReviewBanner(
              onTap: () => GoRouter.maybeOf(context)?.push('/review'),
            ),
            const SizedBox(height: 18),
            StickerCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionLabel(l.sectionMomentum),
                      Text(
                        l.tasksDoneOfToday(doneCount, tasks.length),
                        style: AppText.display(size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MomentumMeter(
                    value: tasks.isEmpty ? 0 : doneCount / tasks.length,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const GoalsLinkCard(),
            const SizedBox(height: 18),
            SectionLabel(l.upNext),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              EmptyState(
                title: l.tasksEmptyTitle,
                body: l.tasksEmptyBody,
                actionLabel: l.addATask,
                onAction: _add,
                pipSize: 72,
              ),
            for (final i in tasks) ...[
              _taskRow(i, location),
              const SizedBox(height: 10),
            ],
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Semantics(
            button: true,
            label: l.addATask,
            child: GestureDetector(
              onTap: _add,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.sun,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppStroke.border,
                  ),
                  boxShadow: AppShadows.hard(),
                ),
                child: const Icon(Icons.add, color: AppColors.ink, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _taskRow(TodayItem item, tz.Location location) {
    final l = context.l10n;
    final t = item.task;
    final done = item.isDone;
    final at = item.at;
    final tag = taskTagColor(t);
    final onViolet = tag == AppColors.violet;
    final actions = ref.read(taskActionsProvider);
    // A series row completes its own occurrence; the series continues.
    Future<void> toggle() =>
        actions.toggle(context, t, occurrenceAt: item.occurrence ? at : null);
    return Dismissible(
      key: ValueKey('task-${item.key}'),
      background: _swipeBackground(
        AppColors.mint,
        Icons.check,
        Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        AppColors.pink,
        Icons.delete_outline,
        Alignment.centerRight,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await toggle();
          return false;
        }
        return true;
      },
      onDismissed: (_) {
        final rowKey = item.key;
        setState(() => _hidden.add(rowKey));
        actions.deleteWithUndo(
          context,
          t,
          onUndo: () {
            if (mounted) setState(() => _hidden.remove(rowKey));
          },
        );
      },
      child: Semantics(
        button: true,
        checked: done,
        label: t.title,
        child: GestureDetector(
          onTap: () => _open(t),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: done ? AppColors.lilac : AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.row),
              border: Border.all(color: AppColors.ink, width: AppStroke.border),
              boxShadow: AppShadows.hard(3),
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: done
                      ? l.todayMarkOpen(t.title)
                      : l.todayComplete(t.title),
                  excludeSemantics: true,
                  onTap: toggle,
                  child: GestureDetector(
                    onTap: toggle,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: done ? tag : AppColors.card,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: AppColors.ink,
                              width: AppStroke.border,
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
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style:
                            AppText.bold(
                              size: 16,
                              color: done ? AppColors.muted : AppColors.ink,
                            ).copyWith(
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.firstAction ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 13, color: AppColors.muted),
                      ),
                      if (_areaFor(t) != null) ...[
                        const SizedBox(height: 6),
                        GoalAreaChip(
                          key: Key('task-goal-${t.id}'),
                          area: _areaFor(t)!,
                          height: 22,
                          onTap: () => GoRouter.maybeOf(
                            context,
                          )?.push('/goals/${t.goalId}'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (at != null)
                  Pill(
                    label: formatClock(at, location),
                    color: tag,
                    textColor: onViolet ? Colors.white : AppColors.ink,
                    fontSize: 13,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The task's goal area, if the task links to a goal that has one.
  /// Null for tasks without a goal or whose goal has no area set.
  GoalArea? _areaFor(Task t) {
    final goalId = t.goalId;
    if (goalId == null) return null;
    final goal = ref.watch(goalByIdProvider(goalId));
    if (goal == null) return null;
    return GoalArea.resolve(goal.area);
  }

  Widget _swipeBackground(Color color, IconData icon, Alignment align) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.row),
        border: Border.all(color: AppColors.ink, width: AppStroke.border),
      ),
      child: Icon(icon, color: AppColors.ink),
    );
  }
}

/// "Good morning!" before noon, then afternoon, then evening, by the clock
/// in [location] (device-local without one).
String greetingFor(AppLocalizations l, DateTime now, [tz.Location? location]) {
  final h = location == null
      ? now.toLocal().hour
      : tz.TZDateTime.from(now, location).hour;
  if (h >= 5 && h < 12) return l.goodMorning;
  if (h >= 12 && h < 18) return l.goodAfternoon;
  return l.goodEvening;
}
