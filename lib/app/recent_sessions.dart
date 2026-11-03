import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../features/companion/pip_providers.dart';
import '../features/focus/providers.dart';

/// Focus sessions of the last four weeks, live. Feeds the companion's effort
/// score and the unlock rules (`focusSessionsProvider` defaults to empty).
final recentFocusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final now = ref.watch(clockProvider).now().toUtc();
  return ref
      .watch(focusSessionRepositoryProvider)
      .watchBetween(
        now.subtract(const Duration(days: 28)),
        now.add(const Duration(days: 1)),
      );
});

/// Override for `main.dart`: the companion reads real sessions.
Override recentFocusSessionsOverride() => focusSessionsProvider.overrideWith(
  (ref) => ref.watch(recentFocusSessionsProvider).value ?? const [],
);
