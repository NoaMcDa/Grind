import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';

/// Local midnight of the day the Plan tab shows (today, per the app clock).
final planDayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider).now();
  return DateTime(now.year, now.month, now.day);
});

/// "Thu, Oct 29".
final planDayLabelProvider = Provider<String>((ref) {
  final d = ref.watch(planDayProvider);
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
});

/// Tasks scheduled on the day, ordered by start. Re-queries whenever any task
/// changes.
final planTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  ref.watch(tasksProvider);
  final day = ref.watch(planDayProvider);
  final next = DateTime(day.year, day.month, day.day + 1);
  final tasks = await ref
      .watch(taskRepositoryProvider)
      .getScheduledBetween(day, next);
  return tasks..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
});

/// Calendar events on the day, live.
final planEventsProvider = StreamProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  final day = ref.watch(planDayProvider);
  final next = DateTime(day.year, day.month, day.day + 1);
  return ref.watch(calendarRepositoryProvider).watchBetween(day, next);
});
