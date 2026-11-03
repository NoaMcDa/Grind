import 'dart:async';

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

/// Cosmetic choice, stored as [Preferences.pipAccessory].
class CompanionPrefs {
  const CompanionPrefs({this.accessory = Preferences.defaultPipAccessory});
  final String accessory;
}

/// Mirrors [Preferences.pipAccessory] from [PreferencesRepository]. [wear]
/// updates the state at once and saves in the background; stored changes
/// (another screen, an import) flow back in through `watch()`.
class CompanionPrefsNotifier extends StateNotifier<CompanionPrefs> {
  CompanionPrefsNotifier(this._repo) : super(const CompanionPrefs()) {
    _sub = _repo.watch().listen(_onStored, onError: (Object _) {});
  }

  final PreferencesRepository _repo;
  late final StreamSubscription<Preferences> _sub;

  /// The accessory being saved; stored values that differ are older.
  String? _pending;

  void _onStored(Preferences p) {
    final stored = p.pipAccessory;
    if (_pending != null) {
      if (stored != _pending) return;
      _pending = null;
    }
    if (stored != state.accessory) state = CompanionPrefs(accessory: stored);
  }

  void wear(String accessory) {
    state = CompanionPrefs(accessory: accessory);
    _pending = accessory;
    unawaited(_save(accessory));
  }

  Future<void> _save(String accessory) async {
    final p = await _repo.get();
    await _repo.save(p.copyWith(pipAccessory: accessory));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final companionPrefsProvider =
    StateNotifierProvider<CompanionPrefsNotifier, CompanionPrefs>(
      (ref) => CompanionPrefsNotifier(ref.watch(preferencesRepositoryProvider)),
    );
