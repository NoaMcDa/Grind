import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/pip_toast.dart';
import '../../widgets/sticker_date_time_picker.dart';
import '../calendar/sync/providers.dart';
import '../calendar/sync/sync_status.dart';
import '../tasks/day_bounds.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_form.dart';
import 'plan_l10n.dart';
import 'plan_providers.dart';
import 'plan_replan_sheet.dart';
import 'plan_scheduler.dart';
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

  /// Same as Today: on a recurring task, completes the current occurrence
  /// and the series continues.
  Future<void> _toggle(Task task) async {
    final t = await ref.read(taskRepositoryProvider).getById(task.id);
    if (t == null || !mounted) return;
    await ref.read(taskActionsProvider).toggle(context, t);
  }

  /// A manual placement: the sync engine writes it back to the calendars.
  /// [localStart] is wall-clock time in the user's zone.
  Future<void> _move(Task task, DateTime localStart) async {
    final repo = ref.read(taskRepositoryProvider);
    final t = await repo.getById(task.id);
    if (t == null || !t.isScheduled) return;
    final dur = t.scheduledEnd!.difference(t.scheduledStart!);
    final start = fromZoneWall(localStart, ref.read(zoneLocationProvider));
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

  bool _replanning = false;

  Future<void> _replan() async {
    if (_replanning) return;
    _replanning = true;
    try {
      await replanWithPip(context, ref, ref.read(selectedDayProvider));
    } finally {
      _replanning = false;
    }
  }

  /// The last sync error shown, so each error toasts once.
  String? _shownSyncError;

  void _onSyncStatus(SyncStatus? status) {
    if (status == null) return;
    if (!status.isError) {
      if (status.phase == SyncPhase.idle) _shownSyncError = null;
      return;
    }
    final message = status.message ?? '';
    if (message.isEmpty || message == _shownSyncError) return;
    _shownSyncError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showPipToast(context, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedDayProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    });
    ref.listen(
      syncStatusProvider,
      (_, next) => _onSyncStatus(next.valueOrNull),
    );
    final day = ref.watch(selectedDayProvider);
    final tasks = ref.watch(planTasksProvider);
    final events =
        ref.watch(planEventsProvider).valueOrNull ?? const <CalendarEvent>[];
    final prefs = ref.watch(planPrefsProvider);
    final clock = ref.watch(clockProvider);
    final isToday = ref.watch(planTodayProvider) == day;
    final now = isToday
        ? (ref.watch(planNowProvider).valueOrNull ?? clock.now())
        : null;
    final doneCount = tasks.where((t) => t.isDone).length;
    final l = context.l10n;
    final capacity = ref.watch(planCapacityMinutesProvider);
    final top = MediaQuery.paddingOf(context).top;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    Widget arrow(bool previous) {
      final left = previous != rtl;
      return Semantics(
        button: true,
        label: previous ? l.planPreviousDay : l.planNextDay,
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
                    label: l.planPickDay,
                    child: GestureDetector(
                      key: const Key('plan-date-pill'),
                      onTap: _pickDay,
                      behavior: HitTestBehavior.opaque,
                      child: Pill(
                        label: formatPlanDay(l, day),
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
                        isToday ? l.planDrafted : l.planYourDay,
                        style: AppText.display(letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.planSubtitle(tasks.length, events.length),
                        style: AppText.body(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planCapacityLine(
                          l,
                          freeMinutes: capacity.free,
                          plannedMinutes: capacity.planned,
                        ),
                        key: const Key('plan-capacity'),
                        style: AppText.bold(size: 13, color: AppColors.ink),
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
                SectionLabel(l.sectionEnergy),
                Pill(
                  label: l.energyDeep,
                  color: AppColors.violet,
                  textColor: Colors.white,
                  height: 24,
                  icon: const Icon(Icons.bolt),
                ),
                Pill(
                  label: l.energyLight,
                  color: AppColors.sky,
                  height: 24,
                  icon: const Icon(Icons.cloud_outlined),
                ),
                Pill(
                  label: l.doneOfTotal(doneCount, tasks.length),
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
              SizedBox(
                height: 320,
                child: EmptyState(
                  title: l.planEmptyTitle,
                  body: l.planEmptyBody,
                  pipSize: 80,
                ),
              )
            else
              PlanTimeline(
                day: day,
                tasks: tasks,
                events: events,
                prefs: prefs,
                location: ref.watch(zoneLocationProvider),
                now: now,
                nowKey: _nowKey,
                onToggle: _toggle,
                onOpenTask: (t) => PlanTaskDetailPage.open(context, t.id),
                onOpenEvent: (e) => showPlanEventSheet(context, e),
                onStartFocus: _startFocus,
                onMove: _move,
                onSwipe: _shift,
                onRejectedDrop: () => ScaffoldMessenger.maybeOf(
                  context,
                )?.showSnackBar(SnackBar(content: Text(l.planCantDropHere))),
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
                    key: const Key('plan-replan'),
                    label: l.rePlanWithPip,
                    color: AppColors.violet,
                    textColor: Colors.white,
                    height: 52,
                    shadow: 4,
                    fontSize: 17,
                    display: true,
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: _replan,
                  ),
                ),
                const SizedBox(width: 10),
                PillButton(
                  label: l.addTask,
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
