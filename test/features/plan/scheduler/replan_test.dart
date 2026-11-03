import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/plan/scheduler/providers.dart';
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

  ReplanResult again(List<Task> ts, List<CalendarEvent> evs, {DateTime? at_}) =>
      replan(
        previous: first(),
        tasks: ts,
        goals: const {},
        events: evs,
        prefs: prefsFixture,
        now: at_ ?? now,
        horizonEnd: horizonEnd,
      );

  void expectLockedStill(Plan p) {
    final l = p.placementsFor('pinned').single;
    expect(l.start, at(0, 9));
    expect(l.end, at(0, 9, 30));
    expect(l.locked, isTrue);
  }

  test('baseline plan', () {
    final p = first();
    expect(
      p.placed.map((x) => '${x.taskId} ${x.start.hour}:${x.start.minute}'),
      ['pinned 9:0', 'a 9:30', 'b 10:30', 'c 11:0'],
    );
  });

  test('nothing changed: empty diff', () {
    final r = again(tasks, [meeting]);
    expect(r.diff.isEmpty, isTrue);
    expect(r.plan, first());
  });

  test('mark one done: it is removed, the rest move up with reasons', () {
    final done = [
      for (final t in tasks)
        t.id == 'a' ? t.copyWith(status: TaskStatus.done) : t,
    ];
    final r = again(done, [meeting]);
    expectLockedStill(r.plan);
    expect(r.diff.removed, const [
      PlanRemoval(taskId: 'a', reason: 'done, nice work'),
    ]);
    expect(r.diff.added, isEmpty);
    expect(r.diff.moved.map((m) => m.taskId), ['b', 'c']);
    for (final m in r.diff.moved) {
      expect(m.reason, 'an earlier slot opened up');
    }
    expect(r.plan.placementsFor('b').single.start, at(0, 9, 30));
  });

  test('shift one meeting onto a task: only explained moves', () {
    final shifted = meeting.copyWith(start: at(0, 10), end: at(0, 11));
    final r = again(tasks, [shifted]);
    expectLockedStill(r.plan);
    expect(r.diff.moved, isNotEmpty);
    final byId = {for (final m in r.diff.moved) m.taskId: m};
    expect(byId['a']!.reason, 'Team sync now takes that time');
    for (final m in r.diff.moved) {
      expect(m.reason, isNotEmpty);
      expect(m.taskId, isNot('pinned'));
    }
    // New placements avoid the shifted meeting and its buffers.
    for (final p in r.plan.placed) {
      expect(p.slot.overlaps(Slot(at(0, 9, 50), at(0, 11, 10))), isFalse);
    }
  });

  test('time passing moves what is now in the past', () {
    final r = again(tasks, [meeting], at_: at(0, 10, 30));
    // The pin is in the past now: dropped from the plan, never moved.
    expect(r.diff.removed, const [
      PlanRemoval(taskId: 'pinned', reason: 'that time has passed'),
    ]);
    final reasons = {for (final m in r.diff.moved) m.taskId: m.reason};
    expect(reasons.containsKey('pinned'), isFalse);
    expect(reasons['a'], 'that time has passed');
    expect(reasons['b'], 'made room for Essay outline');
    expect(
      r.plan.placed
          .where((p) => !p.locked)
          .every((p) => !p.start.isBefore(at(0, 10, 30))),
      isTrue,
    );
  });

  test('a newly pinned task bumps what was there', () {
    final pinnedC = [
      ...tasks,
      task(
        'new',
        title: 'Dentist',
        lockedStart: at(0, 10),
        lockedEnd: at(0, 11),
      ),
    ];
    final r = again(pinnedC, [meeting]);
    expect(r.diff.added, ['new']);
    final byId = {for (final m in r.diff.moved) m.taskId: m};
    expect(byId['a']!.reason, 'you put Dentist there');
  });

  test('deleted tasks are removed with a reason', () {
    final r = again(tasks.where((t) => t.id != 'c').toList(), [meeting]);
    expect(r.diff.removed, const [
      PlanRemoval(taskId: 'c', reason: 'no longer on your list'),
    ]);
  });

  test('schedulerProvider takes now from clockProvider', () {
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(FixedClock(now))],
    );
    addTearDown(container.dispose);
    final service = container.read(schedulerProvider);
    final p = service.plan(
      tasks: tasks,
      goals: const {},
      events: [meeting],
      prefs: prefsFixture,
      horizonEnd: horizonEnd,
    );
    expect(p, first());
  });
}
