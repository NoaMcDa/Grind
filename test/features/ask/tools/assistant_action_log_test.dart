import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/tools/assistant_action_log.dart';

AssistantAction _action({
  String id = 'a-1',
  DateTime? timestamp,
  String toolName = 'addTask',
  Map<String, Object?>? inverseDescriptor,
  String humanLabel = 'Scheduled Gym · 09:00–09:25',
  AssistantActionStatus status = AssistantActionStatus.applied,
}) {
  return AssistantAction(
    id: id,
    timestamp: timestamp ?? DateTime.utc(2026, 11, 4, 12),
    toolName: toolName,
    inverseDescriptor:
        inverseDescriptor ??
        <String, Object?>{'kind': 'deleteTask', 'taskId': 't-1'},
    humanLabel: humanLabel,
    status: status,
  );
}

void main() {
  group('AssistantAction construction', () {
    test('defaults status to applied', () {
      final a = _action();
      expect(a.status, AssistantActionStatus.applied);
    });

    test('rejects an empty id, toolName and humanLabel', () {
      expect(() => _action(id: ''), throwsArgumentError);
      expect(() => _action(toolName: ''), throwsArgumentError);
      expect(() => _action(humanLabel: ''), throwsArgumentError);
    });

    test('rejects a non-UTC timestamp', () {
      expect(
        () => _action(timestamp: DateTime(2026, 11, 4, 12)),
        throwsArgumentError,
      );
    });

    test('rejects an inverse descriptor without a kind', () {
      expect(
        () => _action(inverseDescriptor: const <String, Object?>{}),
        throwsArgumentError,
      );
      expect(
        () => _action(inverseDescriptor: const <String, Object?>{'kind': ''}),
        throwsArgumentError,
      );
      expect(
        () => _action(inverseDescriptor: const <String, Object?>{'kind': 42}),
        throwsArgumentError,
      );
    });

    test('rejects a descriptor with a non-JSON value', () {
      expect(
        () => _action(
          inverseDescriptor: <String, Object?>{
            'kind': 'x',
            'bad': DateTime.utc(2026),
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => _action(
          inverseDescriptor: <String, Object?>{
            'kind': 'x',
            'nested': <Object?>[DateTime.utc(2026)],
          },
        ),
        throwsArgumentError,
      );
    });

    test('accepts a nested, JSON-shaped descriptor', () {
      final a = _action(
        inverseDescriptor: <String, Object?>{
          'kind': 'restoreTask',
          'task': <String, Object?>{
            'id': 't-1',
            'title': 'Gym',
            'minutes': 25,
            'tags': <Object?>['fitness', 'morning'],
            'notes': null,
            'done': false,
          },
        },
      );
      expect(a.inverseDescriptor['kind'], 'restoreTask');
    });
  });

  group('AssistantAction value semantics', () {
    test('equal actions compare equal and share a hashCode', () {
      final a = _action();
      final b = _action();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different descriptor breaks equality', () {
      final a = _action(
        inverseDescriptor: const <String, Object?>{
          'kind': 'deleteTask',
          'taskId': 't-1',
        },
      );
      final b = _action(
        inverseDescriptor: const <String, Object?>{
          'kind': 'deleteTask',
          'taskId': 't-2',
        },
      );
      expect(a == b, isFalse);
    });

    test('copyWith overrides only the fields passed', () {
      final a = _action();
      final b = a.copyWith(status: AssistantActionStatus.undone);
      expect(b.status, AssistantActionStatus.undone);
      expect(b.id, a.id);
      expect(b.toolName, a.toolName);
      expect(b.humanLabel, a.humanLabel);
      expect(b.timestamp, a.timestamp);
      expect(b.inverseDescriptor, a.inverseDescriptor);
    });
  });

  group('AssistantActionLog append / snapshot', () {
    test('rejects a non-positive capacity', () {
      expect(() => AssistantActionLog(capacity: 0), throwsAssertionError);
      expect(() => AssistantActionLog(capacity: -1), throwsAssertionError);
    });

    test('newly constructed log is empty', () {
      final log = AssistantActionLog();
      expect(log.length, 0);
      expect(log.isEmpty, isTrue);
      expect(log.isNotEmpty, isFalse);
      expect(log.entries, isEmpty);
      expect(log.capacity, 20);
    });

    test('appended entries are returned newest-first', () {
      final log = AssistantActionLog();
      final a = _action(id: 'a', timestamp: DateTime.utc(2026, 11, 4, 9));
      final b = _action(id: 'b', timestamp: DateTime.utc(2026, 11, 4, 10));
      final c = _action(id: 'c', timestamp: DateTime.utc(2026, 11, 4, 11));
      log
        ..append(a)
        ..append(b)
        ..append(c);
      expect(log.entries.map((e) => e.id).toList(), <String>['c', 'b', 'a']);
    });

    test('the snapshot list is unmodifiable', () {
      final log = AssistantActionLog();
      log.append(_action());
      final snapshot = log.entries;
      expect(() => snapshot.clear(), throwsUnsupportedError);
      expect(() => snapshot.removeAt(0), throwsUnsupportedError);
    });

    test('appending past capacity drops the oldest entry', () {
      final log = AssistantActionLog(capacity: 3);
      log
        ..append(_action(id: 'a'))
        ..append(_action(id: 'b'))
        ..append(_action(id: 'c'))
        ..append(_action(id: 'd'));
      expect(log.length, 3);
      expect(log.entries.map((e) => e.id).toList(), <String>['d', 'c', 'b']);
      expect(log.byId('a'), isNull);
    });

    test('appending a duplicate id throws and does not change the log', () {
      final log = AssistantActionLog();
      log.append(_action(id: 'a'));
      expect(() => log.append(_action(id: 'a')), throwsArgumentError);
      expect(log.length, 1);
    });

    test('byId returns the matching entry or null', () {
      final log = AssistantActionLog();
      final a = _action(id: 'a');
      log.append(a);
      expect(log.byId('a'), a);
      expect(log.byId('missing'), isNull);
      expect(log.byId(''), isNull);
    });
  });

  group('AssistantActionLog markUndone', () {
    test('flips an applied entry to undone in place', () {
      final log = AssistantActionLog();
      log
        ..append(_action(id: 'a'))
        ..append(_action(id: 'b'));
      final changed = log.markUndone('a');
      expect(changed, isTrue);
      expect(log.byId('a')!.status, AssistantActionStatus.undone);
      expect(log.byId('b')!.status, AssistantActionStatus.applied);
      // Order is preserved — undo does not move the row.
      expect(log.entries.map((e) => e.id).toList(), <String>['b', 'a']);
    });

    test('returns false for an unknown id', () {
      final log = AssistantActionLog();
      log.append(_action(id: 'a'));
      expect(log.markUndone('missing'), isFalse);
      expect(log.markUndone(''), isFalse);
    });

    test('is idempotent on an already-undone entry', () {
      final log = AssistantActionLog();
      log.append(_action(id: 'a'));
      expect(log.markUndone('a'), isTrue);
      expect(log.markUndone('a'), isFalse);
      expect(log.byId('a')!.status, AssistantActionStatus.undone);
    });
  });

  group('AssistantActionLog listener semantics', () {
    test('append and markUndone fire listeners; no-ops do not', () {
      final log = AssistantActionLog();
      var notified = 0;
      log.addListener(() => notified++);

      log.append(_action(id: 'a'));
      expect(notified, 1);

      // Duplicate append throws and must not notify.
      expect(() => log.append(_action(id: 'a')), throwsArgumentError);
      expect(notified, 1);

      log.markUndone('a');
      expect(notified, 2);

      // Second undo is a no-op and must not notify.
      log.markUndone('a');
      expect(notified, 2);

      // Unknown id must not notify.
      log.markUndone('missing');
      expect(notified, 2);
    });

    test('clear fires once when non-empty and not at all when empty', () {
      final log = AssistantActionLog();
      var notified = 0;
      log.addListener(() => notified++);

      log.clear();
      expect(notified, 0);

      log.append(_action(id: 'a'));
      expect(notified, 1);

      log.clear();
      expect(notified, 2);
      expect(log.isEmpty, isTrue);
    });

    test('the log is a Listenable the UI can observe', () {
      final log = AssistantActionLog();
      expect(log, isA<Listenable>());
    });
  });
}
