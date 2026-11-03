import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../theme/tokens.dart';
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
