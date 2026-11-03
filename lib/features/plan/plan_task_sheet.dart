import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/sticker_bottom_sheet.dart';
import '../../widgets/sticker_card.dart';
import '../today/today_providers.dart' show formatClock;
import 'plan_strings.dart';

String _range(DateTime s, DateTime e) => '${formatClock(s)}–${formatClock(e)}';

/// Lightweight task detail opened from the Plan timeline. The full task
/// detail belongs to the tasks feature; the integrator links them later.
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

/// Read-only sheet for a calendar event.
Future<void> showPlanEventSheet(BuildContext context, CalendarEvent e) {
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
          const PillButton(
            label: PlanStrings.openInCalendar,
            icon: Icon(Icons.open_in_new),
            // Needs url_launcher (not a dependency yet).
            onPressed: null,
          ),
          const SizedBox(height: 8),
          Text(
            PlanStrings.openInCalendarSoon,
            style: AppText.body(size: 12, color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}
