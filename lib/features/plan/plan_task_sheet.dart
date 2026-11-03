import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_toast.dart';
import '../../widgets/sticker_bottom_sheet.dart';
import '../../widgets/sticker_card.dart';
import '../tasks/task_detail_screen.dart';
import '../today/today_providers.dart' show formatClock;
import 'plan_replan_sheet.dart';
import 'plan_strings.dart';

String _range(DateTime s, DateTime e) => '${formatClock(s)}–${formatClock(e)}';

/// Lightweight task detail opened from the Plan timeline: done, schedule,
/// unschedule, and a link to the full [TaskDetailScreen].
class PlanTaskDetailPage extends ConsumerWidget {
  const PlanTaskDetailPage({super.key, required this.taskId});

  final String taskId;

  static Future<void> open(BuildContext context, String taskId) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanTaskDetailPage(taskId: taskId),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = (ref.watch(tasksProvider).valueOrNull ?? const <Task>[])
        .where((t) => t.id == taskId)
        .firstOrNull;
    final repo = ref.read(taskRepositoryProvider);
    final now = ref.read(clockProvider).now().toUtc();

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PillButton(
                  label: PlanStrings.back,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 20),
              if (task == null)
                Text(PlanStrings.taskDetailTitle, style: AppText.display())
              else
                StickerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: AppText.display(size: 24)),
                      const SizedBox(height: 6),
                      if (task.isScheduled)
                        Text(
                          _range(task.scheduledStart!, task.scheduledEnd!),
                          style: AppText.body(color: AppColors.muted),
                        ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          PillButton(
                            label: task.isDone
                                ? PlanStrings.markOpen
                                : PlanStrings.markDone,
                            color: AppColors.mint,
                            icon: const Icon(Icons.check),
                            onPressed: () => repo.upsert(
                              task.copyWith(
                                status: task.isDone
                                    ? TaskStatus.open
                                    : TaskStatus.done,
                                completedAt: task.isDone ? null : now,
                                updatedAt: now,
                              ),
                            ),
                          ),
                          if (!task.isDone)
                            PillButton(
                              key: const Key('plan-sheet-schedule'),
                              label: PlanStrings.scheduleForMe,
                              color: AppColors.lilac,
                              icon: const Icon(Icons.auto_awesome),
                              onPressed: () =>
                                  scheduleTaskForMe(context, ref, task.id),
                            ),
                          PillButton(
                            key: const Key('plan-sheet-details'),
                            label: PlanStrings.details,
                            icon: const Icon(Icons.notes),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    TaskDetailScreen(taskId: task.id),
                              ),
                            ),
                          ),
                          if (task.isScheduled)
                            PillButton(
                              label: PlanStrings.unschedule,
                              icon: const Icon(Icons.event_busy_outlined),
                              onPressed: () async {
                                final nav = Navigator.of(context);
                                await repo.upsert(
                                  task.copyWith(
                                    scheduledStart: null,
                                    scheduledEnd: null,
                                    lockedStart: false,
                                    updatedAt: now,
                                  ),
                                );
                                nav.maybePop();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _sourceName(CalendarSource s) => switch (s) {
  CalendarSource.google => PlanStrings.calendarGoogle,
  CalendarSource.apple => PlanStrings.calendarApple,
  CalendarSource.local => PlanStrings.calendarLocal,
};

/// Opens a URL outside the app. Overridden in tests.
final planUrlLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (_) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  },
);

/// Where "Open in calendar" goes: the provider's web calendar on the
/// event's local day. `CalendarEvent` has no per-event link yet, and Apple
/// Calendar has no web URL, so Apple and Grind-only events get none.
Uri? calendarDayUrl(CalendarEvent e) {
  if (e.source != CalendarSource.google) return null;
  final d = e.start.toLocal();
  return Uri.parse(
    'https://calendar.google.com/calendar/r/day/${d.year}/${d.month}/${d.day}',
  );
}

/// Read-only sheet for a calendar event.
Future<void> showPlanEventSheet(BuildContext context, CalendarEvent e) {
  final url = calendarDayUrl(e);
  return showStickerSheet<void>(
    context,
    (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(PlanStrings.fromCalendar, style: AppText.label(size: 11)),
          const SizedBox(height: 4),
          Text(e.title, style: AppText.display(size: 24)),
          const SizedBox(height: 6),
          Text(
            e.isAllDay ? PlanStrings.allDay : _range(e.start, e.end),
            style: AppText.body(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            '${PlanStrings.calendarLabel}: ${_sourceName(e.source)}',
            style: AppText.body(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) => PillButton(
              key: const Key('plan-open-in-calendar'),
              label: PlanStrings.openInCalendar,
              icon: const Icon(Icons.open_in_new),
              onPressed: url == null
                  ? null
                  : () async {
                      final ok = await ref.read(planUrlLauncherProvider)(url);
                      if (!ok && context.mounted) {
                        showPipToast(context, PlanStrings.openInCalendarFailed);
                      }
                    },
            ),
          ),
          if (url == null) ...[
            const SizedBox(height: 8),
            Text(
              e.source == CalendarSource.apple
                  ? PlanStrings.openInCalendarApple
                  : PlanStrings.openInCalendarLocal,
              style: AppText.body(size: 12, color: AppColors.muted),
            ),
          ],
        ],
      ),
    ),
  );
}
