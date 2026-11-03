import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';

/// True once the user has finished onboarding. The integrator routes to
/// `/onboarding` while this is false.
final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(preferencesRepositoryProvider).get();
  return prefs.onboardingDone;
});
