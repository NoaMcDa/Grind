import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';

import 'review_repository.dart';
import 'rollover.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (_) => InMemoryReviewRepository(),
);

/// True after the evening prompt time (local) when today's review has not
/// been shown yet. Invalidate after the flow closes.
final eveningReviewDueProvider = FutureProvider.autoDispose<bool>((ref) async {
  final prefs = await ref.watch(preferencesProvider.future);
  final minutes = prefs.eveningPromptMinutes;
  if (minutes == null) return false;
  final now = ref.watch(clockProvider).now().toLocal();
  if (now.hour * 60 + now.minute < minutes) return false;
  return !await ref.watch(reviewRepositoryProvider).isHandled(dayKey(now));
});

/// Today's open tasks with a reminder or deadline today.
final todayReviewTasksProvider = Provider.autoDispose<List<Task>>((ref) {
  final all = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
  return reviewTasksFor(all, ref.watch(clockProvider).now());
});
