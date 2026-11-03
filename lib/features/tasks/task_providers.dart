import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';

/// The live task with [id], or null when missing or deleted.
final taskByIdProvider = Provider.family<Task?, String>((ref, id) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  for (final t in all) {
    if (t.id == id) return t;
  }
  return null;
});

DateTime? _when(Task t) => t.remindAt ?? t.dueAt;

int _byWhen(Task a, Task b) {
  final x = _when(a), y = _when(b);
  if (x == null && y == null) return a.createdAt.compareTo(b.createdAt);
  if (x == null) return 1;
  if (y == null) return -1;
  return x.compareTo(y);
}

/// Open tasks, soonest first; tasks without a time go last.
final openTasksProvider = Provider<List<Task>>((ref) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  return all.where((t) => !t.isDone && t.deletedAt == null).toList()
    ..sort(_byWhen);
});

/// Tasks whose reminder or due time falls on today's local day (per
/// [clockProvider]): open ones by time first, done ones sink to the end.
final todayTasksProvider = Provider<List<Task>>((ref) {
  final now = ref.watch(clockProvider).now().toLocal();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day + 1);
  bool today(DateTime? t) {
    if (t == null) return false;
    final l = t.toLocal();
    return !l.isBefore(start) && l.isBefore(end);
  }

  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  final list = all
      .where((t) => t.deletedAt == null)
      .where((t) => today(t.remindAt) || today(t.dueAt))
      .toList();
  list.sort((a, b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    return _byWhen(a, b);
  });
  return list;
});

/// How many of today's tasks are done.
final todayDoneCountProvider = Provider<int>(
  (ref) => ref.watch(todayTasksProvider).where((t) => t.isDone).length,
);
