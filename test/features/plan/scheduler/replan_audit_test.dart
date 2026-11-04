import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

void main() {
  DateTime appliedAt() => DateTime.utc(2026, 11, 4, 15, 30);

  ReplanAuditEntry entry({
    String id = 'r1',
    DateTime? at,
    ReplanReason reason = ReplanReason.taskSkipped,
    String summary = 'you skipped Reading',
    int moveCount = 2,
    int addCount = 0,
    int removeCount = 1,
    String? taskId = 't-1',
    String? eventId,
  }) => ReplanAuditEntry(
    id: id,
    appliedAt: at ?? appliedAt(),
    reason: reason,
    summary: summary,
    moveCount: moveCount,
    addCount: addCount,
    removeCount: removeCount,
    taskId: taskId,
    eventId: eventId,
  );

  group('construction', () {
    test('rejects an empty id', () {
      expect(() => entry(id: ''), throwsA(isA<ArgumentError>()));
    });

    test('rejects a non-UTC appliedAt', () {
      expect(
        () => entry(at: DateTime(2026, 11, 4, 15, 30)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a negative count', () {
      expect(() => entry(moveCount: -1), throwsA(isA<ArgumentError>()));
      expect(() => entry(addCount: -1), throwsA(isA<ArgumentError>()));
      expect(() => entry(removeCount: -1), throwsA(isA<ArgumentError>()));
    });

    test('rejects a summary on a manual re-plan', () {
      // ReplanReason.none is reserved for a user-initiated re-plan: the
      // trigger did not say anything, so the audit row should not either.
      expect(
        () => entry(reason: ReplanReason.none, summary: 'nope'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty taskId / eventId', () {
      expect(() => entry(taskId: ''), throwsA(isA<ArgumentError>()));
      expect(
        () => entry(taskId: null, eventId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows an empty summary for a manual re-plan', () {
      final e = entry(
        reason: ReplanReason.none,
        summary: '',
        moveCount: 0,
        removeCount: 0,
        taskId: null,
      );
      expect(e.reason, ReplanReason.none);
      expect(e.summary, isEmpty);
      expect(e.isEmpty, isTrue);
    });
  });

  group('isEmpty', () {
    test('true when every count is zero', () {
      expect(entry(moveCount: 0, addCount: 0, removeCount: 0).isEmpty, isTrue);
    });

    test('false when any count is positive', () {
      expect(entry(moveCount: 1, addCount: 0, removeCount: 0).isEmpty, isFalse);
      expect(entry(moveCount: 0, addCount: 1, removeCount: 0).isEmpty, isFalse);
      expect(entry(moveCount: 0, addCount: 0, removeCount: 1).isEmpty, isFalse);
    });
  });

  group('copyWith', () {
    test('overrides only the fields passed', () {
      final a = entry();
      final b = a.copyWith(moveCount: 5, summary: 'Seminar ran over');
      expect(b.id, a.id);
      expect(b.appliedAt, a.appliedAt);
      expect(b.reason, a.reason);
      expect(b.summary, 'Seminar ran over');
      expect(b.moveCount, 5);
      expect(b.addCount, a.addCount);
      expect(b.removeCount, a.removeCount);
      expect(b.taskId, a.taskId);
    });

    test('unset fields keep their current value', () {
      final a = entry();
      expect(a.copyWith(), a);
    });
  });

  group('equality', () {
    test('value-based', () {
      expect(entry(), entry());
      expect(entry().hashCode, entry().hashCode);
    });

    test('distinguishes every field', () {
      expect(entry(id: 'r1') == entry(id: 'r2'), isFalse);
      expect(
        entry(at: appliedAt()) ==
            entry(at: appliedAt().add(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        entry(
              reason: ReplanReason.taskSkipped,
              summary: 'you skipped Reading',
            ).copyWith(reason: ReplanReason.taskOverrun) ==
            entry(),
        isFalse,
      );
      expect(entry(summary: 'a') == entry(summary: 'b'), isFalse);
      expect(entry(moveCount: 0) == entry(moveCount: 1), isFalse);
      expect(entry(addCount: 0) == entry(addCount: 1), isFalse);
      expect(entry(removeCount: 0) == entry(removeCount: 1), isFalse);
      expect(entry(taskId: 't-1') == entry(taskId: 't-2'), isFalse);
      expect(
        entry(taskId: null, eventId: 'e-1') ==
            entry(taskId: null, eventId: 'e-2'),
        isFalse,
      );
    });
  });

  group('JSON', () {
    test('round-trips through encode/tryDecode', () {
      final original = entry(
        reason: ReplanReason.calendarEventAdded,
        summary: 'Dentist lands at 15:00',
        moveCount: 3,
        addCount: 1,
        removeCount: 0,
        taskId: null,
        eventId: 'e-7',
      );
      final decoded = ReplanAuditEntry.tryDecode(original.encode());
      expect(decoded, isNotNull);
      expect(decoded, original);
    });

    test('equal entries encode to the same bytes', () {
      // So a persisted log can dedupe by string match without decoding.
      expect(entry().encode(), entry().encode());
    });

    test('omits taskId and eventId when null', () {
      final json = entry(
        reason: ReplanReason.none,
        summary: '',
        moveCount: 0,
        removeCount: 0,
        taskId: null,
      ).toJson();
      expect(json.containsKey('taskId'), isFalse);
      expect(json.containsKey('eventId'), isFalse);
    });

    test('tryDecode returns null for null / empty / malformed input', () {
      expect(ReplanAuditEntry.tryDecode(null), isNull);
      expect(ReplanAuditEntry.tryDecode(''), isNull);
      expect(ReplanAuditEntry.tryDecode('not-json'), isNull);
      expect(ReplanAuditEntry.tryDecode('[]'), isNull);
    });

    test('fromJson rejects a missing or empty id', () {
      expect(
        ReplanAuditEntry.fromJson({
          'appliedAt': appliedAt().toIso8601String(),
          'reason': 'none',
          'summary': '',
        }),
        isNull,
      );
      expect(
        ReplanAuditEntry.fromJson({
          'id': '',
          'appliedAt': appliedAt().toIso8601String(),
          'reason': 'none',
          'summary': '',
        }),
        isNull,
      );
    });

    test('fromJson rejects an unparseable appliedAt', () {
      expect(
        ReplanAuditEntry.fromJson({
          'id': 'r1',
          'appliedAt': 'not-a-date',
          'reason': 'none',
          'summary': '',
        }),
        isNull,
      );
    });

    test('fromJson rejects negative counts', () {
      expect(
        ReplanAuditEntry.fromJson({
          'id': 'r1',
          'appliedAt': appliedAt().toIso8601String(),
          'reason': 'taskSkipped',
          'summary': 'you skipped Reading',
          'moveCount': -1,
        }),
        isNull,
      );
    });

    test('fromJson falls back to none on an unknown reason', () {
      // A newer app may introduce reasons the current build does not know
      // about; the row should still decode so the audit log stays useful.
      final decoded = ReplanAuditEntry.fromJson({
        'id': 'r1',
        'appliedAt': appliedAt().toIso8601String(),
        'reason': 'futureReason',
        'summary': 'something from the future',
        'moveCount': 1,
      });
      expect(decoded, isNotNull);
      expect(decoded!.reason, ReplanReason.none);
      // The summary is cleared to keep the "manual re-plan" invariant that
      // the constructor enforces.
      expect(decoded.summary, isEmpty);
    });

    test('fromJson defaults missing counts to zero', () {
      final decoded = ReplanAuditEntry.fromJson({
        'id': 'r1',
        'appliedAt': appliedAt().toIso8601String(),
        'reason': 'none',
        'summary': '',
      });
      expect(decoded, isNotNull);
      expect(decoded!.moveCount, 0);
      expect(decoded.addCount, 0);
      expect(decoded.removeCount, 0);
      expect(decoded.isEmpty, isTrue);
    });

    test('fromJson normalizes appliedAt to UTC', () {
      final decoded = ReplanAuditEntry.fromJson({
        'id': 'r1',
        'appliedAt': '2026-11-04T15:30:00+02:00',
        'reason': 'none',
        'summary': '',
      });
      expect(decoded, isNotNull);
      expect(decoded!.appliedAt.isUtc, isTrue);
      expect(decoded.appliedAt, DateTime.utc(2026, 11, 4, 13, 30));
    });
  });
}
