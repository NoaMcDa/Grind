import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';

import 'effort_score.dart';
import 'mood.dart';

/// Finished focus sessions. Empty until the focus feature (P2-A) overrides it.
final focusSessionsProvider = Provider<List<FocusSession>>((_) => const []);

final effortScoreProvider = Provider<EffortScore>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final sessions = ref.watch(focusSessionsProvider);
  final now = ref.watch(clockProvider).now();
  return EffortScore.compute(tasks: tasks, sessions: sessions, now: now);
});

final pipMoodProvider = Provider<PipMood>(
  (ref) => moodFor(ref.watch(effortScoreProvider).level),
);

/// Momentum meter data: level plus the two-tone fill (0..1 each).
class Momentum {
  const Momentum({
    required this.level,
    required this.recent,
    required this.carry,
    required this.showedUpDays,
  });
  final MomentumLevel level;
  final double recent;
  final double carry;
  final int showedUpDays;
  double get total => recent + carry;
}

final momentumProvider = Provider<Momentum>((ref) {
  final s = ref.watch(effortScoreProvider);
  return Momentum(
    level: s.level,
    recent: s.recent / 100,
    carry: s.carry / 100,
    showedUpDays: s.showedUpDays,
  );
});

/// Cosmetic choice, in memory for now (see report: `Preferences.pipAccessory`).
class CompanionPrefs {
  const CompanionPrefs({this.accessory = 'scarf'});
  final String accessory;
}

class CompanionPrefsNotifier extends StateNotifier<CompanionPrefs> {
  CompanionPrefsNotifier() : super(const CompanionPrefs());
  void wear(String accessory) => state = CompanionPrefs(accessory: accessory);
}

final companionPrefsProvider =
    StateNotifierProvider<CompanionPrefsNotifier, CompanionPrefs>(
      (_) => CompanionPrefsNotifier(),
    );
