import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/calendar/apple/apple_calendar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel(AppleCalendarMethods.channel);
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      final args = call.arguments as Map<Object?, Object?>?;
      return switch (call.method) {
        'authorizationStatus' => 'writeOnly',
        'requestFullAccess' => 'fullAccess',
        'requestWriteOnlyAccess' => 'writeOnly',
        'listCalendars' => [
          {
            'id': 'c1',
            'title': 'Home',
            'allowsContentModifications': true,
            'isPrimary': true,
          },
        ],
        'fetchEvents' => [
          {
            'eventIdentifier': 'e1',
            'calendarIdentifier': 'c1',
            'title': 'Dentist',
            'startMs': 1000,
            'endMs': 2000,
            'isAllDay': false,
            'isBusy': false,
            'isRecurring': false,
            'url': 'grind://task/t1',
          },
        ],
        'createEvent' => 'new-id',
        'updateEvent' => null,
        'deleteEvent' when args!['eventId'] == 'gone' =>
          throw PlatformException(code: 'notFound'),
        _ => null,
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(methods, null));

  test('parses statuses, calendars and events', () async {
    final channel = MethodChannelAppleCalendarChannel();
    expect(await channel.authorizationStatus(), AppleAuthStatus.writeOnly);
    expect(await channel.requestFullAccess(), AppleAuthStatus.fullAccess);
    expect(await channel.requestWriteOnlyAccess(), AppleAuthStatus.writeOnly);

    final calendars = await channel.listCalendars();
    expect(calendars.single.id, 'c1');
    expect(calendars.single.isPrimary, isTrue);

    final events = await channel.fetchEvents(
      calendarIds: ['c1'],
      fromMs: 0,
      toMs: 5000,
    );
    expect(events.single.eventIdentifier, 'e1');
    expect(events.single.isBusy, isFalse);
    expect(events.single.url, 'grind://task/t1');
    expect(calls.last.arguments, {
      'calendarIds': ['c1'],
      'fromMs': 0,
      'toMs': 5000,
    });
  });

  test('sends write arguments with the names Swift reads', () async {
    final channel = MethodChannelAppleCalendarChannel();
    final id = await channel.createEvent(
      calendarId: 'c1',
      title: 'Task',
      startMs: 1,
      endMs: 2,
      notes: 'grindTaskId:t1',
      taskId: 't1',
    );
    expect(id, 'new-id');
    expect(calls.last.arguments, {
      'calendarId': 'c1',
      'title': 'Task',
      'startMs': 1,
      'endMs': 2,
      'notes': 'grindTaskId:t1',
      'taskId': 't1',
    });

    await channel.updateEvent(eventId: 'e1', title: 'T', startMs: 1, endMs: 2);
    expect((calls.last.arguments as Map)['eventId'], 'e1');
  });

  test('PlatformException becomes AppleCalendarException', () async {
    await expectLater(
      MethodChannelAppleCalendarChannel().deleteEvent('gone'),
      throwsA(
        isA<AppleCalendarException>().having((e) => e.isNotFound, 'nf', true),
      ),
    );
  });

  test(
    'missing plugin is "unavailable", and status parsing is total',
    () async {
      messenger.setMockMethodCallHandler(methods, null);
      await expectLater(
        MethodChannelAppleCalendarChannel().authorizationStatus(),
        throwsA(
          isA<AppleCalendarException>().having(
            (e) => e.code,
            'c',
            'unavailable',
          ),
        ),
      );
      expect(AppleAuthStatus.parse('something new'), AppleAuthStatus.denied);
      expect(AppleAuthStatus.parse(null), AppleAuthStatus.denied);
    },
  );
}
