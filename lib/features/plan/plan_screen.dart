import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../today/today_providers.dart' show formatClock;
import 'plan_providers.dart';

import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';

const _hourHeight = 48.0;
const _startHour = 8;
const _endHour = 18;

enum _Kind { deep, light, mint, lunch }

class _Block {
  const _Block(
    this.id,
    this.title,
    this.time,
    this.start,
    this.end,
    this.kind, {
    this.focus = false,
    this.done = false,
  });

  factory _Block.fromTask(Task t) {
    final kind = switch (t.category) {
      'break' => _Kind.lunch,
      'light' => _Kind.light,
      'move' => _Kind.mint,
      _ => _Kind.deep,
    };
    final s = t.scheduledStart!.toLocal();
    final e = t.scheduledEnd!.toLocal();
    return _Block(
      t.id,
      t.title,
      kind == _Kind.lunch
          ? formatClock(s)
          : '${formatClock(s)}\u2013${formatClock(e)}',
      s.hour + s.minute / 60,
      e.hour + e.minute / 60,
      kind,
      focus: t.priority == 1,
      done: t.isDone,
    );
  }

  final String id, title, time;
  final double start, end;
  final _Kind kind;
  final bool focus, done;
}

class _Event {
  const _Event(this.title, this.time, this.start, this.end);

  factory _Event.fromCalendar(CalendarEvent e) {
    final s = e.start.toLocal();
    final end = e.end.toLocal();
    return _Event(
      e.title,
      '${formatClock(s)}\u2013${formatClock(end)}',
      s.hour + s.minute / 60,
      end.hour + end.minute / 60,
    );
  }

  final String title, time;
  final double start, end;
}

/// Productive layer: the day drafted by Pip around calendar events.
///
/// [onStartFocus] and [onAdd] default to navigating with go_router.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key, this.onStartFocus, this.onAdd});

  final VoidCallback? onStartFocus;
  final VoidCallback? onAdd;

  void _startFocus(BuildContext context) =>
      (onStartFocus ?? () => context.go('/focus'))();
  void _add(BuildContext context) => (onAdd ?? () => context.go('/ask'))();

  Future<void> _toggle(WidgetRef ref, String id) async {
    final repo = ref.read(taskRepositoryProvider);
    final t = await repo.getById(id);
    if (t == null) return;
    final now = ref.read(clockProvider).now().toUtc();
    await repo.upsert(
      t.copyWith(
        status: t.isDone ? TaskStatus.open : TaskStatus.done,
        completedAt: t.isDone ? null : now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = [
      for (final t
          in ref.watch(planTasksProvider).valueOrNull ?? const <Task>[])
        _Block.fromTask(t),
    ];
    final events = [
      for (final e
          in ref.watch(planEventsProvider).valueOrNull ??
              const <CalendarEvent>[])
        _Event.fromCalendar(e),
    ];
    final doneCount = blocks.where((b) => b.done).length;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(20, 18 + top, 20, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Pill(
                    label: ref.watch(planDayLabelProvider),
                    height: 30,
                    fontSize: 13,
                    border: AppStroke.border,
                    icon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Pill(
                    label: '$doneCount of ${blocks.length} done',
                    color: AppColors.mint,
                    height: 30,
                    fontSize: 13,
                    shadow: 2,
                    border: AppStroke.border,
                    icon: const Icon(Icons.check),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your day, drafted',
                        style: AppText.display(letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pip arranged ${blocks.length} tasks around ${events.length} classes. Drag to tweak.',
                        style: AppText.body(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const PipAvatar(size: 48),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                SectionLabel('Energy'),
                Pill(
                  label: 'Deep focus',
                  color: AppColors.violet,
                  textColor: Colors.white,
                  height: 24,
                  icon: Icon(Icons.bolt),
                ),
                Pill(
                  label: 'Light',
                  color: AppColors.sky,
                  height: 24,
                  icon: Icon(Icons.cloud_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: (_endHour - _startHour) * _hourHeight + 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var h = _startHour; h <= _endHour; h++) ...[
                    Positioned(
                      left: 0,
                      top: (h - _startHour) * _hourHeight - 7,
                      child: Text(
                        '${h.toString().padLeft(2, '0')}:00',
                        style: AppText.bold(
                          size: 11,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      right: 0,
                      top: (h - _startHour) * _hourHeight,
                      child: const Divider(
                        height: 1.5,
                        thickness: 1.5,
                        color: AppColors.rule,
                      ),
                    ),
                  ],
                  for (final e in events) _eventCard(e),
                  for (final b in blocks) _blockCard(context, ref, b),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F5F2FF), AppColors.ground],
                stops: [0, 0.4],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'Re-plan with Pip',
                    color: AppColors.violet,
                    textColor: Colors.white,
                    height: 52,
                    shadow: 4,
                    fontSize: 17,
                    display: true,
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                PillButton(
                  label: 'Add task',
                  color: AppColors.sun,
                  height: 52,
                  shadow: 4,
                  fontSize: 15,
                  icon: const Icon(Icons.add),
                  onPressed: () => _add(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventCard(_Event e) {
    return Positioned(
      left: 44,
      right: 4,
      top: (e.start - _startHour) * _hourHeight + 2,
      height: (e.end - e.start) * _hourHeight - 4,
      child: StickerCard(
        dashed: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.ground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppStroke.borderThin,
                ),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM CALENDAR', style: AppText.label(size: 11)),
                  Text(
                    e.title,
                    style: AppText.bold(size: 14, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    e.time,
                    style: AppText.body(
                      size: 12,
                      color: AppColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockCard(BuildContext context, WidgetRef ref, _Block b) {
    final done = b.done;
    final top = (b.start - _startHour) * _hourHeight;
    final height = (b.end - b.start) * _hourHeight;
    final bg = switch (b.kind) {
      _Kind.deep => AppColors.violet,
      _Kind.light => AppColors.sky,
      _Kind.mint => AppColors.mint,
      _Kind.lunch => AppColors.pink,
    };
    final fg = b.kind == _Kind.deep ? Colors.white : AppColors.ink;
    final deco = done ? TextDecoration.lineThrough : null;

    void toggle() => _toggle(ref, b.id);

    if (b.kind == _Kind.lunch) {
      return Positioned(
        left: 44,
        top: top - 11,
        child: GestureDetector(
          onTap: toggle,
          child: Container(
            height: 24,
            padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.borderThin,
              ),
              boxShadow: AppShadows.hard(2),
            ),
            child: Row(
              children: [
                _circle(14, done, fg, AppColors.card),
                const SizedBox(width: 6),
                Text(
                  b.title,
                  style: AppText.bold(
                    size: 12,
                    height: 1,
                  ).copyWith(decoration: deco),
                ),
                const SizedBox(width: 6),
                Text(
                  b.time,
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w500,
                    height: 1,
                  ).copyWith(decoration: deco),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tall = height >= 60;
    return Positioned(
      left: 44,
      right: 4,
      top: top + 2,
      height: height - 4,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            tall ? AppRadii.card : AppRadii.cardSmall,
          ),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
          boxShadow: AppShadows.hard(tall ? 4 : 3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                checked: done,
                label: '${b.title}, ${b.time}',
                child: GestureDetector(
                  onTap: toggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _circle(
                          20,
                          done,
                          fg,
                          b.kind == _Kind.deep ? AppColors.sun : AppColors.card,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: tall
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppText.bold(
                                            size: 14,
                                            color: fg,
                                            height: 1.2,
                                          ).copyWith(
                                            decoration: deco,
                                            decorationColor: fg,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      b.time,
                                      style:
                                          AppText.body(
                                            size: 12,
                                            weight: FontWeight.w500,
                                            color: fg,
                                            height: 1.2,
                                          ).copyWith(
                                            decoration: deco,
                                            decorationColor: fg,
                                          ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            AppText.bold(
                                              size: 14,
                                              color: fg,
                                              height: 1.2,
                                            ).copyWith(
                                              decoration: deco,
                                              decorationColor: fg,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      b.time,
                                      style:
                                          AppText.body(
                                            size: 12,
                                            weight: FontWeight.w500,
                                            color: fg,
                                            height: 1.2,
                                          ).copyWith(
                                            decoration: deco,
                                            decorationColor: fg,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (b.focus)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillButton(
                  label: 'Start focus',
                  color: AppColors.sun,
                  shadow: 3,
                  fontSize: 13,
                  horizontalPadding: 12,
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _startFocus(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, bool done, Color fg, Color doneFill) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? doneFill : Colors.transparent,
        border: Border.all(color: done ? AppColors.ink : fg, width: 2),
      ),
      child: done
          ? Icon(Icons.check, size: size * 0.6, color: AppColors.ink)
          : null,
    );
  }
}
