import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../theme/tokens.dart';

/// Tasks with a reminder, ordered by reminder time: the "Up next" list.
final todayTasksProvider = Provider<List<Task>>((ref) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  return all.where((t) => t.remindAt != null).toList()
    ..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));
});

/// "Thursday, Oct 29" for the clock's current day.
final todayLabelProvider = Provider<String>((ref) {
  final d = ref.watch(clockProvider).now();
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
});

/// "12:30" in local time.
String formatClock(DateTime t) {
  final l = t.toLocal();
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

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
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
