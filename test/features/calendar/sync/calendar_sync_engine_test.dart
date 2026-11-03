import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';
import 'package:grind/features/calendar/sync/calendar_sync_errors.dart';
import 'package:grind/features/calendar/sync/sync_status.dart';

/// [FakeCalendarProvider] that behaves like a real calendar: written-back
/// events show up in later fetches, and the test can move or delete them
/// "in the external calendar".
class LiveFakeProvider extends FakeCalendarProvider {
  LiveFakeProvider({List<ExternalCalendar>? calendars})
    : calendars =
          calendars ??
          const [ExternalCalendar(id: 'primary', name: 'Me', isPrimary: true)],
      super(CalendarSource.google, events: []) {
    connected = true;
  }

  final List<ExternalCalendar> calendars;
  final List<List<String>> fetchedIds = [];
  final List<String> calls = [];
  Object? failWith;

  /// Like the real providers: only events of the asked-for calendars.
  bool onlyFetchCalendars = false;

  @override
  Future<List<ExternalCalendar>> listCalendars() async => calendars;

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async {
    if (failWith != null) throw failWith!;
    fetchedIds.add(calendarIds);
    final all = await super.fetchEvents(
      calendarIds: calendarIds,
      from: from,
      to: to,
    );
    return onlyFetchCalendars
        ? all.where((e) => calendarIds.contains(e.calendarId)).toList()
        : all;
  }

  @override
  Future<String> createEvent({
    required String calendarId,
    required Task task,
  }) async {
    final id = await super.createEvent(calendarId: calendarId, task: task);
    calls.add('create $calendarId ${task.id}');
    events.add(_fromTask(id, calendarId, task));
    return id;
  }

  @override
  Future<void> updateEvent({
    required String calendarId,
    required String externalId,
    required Task task,
  }) async {
    calls.add('update $calendarId $externalId');
    final i = events.indexWhere((e) => e.externalId == externalId);
    events[i] = _fromTask(externalId, calendarId, task);
  }

  @override
  Future<void> deleteEvent({
    required String calendarId,
    required String externalId,
  }) async {
    calls.add('delete $calendarId $externalId');
    events.removeWhere((e) => e.externalId == externalId);
  }

  CalendarEvent _fromTask(String id, String calendarId, Task t) =>
      CalendarEvent(
        id: 'p-$id',
        source: source,
        externalId: id,
        calendarId: calendarId,
        title: t.title,
        start: t.scheduledStart!,
        end: t.scheduledEnd!,
        taskId: t.id,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  /// Someone dragged the event in Google.
  void moveExternally(String externalId, DateTime start, DateTime end) {
    final i = events.indexWhere((e) => e.externalId == externalId);
    events[i] = events[i].copyWith(start: start, end: end);
  }
}

final now = DateTime.utc(2026, 11, 3, 8);
DateTime at(int day, int hour) => DateTime.utc(2026, 11, day, hour);

CalendarEvent meeting(String ext, int day, int hour, {String title = 'Sync'}) =>
    CalendarEvent(
      id: 'ext-$ext',
      source: CalendarSource.google,
      externalId: ext,
      calendarId: 'primary',
      title: title,
      start: at(day, hour),
      end: at(day, hour + 1),
      createdAt: now,
      updatedAt: now,
    );

Task task(String id, {int? day, int hour = 14, String title = 'Write intro'}) =>
    Task(
      id: id,
      title: title,
      scheduledStart: day == null ? null : at(day, hour),
      scheduledEnd: day == null ? null : at(day, hour + 1),
      createdAt: now,
      updatedAt: now,
    );

void main() {
  late LiveFakeProvider provider;
  late InMemoryCalendarRepository calendars;
  late InMemoryTaskRepository tasks;
  late InMemoryPreferencesRepository prefs;
  late CalendarSyncEngine engine;

  CalendarSyncEngine build({bool writeBack = true}) => CalendarSyncEngine(
    provider: provider,
    calendarRepository: calendars,
    taskRepository: tasks,
    preferencesRepository: prefs,
    clock: FixedClock(now),
    writeBack: writeBack,
  );

  setUp(() {
    provider = LiveFakeProvider();
    calendars = InMemoryCalendarRepository();
    tasks = InMemoryTaskRepository();
    prefs = InMemoryPreferencesRepository();
    engine = build();
  });

  Future<List<CalendarEvent>> mirrored() => calendars.getBetween(
    at(1, 0).subtract(const Duration(days: 30)),
    at(30, 0).add(const Duration(days: 60)),
  );

  group('window', () {
    test('is past 7 days to next 30 days', () {
      final w = engine.window();
      expect(w.from, DateTime.utc(2026, 10, 27));
      expect(w.to, DateTime.utc(2026, 12, 4));
    });
  });

  group('pull', () {
    test('mirrors events and keeps the local id on later pulls', () async {
      provider.events.add(meeting('a', 4, 10));
      final first = await engine.pull();
      expect(first.upserted.single.externalId, 'a');
      final local = await calendars.getByExternalId(CalendarSource.google, 'a');
      expect(local!.title, 'Sync');

      provider.events[0] = provider.events[0].copyWith(
        title: 'Sync (moved room)',
      );
      final second = await engine.pull();
      expect(second.upserted.single.id, local.id);
      expect((await mirrored()).single.title, 'Sync (moved room)');
    });

    test('keeps the provider htmlLink and backfills it later', () async {
      provider.events.add(meeting('a', 4, 10));
      await engine.pull();
      expect((await mirrored()).single.htmlLink, isNull);
      provider.events[0] = provider.events[0].copyWith(
        htmlLink: 'https://www.google.com/calendar/event?eid=a',
      );
      final again = await engine.pull();
      expect(again.upserted, hasLength(1));
      expect(
        (await mirrored()).single.htmlLink,
        'https://www.google.com/calendar/event?eid=a',
      );
    });

    test('unchanged events are not rewritten', () async {
      provider.events.add(meeting('a', 4, 10));
      await engine.pull();
      final again = await engine.pull();
      expect(again.upserted, isEmpty);
    });

    test('soft-deletes events that vanished from the window', () async {
      provider.events.addAll([meeting('a', 4, 10), meeting('b', 5, 10)]);
      await engine.pull();
      provider.events.removeWhere((e) => e.externalId == 'a');
      final result = await engine.pull();
      expect(result.removed.map((e) => e.externalId), ['a']);
      expect((await mirrored()).map((e) => e.externalId), ['b']);
    });

    test('does not touch events of other sources', () async {
      await calendars.upsert(
        meeting('x', 4, 9).copyWithSource(CalendarSource.apple),
      );
      await engine.pull();
      expect((await mirrored()).single.source, CalendarSource.apple);
    });

    test('reads the primary calendar when the user never chose', () async {
      provider = LiveFakeProvider(
        calendars: const [
          ExternalCalendar(id: 'work', name: 'Work'),
          ExternalCalendar(id: 'me@x', name: 'Me', isPrimary: true),
        ],
      );
      engine = build();
      await engine.pull();
      expect(provider.fetchedIds.single, ['me@x']);
    });

    test('honours selectedCalendarIds for the source', () async {
      await prefs.save(
        const Preferences(
          selectedCalendarIds: {
            CalendarSource.google: ['a', 'b'],
            CalendarSource.apple: ['z'],
          },
        ),
      );
      await engine.pull();
      expect(provider.fetchedIds.single, ['a', 'b']);
    });

    test('an empty selection reads nothing and clears the mirror', () async {
      provider.events.add(meeting('a', 4, 10));
      await engine.pull();
      await prefs.save(
        const Preferences(selectedCalendarIds: {CalendarSource.google: []}),
      );
      await engine.pull();
      expect(provider.fetchedIds, hasLength(1));
      expect(await mirrored(), isEmpty);
    });
  });

  group('pushTask', () {
    test('creates the write-back and links both sides', () async {
      final t = task('t1', day: 4);
      await tasks.upsert(t);
      final pushed = await engine.pushTask(t);

      expect(provider.calls, ['create primary t1']);
      expect(pushed.calendarEventId, 'fake-1');
      expect((await tasks.getById('t1'))!.calendarEventId, 'fake-1');
      final e = await calendars.getByExternalId(
        CalendarSource.google,
        'fake-1',
      );
      expect(e!.taskId, 't1');
      expect(e.start, at(4, 14));
      expect(e.calendarId, 'primary');
    });

    test('does nothing for an unscheduled task', () async {
      final t = task('t1');
      await tasks.upsert(t);
      expect(await engine.pushTask(t), same(t));
      expect(provider.calls, isEmpty);
    });

    test('updates when the task moved in Grind, skips when in sync', () async {
      await tasks.upsert(task('t1', day: 4));
      var t = await engine.pushTask((await tasks.getById('t1'))!);
      await engine.pushTask(t);
      expect(provider.calls, ['create primary t1']);

      t = t.copyWith(scheduledStart: at(4, 16), scheduledEnd: at(4, 17));
      await tasks.upsert(t);
      await engine.pushTask(t);
      expect(provider.calls.last, 'update primary fake-1');
      expect(provider.events.single.start, at(4, 16));
    });

    test('deletes the event when the task is unscheduled', () async {
      await tasks.upsert(task('t1', day: 4));
      var t = await engine.pushTask((await tasks.getById('t1'))!);
      t = t.copyWith(scheduledStart: null, scheduledEnd: null);
      final out = await engine.pushTask(t);
      expect(provider.calls.last, 'delete primary fake-1');
      expect(out.calendarEventId, isNull);
      expect(provider.events, isEmpty);
      expect(await mirrored(), isEmpty);
    });

    test('recreates the event when the provider lost it', () async {
      final missing = _MissingOnUpdate();
      provider = missing;
      engine = build();
      await tasks.upsert(task('t1', day: 4));
      var t = await engine.pushTask((await tasks.getById('t1'))!);
      t = t.copyWith(scheduledStart: at(5, 9), scheduledEnd: at(5, 10));
      final out = await engine.pushTask(t);
      expect(out.calendarEventId, 'fake-2');
    });

    test(
      'writes to the first writable calendar when primary is read-only',
      () async {
        provider = LiveFakeProvider(
          calendars: const [
            ExternalCalendar(
              id: 'shared',
              name: 'Shared',
              isPrimary: true,
              canWrite: false,
            ),
            ExternalCalendar(id: 'mine', name: 'Mine'),
          ],
        );
        engine = build();
        await engine.pushTask(task('t1', day: 4));
        expect(provider.calls.single, 'create mine t1');
      },
    );

    test('is off when writeBack is false', () async {
      engine = build(writeBack: false);
      await engine.pushTask(task('t1', day: 4));
      expect(provider.calls, isEmpty);
    });
  });

  group('pullWriteBacks (calendar wins for time)', () {
    Future<Task> linked() async {
      await tasks.upsert(task('t1', day: 4));
      return engine.pushTask((await tasks.getById('t1'))!);
    }

    test('an event moved in the calendar moves and pins the task', () async {
      await linked();
      await engine.pull();
      provider.moveExternally('fake-1', at(6, 9), at(6, 11));

      final result = await engine.pull();
      expect(result.moved.single.externalId, 'fake-1');
      final changed = await engine.pullWriteBacks();

      final t = (await tasks.getById('t1'))!;
      expect(changed.single.id, 't1');
      expect(t.scheduledStart, at(6, 9));
      expect(t.scheduledEnd, at(6, 11));
      expect(t.lockedStart, isTrue);
      expect(t.calendarEventId, 'fake-1');
    });

    test('an event deleted in the calendar unschedules the task', () async {
      await linked();
      provider.events.clear();
      await engine.pull();
      await engine.pullWriteBacks();

      final t = (await tasks.getById('t1'))!;
      expect(t.isScheduled, isFalse);
      expect(t.calendarEventId, isNull);
      expect(t.status, TaskStatus.open);
    });

    test('a Grind-side move is pushed, not undone by the stale copy', () async {
      final t = await linked();
      await engine.sync();
      await tasks.upsert(
        t.copyWith(scheduledStart: at(7, 10), scheduledEnd: at(7, 11)),
      );
      await engine.sync();
      expect((await tasks.getById('t1'))!.scheduledStart, at(7, 10));
      expect(provider.events.single.start, at(7, 10));
    });

    test('app wins for task fields while the calendar wins for time', () async {
      final t = await linked();
      await engine.sync();
      provider.moveExternally('fake-1', at(8, 9), at(8, 10));
      await tasks.upsert(t.copyWith(title: 'Write the intro, for real'));
      await engine.sync();

      final after = (await tasks.getById('t1'))!;
      expect(after.title, 'Write the intro, for real');
      expect(after.scheduledStart, at(8, 9));
      final event = provider.events.single;
      expect(event.title, 'Write the intro, for real');
      expect(event.start, at(8, 9));
    });
  });

  group('sync', () {
    test('a write-back in an unselected calendar is not mistaken for a '
        'deletion', () async {
      // Only "work" is read, but write-backs go to the primary calendar.
      provider = LiveFakeProvider(
        calendars: const [
          ExternalCalendar(id: 'primary', name: 'Me', isPrimary: true),
          ExternalCalendar(id: 'work', name: 'Work'),
        ],
      )..onlyFetchCalendars = true;
      prefs = InMemoryPreferencesRepository(
        const Preferences(
          selectedCalendarIds: {
            CalendarSource.google: ['work'],
          },
        ),
      );
      engine = build();
      await tasks.upsert(task('t1', day: 4));
      await engine.sync();
      await engine.sync();
      await engine.sync();
      expect(provider.calls, ['create primary t1'], reason: 'no duplicates');
      final t = (await tasks.getById('t1'))!;
      expect(t.calendarEventId, 'fake-1');
      expect(t.isScheduled, isTrue);
    });

    test(
      'creates write-backs for scheduled open tasks in the window',
      () async {
        await tasks.upsertAll([
          task('in', day: 10),
          task('later', day: 30).copyWith(
            scheduledStart: DateTime.utc(2027, 2, 1, 9),
            scheduledEnd: DateTime.utc(2027, 2, 1, 10),
          ),
          task('done', day: 5).copyWith(status: TaskStatus.done),
          task('loose'),
        ]);
        await engine.sync();
        expect(provider.calls, ['create primary in']);
        expect(engine.status, SyncStatus.idle(lastSyncedAt: now));
      },
    );

    test('deletes write-backs of tasks deleted in Grind', () async {
      await tasks.upsert(task('t1', day: 4));
      await engine.sync();
      await tasks.delete('t1');
      await engine.sync();
      expect(provider.calls.last, 'delete primary fake-1');
      expect(provider.events, isEmpty);
    });

    test('a skipped task loses its event', () async {
      await tasks.upsert(task('t1', day: 4));
      await engine.sync();
      final t = (await tasks.getById('t1'))!;
      await tasks.upsert(t.copyWith(status: TaskStatus.skipped));
      await engine.sync();
      expect(provider.events, isEmpty);
      expect((await tasks.getById('t1'))!.calendarEventId, isNull);
    });

    test('disconnected: clears the mirror and stays idle', () async {
      provider.events.add(meeting('a', 4, 10));
      await engine.sync();
      expect(await mirrored(), hasLength(1));
      provider.connected = false;
      await engine.sync();
      expect(await mirrored(), isEmpty);
      expect(engine.status.phase, SyncPhase.idle);
    });

    test('emits syncing then idle', () async {
      final seen = <SyncPhase>[];
      final sub = engine.watchStatus().listen((s) => seen.add(s.phase));
      await Future<void>.delayed(Duration.zero);
      await engine.sync();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen, [SyncPhase.idle, SyncPhase.syncing, SyncPhase.idle]);
    });

    test('an unexpected error becomes a friendly message', () async {
      provider.failWith = StateError('boom');
      await engine.sync();
      expect(engine.status.phase, SyncPhase.error);
      expect(engine.status.error, SyncErrorKind.generic);
    });

    test('an auth error asks to reconnect', () async {
      provider.failWith = const CalendarAuthException('revoked');
      await engine.sync();
      expect(engine.status.error, SyncErrorKind.reconnect);
    });

    test('concurrent calls share one run', () async {
      final a = engine.sync();
      final b = engine.sync();
      await Future.wait([a, b]);
      expect(provider.fetchedIds, hasLength(1));
    });
  });
}

class _MissingOnUpdate extends LiveFakeProvider {
  @override
  Future<void> updateEvent({
    required String calendarId,
    required String externalId,
    required Task task,
  }) async => throw const ExternalEventMissingException('gone');
}

extension on CalendarEvent {
  CalendarEvent copyWithSource(CalendarSource s) => CalendarEvent(
    id: 'other-$externalId',
    source: s,
    externalId: externalId,
    title: title,
    start: start,
    end: end,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
