import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/tools/assistant_action_log.dart';
import 'package:grind/features/ask/tools/assistant_action_reversal.dart';

void main() {
  group('DeleteTaskReversal', () {
    test('serializes with kind and taskId', () {
      final r = DeleteTaskReversal(taskId: 't-1');
      expect(r.kind, 'deleteTask');
      expect(r.toDescriptor(), <String, Object?>{
        'kind': 'deleteTask',
        'taskId': 't-1',
      });
    });

    test('rejects an empty taskId', () {
      expect(
        () => DeleteTaskReversal(taskId: ''),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('round-trips through fromDescriptor', () {
      final a = DeleteTaskReversal(taskId: 't-42');
      final b = AssistantActionReversal.fromDescriptor(a.toDescriptor());
      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });
  });

  group('RestoreMoveTaskReversal', () {
    final start = DateTime.utc(2026, 11, 4, 9);
    final end = DateTime.utc(2026, 11, 4, 9, 25);

    test('serializes minute-aligned UTC timestamps', () {
      final r = RestoreMoveTaskReversal(
        taskId: 't-1',
        previousStart: start,
        previousEnd: end,
      );
      expect(r.toDescriptor(), <String, Object?>{
        'kind': 'restoreMoveTask',
        'taskId': 't-1',
        'previousStart': '2026-11-04T09:00:00Z',
        'previousEnd': '2026-11-04T09:25:00Z',
      });
    });

    test('normalizes a non-UTC timestamp to UTC on serialization', () {
      // 09:00 in a zone 1 hour ahead of UTC → 08:00 UTC after .toUtc().
      final local = DateTime.utc(2026, 11, 4, 9).toLocal();
      final r = RestoreMoveTaskReversal(
        taskId: 't-1',
        previousStart: local,
        previousEnd: local.add(const Duration(minutes: 25)),
      );
      expect(r.toDescriptor()['previousStart'], '2026-11-04T09:00:00Z');
      expect(r.toDescriptor()['previousEnd'], '2026-11-04T09:25:00Z');
    });

    test('rejects a non-minute-aligned previous window', () {
      expect(
        () => RestoreMoveTaskReversal(
          taskId: 't-1',
          previousStart: DateTime.utc(2026, 11, 4, 9, 0, 30),
          previousEnd: end,
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      expect(
        () => RestoreMoveTaskReversal(
          taskId: 't-1',
          previousStart: start,
          previousEnd: DateTime.utc(2026, 11, 4, 9, 25, 0, 500),
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('rejects an end not after start', () {
      expect(
        () => RestoreMoveTaskReversal(
          taskId: 't-1',
          previousStart: end,
          previousEnd: start,
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      expect(
        () => RestoreMoveTaskReversal(
          taskId: 't-1',
          previousStart: start,
          previousEnd: start,
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('rejects an empty taskId', () {
      expect(
        () => RestoreMoveTaskReversal(
          taskId: '',
          previousStart: start,
          previousEnd: end,
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('round-trips through fromDescriptor', () {
      final a = RestoreMoveTaskReversal(
        taskId: 't-1',
        previousStart: start,
        previousEnd: end,
      );
      final b = AssistantActionReversal.fromDescriptor(a.toDescriptor());
      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });
  });

  group('MergeSplitTaskReversal', () {
    test('serializes original id and chunk ids', () {
      final r = MergeSplitTaskReversal(
        originalTaskId: 't-orig',
        chunkTaskIds: const ['t-a', 't-b'],
      );
      expect(r.toDescriptor(), <String, Object?>{
        'kind': 'mergeSplitTask',
        'originalTaskId': 't-orig',
        'chunkTaskIds': ['t-a', 't-b'],
      });
    });

    test('exposes an unmodifiable chunkTaskIds list', () {
      final r = MergeSplitTaskReversal(
        originalTaskId: 't-orig',
        chunkTaskIds: const ['t-a', 't-b'],
      );
      expect(() => r.chunkTaskIds.add('t-c'), throwsUnsupportedError);
    });

    test('rejects fewer than two chunks', () {
      expect(
        () => MergeSplitTaskReversal(
          originalTaskId: 't-orig',
          chunkTaskIds: const [],
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      expect(
        () => MergeSplitTaskReversal(
          originalTaskId: 't-orig',
          chunkTaskIds: const ['t-a'],
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('rejects a duplicate chunk id', () {
      expect(
        () => MergeSplitTaskReversal(
          originalTaskId: 't-orig',
          chunkTaskIds: const ['t-a', 't-a'],
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('rejects an empty chunk id', () {
      expect(
        () => MergeSplitTaskReversal(
          originalTaskId: 't-orig',
          chunkTaskIds: const ['t-a', ''],
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('rejects an empty originalTaskId', () {
      expect(
        () => MergeSplitTaskReversal(
          originalTaskId: '',
          chunkTaskIds: const ['t-a', 't-b'],
        ),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('round-trips through fromDescriptor', () {
      final a = MergeSplitTaskReversal(
        originalTaskId: 't-orig',
        chunkTaskIds: const ['t-a', 't-b', 't-c'],
      );
      final b = AssistantActionReversal.fromDescriptor(a.toDescriptor());
      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });
  });

  group('CancelFocusReversal', () {
    test('serializes with kind and sessionId', () {
      final r = CancelFocusReversal(sessionId: 's-1');
      expect(r.toDescriptor(), <String, Object?>{
        'kind': 'cancelFocus',
        'sessionId': 's-1',
      });
    });

    test('rejects an empty sessionId', () {
      expect(
        () => CancelFocusReversal(sessionId: ''),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('round-trips through fromDescriptor', () {
      final a = CancelFocusReversal(sessionId: 's-7');
      final b = AssistantActionReversal.fromDescriptor(a.toDescriptor());
      expect(b, a);
    });
  });

  group('DeleteCalendarEventReversal', () {
    test('serializes calendarId and eventId', () {
      final r = DeleteCalendarEventReversal(
        calendarId: 'primary',
        eventId: 'evt-1',
      );
      expect(r.toDescriptor(), <String, Object?>{
        'kind': 'deleteCalendarEvent',
        'calendarId': 'primary',
        'eventId': 'evt-1',
      });
    });

    test('rejects an empty calendarId or eventId', () {
      expect(
        () => DeleteCalendarEventReversal(calendarId: '', eventId: 'evt-1'),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      expect(
        () => DeleteCalendarEventReversal(calendarId: 'primary', eventId: ''),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('round-trips through fromDescriptor', () {
      final a = DeleteCalendarEventReversal(
        calendarId: 'primary',
        eventId: 'evt-1',
      );
      final b = AssistantActionReversal.fromDescriptor(a.toDescriptor());
      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });
  });

  group('AssistantActionReversal.fromDescriptor errors', () {
    test('rejects a non-object payload', () {
      expect(
        () => AssistantActionReversal.fromDescriptor('deleteTask'),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      expect(
        () => AssistantActionReversal.fromDescriptor(null),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('rejects a missing or empty kind', () {
      expect(
        () => AssistantActionReversal.fromDescriptor(<String, Object?>{
          'taskId': 't-1',
        }),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      expect(
        () => AssistantActionReversal.fromDescriptor(<String, Object?>{
          'kind': '',
        }),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('rejects an unknown kind (e.g. "replan")', () {
      expect(
        () => AssistantActionReversal.fromDescriptor(<String, Object?>{
          'kind': 'restorePlan',
        }),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      expect(
        () => AssistantActionReversal.fromDescriptor(<String, Object?>{
          'kind': 'nope',
          'x': 1,
        }),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });

    test('propagates per-kind validation errors', () {
      // Missing "taskId" on a deleteTask descriptor.
      expect(
        () => AssistantActionReversal.fromDescriptor(<String, Object?>{
          'kind': 'deleteTask',
        }),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
      // Malformed ISO timestamp on a restoreMoveTask descriptor.
      expect(
        () => AssistantActionReversal.fromDescriptor(<String, Object?>{
          'kind': 'restoreMoveTask',
          'taskId': 't-1',
          'previousStart': 'yesterday',
          'previousEnd': '2026-11-04T09:25:00Z',
        }),
        throwsA(isA<AssistantActionReversalFormatException>()),
      );
    });
  });

  group('integration with AssistantAction', () {
    test('a reversal descriptor is accepted as an inverseDescriptor', () {
      final reversal = DeleteTaskReversal(taskId: 't-1');
      final action = AssistantAction(
        id: 'a-1',
        timestamp: DateTime.utc(2026, 11, 4, 12),
        toolName: 'addTask',
        inverseDescriptor: reversal.toDescriptor(),
        humanLabel: 'Scheduled Gym · 09:00–09:25',
      );
      // The audit log keeps it round-trippable back to a typed value.
      final back = AssistantActionReversal.fromDescriptor(
        action.inverseDescriptor,
      );
      expect(back, reversal);
    });
  });
}
