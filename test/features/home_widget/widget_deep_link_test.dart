import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/home_widget/widget_deep_link.dart';

void main() {
  group('tryParse', () {
    test('grind://widget → open the app', () {
      expect(WidgetDeepLink.tryParse('grind://widget'), const WidgetOpenApp());
      expect(WidgetDeepLink.tryParse('grind://widget/'), const WidgetOpenApp());
    });

    test('grind://widget/task/<id> → open the task detail', () {
      final link = WidgetDeepLink.tryParse('grind://widget/task/abc');
      expect(link, const WidgetOpenTask(taskId: 'abc'));
    });

    test('grind://widget/task/<id>/done → mark the task done', () {
      final link = WidgetDeepLink.tryParse('grind://widget/task/abc/done');
      expect(link, const WidgetMarkTaskDone(taskId: 'abc'));
    });

    test('grind://widget/focus → start focus with no task preselected', () {
      expect(
        WidgetDeepLink.tryParse('grind://widget/focus'),
        const WidgetStartFocus(),
      );
    });

    test('grind://widget/focus/<id> → start focus on that task', () {
      final link = WidgetDeepLink.tryParse('grind://widget/focus/t-1');
      expect(link, const WidgetStartFocus(taskId: 't-1'));
    });

    test('grind://widget/plan → plan my day', () {
      expect(
        WidgetDeepLink.tryParse('grind://widget/plan'),
        const WidgetPlanMyDay(),
      );
    });

    test('accepts a Uri as well as a string', () {
      final uri = Uri.parse('grind://widget/task/xy/done');
      expect(
        WidgetDeepLink.tryParse(uri),
        const WidgetMarkTaskDone(taskId: 'xy'),
      );
    });

    test('non-widget URIs return null', () {
      // Wrong scheme.
      expect(WidgetDeepLink.tryParse('https://widget/task/a'), isNull);
      // Right scheme, wrong host — e.g. the calendar write-back link.
      expect(WidgetDeepLink.tryParse('grind://task/a'), isNull);
      // Right scheme, empty host — the Live Activity `grind:///focus`.
      expect(WidgetDeepLink.tryParse('grind:///focus'), isNull);
    });

    test('unknown verbs return null (forward compatibility)', () {
      expect(WidgetDeepLink.tryParse('grind://widget/snooze/a'), isNull);
      expect(WidgetDeepLink.tryParse('grind://widget/task'), isNull);
      // Known verb with an unknown action on a task.
      expect(WidgetDeepLink.tryParse('grind://widget/task/a/snooze'), isNull);
      // Too many segments.
      expect(WidgetDeepLink.tryParse('grind://widget/plan/extra'), isNull);
      expect(WidgetDeepLink.tryParse('grind://widget/focus/a/b'), isNull);
    });

    test('malformed input returns null', () {
      expect(WidgetDeepLink.tryParse(null), isNull);
      expect(WidgetDeepLink.tryParse(''), isNull);
      expect(WidgetDeepLink.tryParse(42), isNull);
      expect(WidgetDeepLink.tryParse('not a uri at all'), isNull);
    });

    test('a missing task id does not pass as empty', () {
      // `grind://widget/task//done` collapses to two segments "task" and
      // "done", which is not a legal shape.
      expect(WidgetDeepLink.tryParse('grind://widget/task//done'), isNull);
      expect(WidgetDeepLink.tryParse('grind://widget/task/'), isNull);
    });
  });

  group('toUri', () {
    test('open-app URL has no path', () {
      expect(const WidgetOpenApp().toUriString(), 'grind://widget');
    });

    test('task verb carries just the id', () {
      expect(
        const WidgetOpenTask(taskId: 'abc').toUriString(),
        'grind://widget/task/abc',
      );
    });

    test('task-done carries the id and the done action', () {
      expect(
        const WidgetMarkTaskDone(taskId: 'abc').toUriString(),
        'grind://widget/task/abc/done',
      );
    });

    test('start-focus without a task id has just the verb', () {
      expect(const WidgetStartFocus().toUriString(), 'grind://widget/focus');
    });

    test('start-focus with a task id appends it', () {
      expect(
        const WidgetStartFocus(taskId: 't').toUriString(),
        'grind://widget/focus/t',
      );
    });

    test('plan carries just the verb', () {
      expect(const WidgetPlanMyDay().toUriString(), 'grind://widget/plan');
    });

    test('percent-encodes an id with URL-unsafe characters', () {
      // Uuid-shaped ids never need it, but drafts occasionally include a
      // slash or a space; we rely on Uri to encode them correctly, and
      // the parser peels them back.
      final encoded = const WidgetOpenTask(taskId: 'a b/c').toUriString();
      expect(encoded, 'grind://widget/task/a%20b%2Fc');
      expect(
        WidgetDeepLink.tryParse(encoded),
        const WidgetOpenTask(taskId: 'a b/c'),
      );
    });
  });

  group('round-trip', () {
    const samples = <WidgetDeepLink>[
      WidgetOpenApp(),
      WidgetOpenTask(taskId: 't-1'),
      WidgetMarkTaskDone(taskId: 't-1'),
      WidgetStartFocus(),
      WidgetStartFocus(taskId: 't-2'),
      WidgetPlanMyDay(),
    ];

    for (final link in samples) {
      test('$link → URL → link', () {
        expect(WidgetDeepLink.tryParse(link.toUriString()), link);
      });
    }
  });

  group('equality', () {
    test('same shape and id compare equal', () {
      expect(
        const WidgetOpenTask(taskId: 'a'),
        equals(const WidgetOpenTask(taskId: 'a')),
      );
      expect(
        const WidgetStartFocus().hashCode,
        const WidgetStartFocus().hashCode,
      );
    });

    test('open-task and mark-done with the same id are not equal', () {
      expect(
        const WidgetOpenTask(taskId: 'a') ==
            const WidgetMarkTaskDone(taskId: 'a'),
        isFalse,
      );
      expect(
        const WidgetOpenTask(taskId: 'a').hashCode,
        isNot(const WidgetMarkTaskDone(taskId: 'a').hashCode),
      );
    });

    test('focus with and without a task id differ', () {
      expect(
        const WidgetStartFocus() == const WidgetStartFocus(taskId: 'a'),
        isFalse,
      );
    });
  });

  test('switch over WidgetDeepLink is exhaustive', () {
    // Compile-time check: adding a new subclass without a case here
    // fails analysis, so dispatchers stay honest.
    String label(WidgetDeepLink link) => switch (link) {
      WidgetOpenApp() => 'openApp',
      WidgetOpenTask() => 'openTask',
      WidgetMarkTaskDone() => 'markDone',
      WidgetStartFocus() => 'startFocus',
      WidgetPlanMyDay() => 'planMyDay',
    };
    expect(label(const WidgetOpenApp()), 'openApp');
    expect(label(const WidgetPlanMyDay()), 'planMyDay');
  });
}
