import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../reminders/reminder_now_card.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_form.dart';
import '../tasks/tasks_strings.dart';
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

  /// Ids swiped away; hidden at once so the Dismissible leaves the tree
  /// before the repository stream catches up.
  final Set<String> _hidden = {};

  void _add() => (widget.onAdd ?? () => showTaskSheet(context))();

  void _openSettings() => GoRouter.maybeOf(context)?.push('/settings');

  void _open(Task t) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(taskId: t.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref
        .watch(todayTasksProvider)
        .where((t) => !_hidden.contains(t.id))
        .toList();
    final doneCount = tasks.where((t) => t.isDone).length;
    final top = MediaQuery.paddingOf(context).top;
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
                      SectionLabel(ref.watch(todayLabelProvider)),
                      const SizedBox(height: 4),
                      Text(
                        greetingFor(ref.watch(clockProvider).now()),
                        style: AppText.display(height: 1.05),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  label: 'Settings',
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
            ReminderNowCard(onStartFocus: _startFocus),
            const SizedBox(height: 18),
            StickerCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionLabel('Momentum'),
                      Text(
                        TasksStrings.doneOf(doneCount, tasks.length),
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
            const SizedBox(height: 18),
            const SectionLabel('Up next'),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              EmptyState(
                title: TasksStrings.emptyTitle,
                body: TasksStrings.emptyBody,
                actionLabel: TasksStrings.emptyAction,
                onAction: _add,
                pipSize: 72,
              ),
            for (final t in tasks) ...[_taskRow(t), const SizedBox(height: 10)],
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Semantics(
            button: true,
            label: 'Add a task',
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

  Widget _taskRow(Task t) {
    final done = t.isDone;
    final tag = taskTagColor(t);
    final onViolet = tag == AppColors.violet;
    final actions = ref.read(taskActionsProvider);
    return Dismissible(
      key: ValueKey('task-${t.id}'),
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
          await actions.toggle(context, t);
          return false;
        }
        return true;
      },
      onDismissed: (_) {
        setState(() => _hidden.add(t.id));
        actions.deleteWithUndo(
          context,
          t,
          onUndo: () {
            if (mounted) setState(() => _hidden.remove(t.id));
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
                      ? 'Mark ${t.title} as open'
                      : 'Complete ${t.title}',
                  excludeSemantics: true,
                  onTap: () => actions.toggle(context, t),
                  child: GestureDetector(
                    onTap: () => actions.toggle(context, t),
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (t.remindAt != null)
                  Pill(
                    label: formatClock(t.remindAt!),
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

/// "Good morning!" before noon, then afternoon, then evening.
String greetingFor(DateTime now) {
  final h = now.toLocal().hour;
  if (h >= 5 && h < 12) return 'Good morning!';
  if (h >= 12 && h < 18) return 'Good afternoon!';
  return 'Good evening!';
}
