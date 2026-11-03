import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

void main() {
  // Two working days of 7 free hours each: 14 h free.
  final prefs = prefsFixture.copyWith(
    dailyCushionMinutes: 0,
    bufferBetweenEventsMinutes: 0,
  );
  final now = at(0, 8);
  final horizonEnd = at(2, 0);

  // 8 h due inside the window + 11 h that could wait = 19 h of demand.
  final tasks = [
    for (var i = 0; i < 4; i++)
      task('due$i', minutes: 120, due: at(1, 17), priority: 1),
    task('backlog', minutes: 180),
    for (var i = 0; i < 4; i++) task('later$i', minutes: 120, due: at(30, 17)),
  ];

  Plan run() => plan(
    tasks: tasks,
    goals: const {},
    events: const [],
    prefs: prefs,
    now: now,
    horizonEnd: horizonEnd,
  );

  test('19 h of demand vs 14 h free is overbooked', () {
    final c = run().capacity;
    expect(c.freeMinutes, 14 * 60);
    expect(c.demandMinutes, 19 * 60);
    expect(c.overbooked, isTrue);
    expect(c.days.map((d) => d.freeMinutes), [420, 420]);
    expect(c.days.map((d) => d.deepCapacityMinutes), [180, 180]);
  });

  test('deferrals bring demand under free, lowest score first', () {
    final p = run();
    final deferred = p.deferralSuggestions;
    final freed = deferred.fold(0, (s, d) => s + d.minutes);
    expect(p.capacity.demandMinutes - freed, lessThanOrEqualTo(14 * 60));
    expect(deferred.map((d) => d.taskId), ['backlog', 'later0']);
    expect(deferred.first.reason, 'no deadline, so next week works');
    expect(deferred.last.reason, 'not due until Dec 9');
    expect(
      capacitySummary(p.capacity, deferrals: deferred.length),
      'You have 14 hours free and 19 hours of plans. '
      'Two things could move to next week.',
    );
  });

  test('no in-week deadline is ever deferred', () {
    final p = run();
    for (final d in p.deferralSuggestions) {
      expect(d.taskId.startsWith('due'), isFalse);
    }
    // Even when only in-week work overbooks the week.
    final onlyDue = plan(
      tasks: [
        for (var i = 0; i < 8; i++) task('d$i', minutes: 120, due: at(1, 17)),
      ],
      goals: const {},
      events: const [],
      prefs: prefs,
      now: now,
      horizonEnd: horizonEnd,
    );
    expect(onlyDue.capacity.overbooked, isTrue);
    expect(onlyDue.deferralSuggestions, isEmpty);
  });

  test('a week that fits has no deferrals', () {
    final p = plan(
      tasks: [task('a', minutes: 60), task('b', minutes: 60)],
      goals: const {},
      events: const [],
      prefs: prefs,
      now: now,
      horizonEnd: horizonEnd,
    );
    expect(p.capacity.overbooked, isFalse);
    expect(p.deferralSuggestions, isEmpty);
    expect(
      capacitySummary(p.capacity),
      'You have 14 hours free and 2 hours of plans. '
      'It fits, with room to breathe.',
    );
  });

  test('deep demand over deep capacity also counts as overbooked', () {
    final p = plan(
      tasks: [
        for (var i = 0; i < 5; i++)
          task('deep$i', minutes: 90, energy: Energy.deep, due: at(9, 17)),
      ],
      goals: const {},
      events: const [],
      prefs: prefs.copyWith(maxDeepBlocksPerDay: 1),
      now: now,
      horizonEnd: horizonEnd,
    );
    expect(p.capacity.deepCapacityMinutes, 180);
    expect(p.capacity.deepDemandMinutes, 450);
    expect(p.capacity.overbooked, isTrue);
    final freed = p.deferralSuggestions.fold(0, (s, d) => s + d.minutes);
    expect(450 - freed, lessThanOrEqualTo(180));
    // Only 1 deep block a day placed.
    expect(p.placed.length, 2);
  });

  test('locked tasks count as demand, not as lost free time', () {
    final c = weekCapacity(
      from: now,
      to: horizonEnd,
      prefs: prefs,
      events: const [],
      tasks: [task('l', lockedStart: at(0, 10), lockedEnd: at(0, 11))],
    );
    expect(c.freeMinutes, 14 * 60);
    expect(c.demandMinutes, 60);
  });

  test('avgFreeHoursPerDay ignores days with no free time', () {
    final c = weekCapacity(
      from: at(0, 0),
      to: at(7, 0),
      prefs: prefs,
      events: const [],
      tasks: const [],
    );
    expect(c.days.length, 7);
    expect(avgFreeHoursPerDay(c), 7);
    expect(avgFreeHoursPerDay(WeekCapacity.empty), 1);
  });
}
