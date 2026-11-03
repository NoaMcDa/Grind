import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

// Exact expected placements. The scheduler is deterministic, so a changed
// expectation here means a changed rule: update it on purpose.
void main() {
  group('empty day (Monday)', () {
    final tasks = [
      task(
        'thesis-ch2',
        title: 'Thesis chapter 2',
        minutes: 90,
        energy: Energy.deep,
        due: at(2, 18),
        goalId: 'thesis',
      ),
      task('email', title: 'Email advisor', minutes: 30, due: at(0, 17)),
      task('dentist', title: 'Book dentist', minutes: 15),
    ];
    final result = plan(
      tasks: tasks,
      goals: goalsFixture,
      events: emptyDayEvents,
      prefs: prefsFixture,
      now: at(0, 8),
      horizonEnd: at(1, 0),
    );

    test('places deep work in the focus window, then the rest', () {
      expect(result.placed, [
        Placement(
          taskId: 'thesis-ch2',
          start: at(0, 9),
          end: at(0, 10, 30),
          reasons: const [
            'due Wednesday',
            'part of Thesis',
            'your focus window',
          ],
        ),
        Placement(
          taskId: 'email',
          start: at(0, 10, 30),
          end: at(0, 11),
          reasons: const ['due today'],
        ),
        Placement(
          taskId: 'dentist',
          start: at(0, 11),
          end: at(0, 11, 15),
          reasons: const ['earliest free 15-minute gap'],
        ),
      ]);
      expect(result.unplaced, isEmpty);
    });

    test('capacity: 09–12 and 13–16 free (cushion takes 16–17)', () {
      expect(result.capacity.freeMinutes, 360);
      expect(result.capacity.demandMinutes, 135);
      expect(result.capacity.deepCapacityMinutes, 180);
      expect(result.capacity.overbooked, isFalse);
      expect(result.capacity.days.single.demandMinutes, 135);
      expect(result.deferralSuggestions, isEmpty);
    });
  });

  group('meeting-heavy day (Tuesday)', () {
    final tasks = [
      task(
        'slides',
        title: 'Slides',
        minutes: 90,
        energy: Energy.deep,
        due: at(2, 0),
      ),
      task('expenses', title: 'Expenses', minutes: 15, due: at(1, 17)),
      task(
        'reading',
        title: 'Reading',
        minutes: 40,
        splittable: true,
        minChunk: 20,
      ),
    ];
    final result = plan(
      tasks: tasks,
      goals: goalsFixture,
      events: meetingHeavyEvents,
      prefs: prefsFixture,
      now: at(1, 8),
      horizonEnd: at(2, 0),
    );

    test('free slots are the three 20-minute gaps', () {
      expect(
        freeSlots(
          from: at(1, 8),
          to: at(2, 0),
          prefs: prefsFixture,
          events: meetingHeavyEvents,
          lockedTasks: const [],
        ),
        [
          Slot(at(1, 9), at(1, 9, 20)),
          Slot(at(1, 11, 40), at(1, 12)),
          Slot(at(1, 13), at(1, 13, 20)),
        ],
      );
    });

    test('splits the reading, keeps the focus gap, reports the slides', () {
      expect(result.placed, [
        Placement(
          taskId: 'reading',
          start: at(1, 9),
          end: at(1, 9, 20),
          reasons: const ['first 20 of 40 min'],
        ),
        Placement(
          taskId: 'reading',
          start: at(1, 11, 40),
          end: at(1, 12),
          reasons: const ['last 20 of 40 min'],
        ),
        Placement(
          taskId: 'expenses',
          start: at(1, 13),
          end: at(1, 13, 15),
          // Kept out of the 09:00 and 11:40 focus gaps for the slides.
          reasons: const [
            'due today',
            'keeps your focus window clear',
            'fills a 20-minute gap',
          ],
        ),
      ]);
      expect(result.unplaced, const [
        UnplacedTask(
          taskId: 'slides',
          minutes: 90,
          reason: "no free 90-minute slot before today's deadline",
        ),
      ]);
    });

    test('is overbooked and suggests moving the undated reading', () {
      expect(result.capacity.freeMinutes, 60);
      expect(result.capacity.demandMinutes, 145);
      expect(result.capacity.overbooked, isTrue);
      expect(result.deferralSuggestions, const [
        DeferralSuggestion(
          taskId: 'reading',
          minutes: 40,
          reason: 'no deadline, so next week works',
        ),
      ]);
    });
  });

  group('back-to-back week', () {
    final tasks = [
      task('report', title: 'Report', minutes: 120, due: at(4, 17)),
      task(
        'gym',
        title: 'Gym',
        minutes: 60,
        lockedStart: at(2, 18),
        lockedEnd: at(2, 19),
      ),
      task('course', title: 'PM course', minutes: 60, due: at(20, 0)),
      task('read', title: 'Read', minutes: 30),
    ];
    final result = plan(
      tasks: tasks,
      goals: goalsFixture,
      events: backToBackWeek,
      prefs: prefsFixture,
      now: at(0, 8),
    );

    test('only the locked task is placed, verbatim', () {
      expect(result.placed, [
        Placement(
          taskId: 'gym',
          start: at(2, 18),
          end: at(2, 19),
          reasons: const ['you placed this here'],
          locked: true,
        ),
      ]);
    });

    test('every other task is reported with a reason', () {
      expect(result.unplaced, const [
        UnplacedTask(
          taskId: 'report',
          minutes: 120,
          reason: 'no free 120-minute slot before the Friday deadline',
        ),
        UnplacedTask(
          taskId: 'read',
          minutes: 30,
          reason: 'no free 30-minute slot this week',
        ),
        UnplacedTask(
          taskId: 'course',
          minutes: 60,
          reason: 'no free 60-minute slot this week',
        ),
      ]);
    });

    test('defers only what is not due this week', () {
      expect(result.capacity.freeMinutes, 0);
      expect(result.capacity.overbooked, isTrue);
      expect(result.deferralSuggestions, const [
        DeferralSuggestion(
          taskId: 'course',
          minutes: 60,
          reason: 'not due until Nov 28',
        ),
        DeferralSuggestion(
          taskId: 'read',
          minutes: 30,
          reason: 'no deadline, so next week works',
        ),
      ]);
    });
  });

  test('acceptance: 2 events, 3 tasks, identical on every run', () {
    final events = [
      event('a', at(0, 9), at(0, 10)),
      event('b', at(0, 14), at(0, 15)),
    ];
    final tasks = [
      task('x', minutes: 45, due: at(0, 17)),
      task('y', minutes: 90, energy: Energy.deep, due: at(1, 17)),
      task('z', minutes: 20),
    ];
    Plan run() => plan(
      tasks: tasks,
      goals: const {},
      events: events,
      prefs: prefsFixture,
      now: at(0, 8),
    );
    final first = run();
    for (var i = 0; i < 20; i++) {
      expect(run(), first);
    }
    expect(first.unplaced, isEmpty);
    for (final p in first.placed) {
      expect(p.reasons, isNotEmpty);
    }
    expect(first.placed.map((p) => p.taskId).toSet(), {'x', 'y', 'z'});
  });

  test('default horizon: end of week or 7 days, whichever is later', () {
    expect(defaultHorizonEnd(at(0, 8), prefsFixture), at(7, 8));
    expect(
      defaultHorizonEnd(at(0, 8), prefsFixture.copyWith(weekStart: 7)),
      at(7, 8),
    );
  });
}
