import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/features/assistant/assistant.dart';

void main() {
  group('TaskDraft', () {
    test('toJson omits nulls', () {
      const d = TaskDraft(title: 'Call dentist');
      expect(d.toJson(), {'title': 'Call dentist'});
    });

    test('toJson includes all set fields with energy as name', () {
      const d = TaskDraft(
        title: 'Gym',
        date: '2026-11-04',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
        firstAction: 'pack your bag',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      expect(d.toJson(), {
        'title': 'Gym',
        'date': '2026-11-04',
        'time': '07:00',
        'durationMinutes': 45,
        'energy': 'light',
        'firstAction': 'pack your bag',
        'recurrence': 'FREQ=WEEKLY;BYDAY=MO',
      });
    });

    test('fromJson round-trips a full draft', () {
      const d = TaskDraft(
        title: 'Thesis chapter 2',
        date: '2026-11-05',
        time: '09:30',
        durationMinutes: 90,
        energy: Energy.deep,
        firstAction: 'open the thesis file',
      );
      final decoded = TaskDraft.fromJson(d.toJson());
      expect(decoded, d);
    });

    test('fromJson rejects empty title', () {
      expect(
        () => TaskDraft.fromJson(const {'title': '   '}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TaskDraft.fromJson(const <String, Object?>{}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson drops malformed date/time/duration', () {
      final decoded = TaskDraft.fromJson(const {
        'title': 'x',
        'date': 'not a date',
        'time': '99:99',
        'durationMinutes': 10000,
        'energy': 'foo',
      });
      expect(decoded.title, 'x');
      expect(decoded.date, isNull);
      expect(decoded.time, isNull);
      expect(decoded.durationMinutes, isNull);
      expect(decoded.energy, isNull);
    });

    test('fromJson accepts numeric duration', () {
      final decoded = TaskDraft.fromJson(const {
        'title': 'walk',
        'durationMinutes': 30,
      });
      expect(decoded.durationMinutes, 30);
    });

    test('copyWith clears fields via explicit null', () {
      const d = TaskDraft(title: 'x', date: '2026-01-01', time: '09:00');
      final cleared = d.copyWith(date: null, time: null);
      expect(cleared.date, isNull);
      expect(cleared.time, isNull);
    });

    test('jsonSchema is strict and names TaskDraft fields', () {
      final schema = TaskDraft.jsonSchema;
      expect(schema['type'], 'object');
      expect(schema['additionalProperties'], isFalse);
      expect(schema['required'], ['title']);
      final props = schema['properties']! as Map<String, Object?>;
      expect(props.keys.toSet(), {
        'title',
        'date',
        'time',
        'durationMinutes',
        'energy',
        'firstAction',
        'recurrence',
      });
      final energy = props['energy']! as Map<String, Object?>;
      expect(energy['enum'], ['deep', 'light']);
    });

    test('equality distinguishes by every field', () {
      const a = TaskDraft(title: 'x', date: '2026-01-01');
      const b = TaskDraft(title: 'x', date: '2026-01-01');
      const c = TaskDraft(title: 'x', date: '2026-01-02');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });
}
