import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

void main() {
  final now = at(0, 10); // Monday 10:00
  final endOfToday = at(1, 0); // Tuesday 00:00
  final endOfTomorrow = at(2, 0); // Wednesday 00:00

  group('rePlanHorizonEnd', () {
    test('no tasks: the rest of today', () {
      expect(
        rePlanHorizonEnd(now: now, tasks: const [], prefs: prefsFixture),
        endOfToday,
      );
    });

    test('every open task due today: stays within the day', () {
      final tasks = [
        task('a', due: at(0, 16)),
        task('b'), // no deadline
        task('c', due: at(0, 23, 59)),
      ];
      expect(
        rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
        endOfToday,
      );
    });

    test('one deadline tomorrow: horizon extends to end of tomorrow', () {
      final tasks = [
        task('a', due: at(0, 16)),
        task('b', due: at(1, 10)),
      ];
      expect(
        rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
        endOfTomorrow,
      );
    });

    test('latest deadline wins', () {
      final tasks = [
        task('a', due: at(1, 10)), // Tuesday
        task('b', due: at(3, 14)), // Thursday
        task('c', due: at(2, 9)), // Wednesday
      ];
      expect(
        rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
        at(4, 0), // end of Thursday
      );
    });

    test('a deadline past the week is clamped to the default horizon', () {
      final tasks = [task('a', due: at(20, 12))];
      expect(
        rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
        defaultHorizonEnd(now, prefsFixture),
      );
    });

    test('a pinned task\'s deadline does not push the horizon', () {
      final tasks = [
        task(
          'pinned-tomorrow',
          due: at(1, 10),
          lockedStart: at(0, 14),
          lockedEnd: at(0, 15),
        ),
      ];
      expect(
        rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
        endOfToday,
      );
    });

    test('a done task\'s deadline does not push the horizon', () {
      final tasks = [
        task('done-tomorrow', due: at(1, 10), status: TaskStatus.done),
        task('skipped-tomorrow', due: at(1, 10), status: TaskStatus.skipped),
      ];
      expect(
        rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
        endOfToday,
      );
    });

    test('a deadline earlier today does not shrink the horizon', () {
      final tasks = [task('a', due: at(0, 8))]; // before now
      expect(
        rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
        endOfToday,
      );
    });

    test(
      'a deadline at end-of-today does not extend past today',
      () {
        final tasks = [task('a', due: endOfToday)];
        expect(
          rePlanHorizonEnd(now: now, tasks: tasks, prefs: prefsFixture),
          endOfToday,
        );
      },
    );

    test('used as a horizon, the plan stays within the day', () {
      final tasks = [
        task('a', title: 'A', minutes: 30, due: at(0, 17)),
        task('b', title: 'B', minutes: 30, due: at(0, 17)),
      ];
      final horizon = rePlanHorizonEnd(
        now: now,
        tasks: tasks,
        prefs: prefsFixture,
      );
      final p = plan(
        tasks: tasks,
        goals: const {},
        events: const [],
        prefs: prefsFixture,
        now: now,
        horizonEnd: horizon,
      );
      expect(horizon, endOfToday);
      for (final placed in p.placed) {
        expect(placed.start.day, now.day);
        expect(placed.end.isAfter(endOfToday), isFalse);
      }
    });

    test(
      'with a tomorrow deadline the plan may spill into tomorrow',
      () {
        // Fixture day leaves ~5 hours after now=10:00 (lunch + cushion). Three
        // 2 h tasks don't all fit today, so one must land tomorrow.
        final tasks = [
          for (var i = 0; i < 3; i++)
            task('t$i', title: 'T$i', minutes: 120, due: at(1, 16)),
        ];
        final horizon = rePlanHorizonEnd(
          now: now,
          tasks: tasks,
          prefs: prefsFixture,
        );
        expect(horizon, endOfTomorrow);
        final p = plan(
          tasks: tasks,
          goals: const {},
          events: const [],
          prefs: prefsFixture,
          now: now,
          horizonEnd: horizon,
        );
        // At least one placement lands tomorrow now that the horizon allows
        // it; without this helper the planner would default to the week.
        expect(
          p.placed.any((pl) => pl.start.day == at(1, 0).day),
          isTrue,
          reason: 'expected at least one placement to spill to tomorrow',
        );
        for (final pl in p.placed) {
          expect(pl.end.isAfter(endOfTomorrow), isFalse);
        }
      },
    );
  });
}
