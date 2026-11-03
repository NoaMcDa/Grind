import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

void main() {
  final bare = prefsFixture.copyWith(
    lunch: const [],
    bufferBetweenEventsMinutes: 0,
    dailyCushionMinutes: 0,
  );

  List<Slot> slots(
    Preferences prefs, {
    List<CalendarEvent> events = const [],
    List<Task> locked = const [],
    DateTime? from,
    DateTime? to,
  }) => freeSlots(
    from: from ?? at(0, 0),
    to: to ?? at(1, 0),
    prefs: prefs,
    events: events,
    lockedTasks: locked,
  );

  test('working hours on an empty day', () {
    expect(slots(bare), [Slot(at(0, 9), at(0, 17))]);
  });

  test('a day off has no slots', () {
    expect(slots(bare, from: at(5, 0), to: at(6, 0)), isEmpty); // Saturday
  });

  test('lunch and the cushion come out; cushion from the end', () {
    expect(slots(prefsFixture), [
      Slot(at(0, 9), at(0, 12)),
      Slot(at(0, 13), at(0, 16)),
    ]);
  });

  test('cushion spills into earlier slots when the last one is short', () {
    final p = bare.copyWith(dailyCushionMinutes: 60);
    final events = [event('e', at(0, 16), at(0, 16, 30))];
    // Free 09–16 and 16:30–17; the cushion takes 16:30–17 and 15:30–16.
    expect(slots(p, events: events), [Slot(at(0, 9), at(0, 15, 30))]);
  });

  test('busy events are merged and padded; free events are ignored', () {
    final p = bare.copyWith(bufferBetweenEventsMinutes: 10);
    final events = [
      event('a', at(0, 10), at(0, 11)),
      event('b', at(0, 10, 30), at(0, 11, 30)),
      event('free', at(0, 14), at(0, 15), busy: false),
    ];
    expect(slots(p, events: events), [
      Slot(at(0, 9), at(0, 9, 50)),
      Slot(at(0, 11, 40), at(0, 17)),
    ]);
  });

  test('deleted events and task write-backs do not block', () {
    final events = [
      event('gone', at(0, 10), at(0, 11)).copyWith(deletedAt: at(0, 7)),
      event('copy', at(0, 12), at(0, 13)).copyWith(taskId: 'x'),
    ];
    expect(slots(bare, events: events), [Slot(at(0, 9), at(0, 17))]);
  });

  test('locked tasks are subtracted, without buffers', () {
    final p = bare.copyWith(bufferBetweenEventsMinutes: 10);
    final locked = [task('l', lockedStart: at(0, 10), lockedEnd: at(0, 11))];
    expect(slots(p, locked: locked), [
      Slot(at(0, 9), at(0, 10)),
      Slot(at(0, 11), at(0, 17)),
    ]);
  });

  test('gaps under 15 minutes are dropped', () {
    final events = [
      event('a', at(0, 9, 10), at(0, 12)),
      event('b', at(0, 12, 14), at(0, 17)),
    ];
    expect(slots(bare, events: events), isEmpty);
  });

  test('clipped to [from, to); the cushion stays at the end of the day', () {
    final p = bare.copyWith(dailyCushionMinutes: 60);
    expect(slots(p, from: at(0, 14, 20)), [Slot(at(0, 14, 20), at(0, 16))]);
    expect(slots(p, from: at(0, 15, 50)), isEmpty);
  });

  test('an overnight event blocks both days', () {
    final events = [event('trip', at(0, 15), at(1, 11))];
    expect(slots(bare, events: events, to: at(2, 0)), [
      Slot(at(0, 9), at(0, 15)),
      Slot(at(1, 11), at(1, 17)),
    ]);
  });

  test('slots are sorted across days', () {
    final s = slots(prefsFixture, to: at(5, 0));
    expect(s.length, 10);
    for (var i = 1; i < s.length; i++) {
      expect(s[i].start.isAfter(s[i - 1].end), isTrue);
    }
  });
}
