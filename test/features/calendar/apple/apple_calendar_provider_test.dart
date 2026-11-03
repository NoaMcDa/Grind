import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/apple/apple_calendar.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';

final _now = DateTime.utc(2026, 11, 3, 8);
int _ms(DateTime d) => d.millisecondsSinceEpoch;

Task _task({String id = 't1', String? notes, bool scheduled = true}) => Task(
  id: id,
  title: 'Write thesis intro',
  notes: notes,
  scheduledStart: scheduled ? DateTime.utc(2026, 11, 3, 10) : null,
  scheduledEnd: scheduled ? DateTime.utc(2026, 11, 3, 11) : null,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  late FakeAppleCalendarChannel channel;

  AppleCalendarProvider make({bool supported = true}) => AppleCalendarProvider(
    channel: channel,
    clock: FixedClock(_now),
    isSupported: supported,
  );

  setUp(() {
    channel = FakeAppleCalendarChannel(
      calendars: const [
        AppleCalendarInfo(id: 'home', title: 'Home', isPrimary: true),
        AppleCalendarInfo(
          id: 'holidays',
          title: 'Holidays',
          allowsContentModifications: false,
        ),
      ],
    );
  });

  group('connect', () {
    test('granted: asks for full access once, then is connected', () async {
      final provider = make();
      expect(await provider.isConnected(), isFalse);
      expect(await provider.connect(), isTrue);
      expect(channel.requests, [AppleCalendarMethods.requestFullAccess]);
      expect(await provider.isConnected(), isTrue);

      expect(await provider.connect(), isTrue);
      expect(channel.requests, hasLength(1), reason: 'no second prompt');
    });

    test('denied at the prompt: false, app keeps working', () async {
      channel.answerToPrompt = false;
      final provider = make();
      expect(await provider.connect(), isFalse);
      expect(await provider.status(), AppleAuthStatus.denied);
      expect(await provider.isConnected(), isFalse);
      expect(await provider.listCalendars(), isEmpty);
      expect(
        await provider.fetchEvents(
          calendarIds: ['home'],
          from: _now,
          to: _now.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
    });

    test('denied earlier: no prompt (iOS will not show one)', () async {
      channel.status = AppleAuthStatus.denied;
      expect(await make().connect(), isFalse);
      expect(channel.requests, isEmpty);
    });

    test('restricted: no prompt, false', () async {
      channel.status = AppleAuthStatus.restricted;
      final provider = make();
      expect(await provider.connect(), isFalse);
      expect(await provider.connectWriteOnly(), isFalse);
      expect(channel.requests, isEmpty);
    });

    test('write-only: connects without read access', () async {
      final provider = make();
      expect(await provider.connectWriteOnly(), isTrue);
      expect(channel.requests, [AppleCalendarMethods.requestWriteOnlyAccess]);
      expect(await provider.isConnected(), isTrue);
      expect(await provider.listCalendars(), isEmpty);
      final id = await provider.createEvent(calendarId: '', task: _task());
      expect(channel.events.single.eventIdentifier, id);
    });

    test('write-only then connect asks to upgrade to full access', () async {
      channel.status = AppleAuthStatus.writeOnly;
      final provider = make();
      expect(await provider.connect(), isTrue);
      expect(channel.requests, [AppleCalendarMethods.requestFullAccess]);
      expect(await provider.status(), AppleAuthStatus.fullAccess);
    });

    test('disconnect stops use for the session; connect restores', () async {
      channel.status = AppleAuthStatus.fullAccess;
      final provider = make();
      await provider.disconnect();
      expect(await provider.isConnected(), isFalse);
      expect(await provider.listCalendars(), isEmpty);
      expect(await provider.connect(), isTrue);
      expect(await provider.isConnected(), isTrue);
    });
  });

  group('reading', () {
    setUp(() => channel.status = AppleAuthStatus.fullAccess);

    test('lists calendars with default and read-only flags', () async {
      final calendars = await make().listCalendars();
      expect(calendars.map((c) => c.id), ['home', 'holidays']);
      expect(calendars.first.isPrimary, isTrue);
      expect(calendars.first.canWrite, isTrue);
      expect(calendars.last.canWrite, isFalse);
    });

    test('maps timed, all-day, free and recurring events', () async {
      final day = DateTime.utc(2026, 11, 3);
      channel.events.addAll([
        AppleEventData(
          eventIdentifier: 'ev1',
          calendarIdentifier: 'home',
          title: 'Dentist',
          startMs: _ms(day.add(const Duration(hours: 9))),
          endMs: _ms(day.add(const Duration(hours: 10))),
          createdMs: _ms(DateTime.utc(2026, 10, 1)),
          updatedMs: _ms(DateTime.utc(2026, 10, 2)),
        ),
        AppleEventData(
          eventIdentifier: 'ev2',
          calendarIdentifier: 'holidays',
          title: 'Holiday',
          startMs: _ms(day),
          endMs: _ms(day.add(const Duration(days: 1))),
          isAllDay: true,
          isBusy: false,
        ),
        AppleEventData(
          eventIdentifier: 'ev3',
          calendarIdentifier: 'home',
          title: 'Standup',
          startMs: _ms(day.add(const Duration(hours: 12))),
          endMs: _ms(day.add(const Duration(hours: 12, minutes: 15))),
          isRecurring: true,
        ),
        AppleEventData(
          eventIdentifier: 'other-calendar',
          calendarIdentifier: 'work',
          title: 'Not selected',
          startMs: _ms(day.add(const Duration(hours: 9))),
          endMs: _ms(day.add(const Duration(hours: 10))),
        ),
      ]);

      final events = await make().fetchEvents(
        calendarIds: ['home', 'holidays'],
        from: day,
        to: day.add(const Duration(days: 1)),
      );
      expect(events.map((e) => e.externalId), [
        'ev1',
        'ev2',
        'ev3@${_ms(day.add(const Duration(hours: 12)))}',
      ]);

      final dentist = events[0];
      expect(dentist.id, 'apple:ev1');
      expect(dentist.source, CalendarSource.apple);
      expect(dentist.calendarId, 'home');
      expect(dentist.start, DateTime.utc(2026, 11, 3, 9));
      expect(dentist.start.isUtc, isTrue);
      expect(dentist.end.isUtc, isTrue);
      expect(dentist.isAllDay, isFalse);
      expect(dentist.isBusy, isTrue);
      expect(dentist.taskId, isNull);
      expect(dentist.createdAt, DateTime.utc(2026, 10, 1));
      expect(dentist.updatedAt, DateTime.utc(2026, 10, 2));

      final holiday = events[1];
      expect(holiday.isAllDay, isTrue);
      expect(holiday.isBusy, isFalse, reason: 'free events do not block');
      expect(holiday.duration, const Duration(days: 1));
      expect(holiday.createdAt, _now, reason: 'falls back to the clock');

      expect(
        events[2].id,
        'apple:ev3@${_ms(day.add(const Duration(hours: 12)))}',
      );
    });

    test('every occurrence of a recurring event survives a sync', () async {
      final day = DateTime.utc(2026, 11, 3);
      for (final d in [0, 7]) {
        channel.events.add(
          AppleEventData(
            eventIdentifier: 'weekly',
            calendarIdentifier: 'home',
            title: 'Standup',
            startMs: _ms(day.add(Duration(days: d, hours: 9))),
            endMs: _ms(day.add(Duration(days: d, hours: 10))),
            isRecurring: true,
          ),
        );
      }
      final calendars = InMemoryCalendarRepository();
      final engine = CalendarSyncEngine(
        provider: make(),
        calendarRepository: calendars,
        taskRepository: InMemoryTaskRepository(),
        preferencesRepository: InMemoryPreferencesRepository(
          const Preferences(
            selectedCalendarIds: {
              CalendarSource.apple: ['home'],
            },
          ),
        ),
        clock: FixedClock(_now),
        writeBack: false,
      );
      await engine.pull();
      final mirrored = await calendars.getBetween(
        day,
        day.add(const Duration(days: 14)),
      );
      expect(mirrored.map((e) => e.start), [
        day.add(const Duration(hours: 9)),
        day.add(const Duration(days: 7, hours: 9)),
      ]);
    });

    test('no calendars chosen or an empty range reads nothing', () async {
      channel.events.add(
        AppleEventData(
          eventIdentifier: 'ev1',
          calendarIdentifier: 'home',
          title: 'x',
          startMs: _ms(_now),
          endMs: _ms(_now.add(const Duration(hours: 1))),
        ),
      );
      final provider = make();
      expect(
        await provider.fetchEvents(
          calendarIds: const [],
          from: _now,
          to: _now.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
      expect(
        await provider.fetchEvents(calendarIds: ['home'], from: _now, to: _now),
        isEmpty,
      );
    });

    test('changes forwards store notifications', () async {
      final provider = make();
      var count = 0;
      final sub = provider.changes.listen((_) => count++);
      channel
        ..emitChange()
        ..emitChange();
      await pumpEventQueue();
      expect(count, 2);
      await sub.cancel();
    });
  });

  group('write-back', () {
    setUp(() => channel.status = AppleAuthStatus.fullAccess);

    test('task id round-trips through create and fetch', () async {
      final provider = make();
      final id = await provider.createEvent(
        calendarId: 'home',
        task: _task(notes: 'Chapter 1'),
      );
      final stored = channel.events.single;
      expect(stored.notes, 'Chapter 1\n\ngrindTaskId:t1');
      expect(stored.url, 'grind://task/t1');

      final events = await provider.fetchEvents(
        calendarIds: ['home'],
        from: DateTime.utc(2026, 11, 3),
        to: DateTime.utc(2026, 11, 4),
      );
      expect(events.single.externalId, id);
      expect(events.single.taskId, 't1');
      expect(events.single.start, DateTime.utc(2026, 11, 3, 10));
    });

    test('a move in Calendar.app is visible on the next fetch', () async {
      final provider = make();
      final id = await provider.createEvent(calendarId: 'home', task: _task());
      final moved = DateTime.utc(2026, 11, 3, 15);
      channel.events[0] = channel.events[0].copyWith(
        startMs: _ms(moved),
        endMs: _ms(moved.add(const Duration(hours: 1))),
      );
      final events = await provider.fetchEvents(
        calendarIds: ['home'],
        from: DateTime.utc(2026, 11, 3),
        to: DateTime.utc(2026, 11, 4),
      );
      expect(events.single.externalId, id);
      expect(events.single.start, moved);
      expect(events.single.taskId, 't1');
    });

    test('update rewrites times; delete is idempotent', () async {
      final provider = make();
      final id = await provider.createEvent(calendarId: 'home', task: _task());
      final later = _task().copyWith(
        scheduledStart: DateTime.utc(2026, 11, 3, 16),
        scheduledEnd: DateTime.utc(2026, 11, 3, 17),
      );
      await provider.updateEvent(
        calendarId: 'home',
        externalId: id,
        task: later,
      );
      expect(channel.events.single.startMs, _ms(DateTime.utc(2026, 11, 3, 16)));

      await provider.deleteEvent(calendarId: 'home', externalId: id);
      expect(channel.events, isEmpty);
      await provider.deleteEvent(calendarId: 'home', externalId: id);
    });

    test('update of a vanished event reports notFound', () async {
      await expectLater(
        make().updateEvent(
          calendarId: 'home',
          externalId: 'gone',
          task: _task(),
        ),
        throwsA(
          isA<AppleCalendarException>().having(
            (e) => e.isNotFound,
            'notFound',
            true,
          ),
        ),
      );
    });

    test('unscheduled task cannot be written', () async {
      await expectLater(
        make().createEvent(calendarId: 'home', task: _task(scheduled: false)),
        throwsA(
          isA<AppleCalendarException>().having(
            (e) => e.code,
            'code',
            'notScheduled',
          ),
        ),
      );
    });

    test('without permission writes are refused', () async {
      channel.status = AppleAuthStatus.denied;
      await expectLater(
        make().createEvent(calendarId: 'home', task: _task()),
        throwsA(
          isA<AppleCalendarException>().having(
            (e) => e.code,
            'code',
            'notAuthorized',
          ),
        ),
      );
    });
  });

  group('unavailable platform', () {
    test('everything is a graceful no', () async {
      channel.status = AppleAuthStatus.fullAccess;
      final provider = make(supported: false);
      expect(provider.source, CalendarSource.apple);
      expect(await provider.isConnected(), isFalse);
      expect(await provider.connect(), isFalse);
      expect(await provider.connectWriteOnly(), isFalse);
      expect(await provider.status(), AppleAuthStatus.denied);
      expect(await provider.listCalendars(), isEmpty);
      expect(
        await provider.fetchEvents(
          calendarIds: ['home'],
          from: _now,
          to: _now.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
      expect(await provider.changes.isEmpty, isTrue);
      await provider.deleteEvent(calendarId: 'home', externalId: 'x');
      await expectLater(
        provider.createEvent(calendarId: 'home', task: _task()),
        throwsA(
          isA<AppleCalendarException>().having(
            (e) => e.code,
            'code',
            'unavailable',
          ),
        ),
      );
      expect(channel.requests, isEmpty, reason: 'never touches the channel');
    });

    test(
      'default constructor is unavailable in the test VM (not iOS)',
      () async {
        final provider = AppleCalendarProvider();
        expect(provider.isSupported, isFalse);
        expect(await provider.connect(), isFalse);
      },
    );
  });

  group('providers', () {
    test('appleCalendarOverride swaps in the EventKit provider', () async {
      channel.status = AppleAuthStatus.fullAccess;
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(_now)),
          appleCalendarOverride(channel: channel),
        ],
      );
      addTearDown(container.dispose);
      final provider = container.read(appleCalendarProvider);
      expect(provider, isA<AppleCalendarProvider>());
      expect(provider.source, CalendarSource.apple);
    });

    test('changes provider is empty with the default fake', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(appleCalendarChangesProvider, (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(container.read(appleCalendarChangesProvider).hasValue, isFalse);
    });
  });
}
