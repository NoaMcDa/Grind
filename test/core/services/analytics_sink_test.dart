import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  group('AnalyticsEvent.of', () {
    test('builds an event with only a name', () {
      final e = AnalyticsEvent.of('task_done');
      expect(e.name, 'task_done');
      expect(e.properties, isEmpty);
    });

    test('copies the properties map so caller mutations do not leak in', () {
      final live = <String, Object?>{'source': 'widget'};
      final event = AnalyticsEvent.of('task_done', properties: live);
      live['source'] = 'mutated';
      expect(event.properties['source'], 'widget');
    });

    test('accepts string, int, double, bool and null values', () {
      final event = AnalyticsEvent.of(
        'plan_drafted',
        properties: const {
          'source': 'morning_card',
          'tasks': 5,
          'minutes': 42.5,
          'has_deadline': true,
          'note': null,
        },
      );
      expect(event.properties['source'], 'morning_card');
      expect(event.properties['tasks'], 5);
      expect(event.properties['minutes'], 42.5);
      expect(event.properties['has_deadline'], true);
      expect(event.properties['note'], isNull);
    });

    test('throws on a non-scalar property value', () {
      expect(
        () => AnalyticsEvent.of(
          'bad',
          properties: const {
            'tags': ['a', 'b'],
          },
        ),
        throwsA(
          isA<InvalidAnalyticsPropertyException>().having(
            (e) => e.key,
            'key',
            'tags',
          ),
        ),
      );
    });

    test('rejects a map property value', () {
      expect(
        () => AnalyticsEvent.of(
          'bad',
          properties: const {
            'nested': {'k': 'v'},
          },
        ),
        throwsA(isA<InvalidAnalyticsPropertyException>()),
      );
    });

    test('the returned properties map is unmodifiable', () {
      final event = AnalyticsEvent.of(
        'task_done',
        properties: const {'source': 'widget'},
      );
      expect(
        () => event.properties['source'] = 'elsewhere',
        throwsUnsupportedError,
      );
    });
  });

  group('AnalyticsEvent equality', () {
    test('two events with the same name and properties compare equal', () {
      final a = AnalyticsEvent.of(
        'task_done',
        properties: const {'source': 'widget', 'count': 1},
      );
      final b = AnalyticsEvent.of(
        'task_done',
        properties: const {'count': 1, 'source': 'widget'},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('name differences break equality', () {
      final a = AnalyticsEvent.of('task_done');
      final b = AnalyticsEvent.of('task_undone');
      expect(a, isNot(equals(b)));
    });

    test('property differences break equality', () {
      final a = AnalyticsEvent.of(
        'task_done',
        properties: const {'source': 'widget'},
      );
      final b = AnalyticsEvent.of(
        'task_done',
        properties: const {'source': 'today'},
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('NoopAnalyticsSink', () {
    test('accepts events and does nothing observable', () {
      const sink = NoopAnalyticsSink();
      // No throw, no state, no return value.
      sink.record(AnalyticsEvent.of('task_done'));
      sink.record(AnalyticsEvent.of('plan_drafted'));
    });
  });

  group('BufferedAnalyticsSink', () {
    test('records events in order', () {
      final sink = BufferedAnalyticsSink();
      sink.record(AnalyticsEvent.of('a'));
      sink.record(AnalyticsEvent.of('b'));
      sink.record(AnalyticsEvent.of('c'));
      expect(sink.events.map((e) => e.name).toList(), ['a', 'b', 'c']);
    });

    test('clear empties the buffer without affecting later records', () {
      final sink = BufferedAnalyticsSink();
      sink.record(AnalyticsEvent.of('a'));
      sink.clear();
      expect(sink.events, isEmpty);
      sink.record(AnalyticsEvent.of('b'));
      expect(sink.events.map((e) => e.name).toList(), ['b']);
    });

    test('events getter is a read-only view', () {
      final sink = BufferedAnalyticsSink();
      sink.record(AnalyticsEvent.of('a'));
      expect(
        () => sink.events.add(AnalyticsEvent.of('smuggled')),
        throwsUnsupportedError,
      );
      // Internal buffer unchanged.
      expect(sink.events.map((e) => e.name).toList(), ['a']);
    });
  });
}
