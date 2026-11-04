import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/home_widget/widget_action.dart';

void main() {
  group('encode / decode', () {
    test('round-trips a Done payload', () {
      const original = WidgetActionTaskDone(taskId: 'abc');
      final decoded = WidgetAction.tryDecode(original.encode());
      expect(decoded, isA<WidgetActionTaskDone>());
      expect(decoded, equals(original));
      expect(decoded!.taskId, 'abc');
    });

    test('round-trips a Start-focus payload', () {
      const original = WidgetActionStartFocus(taskId: 'xyz');
      final decoded = WidgetAction.tryDecode(original.encode());
      expect(decoded, isA<WidgetActionStartFocus>());
      expect(decoded, equals(original));
      expect(decoded!.taskId, 'xyz');
    });

    test('encoded form carries kind and taskId only', () {
      final json =
          jsonDecode(const WidgetActionTaskDone(taskId: 't').encode())
              as Map<String, Object?>;
      expect(json, {'kind': 'taskDone', 'taskId': 't'});
    });

    test('rejects null, empty, non-JSON, and non-object payloads', () {
      expect(WidgetAction.tryDecode(null), isNull);
      expect(WidgetAction.tryDecode(''), isNull);
      expect(WidgetAction.tryDecode('not json'), isNull);
      expect(WidgetAction.tryDecode('"a string"'), isNull);
      expect(WidgetAction.tryDecode('[]'), isNull);
    });

    test('rejects an unknown kind (forward compatibility)', () {
      final raw = jsonEncode({'kind': 'planMyDay', 'taskId': 't'});
      expect(WidgetAction.tryDecode(raw), isNull);
    });

    test('rejects a missing or empty taskId', () {
      expect(
        WidgetAction.tryDecode(jsonEncode({'kind': 'taskDone'})),
        isNull,
      );
      expect(
        WidgetAction.tryDecode(
          jsonEncode({'kind': 'taskDone', 'taskId': ''}),
        ),
        isNull,
      );
      expect(
        WidgetAction.tryDecode(
          jsonEncode({'kind': 'taskDone', 'taskId': 42}),
        ),
        isNull,
      );
    });
  });

  group('equality', () {
    test('two Done payloads with the same taskId are equal', () {
      expect(
        const WidgetActionTaskDone(taskId: 'a'),
        equals(const WidgetActionTaskDone(taskId: 'a')),
      );
    });

    test('Done and Start-focus with the same taskId are NOT equal', () {
      expect(
        const WidgetActionTaskDone(taskId: 'a') ==
            const WidgetActionStartFocus(taskId: 'a'),
        isFalse,
      );
    });

    test('hashCode differs by kind', () {
      expect(
        const WidgetActionTaskDone(taskId: 'a').hashCode,
        isNot(const WidgetActionStartFocus(taskId: 'a').hashCode),
      );
    });
  });

  test('switch over WidgetAction is exhaustive', () {
    // Compile-time check: a `switch` with no default must cover every
    // subclass. A new kind added without a case here fails analysis.
    String label(WidgetAction a) => switch (a) {
      WidgetActionTaskDone() => 'done',
      WidgetActionStartFocus() => 'focus',
    };
    expect(label(const WidgetActionTaskDone(taskId: 't')), 'done');
    expect(label(const WidgetActionStartFocus(taskId: 't')), 'focus');
  });
}
