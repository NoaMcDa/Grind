import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/features/ask/tools/tool_call.dart';

void main() {
  group('ToolCall.fromJson dispatch', () {
    test('rejects non-object input', () {
      expect(
        () => ToolCall.fromJson('nope'),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects missing/empty name', () {
      expect(
        () => ToolCall.fromJson(<String, Object?>{'arguments': {}}),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => ToolCall.fromJson({'name': '', 'arguments': {}}),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects unknown name', () {
      expect(
        () => ToolCall.fromJson({'name': 'deleteEverything', 'arguments': {}}),
        throwsA(
          isA<ToolCallFormatException>().having(
            (e) => e.message,
            'message',
            contains('unknown tool'),
          ),
        ),
      );
    });

    test('rejects non-object arguments', () {
      expect(
        () => ToolCall.fromJson({'name': 'addTask', 'arguments': 'oops'}),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('missing arguments defaults to {}', () {
      // startFocus with no arguments is still invalid (plannedMinutes
      // required), but the dispatch itself should not blow up on the
      // missing arguments field.
      expect(
        () => ToolCall.fromJson({'name': 'startFocus'}),
        throwsA(
          isA<ToolCallFormatException>().having(
            (e) => e.message,
            'message',
            contains('plannedMinutes'),
          ),
        ),
      );
    });
  });

  group('AddTaskCall', () {
    final start = DateTime.utc(2026, 11, 3, 9);
    final end = DateTime.utc(2026, 11, 3, 10);

    test('defaults fill in and round-trip through JSON', () {
      final call = AddTaskCall(title: 'Write intro');
      expect(call.name, 'addTask');
      expect(call.estimatedMinutes, 30);
      expect(call.energy, Energy.light);
      expect(call.priority, 2);
      final decoded = ToolCall.fromJson(call.toJson());
      expect(decoded, call);
      expect(decoded, isA<AddTaskCall>());
    });

    test('a full payload round-trips with all optional fields', () {
      final due = DateTime.utc(2026, 11, 5, 23, 59);
      final call = AddTaskCall(
        title: 'Thesis',
        estimatedMinutes: 90,
        energy: Energy.deep,
        priority: 1,
        notes: 'intro + lit review',
        goalId: 'goal-1',
        category: 'study',
        firstAction: 'Open the thesis file',
        dueAt: due,
        scheduledStart: start,
        scheduledEnd: end,
        splittable: true,
      );
      final json = call.toJson();
      expect(json['name'], 'addTask');
      final args = json['arguments'] as Map<String, Object?>;
      expect(args['dueAt'], '2026-11-05T23:59:00Z');
      expect(args['scheduledStart'], '2026-11-03T09:00:00Z');
      expect(args['energy'], 'deep');
      expect(args['priority'], 1);
      expect(args['splittable'], true);
      expect(ToolCall.fromJson(json), call);
    });

    test('rejects empty title', () {
      expect(
        () => AddTaskCall(title: ''),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => ToolCall.fromJson({
          'name': 'addTask',
          'arguments': {'title': ''},
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects non-minute-aligned times', () {
      expect(
        () => AddTaskCall(
          title: 'x',
          scheduledStart: DateTime.utc(2026, 11, 3, 9, 0, 1),
          scheduledEnd: end,
        ),
        throwsA(
          isA<ToolCallFormatException>().having(
            (e) => e.message,
            'message',
            contains('minute'),
          ),
        ),
      );
    });

    test('rejects a schedule without an end', () {
      expect(
        () => AddTaskCall(title: 'x', scheduledStart: start),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects an end before/equal to start', () {
      expect(
        () => AddTaskCall(
          title: 'x',
          scheduledStart: end,
          scheduledEnd: start,
        ),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => AddTaskCall(
          title: 'x',
          scheduledStart: start,
          scheduledEnd: start,
        ),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects priority outside 1..3 and bad estimate', () {
      expect(
        () => AddTaskCall(title: 'x', priority: 0),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => AddTaskCall(title: 'x', priority: 4),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => AddTaskCall(title: 'x', estimatedMinutes: 0),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => AddTaskCall(title: 'x', estimatedMinutes: 24 * 60 + 1),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects unknown energy strings on parse', () {
      expect(
        () => ToolCall.fromJson({
          'name': 'addTask',
          'arguments': {'title': 'x', 'energy': 'maximum'},
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects non-integer estimatedMinutes on parse', () {
      expect(
        () => ToolCall.fromJson({
          'name': 'addTask',
          'arguments': {'title': 'x', 'estimatedMinutes': 30.5},
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('accepts a non-UTC ISO timestamp and normalises to UTC', () {
      final decoded = ToolCall.fromJson({
        'name': 'addTask',
        'arguments': {
          'title': 'Gym',
          'scheduledStart': '2026-11-03T11:00:00+02:00',
          'scheduledEnd': '2026-11-03T11:45:00+02:00',
        },
      }) as AddTaskCall;
      expect(decoded.scheduledStart, DateTime.utc(2026, 11, 3, 9));
      expect(decoded.scheduledEnd, DateTime.utc(2026, 11, 3, 9, 45));
    });
  });

  group('MoveTaskCall', () {
    final start = DateTime.utc(2026, 11, 3, 15);
    final end = DateTime.utc(2026, 11, 3, 16);

    test('round-trips', () {
      final call = MoveTaskCall(
        taskId: 'task-42',
        scheduledStart: start,
        scheduledEnd: end,
      );
      expect(call.name, 'moveTask');
      final json = call.toJson();
      final args = json['arguments'] as Map;
      expect(args['scheduledStart'], '2026-11-03T15:00:00Z');
      expect(ToolCall.fromJson(json), call);
    });

    test('rejects empty taskId', () {
      expect(
        () => MoveTaskCall(
          taskId: '',
          scheduledStart: start,
          scheduledEnd: end,
        ),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects missing taskId on parse', () {
      expect(
        () => ToolCall.fromJson({
          'name': 'moveTask',
          'arguments': {
            'scheduledStart': '2026-11-03T15:00:00Z',
            'scheduledEnd': '2026-11-03T16:00:00Z',
          },
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects a malformed timestamp on parse', () {
      expect(
        () => ToolCall.fromJson({
          'name': 'moveTask',
          'arguments': {
            'taskId': 'x',
            'scheduledStart': 'yesterday',
            'scheduledEnd': '2026-11-03T16:00:00Z',
          },
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });
  });

  group('SplitTaskCall', () {
    test('either chunkMinutes or chunkCount is required', () {
      expect(
        () => SplitTaskCall(taskId: 'x'),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects chunkMinutes below the minimum (5)', () {
      expect(
        () => SplitTaskCall(taskId: 'x', chunkMinutes: 4),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects chunkCount of 1 or 25', () {
      expect(
        () => SplitTaskCall(taskId: 'x', chunkCount: 1),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => SplitTaskCall(taskId: 'x', chunkCount: 25),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('chunkMinutes-only and chunkCount-only both round-trip', () {
      final a = SplitTaskCall(taskId: 'x', chunkMinutes: 25);
      expect(ToolCall.fromJson(a.toJson()), a);

      final b = SplitTaskCall(taskId: 'x', chunkCount: 3);
      expect(ToolCall.fromJson(b.toJson()), b);
    });
  });

  group('StartFocusCall', () {
    test('plannedMinutes alone is enough and round-trips', () {
      final call = StartFocusCall(plannedMinutes: 25);
      expect(call.name, 'startFocus');
      expect(call.taskId, isNull);
      final json = call.toJson();
      expect((json['arguments'] as Map).containsKey('taskId'), isFalse);
      expect(ToolCall.fromJson(json), call);
    });

    test('taskId when set must be non-empty', () {
      expect(
        () => StartFocusCall(plannedMinutes: 25, taskId: ''),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('plannedMinutes is capped at 240 and must be positive', () {
      expect(
        () => StartFocusCall(plannedMinutes: 0),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => StartFocusCall(plannedMinutes: 241),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('plannedMinutes required on parse', () {
      expect(
        () => ToolCall.fromJson({'name': 'startFocus', 'arguments': {}}),
        throwsA(isA<ToolCallFormatException>()),
      );
    });
  });

  group('CreateCalendarEventCall', () {
    final start = DateTime.utc(2026, 11, 3, 9);
    final end = DateTime.utc(2026, 11, 3, 9, 45);

    test('round-trips and defaults isBusy to true', () {
      final call = CreateCalendarEventCall(
        title: 'Gym',
        start: start,
        end: end,
      );
      expect(call.isBusy, true);
      final decoded = ToolCall.fromJson(call.toJson());
      expect(decoded, call);
    });

    test('a free/busy=false event round-trips and keeps the flag', () {
      final call = CreateCalendarEventCall(
        title: 'Birthday',
        start: start,
        end: end,
        isBusy: false,
        calendarId: 'cal-1',
        taskId: 't-1',
        notes: 'bring cake',
      );
      final json = call.toJson();
      expect((json['arguments'] as Map)['isBusy'], false);
      expect(ToolCall.fromJson(json), call);
    });

    test('rejects an end before/equal to start', () {
      expect(
        () => CreateCalendarEventCall(title: 'x', start: end, end: start),
        throwsA(isA<ToolCallFormatException>()),
      );
      expect(
        () => CreateCalendarEventCall(title: 'x', start: start, end: start),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects a non-boolean isBusy on parse', () {
      expect(
        () => ToolCall.fromJson({
          'name': 'createCalendarEvent',
          'arguments': {
            'title': 'x',
            'start': '2026-11-03T09:00:00Z',
            'end': '2026-11-03T10:00:00Z',
            'isBusy': 'yes',
          },
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });
  });

  group('ReplanCall', () {
    test('date-only round-trips as YYYY-MM-DD', () {
      final call = ReplanCall(date: DateTime(2026, 11, 3));
      final json = call.toJson();
      expect((json['arguments'] as Map)['date'], '2026-11-03');
      expect((json['arguments'] as Map).containsKey('from'), isFalse);
      expect(ToolCall.fromJson(json), call);
    });

    test('a from cutoff round-trips as UTC minute ISO', () {
      final call = ReplanCall(
        date: DateTime(2026, 11, 3),
        from: DateTime.utc(2026, 11, 3, 12),
      );
      final args = call.toJson()['arguments'] as Map;
      expect(args['from'], '2026-11-03T12:00:00Z');
      expect(ToolCall.fromJson(call.toJson()), call);
    });

    test('rejects a date with a time component', () {
      expect(
        () => ReplanCall(date: DateTime(2026, 11, 3, 9)),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects a non-existent calendar day on parse', () {
      expect(
        () => ToolCall.fromJson({
          'name': 'replan',
          'arguments': {'date': '2026-02-31'},
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects a malformed date string on parse', () {
      expect(
        () => ToolCall.fromJson({
          'name': 'replan',
          'arguments': {'date': '11/03/2026'},
        }),
        throwsA(isA<ToolCallFormatException>()),
      );
    });

    test('rejects a non-minute-aligned from cutoff', () {
      expect(
        () => ReplanCall(
          date: DateTime(2026, 11, 3),
          from: DateTime.utc(2026, 11, 3, 12, 0, 1),
        ),
        throwsA(isA<ToolCallFormatException>()),
      );
    });
  });

  group('equality & hashing', () {
    test('two equal AddTaskCalls are == and share hashCode', () {
      final a = AddTaskCall(
        title: 'x',
        dueAt: DateTime.utc(2026, 11, 5, 23, 59),
      );
      final b = AddTaskCall(
        title: 'x',
        dueAt: DateTime.utc(2026, 11, 5, 23, 59),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different tool is never equal to AddTaskCall', () {
      final a = AddTaskCall(title: 'x');
      final b = StartFocusCall(plannedMinutes: 25);
      expect(a == b, isFalse);
    });
  });
}
