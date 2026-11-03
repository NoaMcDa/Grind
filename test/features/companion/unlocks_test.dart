import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/companion/unlocks.dart';
import 'package:grind/features/goals/goals.dart';
import 'package:grind/widgets/pip_avatar.dart';

final _now = DateTime(2026, 11, 3, 12);

Task _done(String id, DateTime at) => Task(
  id: id,
  title: id,
  status: TaskStatus.done,
  completedAt: at,
  createdAt: at,
  updatedAt: at,
);

FocusSession _session(int i) => FocusSession(
  id: 's$i',
  plannedMinutes: 25,
  startedAt: _now,
  endedAt: _now,
  completed: true,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  test('scarf is always unlocked, the rest start locked', () {
    expect(UnlockRules.unlockedSet(const UnlockStats()), {PipAccessory.scarf});
  });

  test('sunglasses at 10 focus sessions', () {
    expect(
      UnlockRules.unlockedSet(const UnlockStats(sessionsDone: 9)),
      isNot(contains(PipAccessory.sunglasses)),
    );
    final p = UnlockRules.progressFor(
      PipAccessory.sunglasses,
      const UnlockStats(sessionsDone: 7),
    );
    expect(p.remaining, 3);
    expect(p.fraction, closeTo(0.7, 1e-9));
    expect(
      UnlockRules.unlockedSet(const UnlockStats(sessionsDone: 10)),
      contains(PipAccessory.sunglasses),
    );
  });

  test('party hat: 25 tasks or a weekly metric hit', () {
    expect(
      UnlockRules.unlockedSet(const UnlockStats(tasksDone: 24)),
      isNot(contains(PipAccessory.partyHat)),
    );
    expect(
      UnlockRules.unlockedSet(const UnlockStats(tasksDone: 25)),
      contains(PipAccessory.partyHat),
    );
    expect(
      UnlockRules.unlockedSet(const UnlockStats(weeklyMetricHit: true)),
      contains(PipAccessory.partyHat),
    );
  });

  test('rain boots at 20 of 28 days, crown on a completed goal', () {
    expect(
      UnlockRules.unlockedSet(const UnlockStats(showedUpDays: 19)),
      isNot(contains(PipAccessory.rainBoots)),
    );
    expect(
      UnlockRules.unlockedSet(const UnlockStats(showedUpDays: 20)),
      contains(PipAccessory.rainBoots),
    );
    expect(
      UnlockRules.unlockedSet(const UnlockStats(goalCompleted: true)),
      contains(PipAccessory.crown),
    );
  });

  test('stats from data: days in the 28 day window, no streak needed', () {
    final tasks = [
      for (var i = 0; i < 20; i++)
        _done('t$i', _now.subtract(Duration(days: i))),
      _done('old', _now.subtract(const Duration(days: 40))),
    ];
    final stats = UnlockRules.statsOf(
      tasks: tasks,
      sessions: [for (var i = 0; i < 3; i++) _session(i)],
      goals: const [],
      now: _now,
    );
    expect(stats.tasksDone, 21);
    expect(stats.sessionsDone, 3);
    expect(stats.showedUpDays, 20);
  });

  test('stats from goals: a done weekly goal gives both flags', () {
    final g = GoalRecord(
      id: 'g',
      title: 'g',
      horizon: GoalHorizon.week,
      status: GoalStatus.done,
      createdAt: _now,
      updatedAt: _now,
    );
    final stats = UnlockRules.statsOf(
      tasks: const [],
      sessions: const [],
      goals: [g],
      now: _now,
    );
    expect(stats.weeklyMetricHit, isTrue);
    expect(stats.goalCompleted, isTrue);
  });

  test('UnlockSeen: first sync is a baseline, then each unlock once', () {
    final seen = UnlockSeen();
    final base = {PipAccessory.scarf, PipAccessory.crown};
    expect(seen.sync(base), isEmpty);
    expect(seen.sync(base), isEmpty);
    final more = {...base, PipAccessory.sunglasses};
    expect(seen.sync(more), [PipAccessory.sunglasses]);
    expect(seen.sync(more), isEmpty);
  });
}
