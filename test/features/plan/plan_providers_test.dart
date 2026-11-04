import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart'
    show importedCalendarEventIdFor;
import 'package:grind/features/plan/plan_providers.dart';

void main() {
  final t = DateTime.utc(2026, 10, 29, 10);
  CalendarEvent event(String id, {String? externalId}) => CalendarEvent(
    id: id,
    source: CalendarSource.google,
    externalId: externalId ?? id,
    title: 'E $id',
    start: t,
    end: t.add(const Duration(hours: 1)),
    createdAt: t,
    updatedAt: t,
  );
  Task task(String id, {String? calendarEventId}) => Task(
    id: id,
    title: 'T $id',
    calendarEventId: calendarEventId,
    createdAt: t,
    updatedAt: t,
  );

  group('eventsWithoutLinkedTasks', () {
    test('keeps every event when no task carries an imported sentinel', () {
      final events = [event('a'), event('b')];
      final result = eventsWithoutLinkedTasks(events, [
        task('t1'),
        task('t2', calendarEventId: 'plain-not-imported'),
      ]);
      expect(result.map((e) => e.id), ['a', 'b']);
    });

    test('drops an event whose externalId is linked to an imported task', () {
      final events = [event('a', externalId: 'ext-a'), event('b')];
      final tasks = [
        task('t1', calendarEventId: importedCalendarEventIdFor('ext-a')),
      ];
      final result = eventsWithoutLinkedTasks(events, tasks);
      expect(result.map((e) => e.id), ['b']);
    });

    test('ignores non-imported calendarEventId values (write-back links)', () {
      // The sync engine writes a task's real calendar event id into
      // Task.calendarEventId after push; those events must stay visible.
      final events = [event('a', externalId: 'ext-a')];
      final tasks = [task('t1', calendarEventId: 'ext-a')];
      final result = eventsWithoutLinkedTasks(events, tasks);
      expect(result.map((e) => e.id), ['a']);
    });
  });
}
