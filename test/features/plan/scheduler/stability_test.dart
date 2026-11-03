import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

void main() {
  final now = at(0, 8);
  final horizonEnd = at(1, 0);
  final meeting = event('m', at(0, 13), at(0, 14), title: 'Team sync');
  final tasks = [
    task(
      'pinned',
      title: 'Call mom',
      lockedStart: at(0, 9),
      lockedEnd: at(0, 9, 30),
    ),
    task('a', title: 'Essay outline', minutes: 60, due: at(0, 17)),
    task('b', title: 'Invoices', minutes: 30, due: at(0, 17)),
    task('c', title: 'Read paper', minutes: 45),
  ];

  Plan first() => plan(
    tasks: tasks,
    goals: const {},
    events: [meeting],
    prefs: prefsFixture,
    now: now,
    horizonEnd: horizonEnd,
  );

  ReplanResult againStable(
    List<Task> ts,
    List<CalendarEvent> evs, {
    Plan? from,
    DateTime? at_,
  }) {
    final prev = from ?? first();
    return replan(
      previous: prev,
      tasks: ts,
      goals: const {},
      events: evs,
      prefs: prefsFixture,
      now: at_ ?? now,
      horizonEnd: horizonEnd,
      prevPlacements: prevPlacementsFromPlan(prev),
    );
  }

  test('nothing changed: minimal-change replan is a no-op', () {
    final r = againStable(tasks, [meeting]);
    expect(r.diff.isEmpty, isTrue);
    expect(r.plan, first());
  });

  test(
    'mark one done: downstream tasks stay put instead of moving earlier',
    () {
      // Baseline: pinned 9:00, a 9:30-10:30, b 10:30-11:00, c 11:00-11:45.
      final done = [
        for (final t in tasks)
          t.id == 'a' ? t.copyWith(status: TaskStatus.done) : t,
      ];
      final r = againStable(done, [meeting]);
      expect(r.diff.removed, const [
        PlanRemoval(taskId: 'a', reason: 'done, nice work'),
      ]);
      // With the minimal-change bias, b and c keep their old slots.
      expect(r.diff.moved, isEmpty);
      expect(r.plan.placementsFor('b').single.start, at(0, 10, 30));
      expect(r.plan.placementsFor('c').single.start, at(0, 11));
    },
  );

  test('a shifted meeting still forces the blocked task to move', () {
    // Shift the sync onto b's old 10:30 slot.
    final shifted = meeting.copyWith(start: at(0, 10, 30), end: at(0, 11, 15));
    final r = againStable(tasks, [shifted]);
    final byId = {for (final m in r.diff.moved) m.taskId: m};
    // b cannot stay at 10:30 — the meeting (and its buffers) now cover it.
    expect(byId.containsKey('b'), isTrue);
    for (final p in r.plan.placementsFor('b')) {
      expect(
        p.slot.overlaps(Slot(at(0, 10, 20), at(0, 11, 25))),
        isFalse,
        reason: 'b must not overlap the shifted meeting or its buffer',
      );
    }
    // The pin and any task whose old slot is untouched still stay.
    expect(r.plan.placementsFor('pinned').single.start, at(0, 9));
  });

  test('a changed estimate falls back to a fresh placement', () {
    // c (undated, last in queue) grows from 45 to 60 min: its 45-min prev
    // slot can no longer cover it, so it drops the bias and refits.
    final grew = [
      for (final t in tasks)
        t.id == 'c' ? t.copyWith(estimatedMinutes: 60) : t,
    ];
    final r = againStable(grew, [meeting]);
    // c is placed with 60 min now.
    expect(r.plan.placementsFor('c').single.minutes, 60);
    // Higher-scored a and b keep their old slots — the fall-back is per task.
    expect(r.plan.placementsFor('a').single.start, at(0, 9, 30));
    expect(r.plan.placementsFor('b').single.start, at(0, 10, 30));
  });

  test('a new pinned task that takes the old slot forces a move', () {
    // User pins "Dentist" over b's old 10:30-11:00 slot.
    final withPin = [
      ...tasks,
      task(
        'dentist',
        title: 'Dentist',
        lockedStart: at(0, 10, 30),
        lockedEnd: at(0, 11),
      ),
    ];
    final r = againStable(withPin, [meeting]);
    expect(r.diff.added, ['dentist']);
    final byId = {for (final m in r.diff.moved) m.taskId: m};
    // b cannot stay at 10:30 — the pin took it.
    expect(byId.containsKey('b'), isTrue);
    expect(byId['b']!.reason, 'you put Dentist there');
  });

  test('a time-passed slot does not keep the task in the past', () {
    // It is now 10:20, after a's old 9:30-10:30 slot.
    final r = againStable(tasks, [meeting], at_: at(0, 10, 20));
    // Pin at 9:00 is in the past — dropped.
    expect(
      r.diff.removed
          .any((rem) => rem.taskId == 'pinned' && rem.reason.contains('passed')),
      isTrue,
    );
    // a's old 9:30-10:30 is also in the past — it must be re-placed later.
    for (final p in r.plan.placementsFor('a')) {
      expect(p.start.isBefore(at(0, 10, 20)), isFalse);
    }
  });

  test('prevPlacementsFromPlan skips locked placements', () {
    final p = first();
    final prev = prevPlacementsFromPlan(p);
    // The pinned task is not fed back to the bias — the planner keeps it
    // through its own locked path.
    expect(prev.containsKey('pinned'), isFalse);
    expect(prev['a'], [Slot(at(0, 9, 30), at(0, 10, 30))]);
    expect(prev['b'], [Slot(at(0, 10, 30), at(0, 11))]);
  });

  test('empty prevPlacements keeps the pre-#18 behaviour', () {
    // Without the bias, b moves up to 9:30 (the earlier slot that opened).
    final done = [
      for (final t in tasks)
        t.id == 'a' ? t.copyWith(status: TaskStatus.done) : t,
    ];
    final r = replan(
      previous: first(),
      tasks: done,
      goals: const {},
      events: [meeting],
      prefs: prefsFixture,
      now: now,
      horizonEnd: horizonEnd,
    );
    expect(r.plan.placementsFor('b').single.start, at(0, 9, 30));
  });
}
