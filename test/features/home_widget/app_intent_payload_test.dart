import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/home_widget/app_intent_payload.dart';

void main() {
  group('encode / decode', () {
    test('round-trips AddTask with every optional field', () {
      final original = AppIntentAddTask(
        title: 'Buy milk',
        notes: 'oat, 2L',
        dueAt: DateTime.utc(2026, 4, 20, 17, 0),
      );
      final decoded = AppIntentPayload.tryDecode(original.encode());
      expect(decoded, isA<AppIntentAddTask>());
      expect(decoded, equals(original));
      final addTask = decoded! as AppIntentAddTask;
      expect(addTask.title, 'Buy milk');
      expect(addTask.notes, 'oat, 2L');
      expect(addTask.dueAt, DateTime.utc(2026, 4, 20, 17, 0));
    });

    test('round-trips a bare AddTask (title only)', () {
      final original = AppIntentAddTask(title: 'Call dentist');
      final decoded = AppIntentPayload.tryDecode(original.encode());
      expect(decoded, equals(original));
      final addTask = decoded! as AppIntentAddTask;
      expect(addTask.notes, isNull);
      expect(addTask.dueAt, isNull);
    });

    test('AddTask encoded form omits null optionals', () {
      final json =
          jsonDecode(AppIntentAddTask(title: 'Walk').encode())
              as Map<String, Object?>;
      expect(json, {'kind': 'addTask', 'title': 'Walk'});
    });

    test('AddTask normalises title whitespace', () {
      final payload = AppIntentAddTask(title: '  padded  ');
      expect(payload.title, 'padded');
      final decoded =
          AppIntentPayload.tryDecode(jsonEncode({'kind': 'addTask', 'title': '  padded  '}))
              as AppIntentAddTask?;
      expect(decoded?.title, 'padded');
    });

    test('AddTask stores dueAt in UTC even when given a local timestamp', () {
      // A Shortcuts timestamp with an offset parses into a local DateTime;
      // the payload canonicalises to UTC so the dispatcher never sees two
      // forms of the same instant.
      final raw = jsonEncode({
        'kind': 'addTask',
        'title': 'Standup',
        'dueAt': '2026-04-20T10:00:00+03:00',
      });
      final decoded = AppIntentPayload.tryDecode(raw) as AppIntentAddTask?;
      expect(decoded, isNotNull);
      expect(decoded!.dueAt!.isUtc, isTrue);
      expect(decoded.dueAt, DateTime.utc(2026, 4, 20, 7, 0));
    });

    test('round-trips StartFocus with a taskId', () {
      const original = AppIntentStartFocus(taskId: 'task-123');
      final decoded = AppIntentPayload.tryDecode(original.encode());
      expect(decoded, isA<AppIntentStartFocus>());
      expect(decoded, equals(original));
      expect((decoded! as AppIntentStartFocus).taskId, 'task-123');
    });

    test('round-trips StartFocus without a taskId (free session)', () {
      const original = AppIntentStartFocus();
      final decoded = AppIntentPayload.tryDecode(original.encode());
      expect(decoded, isA<AppIntentStartFocus>());
      expect(decoded, equals(original));
      expect((decoded! as AppIntentStartFocus).taskId, isNull);
    });

    test('StartFocus encoded form omits a null taskId', () {
      final json =
          jsonDecode(const AppIntentStartFocus().encode())
              as Map<String, Object?>;
      expect(json, {'kind': 'startFocus'});
    });

    test('round-trips PlanMyDay', () {
      const original = AppIntentPlanMyDay();
      final decoded = AppIntentPayload.tryDecode(original.encode());
      expect(decoded, isA<AppIntentPlanMyDay>());
      expect(decoded, equals(original));
    });

    test('PlanMyDay encoded form carries only the kind', () {
      final json =
          jsonDecode(const AppIntentPlanMyDay().encode())
              as Map<String, Object?>;
      expect(json, {'kind': 'planMyDay'});
    });

    test('rejects null, empty, non-JSON, and non-object payloads', () {
      expect(AppIntentPayload.tryDecode(null), isNull);
      expect(AppIntentPayload.tryDecode(''), isNull);
      expect(AppIntentPayload.tryDecode('not json'), isNull);
      expect(AppIntentPayload.tryDecode('"a string"'), isNull);
      expect(AppIntentPayload.tryDecode('[]'), isNull);
    });

    test('rejects an unknown kind (forward compatibility)', () {
      final raw = jsonEncode({'kind': 'sendReminder', 'title': 't'});
      expect(AppIntentPayload.tryDecode(raw), isNull);
    });

    test('rejects AddTask with a missing, non-string, or blank title', () {
      expect(AppIntentPayload.tryDecode(jsonEncode({'kind': 'addTask'})), isNull);
      expect(
        AppIntentPayload.tryDecode(jsonEncode({'kind': 'addTask', 'title': 42})),
        isNull,
      );
      expect(
        AppIntentPayload.tryDecode(jsonEncode({'kind': 'addTask', 'title': ''})),
        isNull,
      );
      expect(
        AppIntentPayload.tryDecode(
          jsonEncode({'kind': 'addTask', 'title': '   '}),
        ),
        isNull,
      );
    });

    test('rejects AddTask with a non-string notes field', () {
      expect(
        AppIntentPayload.tryDecode(
          jsonEncode({'kind': 'addTask', 'title': 't', 'notes': 7}),
        ),
        isNull,
      );
    });

    test('rejects AddTask with an unparseable dueAt', () {
      expect(
        AppIntentPayload.tryDecode(
          jsonEncode({'kind': 'addTask', 'title': 't', 'dueAt': 'tomorrow'}),
        ),
        isNull,
      );
      expect(
        AppIntentPayload.tryDecode(
          jsonEncode({'kind': 'addTask', 'title': 't', 'dueAt': 42}),
        ),
        isNull,
      );
    });

    test('rejects StartFocus with a non-string or empty taskId', () {
      expect(
        AppIntentPayload.tryDecode(
          jsonEncode({'kind': 'startFocus', 'taskId': 42}),
        ),
        isNull,
      );
      expect(
        AppIntentPayload.tryDecode(
          jsonEncode({'kind': 'startFocus', 'taskId': ''}),
        ),
        isNull,
      );
    });
  });

  group('equality', () {
    test('two AddTask payloads with the same fields are equal', () {
      final a = AppIntentAddTask(
        title: 'x',
        notes: 'n',
        dueAt: DateTime.utc(2026, 1, 1),
      );
      final b = AppIntentAddTask(
        title: 'x',
        notes: 'n',
        dueAt: DateTime.utc(2026, 1, 1),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('AddTask differs from StartFocus even with matching ids', () {
      expect(
        AppIntentAddTask(title: 'a') == const AppIntentStartFocus(taskId: 'a'),
        isFalse,
      );
    });

    test('PlanMyDay is a singleton-like value', () {
      expect(const AppIntentPlanMyDay(), equals(const AppIntentPlanMyDay()));
      expect(
        const AppIntentPlanMyDay().hashCode,
        const AppIntentPlanMyDay().hashCode,
      );
    });
  });

  test('switch over AppIntentPayload is exhaustive', () {
    // Compile-time check: a `switch` with no default must cover every
    // subclass. A new intent added without a case here fails analysis.
    String label(AppIntentPayload p) => switch (p) {
      AppIntentAddTask() => 'add',
      AppIntentStartFocus() => 'focus',
      AppIntentPlanMyDay() => 'plan',
    };
    expect(label(AppIntentAddTask(title: 't')), 'add');
    expect(label(const AppIntentStartFocus()), 'focus');
    expect(label(const AppIntentPlanMyDay()), 'plan');
  });
}
