import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/database.dart';
import '../../core/data/focus_session_repository.dart';
import '../../core/data/repositories/drift_focus_session_repository.dart';
import 'focus_controller.dart';

export '../../core/data/focus_session_repository.dart';
export 'focus_controller.dart';

/// Focus sessions storage. Defaults to in-memory so the Focus tab runs in
/// tests and the demo; `main.dart` swaps in Drift with
/// [focusRepositoryOverride].
final focusSessionRepositoryProvider = Provider<FocusSessionRepository>(
  (_) => InMemoryFocusSessionRepository(),
);

/// Add to the `ProviderScope` overrides in `main.dart`, next to
/// `dataProvidersOverrides(db)`:
///
/// ```dart
/// overrides: [...dataProvidersOverrides(db), focusRepositoryOverride(db)]
/// ```
Override focusRepositoryOverride(AppDatabase db) =>
    focusSessionRepositoryProvider.overrideWith(
      (_) => DriftFocusSessionRepository(db),
    );

/// The running focus session, break and cycle. Kept alive (not auto-disposed)
/// so switching tabs does not lose the timer.
final focusControllerProvider =
    AsyncNotifierProvider<FocusController, FocusState>(FocusController.new);
