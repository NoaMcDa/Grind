import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../theme/tokens.dart';
import '../goals/domain/metric_ticks.dart';
import '../plan/draft/day_drafter.dart' show draftCandidates;
import '../tasks/day_bounds.dart';

export '../tasks/task_providers.dart' show TodayItem, todayTasksProvider;

/// The current day in the user's zone; the screen words it with
/// `formatTodayLabel` in the app language.
final todayDateProvider = Provider.autoDispose<DateTime>(
  (ref) => ref.watch(todayBoundsProvider).date,
);

/// "12:30" in [location] (the user's zone), or device-local time without
/// one (for values that already are wall-clock fields).
String formatClock(DateTime t, [tz.Location? location]) {
  final l = location == null ? t.toLocal() : tz.TZDateTime.from(t, location);
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}

/// Row tag colour by task category.
Color taskTagColor(Task t) => switch (t.category) {
  'light' => AppColors.sky,
  'move' => AppColors.mint,
  'social' => AppColors.pink,
  _ => AppColors.violet,
};

/// The day (a floating date in the user's zone) the "Plan my day" card was
/// hidden for; it comes back the next morning. Session only.
final planMyDayHiddenProvider = StateProvider<DateTime?>((_) => null);

/// Whether Today shows the "Plan my day with Pip" invitation: see
/// [planMyDayInvitation].
final planMyDayCardProvider = Provider.autoDispose<bool>((ref) {
  final day = ref.watch(todayBoundsProvider);
  if (ref.watch(planMyDayHiddenProvider) == day.date) return false;
  final now =
      ref.watch(minuteTickProvider).valueOrNull ??
      ref.watch(clockProvider).now();
  return planMyDayInvitation(
    tasks: ref.watch(tasksProvider).valueOrNull ?? const <Task>[],
    prefs: ref.watch(preferencesProvider).valueOrNull ?? const Preferences(),
    nowUtc: now.toUtc(),
    day: day,
  );
});

/// The morning invitation to draft the day, shown when all hold:
///
/// - it is morning in the user's zone: from 05:00 (or the morning prompt,
///   if earlier) until noon (or three hours after the prompt, if later);
/// - today still has working hours ahead;
/// - nothing is scheduled today yet;
/// - there are open tasks the draft could place ([draftCandidates]).
bool planMyDayInvitation({
  required List<Task> tasks,
  required Preferences prefs,
  required DateTime nowUtc,
  required DayBounds day,
}) {
  final wall = zoneWall(nowUtc, day.location);
  final minutes = wall.hour * 60 + wall.minute;
  final prompt = prefs.morningPromptMinutes;
  final from = math.min(5 * 60, prompt ?? 5 * 60);
  final until = math.max(12 * 60, (prompt ?? 0) + 3 * 60);
  if (minutes < from || minutes >= until) return false;
  final hours = prefs.workingHours[wall.weekday] ?? const <TimeRange>[];
  if (!hours.any((r) => r.endMinutes > minutes)) return false;
  final scheduledToday = tasks.any(
    (t) =>
        t.deletedAt == null &&
        !isMetricTick(t) &&
        t.isScheduled &&
        t.scheduledStart!.isBefore(day.end) &&
        t.scheduledEnd!.isAfter(day.start),
  );
  if (scheduledToday) return false;
  return draftCandidates(tasks, day, nowUtc).isNotEmpty;
}
