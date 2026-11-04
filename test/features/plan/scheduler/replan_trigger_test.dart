import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

void main() {
  // One typical morning: a meeting, a pin, a few open tasks.
  final now = at(0, 8);
  final horizonEnd = at(1, 0);
  final meeting = event('m', at(0, 13), at(0, 14), title: 'Team sync');
  final baseline = [
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

  Plan baselinePlan() => plan(
    tasks: baseline,
    goals: const {},
    events: [meeting],
    prefs: prefsFixture,
    now: now,
    horizonEnd: horizonEnd,
  );

  group('nothing changed', () {
    test('no reason to nudge the user', () {
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: baseline,
        events: [meeting],
        previousEvents: [meeting],
        now: now,
      );
      expect(trigger, ReplanTrigger.none);
      expect(trigger.needed, isFalse);
      expect(trigger.summary, isEmpty);
    });
  });

  group('task closed', () {
    test('skipping an upcoming task triggers a re-plan', () {
      final skipped = [
        for (final t in baseline)
          t.id == 'a' ? t.copyWith(status: TaskStatus.skipped) : t,
      ];
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: skipped,
        events: [meeting],
        previousEvents: [meeting],
        now: now,
      );
      expect(trigger.reason, ReplanReason.taskSkipped);
      expect(trigger.taskId, 'a');
      expect(trigger.summary, 'you skipped Essay outline');
      expect(trigger.needed, isTrue);
    });

    test('a task finished long after its block triggers "done late"', () {
      // Plan: `a` runs 9:30 – 10:30 (after the pin). Close it at 11:30.
      final overran = [
        for (final t in baseline)
          t.id == 'a'
              ? t.copyWith(status: TaskStatus.done, completedAt: at(0, 11, 30))
              : t,
      ];
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: overran,
        events: [meeting],
        previousEvents: [meeting],
        now: at(0, 11, 30),
      );
      expect(trigger.reason, ReplanReason.taskDoneLate);
      expect(trigger.taskId, 'a');
      expect(trigger.summary, 'Essay outline ran 1h over');
    });

    test('closing one minute late is forgiven', () {
      final done = [
        for (final t in baseline)
          t.id == 'a'
              ? t.copyWith(status: TaskStatus.done, completedAt: at(0, 10, 31))
              : t,
      ];
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: done,
        events: [meeting],
        previousEvents: [meeting],
        now: at(0, 10, 31),
      );
      expect(trigger.reason, ReplanReason.none);
    });
  });

  group('task overrun', () {
    test('an open task whose block ended ago still fires', () {
      // `a` is 9:30–10:30 in the baseline plan. At 10:46 it is 16 min over.
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: baseline,
        events: [meeting],
        previousEvents: [meeting],
        now: at(0, 10, 46),
      );
      expect(trigger.reason, ReplanReason.taskOverrun);
      expect(trigger.taskId, 'a');
      expect(trigger.summary, 'Essay outline ran 16 min over');
    });

    test('a pinned task is never flagged as overrunning', () {
      final trigger = replanTrigger(
        previous: baselinePlan(),
        // Keep only the pin to isolate the rule.
        tasks: baseline.where((t) => t.id == 'pinned').toList(),
        events: [meeting],
        previousEvents: [meeting],
        now: at(0, 11),
      );
      expect(trigger.reason, ReplanReason.none);
    });
  });

  group('calendar changes', () {
    test('a new busy event over a placement fires', () {
      // `a` lives at 9:30–10:30 in the baseline; drop a meeting on it.
      final dentist = event('dentist', at(0, 10), at(0, 11), title: 'Dentist');
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: baseline,
        events: [meeting, dentist],
        previousEvents: [meeting],
        now: now,
      );
      expect(trigger.reason, ReplanReason.calendarEventAdded);
      expect(trigger.eventId, 'dentist');
      expect(trigger.summary, 'Dentist lands at 10:00');
    });

    test('an existing event moved onto a placement fires "moved"', () {
      // Shift the team sync to 10:00–11:00: it clashes with `a`'s slot.
      final shifted = meeting.copyWith(start: at(0, 10), end: at(0, 11));
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: baseline,
        events: [shifted],
        previousEvents: [meeting],
        now: now,
      );
      expect(trigger.reason, ReplanReason.calendarEventMoved);
      expect(trigger.eventId, 'm');
      expect(trigger.summary, 'Team sync moved to 10:00');
    });

    test('a non-busy ("free") event never triggers', () {
      final transparent = event(
        'free',
        at(0, 10),
        at(0, 11),
        title: 'Coffee',
        busy: false,
      );
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: baseline,
        events: [meeting, transparent],
        previousEvents: [meeting],
        now: now,
      );
      expect(trigger.reason, ReplanReason.none);
    });

    test('an event added past every placement does not trigger', () {
      final late = event('late', at(0, 16, 30), at(0, 17), title: 'Debrief');
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: baseline,
        events: [meeting, late],
        previousEvents: [meeting],
        now: now,
      );
      expect(trigger.reason, ReplanReason.none);
    });

    test('a removed event never triggers on its own', () {
      final trigger = replanTrigger(
        previous: baselinePlan(),
        tasks: baseline,
        events: const [],
        previousEvents: [meeting],
        now: now,
      );
      expect(trigger.reason, ReplanReason.none);
    });
  });

  test('priority: a skipped task wins over a shifted meeting', () {
    final skipped = [
      for (final t in baseline)
        t.id == 'a' ? t.copyWith(status: TaskStatus.skipped) : t,
    ];
    final shifted = meeting.copyWith(start: at(0, 10), end: at(0, 11));
    final trigger = replanTrigger(
      previous: baselinePlan(),
      tasks: skipped,
      events: [shifted],
      previousEvents: [meeting],
      now: now,
    );
    expect(trigger.reason, ReplanReason.taskSkipped);
  });

  test('determinism: same inputs give the same ReplanTrigger', () {
    final dentist = event('dentist', at(0, 10), at(0, 11), title: 'Dentist');
    final a = replanTrigger(
      previous: baselinePlan(),
      tasks: baseline,
      events: [meeting, dentist],
      previousEvents: [meeting],
      now: now,
    );
    final b = replanTrigger(
      previous: baselinePlan(),
      tasks: baseline,
      events: [meeting, dentist],
      previousEvents: [meeting],
      now: now,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
