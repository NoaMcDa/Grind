import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_toast.dart';
import '../../widgets/sticker_bottom_sheet.dart';
import '../../widgets/sticker_card.dart';
import '../tasks/day_bounds.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_detail_screen.dart';
import '../today/today_providers.dart' show formatClock;
import 'plan_replan_sheet.dart';
import '../../l10n/l10n.dart';

String _range(DateTime s, DateTime e, tz.Location location) =>
    '${formatClock(s, location)}–${formatClock(e, location)}';

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
    final location = ref.watch(zoneLocationProvider);

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
                  label: context.l10n.commonBack,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 20),
              if (task == null)
                Text(context.l10n.tasksDetailTitle, style: AppText.display())
              else
                StickerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: AppText.display(size: 24)),
                      const SizedBox(height: 6),
                      if (task.isScheduled)
                        Text(
                          _range(
                            task.scheduledStart!,
                            task.scheduledEnd!,
                            location,
                          ),
                          style: AppText.body(color: AppColors.muted),
                        ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          PillButton(
                            label: task.isDone
                                ? context.l10n.planMarkOpen
                                : context.l10n.planMarkDone,
                            color: AppColors.mint,
                            icon: const Icon(Icons.check),
                            // Series-aware, as on Today.
                            onPressed: () => ref
                                .read(taskActionsProvider)
                                .toggle(context, task),
                          ),
                          if (!task.isDone)
                            PillButton(
                              key: const Key('plan-sheet-schedule'),
                              label: context.l10n.planScheduleForMe,
                              color: AppColors.lilac,
                              icon: const Icon(Icons.auto_awesome),
                              onPressed: () =>
                                  scheduleTaskForMe(context, ref, task.id),
                            ),
                          PillButton(
                            key: const Key('plan-sheet-details'),
                            label: context.l10n.planDetails,
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
                              label: context.l10n.planUnschedule,
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

String _sourceName(BuildContext context, CalendarSource s) => switch (s) {
  CalendarSource.google => context.l10n.commonGoogleCalendar,
  CalendarSource.apple => context.l10n.commonAppleCalendar,
  CalendarSource.local => context.l10n.planCalendarLocal,
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

/// Where "Open in calendar" goes: the event itself when the provider gave a
/// link ([CalendarEvent.htmlLink], https only), else the provider's web
/// calendar on the event's day in [location] (the device zone without one).
/// Apple Calendar has no web URL, so Apple and Grind-only events without a
/// link get none.
Uri? calendarDayUrl(CalendarEvent e, [tz.Location? location]) {
  final link = e.htmlLink == null ? null : Uri.tryParse(e.htmlLink!);
  if (link != null && link.scheme == 'https' && link.host.isNotEmpty) {
    return link;
  }
  if (e.source != CalendarSource.google) return null;
  final d = location == null ? e.start.toLocal() : zoneWall(e.start, location);
  return Uri.parse(
    'https://calendar.google.com/calendar/r/day/${d.year}/${d.month}/${d.day}',
  );
}

/// Read-only sheet for a calendar event.
Future<void> showPlanEventSheet(BuildContext context, CalendarEvent e) {
  final location = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(zoneLocationProvider);
  final url = calendarDayUrl(e, location);
  return showStickerSheet<void>(
    context,
    (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ctx.l10n.fromCalendar.toUpperCase(),
            style: AppText.label(size: 11),
          ),
          const SizedBox(height: 4),
          Text(e.title, style: AppText.display(size: 24)),
          const SizedBox(height: 6),
          Text(
            e.isAllDay ? ctx.l10n.planAllDay : _range(e.start, e.end, location),
            style: AppText.body(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            '${ctx.l10n.planCalendarLabel}: ${_sourceName(ctx, e.source)}',
            style: AppText.body(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) => PillButton(
              key: const Key('plan-open-in-calendar'),
              label: context.l10n.planOpenInCalendar,
              icon: const Icon(Icons.open_in_new),
              onPressed: url == null
                  ? null
                  : () async {
                      final ok = await ref.read(planUrlLauncherProvider)(url);
                      if (!ok && context.mounted) {
                        showPipToast(
                          context,
                          context.l10n.planOpenInCalendarFailed,
                        );
                      }
                    },
            ),
          ),
          if (url == null) ...[
            const SizedBox(height: 8),
            Text(
              e.source == CalendarSource.apple
                  ? ctx.l10n.planOpenInCalendarApple
                  : ctx.l10n.planOpenInCalendarLocal,
              style: AppText.body(size: 12, color: AppColors.muted),
            ),
          ],
        ],
      ),
    ),
  );
}
