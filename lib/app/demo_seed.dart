import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';

/// The tasks the prototype screens used to hard-code, placed on [day]
/// (local midnight). Titles, times and copy match the mockup.
List<Task> demoTasks(DateTime day) {
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  final created = at(0, 0).toUtc();
  var n = 0;
  Task task(
    String id,
    String title, {
    required String category,
    Energy energy = Energy.light,
    int priority = 2,
    String? firstAction,
    DateTime? start,
    DateTime? end,
    DateTime? remindAt,
    bool done = false,
  }) {
    final c = created.add(Duration(minutes: n++));
    return Task(
      id: id,
      title: title,
      category: category,
      energy: energy,
      priority: priority,
      firstAction: firstAction,
      scheduledStart: start?.toUtc(),
      scheduledEnd: end?.toUtc(),
      remindAt: remindAt?.toUtc(),
      status: done ? TaskStatus.done : TaskStatus.open,
      completedAt: done ? c : null,
      createdAt: c,
      updatedAt: c,
    );
  }

  return [
    task(
      'thesis',
      'Thesis: write related-work section',
      category: 'deep',
      energy: Energy.deep,
      priority: 1,
      start: at(8, 0),
      end: at(9, 30),
      done: true,
    ),
    task(
      'lunch',
      'Lunch break',
      category: 'break',
      start: at(12, 0),
      end: at(12, 30),
      done: true,
    ),
    task(
      'lab',
      'Deep learning lab 4',
      category: 'deep',
      energy: Energy.deep,
      firstAction: 'If lunch is over, then open the notebook',
      start: at(12, 30),
      end: at(13, 15),
      remindAt: at(12, 30),
    ),
    task(
      'papers',
      'Read 2 papers',
      category: 'light',
      firstAction: 'If you get to the library, then start with the shorter one',
      start: at(16, 0),
      end: at(16, 45),
      remindAt: at(16, 0),
    ),
    task(
      'gym',
      'Gym',
      category: 'move',
      firstAction: 'If it is 17:00, then pack your bag',
      start: at(17, 15),
      end: at(18, 0),
      remindAt: at(17, 15),
    ),
    task(
      'mom',
      'Call mom',
      category: 'social',
      firstAction: 'If dinner is done, then call',
      remindAt: at(19, 30),
      done: true,
    ),
  ];
}

/// The two calendar events the Plan screen used to hard-code.
List<CalendarEvent> demoEvents(DateTime day) {
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  final created = at(0, 0).toUtc();
  CalendarEvent event(String id, String title, DateTime s, DateTime e) =>
      CalendarEvent(
        id: id,
        source: CalendarSource.local,
        externalId: id,
        title: title,
        start: s.toUtc(),
        end: e.toUtc(),
        createdAt: created,
        updatedAt: created,
      );
  return [
    event('lecture-cv', 'Lecture: Computer Vision', at(10, 0), at(11, 30)),
    event('seminar', 'Seminar with supervisor', at(14, 0), at(15, 30)),
  ];
}

/// Overrides that fill the in-memory repositories with the demo day (the day
/// of [clock]). Pass to `GrindApp(overrides: ...)` until the real database
/// lands.
List<Override> demoOverrides({Clock clock = const SystemClock()}) {
  final now = clock.now();
  final day = DateTime(now.year, now.month, now.day);
  return [
    clockProvider.overrideWithValue(clock),
    taskRepositoryProvider.overrideWithValue(
      InMemoryTaskRepository(demoTasks(day)),
    ),
    calendarRepositoryProvider.overrideWithValue(
      InMemoryCalendarRepository(demoEvents(day)),
    ),
  ];
}
