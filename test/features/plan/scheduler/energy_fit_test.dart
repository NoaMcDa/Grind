// Energy match, deadline slack, duration fit and the deep-block cap (#17).
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

/// [prefsFixture] without focus windows, buffers or cushion, so a test can
/// look at one rule at a time.
final _plain = prefsFixture.copyWith(
  deepWindows: const [],
  bufferBetweenEventsMinutes: 0,
  dailyCushionMinutes: 0,
);

Plan _day(
  List<Task> tasks, {
  Preferences? prefs,
  List<CalendarEvent> events = const [],
}) => plan(
  tasks: tasks,
  goals: const {},
  events: events,
  prefs: prefs ?? prefsFixture,
  now: at(0, 8),
  horizonEnd: at(1, 0),
);

void main() {
  group('duration fit', () {
    // Free: 09:00–10:00, 10:30–11:00, 13:00–17:00.
    final events = [
      event('a', at(0, 10), at(0, 10, 30)),
      event('b', at(0, 11), at(0, 12)),
    ];

    test('a short task fills the gap it fits instead of fragmenting a '
        'longer one', () {
      final r = _day(
        [task('quick', minutes: 30), task('hour', minutes: 60)],
        prefs: _plain,
        events: events,
      );
      expect(r.placed, [
        Placement(
          taskId: 'hour',
          start: at(0, 9),
          end: at(0, 10),
          reasons: const ['fills a 60-minute gap'],
        ),
        Placement(
          taskId: 'quick',
          start: at(0, 10, 30),
          end: at(0, 11),
          reasons: const ['fills a 30-minute gap'],
        ),
      ]);
    });

    test('without a snug gap the earliest fit wins', () {
      final r = _day([task('t', minutes: 20)], prefs: _plain);
      expect(r.placed.single.start, at(0, 9));
      expect(r.placed.single.reasons, const ['earliest free 20-minute gap']);
    });
  });

  group('energy match', () {
    test('deep work takes the focus window, light work keeps it clear', () {
      final r = _day([
        task('email', minutes: 30, due: at(0, 17)),
        task('thesis', minutes: 90, energy: Energy.deep),
      ]);
      final thesis = r.placementsFor('thesis').single;
      final email = r.placementsFor('email').single;
      expect(thesis.start, at(0, 9));
      expect(thesis.reasons, contains('your focus window'));
      expect(email.start, at(0, 13));
      expect(email.reasons, const [
        'due today',
        'keeps your focus window clear',
      ]);
    });

    test('with no deep work waiting, light work may use the window', () {
      final r = _day([task('email', minutes: 30)]);
      final email = r.placed.single;
      expect(email.start, at(0, 9));
      expect(email.reasons, isNot(contains('keeps your focus window clear')));
    });
  });

  group('deadline slack', () {
    test('the task due today goes first', () {
      final r = _day([
        task('later', minutes: 60, due: at(4, 17)),
        task('today', minutes: 60, due: at(0, 17)),
      ], prefs: _plain);
      expect(r.placementsFor('today').single.start, at(0, 9));
      expect(r.placementsFor('today').single.reasons.first, 'due today');
      expect(r.placementsFor('later').single.start, at(0, 10));
    });
  });

  group('max deep blocks per day', () {
    test('the cap holds and the extra deep task says why', () {
      final r = _day([
        task('d1', minutes: 60, energy: Energy.deep, priority: 1),
        task('d2', minutes: 60, energy: Energy.deep),
      ], prefs: prefsFixture.copyWith(maxDeepBlocksPerDay: 1));
      expect(r.placed.map((p) => p.taskId), ['d1']);
      expect(r.unplaced, const [
        UnplacedTask(
          taskId: 'd2',
          minutes: 60,
          reason: 'focus blocks are full today',
        ),
      ]);
    });
  });

  test('a one-day horizon words a miss as "today"', () {
    final r = _day([task('big', minutes: 600)]);
    expect(r.unplaced.single.reason, 'no free 600-minute slot today');
  });
}
