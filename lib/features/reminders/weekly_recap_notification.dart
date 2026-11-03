import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notification_scheduler.dart';
import 'package:grind/core/notifications/notification_sync.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../goals/domain/goal_metric.dart' show MetricPeriod;
import '../goals/domain/goal_repository.dart';
import '../goals/domain/metric_period.dart';
import '../goals/domain/weekly_recap.dart';
import '../goals/goal_providers.dart' show goalRepositoryProvider;
import '../goals/presentation/goal_l10n.dart';
import '../review/review_providers.dart';
import '../review/review_repository.dart';

/// When the weekly recap fires on the week's last day: an hour before the
/// evening prompt (so the two never arrive together), or 19:30 when the
/// evening prompt is off. Local minutes after midnight.
int recapMinutesFor(Preferences prefs) {
  final evening = prefs.eveningPromptMinutes;
  if (evening == null) return 19 * 60 + 30;
  return evening >= 60 ? evening - 60 : 0;
}

/// The [ExtraNotifications] hook for the weekly recap (#28): one
/// notification on the last evening of the current week (the user's
/// `weekStart` and `timeZoneName`), titled "Your week with Pip" and leading
/// with the week's biggest win ([GoalL10n.recapHeadline]). Built from the
/// week so far; every re-plan refreshes it. A quiet week sends nothing,
/// so there is never a "you missed" line. A tap opens `/highlights`
/// (`NotificationRouter.openLocation`).
///
/// `NotificationScheduler.plan` applies quiet hours, the horizon and the cap.
ExtraNotifications weeklyRecapNotifications({
  required GoalRepository goals,
  required ReviewRepository reviews,
  Clock clock = const SystemClock(),
}) {
  return (List<Task> tasks, Preferences prefs) async {
    final now = clock.now().toUtc();
    final location = locationFor(prefs.timeZoneName);
    final week = periodOf(
      MetricPeriod.week,
      PeriodContext(now: now, location: location, weekStart: prefs.weekStart),
    );
    final last = week.lastDay;
    final minutes = recapMinutesFor(prefs);
    final fireAt = tz.TZDateTime(
      location,
      last.year,
      last.month,
      last.day,
      minutes ~/ 60,
      minutes % 60,
    ).toUtc();
    if (!fireAt.isAfter(now)) return const [];
    final recap = buildWeeklyRecap(
      week: week,
      isCurrentWeek: true,
      goals: await goals.getAll(),
      tasks: tasks,
      reviews: await reviews.all(),
    );
    if (recap.lead == RecapLead.quiet) return const [];
    final l = lookupAppLocalizations(Locale(_lang(prefs.localeCode)));
    return [
      ScheduledNotification(
        id: recapNotificationId(last),
        taskId: '',
        fireAt: fireAt,
        title: l.recapNotificationTitle,
        body: l.recapHeadline(recap),
        actions: const [],
      ),
    ];
  };
}

/// `recap:weekly:<yyyy-MM-dd of the week's last day>`.
String recapNotificationId(DateTime lastDay) =>
    '${NotificationScheduler.recapPrefix}'
    '${lastDay.year.toString().padLeft(4, '0')}-'
    '${lastDay.month.toString().padLeft(2, '0')}-'
    '${lastDay.day.toString().padLeft(2, '0')}';

String _lang(String code) {
  final c = code.toLowerCase();
  return c.startsWith('he') || c.startsWith('iw') ? 'he' : 'en';
}

/// Compose into `notificationExtraProvider` in `main.dart`:
/// `combineExtras([ref.watch(recurrenceExtraProvider),
/// ref.watch(recapExtraProvider)])`.
final recapExtraProvider = Provider<ExtraNotifications>(
  (ref) => weeklyRecapNotifications(
    goals: ref.watch(goalRepositoryProvider),
    reviews: ref.watch(reviewRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
