import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/pip_avatar.dart';
import '../goals/domain/goal_progress.dart';
import '../goals/domain/goal_record.dart';
import '../goals/goal_providers.dart';
import 'effort_score.dart';
import 'pip_providers.dart';

/// What the unlock rules look at. Effort only: there are no streaks, so a
/// quiet week can never take anything away.
@immutable
class UnlockStats {
  const UnlockStats({
    this.tasksDone = 0,
    this.sessionsDone = 0,
    this.showedUpDays = 0,
    this.weeklyMetricHit = false,
    this.goalCompleted = false,
  });

  final int tasksDone;
  final int sessionsDone;

  /// Distinct days with finished work in the last [UnlockRules.showedUpWindow].
  final int showedUpDays;

  /// A weekly goal reached its target at least once.
  final bool weeklyMetricHit;

  /// A goal was completed at least once.
  final bool goalCompleted;
}

/// Where one accessory stands.
@immutable
class UnlockProgress {
  const UnlockProgress({
    required this.accessory,
    required this.current,
    required this.target,
    required this.unlocked,
  });

  final PipAccessory accessory;
  final int current;
  final int target;
  final bool unlocked;

  int get remaining => unlocked ? 0 : (target - current).clamp(0, target);

  /// 0..1 for the progress ring.
  double get fraction =>
      unlocked ? 1 : (target <= 0 ? 0 : (current / target).clamp(0.0, 1.0));

  /// Locked with no progress yet (shows a lock, not a ring).
  bool get untouched => !unlocked && current <= 0;
}

/// Accessory rules (#35). Pure.
abstract final class UnlockRules {
  static const sunglassesSessions = 10;
  static const partyHatTasks = 25;
  static const bootsDays = 20;
  static const showedUpWindow = 28;

  /// Display order on the Pip screen.
  static const accessories = [
    PipAccessory.scarf,
    PipAccessory.sunglasses,
    PipAccessory.partyHat,
    PipAccessory.rainBoots,
    PipAccessory.crown,
  ];

  static UnlockProgress progressFor(PipAccessory a, UnlockStats s) {
    UnlockProgress of(int cur, int target, bool done) => UnlockProgress(
      accessory: a,
      current: cur > target ? target : cur,
      target: target,
      unlocked: done,
    );
    return switch (a) {
      PipAccessory.none || PipAccessory.scarf => of(1, 1, true),
      PipAccessory.sunglasses => of(
        s.sessionsDone,
        sunglassesSessions,
        s.sessionsDone >= sunglassesSessions,
      ),
      PipAccessory.partyHat => of(
        s.tasksDone,
        partyHatTasks,
        s.weeklyMetricHit || s.tasksDone >= partyHatTasks,
      ),
      PipAccessory.rainBoots => of(
        s.showedUpDays,
        bootsDays,
        s.showedUpDays >= bootsDays,
      ),
      PipAccessory.crown => of(s.goalCompleted ? 1 : 0, 1, s.goalCompleted),
    };
  }

  static List<UnlockProgress> evaluate(UnlockStats s) => [
    for (final a in accessories) progressFor(a, s),
  ];

  static Set<PipAccessory> unlockedSet(UnlockStats s) => {
    for (final p in evaluate(s))
      if (p.unlocked) p.accessory,
  };

  /// Computes the stats from stored work. [now] anchors the 28-day window.
  static UnlockStats statsOf({
    required List<Task> tasks,
    required List<FocusSession> sessions,
    required List<GoalRecord> goals,
    required DateTime now,
  }) {
    final live = tasks.where((t) => t.deletedAt == null).toList();
    final doneTasks = live.where((t) => t.status == TaskStatus.done).toList();
    final doneSessions = sessions
        .where((s) => s.completed && s.deletedAt == null)
        .toList();
    DateTime day(DateTime d) {
      final l = d.toLocal();
      return DateTime(l.year, l.month, l.day);
    }

    final today = day(now);
    final days = <DateTime>{};
    for (final e in EffortScore.eventsOf(live, doneSessions)) {
      if (!e.completed) continue;
      final ago = today.difference(day(e.at)).inHours / 24;
      if (ago > -1 && ago < showedUpWindow) days.add(day(e.at));
    }
    var weekly = false;
    var goalDone = false;
    for (final g in goals) {
      if (g.deletedAt != null) continue;
      final done =
          g.status == GoalStatus.done ||
          GoalProgress.of(
            g,
            linkedTasks: [
              for (final t in live)
                if (t.goalId == g.id) t,
            ],
          ).isCompleted;
      if (!done) continue;
      goalDone = true;
      if (g.horizon == GoalHorizon.week) weekly = true;
    }
    return UnlockStats(
      tasksDone: doneTasks.length,
      sessionsDone: doneSessions.length,
      showedUpDays: days.length,
      weeklyMetricHit: weekly,
      goalCompleted: goalDone,
    );
  }
}

final unlockStatsProvider = Provider<UnlockStats>((ref) {
  return UnlockRules.statsOf(
    tasks: ref.watch(tasksProvider).value ?? const <Task>[],
    sessions: ref.watch(focusSessionsProvider),
    goals: ref.watch(goalsProvider).value ?? const <GoalRecord>[],
    now: ref.watch(clockProvider).now(),
  );
});

final unlockProgressProvider = Provider<List<UnlockProgress>>(
  (ref) => UnlockRules.evaluate(ref.watch(unlockStatsProvider)),
);

final unlockedAccessoriesProvider = Provider<Set<PipAccessory>>(
  (ref) => UnlockRules.unlockedSet(ref.watch(unlockStatsProvider)),
);

/// True once tasks and goals have delivered their first value, so the
/// first unlock evaluation reflects stored data rather than an empty list.
final unlocksReadyProvider = Provider<bool>(
  (ref) =>
      ref.watch(tasksProvider).hasValue && ref.watch(goalsProvider).hasValue,
);

/// Which unlocks Pip has already announced.
///
/// In memory for now. PROPOSED: persist as `Preferences.seenUnlocks`
/// (comma-separated accessory names, default `scarf`) so an unlock is
/// announced once across launches; the notifier then seeds from it.
class UnlockSeen extends StateNotifier<Set<PipAccessory>?> {
  UnlockSeen() : super(null);

  /// Compares [unlocked] with what was announced. The first call only sets
  /// the baseline (existing unlocks are not news); later calls return the
  /// accessories that are new, in rule order, and remember them.
  List<PipAccessory> sync(Set<PipAccessory> unlocked) {
    final seen = state;
    if (seen == null) {
      state = {...unlocked};
      return const [];
    }
    final fresh = [
      for (final a in UnlockRules.accessories)
        if (unlocked.contains(a) && !seen.contains(a)) a,
    ];
    if (fresh.isNotEmpty) state = {...seen, ...fresh};
    return fresh;
  }
}

final unlockSeenProvider =
    StateNotifierProvider<UnlockSeen, Set<PipAccessory>?>((_) => UnlockSeen());

/// Localised accessory name.
String accessoryName(AppLocalizations l, PipAccessory a) => switch (a) {
  PipAccessory.none => l.pipNoAccessory,
  PipAccessory.scarf => l.accScarf,
  PipAccessory.sunglasses => l.accSunglasses,
  PipAccessory.partyHat => l.accPartyHat,
  PipAccessory.rainBoots => l.accRainBoots,
  PipAccessory.crown => l.accCrown,
};

/// What is left for a locked accessory ("3 more sessions").
String unlockHint(AppLocalizations l, UnlockProgress p) =>
    switch (p.accessory) {
      PipAccessory.sunglasses => l.pipMoreSessions(p.remaining),
      PipAccessory.partyHat => l.pipMoreTasks(p.remaining),
      PipAccessory.rainBoots => l.pipMoreDays(p.remaining),
      PipAccessory.crown => l.pipFinishGoal,
      _ => '',
    };
