import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/unstick/unstick_request.dart';

void main() {
  final anchor = DateTime(2026, 11, 4, 9, 0);

  group('UnstickRequest construction', () {
    test('holds required fields with sensible defaults', () {
      final req = UnstickRequest(
        taskTitle: 'Thesis chapter 3',
        estimatedMinutes: 90,
      );

      expect(req.taskTitle, 'Thesis chapter 3');
      expect(req.estimatedMinutes, 90);
      expect(req.overdueBy, isNull);
      expect(req.isOverdue, isFalse);
      expect(req.recentHistory, isEmpty);
      expect(req.localeCode, 'en');
    });

    test('isOverdue is true only for a positive duration', () {
      final notOverdue = UnstickRequest(taskTitle: 'x', estimatedMinutes: 30);
      final zero = UnstickRequest(
        taskTitle: 'x',
        estimatedMinutes: 30,
        overdueBy: Duration.zero,
      );
      final late = UnstickRequest(
        taskTitle: 'x',
        estimatedMinutes: 30,
        overdueBy: const Duration(hours: 5),
      );

      expect(notOverdue.isOverdue, isFalse);
      expect(zero.isOverdue, isFalse);
      expect(late.isOverdue, isTrue);
    });

    test('recentHistory is unmodifiable', () {
      final history = [
        RecentEvent(
          kind: RecentEventKind.completed,
          taskTitle: 'Breakfast',
          when: anchor,
        ),
      ];
      final req = UnstickRequest(
        taskTitle: 'x',
        estimatedMinutes: 30,
        recentHistory: history,
      );

      expect(
        () => req.recentHistory.add(
          RecentEvent(
            kind: RecentEventKind.skipped,
            taskTitle: 'y',
            when: anchor,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects empty title and non-positive minutes', () {
      expect(
        () => UnstickRequest(taskTitle: '', estimatedMinutes: 30),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UnstickRequest(taskTitle: 'x', estimatedMinutes: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UnstickRequest(taskTitle: 'x', estimatedMinutes: -5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('UnstickRequest equality', () {
    test('same fields compare equal, different history does not', () {
      final a = UnstickRequest(
        taskTitle: 'Thesis',
        estimatedMinutes: 60,
        overdueBy: const Duration(days: 1),
        recentHistory: [
          RecentEvent(
            kind: RecentEventKind.skipped,
            taskTitle: 'Yesterday write-up',
            when: anchor,
          ),
        ],
      );
      final b = UnstickRequest(
        taskTitle: 'Thesis',
        estimatedMinutes: 60,
        overdueBy: const Duration(days: 1),
        recentHistory: [
          RecentEvent(
            kind: RecentEventKind.skipped,
            taskTitle: 'Yesterday write-up',
            when: anchor,
          ),
        ],
      );
      final c = b.copyWith(
        recentHistory: [
          RecentEvent(
            kind: RecentEventKind.completed,
            taskTitle: 'Yesterday write-up',
            when: anchor,
          ),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('copyWith clears overdueBy through the sentinel', () {
      final req = UnstickRequest(
        taskTitle: 'x',
        estimatedMinutes: 30,
        overdueBy: const Duration(hours: 2),
      );

      final cleared = req.copyWith(overdueBy: null);
      expect(cleared.overdueBy, isNull);
      expect(cleared.isOverdue, isFalse);
    });
  });

  group('UnstickRequest JSON', () {
    test('round-trips through toJson/fromJson', () {
      final req = UnstickRequest(
        taskTitle: 'Thesis chapter 3',
        estimatedMinutes: 90,
        overdueBy: const Duration(hours: 26),
        recentHistory: [
          RecentEvent(
            kind: RecentEventKind.completed,
            taskTitle: 'Morning routine',
            when: anchor,
          ),
          RecentEvent(
            kind: RecentEventKind.skipped,
            taskTitle: 'Yesterday write-up',
            when: anchor.subtract(const Duration(days: 1)),
          ),
        ],
        localeCode: 'he',
      );

      final decoded = UnstickRequest.fromJson(req.toJson());
      expect(decoded, req);
    });

    test('omits optional fields when absent', () {
      final req = UnstickRequest(taskTitle: 'x', estimatedMinutes: 30);
      final json = req.toJson();

      expect(json.containsKey('overdueMinutes'), isFalse);
      expect(json.containsKey('recentHistory'), isFalse);
      expect(json['localeCode'], 'en');
    });

    test('fromJson rejects structurally bad input', () {
      expect(UnstickRequest.fromJson(null), isNull);
      expect(UnstickRequest.fromJson('nope'), isNull);
      expect(UnstickRequest.fromJson({'taskTitle': ''}), isNull);
      expect(
        UnstickRequest.fromJson({'taskTitle': 'x', 'estimatedMinutes': 0}),
        isNull,
      );
      expect(
        UnstickRequest.fromJson({'taskTitle': 'x', 'estimatedMinutes': -1}),
        isNull,
      );
      expect(
        UnstickRequest.fromJson({
          'taskTitle': 'x',
          // missing estimatedMinutes
        }),
        isNull,
      );
    });

    test('fromJson accepts numeric estimatedMinutes', () {
      final decoded = UnstickRequest.fromJson({
        'taskTitle': 'x',
        'estimatedMinutes': 45.0,
      });
      expect(decoded, isNotNull);
      expect(decoded!.estimatedMinutes, 45);
    });

    test('fromJson falls back to English for a blank locale', () {
      final decoded = UnstickRequest.fromJson({
        'taskTitle': 'x',
        'estimatedMinutes': 30,
        'localeCode': '',
      });
      expect(decoded, isNotNull);
      expect(decoded!.localeCode, 'en');
    });

    test('fromJson skips malformed history entries', () {
      final decoded = UnstickRequest.fromJson({
        'taskTitle': 'x',
        'estimatedMinutes': 30,
        'recentHistory': [
          {
            'kind': 'completed',
            'taskTitle': 'ok',
            'when': anchor.toIso8601String(),
          },
          'not an object',
          {'kind': 'skipped'}, // missing fields
          {
            'kind': 'unknown-kind',
            'taskTitle': 'fallback',
            'when': anchor.toIso8601String(),
          },
        ],
      });

      expect(decoded, isNotNull);
      expect(decoded!.recentHistory.length, 2);
      expect(decoded.recentHistory.first.kind, RecentEventKind.completed);
      // Unknown kinds fall back to `missed`, matching UnstickOption's
      // fromJson behaviour.
      expect(decoded.recentHistory.last.kind, RecentEventKind.missed);
      expect(decoded.recentHistory.last.taskTitle, 'fallback');
    });
  });

  group('RecentEvent JSON', () {
    test('round-trips', () {
      final event = RecentEvent(
        kind: RecentEventKind.started,
        taskTitle: 'Focus block A',
        when: anchor,
      );
      expect(RecentEvent.fromJson(event.toJson()), event);
    });

    test('fromJson rejects malformed input', () {
      expect(RecentEvent.fromJson(null), isNull);
      expect(RecentEvent.fromJson({'kind': 'completed'}), isNull);
      expect(
        RecentEvent.fromJson({
          'kind': 'completed',
          'taskTitle': '',
          'when': anchor.toIso8601String(),
        }),
        isNull,
      );
      expect(
        RecentEvent.fromJson({
          'kind': 'completed',
          'taskTitle': 'x',
          'when': 'not a date',
        }),
        isNull,
      );
    });
  });
}
