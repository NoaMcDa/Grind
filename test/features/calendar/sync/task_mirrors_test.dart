import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';
import 'package:grind/features/calendar/sync/task_mirrors.dart';

final _c = DateTime.utc(2026);

CalendarEvent _event(String ext, {String? taskId}) => CalendarEvent(
  id: 'google:$ext',
  source: CalendarSource.google,
  externalId: ext,
  title: ext,
  start: DateTime.utc(2026, 11, 4, 10),
  end: DateTime.utc(2026, 11, 4, 11),
  taskId: taskId,
  createdAt: _c,
  updatedAt: _c,
);

Task _task(String id, {String? calendarEventId, DateTime? deletedAt}) => Task(
  id: id,
  title: id,
  scheduledStart: DateTime.utc(2026, 11, 4, 10),
  scheduledEnd: DateTime.utc(2026, 11, 4, 11),
  calendarEventId: calendarEventId,
  createdAt: _c,
  updatedAt: _c,
  deletedAt: deletedAt,
);

void main() {
  test('a write-back (event with taskId) is a task mirror', () {
    final kept = withoutTaskMirrors(
      [_event('plain'), _event('wb', taskId: 't1')],
      [_task('t1', calendarEventId: 'wb')],
    );
    expect(kept.map((e) => e.externalId), ['plain']);
  });

  test('an event a live task was created from is a task mirror', () {
    final sentinel = importedCalendarEventIdFor('lesson');
    final kept = withoutTaskMirrors(
      [_event('plain'), _event('lesson')],
      [_task('t1', calendarEventId: sentinel)],
    );
    expect(kept.map((e) => e.externalId), ['plain']);
  });

  test('an imported event comes back once its task is deleted', () {
    final sentinel = importedCalendarEventIdFor('lesson');
    final kept = withoutTaskMirrors(
      [_event('lesson')],
      [_task('t1', calendarEventId: sentinel, deletedAt: _c)],
    );
    expect(kept.map((e) => e.externalId), ['lesson']);
  });

  test('a plain calendarEventId (write-back) does not hide a same-id event '
      'through the import path alone', () {
    // The write-back is hidden by its own taskId, not by the task's id.
    expect(importedExternalIds([_task('t1', calendarEventId: 'wb')]), isEmpty);
    expect(isTaskMirror(_event('wb'), const {}), isFalse);
  });
}
