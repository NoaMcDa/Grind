import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/google/google_auth.dart';
import 'package:grind/features/calendar/google/google_calendar_provider.dart';
import 'package:grind/features/calendar/google/google_config.dart';
import 'package:grind/features/calendar/google/google_event_mapper.dart';
import 'package:grind/features/calendar/google/key_value_store.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';
import 'package:grind/features/calendar/sync/calendar_sync_errors.dart';

import 'fakes.dart';

const configured = GoogleCalendarConfig(
  iosClientId: '123-ios.apps.googleusercontent.com',
  webClientId: '123-web.apps.googleusercontent.com',
);

final now = DateTime.utc(2026, 11, 3, 8);
DateTime at(int day, int hour) => DateTime.utc(2026, 11, day, hour);
final from = DateTime.utc(2026, 10, 27);
final to = DateTime.utc(2026, 12, 4);

void main() {
  late FakeGateway gw;
  late FakeAuth auth;
  late InMemoryKeyValueStore store;

  GoogleCalendarProvider build({
    GoogleCalendarConfig config = configured,
    bool web = false,
  }) => GoogleCalendarProvider(
    auth: auth,
    store: store,
    config: config,
    web: web,
    clock: FixedClock(now),
  );

  setUp(() {
    gw = FakeGateway();
    auth = FakeAuth(gw);
    store = InMemoryKeyValueStore();
  });

  group('connect', () {
    test(
      'placeholder client id: false with a setup hint, no sign-in',
      () async {
        for (final web in [false, true]) {
          final p = build(
            config: const GoogleCalendarConfig.fromEnvironment(),
            web: web,
          );
          expect(await p.connect(), isFalse);
          expect(auth.signIns, 0);
          expect(
            p.lastError,
            contains(web ? 'GOOGLE_CLIENT_ID_WEB' : 'GOOGLE_CLIENT_ID_IOS'),
          );
          expect(p.lastError, contains('docs/adr/0005-google-calendar.md'));
          expect(await p.isConnected(), isFalse);
        }
      },
    );

    test('authorized: connected and remembered across instances', () async {
      expect(await build().connect(), isTrue);
      expect(await build().isConnected(), isTrue);
    });

    test('cancelled: false, no error', () async {
      auth.outcome = GoogleSignInOutcome.cancelled;
      final p = build();
      expect(await p.connect(), isFalse);
      expect(p.lastError, isNull);
      expect(await p.isConnected(), isFalse);
    });

    test('failed: false with the reason', () async {
      auth.outcome = GoogleSignInOutcome.failed;
      final p = build();
      expect(await p.connect(), isFalse);
      expect(p.lastError, 'popup_closed');
    });

    test('disconnect signs out and forgets sync state', () async {
      final p = build();
      await p.connect();
      await p.fetchEvents(calendarIds: ['primary'], from: from, to: to);
      expect(store.values, isNotEmpty);
      await p.disconnect();
      expect(auth.signOuts, 1);
      expect(store.values, isEmpty);
      expect(await p.isConnected(), isFalse);
    });

    test('an expired session asks to reconnect', () async {
      final p = build();
      await p.connect();
      auth.sessionValid = false;
      expect(
        () => p.fetchEvents(calendarIds: ['primary'], from: from, to: to),
        throwsA(isA<CalendarAuthException>()),
      );
    });
  });

  test('listCalendars maps primary and write access', () async {
    gw.calendarList.add(
      gcal.CalendarListEntry(
        id: 'holidays',
        summary: 'Holidays',
        accessRole: 'reader',
      ),
    );
    final list = await build().listCalendars();
    expect(list.map((c) => c.id), ['primary', 'holidays']);
    expect(list.first.isPrimary, isTrue);
    expect(list.first.canWrite, isTrue);
    expect(list.last.canWrite, isFalse);
  });

  group('incremental sync', () {
    test('first fetch is a full sync; the token is persisted', () async {
      gw.put('primary', timed('a', at(4, 10), at(4, 11)));
      final p = build();
      final events = await p.fetchEvents(
        calendarIds: ['primary'],
        from: from,
        to: to,
      );
      expect(events.single.externalId, 'a');
      expect(gw.listCalls.single.syncToken, isNull);
      expect(gw.listCalls.single.timeMin, from);
      final saved = jsonDecode(store.values['grind.google.sync.primary']!);
      expect(saved['token'], 'tok-1');
    });

    test('a new instance resumes from the stored token', () async {
      gw.put('primary', timed('a', at(4, 10), at(4, 11)));
      await build().fetchEvents(calendarIds: ['primary'], from: from, to: to);

      gw.put('primary', timed('b', at(5, 10), at(5, 11)));
      gw.cancel('primary', 'a');
      final events = await build().fetchEvents(
        calendarIds: ['primary'],
        from: from,
        to: to,
      );
      expect(gw.listCalls.last.syncToken, 'tok-1');
      expect(events.map((e) => e.externalId), ['b']);
    });

    test('pages are followed in both modes', () async {
      gw = FakeGateway(pageSize: 2);
      auth = FakeAuth(gw);
      for (var i = 0; i < 5; i++) {
        gw.put('primary', timed('e$i', at(4 + i, 10), at(4 + i, 11)));
      }
      final p = build();
      expect(
        await p.fetchEvents(calendarIds: ['primary'], from: from, to: to),
        hasLength(5),
      );
      for (var i = 5; i < 8; i++) {
        gw.put('primary', timed('e$i', at(4 + i, 10), at(4 + i, 11)));
      }
      expect(
        await p.fetchEvents(calendarIds: ['primary'], from: from, to: to),
        hasLength(8),
      );
      expect(gw.listCalls.last.syncToken, isNotNull);
    });

    test('HTTP 410 on the token triggers a full resync', () async {
      gw.put('primary', timed('a', at(4, 10), at(4, 11)));
      final p = build();
      await p.fetchEvents(calendarIds: ['primary'], from: from, to: to);
      gw.put('primary', timed('b', at(5, 10), at(5, 11)));
      gw.expireTokens = true;

      final events = await p.fetchEvents(
        calendarIds: ['primary'],
        from: from,
        to: to,
      );
      expect(events.map((e) => e.externalId), ['a', 'b']);
      expect(gw.listCalls.map((c) => c.syncToken), [null, 'tok-1', null]);
      final saved = jsonDecode(store.values['grind.google.sync.primary']!);
      expect(saved['token'], 'tok-2');
    });

    test('a window past the stored one forces a full sync', () async {
      final p = build();
      await p.fetchEvents(calendarIds: ['primary'], from: from, to: to);
      await p.fetchEvents(
        calendarIds: ['primary'],
        from: from.add(const Duration(days: 1)),
        to: to.add(const Duration(days: 1)),
      );
      expect(gw.listCalls.last.syncToken, isNotNull, reason: 'within slack');
      await p.fetchEvents(
        calendarIds: ['primary'],
        from: from.add(const Duration(days: 10)),
        to: to.add(const Duration(days: 10)),
      );
      expect(gw.listCalls.last.syncToken, isNull);
    });

    test('a corrupt stored state falls back to a full sync', () async {
      store.values['grind.google.sync.primary'] = '{not json';
      await build().fetchEvents(calendarIds: ['primary'], from: from, to: to);
      expect(gw.listCalls.single.syncToken, isNull);
    });

    test('an event moved out of the window drops out', () async {
      gw.put('primary', timed('a', at(4, 10), at(4, 11)));
      final p = build();
      await p.fetchEvents(calendarIds: ['primary'], from: from, to: to);
      gw.put(
        'primary',
        timed('a', DateTime.utc(2027, 6, 1), DateTime.utc(2027, 6, 1, 1)),
      );
      expect(
        await p.fetchEvents(calendarIds: ['primary'], from: from, to: to),
        isEmpty,
      );
    });
  });

  group('htmlLink', () {
    test('the mapping keeps an https htmlLink and drops others', () {
      final e = timed('a', at(4, 10), at(4, 11))
        ..htmlLink = 'https://www.google.com/calendar/event?eid=YQ';
      expect(
        GoogleEventMapper.toDomain(
          e,
          calendarId: 'primary',
          now: now,
        )!.htmlLink,
        'https://www.google.com/calendar/event?eid=YQ',
      );
      e.htmlLink = 'javascript:alert(1)';
      expect(
        GoogleEventMapper.toDomain(
          e,
          calendarId: 'primary',
          now: now,
        )!.htmlLink,
        isNull,
      );
    });

    test('reaches fetchEvents and survives the persisted mirror', () async {
      gw.put(
        'primary',
        timed('a', at(4, 10), at(4, 11))
          ..htmlLink = 'https://www.google.com/calendar/event?eid=YQ',
      );
      final first = await build().fetchEvents(
        calendarIds: ['primary'],
        from: from,
        to: to,
      );
      expect(first.single.htmlLink, contains('eid=YQ'));
      final mapped = GoogleEventMapper.toDomain(
        timed('b', at(4, 10), at(4, 11))..htmlLink = 'https://x.test/b',
        calendarId: 'primary',
        now: now,
      )!;
      final back = GoogleEventMapper.fromJson(GoogleEventMapper.toJson(mapped));
      expect(back.htmlLink, 'https://x.test/b');
    });
  });

  group('write-back', () {
    final task = Task(
      id: 'task-42',
      title: 'Draft chapter 2',
      notes: 'Start with the outline',
      scheduledStart: at(5, 13),
      scheduledEnd: at(5, 14),
      createdAt: now,
      updatedAt: now,
    );

    test('creates an event tagged with grindTaskId', () async {
      final p = build();
      final id = await p.createEvent(calendarId: 'primary', task: task);
      final sent = gw.calendars['primary']![id]!;
      expect(sent.extendedProperties!.private!['grindTaskId'], 'task-42');
      expect(sent.summary, 'Draft chapter 2');
      expect(sent.description, contains('Start with the outline'));
      expect(sent.start!.dateTime, at(5, 13));
      expect(sent.reminders!.useDefault, isFalse);

      final events = await p.fetchEvents(
        calendarIds: ['primary'],
        from: from,
        to: to,
      );
      expect(events.single.taskId, 'task-42');
    });

    test('update patches, delete removes', () async {
      final p = build();
      await p.fetchEvents(calendarIds: ['primary'], from: from, to: to);
      final id = await p.createEvent(calendarId: 'primary', task: task);
      await p.updateEvent(
        calendarId: 'primary',
        externalId: id,
        task: task.copyWith(scheduledStart: at(6, 9), scheduledEnd: at(6, 10)),
      );
      var events = await p.fetchEvents(
        calendarIds: ['primary'],
        from: from,
        to: to,
      );
      expect(events.single.start, at(6, 9));

      await p.deleteEvent(calendarId: 'primary', externalId: id);
      events = await p.fetchEvents(
        calendarIds: ['primary'],
        from: from,
        to: to,
      );
      expect(events, isEmpty);
    });

    test(
      'engine round trip: moving the event in Google moves the task',
      () async {
        final p = build();
        await p.connect();
        final tasks = InMemoryTaskRepository([task]);
        final engine = CalendarSyncEngine(
          provider: p,
          calendarRepository: InMemoryCalendarRepository(),
          taskRepository: tasks,
          preferencesRepository: InMemoryPreferencesRepository(),
          clock: FixedClock(now),
        );
        await engine.sync();
        final linked = (await tasks.getById('task-42'))!;
        expect(linked.calendarEventId, isNotNull);

        final ev = gw.calendars['primary']![linked.calendarEventId]!;
        gw.put(
          'primary',
          clone(ev)
            ..start = gcal.EventDateTime(dateTime: at(9, 15))
            ..end = gcal.EventDateTime(dateTime: at(9, 16)),
        );
        await engine.sync();
        final moved = (await tasks.getById('task-42'))!;
        expect(moved.scheduledStart, at(9, 15));

        gw.cancel('primary', linked.calendarEventId!);
        await engine.sync();
        expect((await tasks.getById('task-42'))!.isScheduled, isFalse);
      },
    );
  });

  group('mapping', () {
    test('timed events become UTC instants', () {
      final e = GoogleEventMapper.toDomain(
        gcal.Event.fromJson({
          'id': 'x',
          'summary': 'Standup',
          'start': {
            'dateTime': '2026-11-04T10:00:00+02:00',
            'timeZone': 'Asia/Jerusalem',
          },
          'end': {'dateTime': '2026-11-04T10:15:00+02:00'},
        }),
        calendarId: 'primary',
        now: now,
      )!;
      expect(e.start, DateTime.utc(2026, 11, 4, 8));
      expect(e.end, DateTime.utc(2026, 11, 4, 8, 15));
      expect(e.start.isUtc, isTrue);
      expect(e.isAllDay, isFalse);
      expect(e.isBusy, isTrue);
      expect(e.id, 'google:x');
    });

    test('all-day events cover local midnight to midnight', () {
      final e = GoogleEventMapper.toDomain(
        gcal.Event.fromJson({
          'id': 'trip',
          'summary': 'Trip',
          'start': {'date': '2026-11-10'},
          'end': {'date': '2026-11-12'},
          'transparency': 'transparent',
        }),
        calendarId: 'primary',
        now: now,
      )!;
      expect(e.isAllDay, isTrue);
      expect(e.start, DateTime(2026, 11, 10).toUtc());
      expect(e.end, DateTime(2026, 11, 12).toUtc());
      expect(e.isBusy, isFalse);
    });

    test('declined invites do not block time; cancelled are dropped', () {
      final declined = GoogleEventMapper.toDomain(
        gcal.Event.fromJson({
          'id': 'inv',
          'start': {'dateTime': '2026-11-04T10:00:00Z'},
          'end': {'dateTime': '2026-11-04T11:00:00Z'},
          'attendees': [
            {'email': 'me@x', 'self': true, 'responseStatus': 'declined'},
          ],
        }),
        calendarId: 'primary',
        now: now,
      )!;
      expect(declined.isBusy, isFalse);
      expect(declined.title, '(No title)');
      expect(
        GoogleEventMapper.toDomain(
          gcal.Event(id: 'c', status: 'cancelled'),
          calendarId: 'primary',
          now: now,
        ),
        isNull,
      );
    });

    test('JSON round trip keeps every field', () {
      final e = CalendarEvent(
        id: 'google:a',
        source: CalendarSource.google,
        externalId: 'a',
        calendarId: 'primary',
        title: 'T',
        start: at(4, 1),
        end: at(4, 2),
        isAllDay: true,
        isBusy: false,
        taskId: 't',
        createdAt: now,
        updatedAt: now,
      );
      final back = GoogleEventMapper.fromJson(GoogleEventMapper.toJson(e));
      expect(
        [
          back.id,
          back.externalId,
          back.calendarId,
          back.title,
          back.start,
          back.end,
          back.isAllDay,
          back.isBusy,
          back.taskId,
        ],
        [
          e.id,
          e.externalId,
          e.calendarId,
          e.title,
          e.start,
          e.end,
          e.isAllDay,
          e.isBusy,
          e.taskId,
        ],
      );
    });
  });
}
