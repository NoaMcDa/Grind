import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_date_time_picker.dart';
import '../tasks/task_form.dart';
import 'plan_layout.dart';
import 'plan_providers.dart';
import 'plan_strings.dart';
import 'plan_task_sheet.dart';
import 'plan_timeline.dart';
import 'plan_week_strip.dart';

/// Productive layer: the day drafted by Pip around calendar events, for any
/// day, with a week strip and drag-to-reschedule.
///
/// [onStartFocus] and [onAdd] default to navigating with go_router.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key, this.onStartFocus, this.onAdd});

  final VoidCallback? onStartFocus;
  final VoidCallback? onAdd;

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _scroll = ScrollController();
  final _nowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    final ctx = _nowKey.currentContext;
    if (ctx == null || !mounted) return;
    Scrollable.ensureVisible(ctx, alignment: 0.4);
  }

  void _startFocus() => (widget.onStartFocus ?? () => context.go('/focus'))();
  void _add() => (widget.onAdd ?? () => showTaskSheet(context))();

  Future<void> _toggle(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    final t = await repo.getById(task.id);
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

  /// A manual placement: the sync engine writes it back to the calendars.
  Future<void> _move(Task task, DateTime localStart) async {
    final repo = ref.read(taskRepositoryProvider);
    final t = await repo.getById(task.id);
    if (t == null || !t.isScheduled) return;
    final dur = t.scheduledEnd!.difference(t.scheduledStart!);
    final start = localStart.toUtc();
    await repo.upsert(
      t.copyWith(
        scheduledStart: start,
        scheduledEnd: start.add(dur),
        lockedStart: true,
        updatedAt: ref.read(clockProvider).now().toUtc(),
      ),
    );
  }

  Future<void> _pickDay() async {
    final selected = ref.read(selectedDayProvider);
    final picked = await showStickerDatePicker(
      context,
      initialDate: selected,
      firstDate: DateTime(selected.year - 1),
      lastDate: DateTime(selected.year + 2),
    );
    if (picked != null) ref.read(selectedDayProvider.notifier).select(picked);
  }

  void _shift(int days) => ref.read(selectedDayProvider.notifier).shift(days);

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedDayProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    });
    final day = ref.watch(selectedDayProvider);
    final tasks = ref.watch(planTasksProvider);
    final events =
        ref.watch(planEventsProvider).valueOrNull ?? const <CalendarEvent>[];
    final prefs = ref.watch(planPrefsProvider);
    final clock = ref.watch(clockProvider);
    final isToday = dateOnly(clock.now()) == day;
    final now = isToday
        ? (ref.watch(planNowProvider).valueOrNull ?? clock.now())
        : null;
    final doneCount = tasks.where((t) => t.isDone).length;
    final top = MediaQuery.paddingOf(context).top;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    Widget arrow(bool previous) {
      final left = previous != rtl;
      return Semantics(
        button: true,
        label: previous ? PlanStrings.previousDay : PlanStrings.nextDay,
        excludeSemantics: true,
        onTap: () => _shift(previous ? -1 : 1),
        child: GestureDetector(
          key: Key(previous ? 'plan-prev-day' : 'plan-next-day'),
          onTap: () => _shift(previous ? -1 : 1),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              left ? Icons.chevron_left : Icons.chevron_right,
              color: AppColors.ink,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(20, 18 + top, 20, 90),
          children: [
            Row(
              children: [
                arrow(true),
                Flexible(
                  child: Semantics(
                    button: true,
                    label: PlanStrings.pickDay,
                    child: GestureDetector(
                      key: const Key('plan-date-pill'),
                      onTap: _pickDay,
                      behavior: HitTestBehavior.opaque,
                      child: Pill(
                        label: ref.watch(planDayLabelProvider),
                        height: 30,
                        fontSize: 13,
                        border: AppStroke.border,
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ),
                arrow(false),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday
                            ? PlanStrings.titleToday
                            : PlanStrings.titleOtherDay,
                        style: AppText.display(letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        PlanStrings.subtitle(tasks.length, events.length),
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
            const SizedBox(height: 12),
            const PlanWeekStrip(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const SectionLabel('Energy'),
                const Pill(
                  label: 'Deep focus',
                  color: AppColors.violet,
                  textColor: Colors.white,
                  height: 24,
                  icon: Icon(Icons.bolt),
                ),
                const Pill(
                  label: 'Light',
                  color: AppColors.sky,
                  height: 24,
                  icon: Icon(Icons.cloud_outlined),
                ),
                Pill(
                  label: PlanStrings.doneCount(doneCount, tasks.length),
                  color: AppColors.mint,
                  height: 24,
                  fontSize: 12,
                  shadow: 2,
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (tasks.isEmpty && events.isEmpty)
              const SizedBox(
                height: 320,
                child: EmptyState(
                  title: PlanStrings.emptyTitle,
                  body: PlanStrings.emptyBody,
                  pipSize: 80,
                ),
              )
            else
              PlanTimeline(
                day: day,
                tasks: tasks,
                events: events,
                prefs: prefs,
                now: now,
                nowKey: _nowKey,
                onToggle: _toggle,
                onOpenTask: (t) => PlanTaskDetailPage.open(context, t.id),
                onOpenEvent: (e) => showPlanEventSheet(context, e),
                onStartFocus: _startFocus,
                onMove: _move,
                onSwipe: _shift,
                onRejectedDrop: () =>
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text(PlanStrings.cantDropHere)),
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
                    // Wired to the scheduler in wave 3.
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
                  onPressed: _add,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
