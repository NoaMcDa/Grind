import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import 'today_providers.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/momentum_meter.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

enum _ReminderState { open, done, snoozed }

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
  _ReminderState _reminder = _ReminderState.open;

  void _startFocus() => (widget.onStartFocus ?? () => context.go('/focus'))();
  void _add() => (widget.onAdd ?? () => context.go('/ask'))();

  Future<void> _toggle(Task t) {
    final now = ref.read(clockProvider).now().toUtc();
    return ref
        .read(taskRepositoryProvider)
        .upsert(
          t.copyWith(
            status: t.isDone ? TaskStatus.open : TaskStatus.done,
            completedAt: t.isDone ? null : now,
            updatedAt: now,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(todayTasksProvider);
    final doneCount =
        tasks.where((t) => t.isDone).length +
        (_reminder == _ReminderState.done ? 1 : 0);
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
                        'Good morning!',
                        style: AppText.display(height: 1.05),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const PipAvatar(size: 58),
              ],
            ),
            const SizedBox(height: 18),
            _reminderCard(),
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
                        '$doneCount of 5 today',
                        style: AppText.display(size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MomentumMeter(value: doneCount / 5),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Up next'),
            const SizedBox(height: 10),
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

  Widget _reminderCard() {
    switch (_reminder) {
      case _ReminderState.open:
        return StickerCard(
          color: AppColors.violet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: AppColors.sun,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'REMINDER · NOW',
                    style: AppText.label(size: 12, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '7:00 — open the thesis file.',
                style: AppText.display(
                  size: 21,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '25 minutes is enough to start. Pip has the timer ready.',
                style: AppText.body(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: PillButton(
                      label: 'Done',
                      horizontalPadding: 8,
                      color: AppColors.sun,
                      onPressed: () =>
                          setState(() => _reminder = _ReminderState.done),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 10,
                    child: PillButton(
                      label: 'Snooze 15',
                      horizontalPadding: 8,
                      onPressed: () =>
                          setState(() => _reminder = _ReminderState.snoozed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 13,
                    child: PillButton(
                      label: 'Start focus',
                      color: AppColors.mint,
                      icon: const Icon(Icons.play_arrow),
                      horizontalPadding: 8,
                      onPressed: _startFocus,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case _ReminderState.done:
        return StickerCard(
          color: AppColors.sun,
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 40,
                color: AppColors.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nice start!', style: AppText.display(size: 20)),
                    Text(
                      'Pip is doing a little happy dance.',
                      style: AppText.body(size: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case _ReminderState.snoozed:
        return StickerCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('See you at 7:15', style: AppText.display(size: 20)),
                    Text(
                      'Snooze again and Pip will offer to move it instead.',
                      style: AppText.body(size: 14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PillButton(
                label: 'Undo',
                color: AppColors.ground,
                shadow: 0,
                onPressed: () =>
                    setState(() => _reminder = _ReminderState.open),
              ),
            ],
          ),
        );
    }
  }

  Widget _taskRow(Task t) {
    final done = t.isDone;
    final tag = taskTagColor(t);
    final onViolet = tag == AppColors.violet;
    return Semantics(
      button: true,
      checked: done,
      label: t.title,
      child: GestureDetector(
        onTap: () => _toggle(t),
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
              Container(
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
                    ? const Icon(Icons.check, size: 16, color: AppColors.ink)
                    : null,
              ),
              const SizedBox(width: 12),
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
    );
  }
}
