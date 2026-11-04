import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/plan/replan_audit_log.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

ReplanAuditEntry _entry({
  String id = 'r-1',
  DateTime? at,
  ReplanReason reason = ReplanReason.taskSkipped,
  String summary = 'you skipped Reading',
  int moveCount = 1,
  int addCount = 0,
  int removeCount = 0,
  String? taskId = 't-1',
  String? eventId,
}) => ReplanAuditEntry(
  id: id,
  appliedAt: at ?? DateTime.utc(2026, 11, 4, 15, 30),
  reason: reason,
  summary: summary,
  moveCount: moveCount,
  addCount: addCount,
  removeCount: removeCount,
  taskId: taskId,
  eventId: eventId,
);

void main() {
  group('ReplanAuditLog construction', () {
    test('defaults to capacity 20 and starts empty', () {
      final log = ReplanAuditLog();
      expect(log.capacity, 20);
      expect(log.length, 0);
      expect(log.isEmpty, isTrue);
      expect(log.isNotEmpty, isFalse);
      expect(log.entries, isEmpty);
      expect(log.latest, isNull);
    });

    test('rejects a non-positive capacity', () {
      expect(() => ReplanAuditLog(capacity: 0), throwsA(isA<AssertionError>()));
      expect(() => ReplanAuditLog(capacity: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('append', () {
    test('puts the newest entry first', () {
      final log = ReplanAuditLog();
      log.append(_entry(id: 'r-1'));
      log.append(_entry(id: 'r-2'));
      log.append(_entry(id: 'r-3'));
      expect(log.entries.map((e) => e.id), ['r-3', 'r-2', 'r-1']);
      expect(log.latest?.id, 'r-3');
    });

    test('rejects a duplicate id', () {
      final log = ReplanAuditLog();
      log.append(_entry(id: 'r-1'));
      expect(() => log.append(_entry(id: 'r-1')), throwsArgumentError);
      // The log is unchanged — the duplicate never landed.
      expect(log.length, 1);
    });

    test('drops the oldest entry past capacity', () {
      final log = ReplanAuditLog(capacity: 3);
      for (var i = 1; i <= 5; i++) {
        log.append(_entry(id: 'r-$i'));
      }
      expect(log.length, 3);
      expect(log.entries.map((e) => e.id), ['r-5', 'r-4', 'r-3']);
      expect(log.byId('r-1'), isNull);
      expect(log.byId('r-2'), isNull);
    });

    test('notifies listeners once per append', () {
      final log = ReplanAuditLog();
      var count = 0;
      log.addListener(() => count++);
      log.append(_entry(id: 'r-1'));
      log.append(_entry(id: 'r-2'));
      expect(count, 2);
    });

    test('exposes an unmodifiable snapshot of entries', () {
      final log = ReplanAuditLog();
      log.append(_entry(id: 'r-1'));
      final snapshot = log.entries;
      expect(() => snapshot.add(_entry(id: 'r-2')), throwsUnsupportedError);
      expect(() => snapshot.clear(), throwsUnsupportedError);
    });

    test('a rejected duplicate append fires no listeners', () {
      final log = ReplanAuditLog();
      log.append(_entry(id: 'r-1'));
      var count = 0;
      log.addListener(() => count++);
      expect(() => log.append(_entry(id: 'r-1')), throwsArgumentError);
      expect(count, 0);
    });
  });

  group('byId', () {
    test('returns the matching entry', () {
      final log = ReplanAuditLog();
      final a = _entry(id: 'r-1');
      final b = _entry(id: 'r-2');
      log.append(a);
      log.append(b);
      expect(log.byId('r-1'), a);
      expect(log.byId('r-2'), b);
    });

    test('returns null for a missing or empty id', () {
      final log = ReplanAuditLog();
      log.append(_entry(id: 'r-1'));
      expect(log.byId('r-missing'), isNull);
      expect(log.byId(''), isNull);
    });
  });

  group('clear', () {
    test('empties the log and notifies when it had entries', () {
      final log = ReplanAuditLog();
      log.append(_entry(id: 'r-1'));
      log.append(_entry(id: 'r-2'));
      var count = 0;
      log.addListener(() => count++);
      log.clear();
      expect(log.isEmpty, isTrue);
      expect(count, 1);
    });

    test('is a no-op on an empty log (no listener fire)', () {
      final log = ReplanAuditLog();
      var count = 0;
      log.addListener(() => count++);
      log.clear();
      expect(count, 0);
    });
  });

  test('is a ChangeNotifier', () {
    // Smoke-check for the Flutter integration a UI row would use.
    final log = ReplanAuditLog();
    expect(log, isA<ChangeNotifier>());
  });
}
