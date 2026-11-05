import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/features/assistant/assistant.dart';

void main() {
  group('TaskDraftDiff', () {
    test('empty when drafts are identical', () {
      const d = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
        firstAction: 'pack your bag',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      final diff = TaskDraftDiff.between(d, d);
      expect(diff.isEmpty, isTrue);
      expect(diff.isNotEmpty, isFalse);
      expect(diff.length, 0);
      expect(diff.changedFields, isEmpty);
      expect(diff, TaskDraftDiff.empty);
    });

    test('reports a title change', () {
      const before = TaskDraft(title: 'Gym');
      const after = TaskDraft(title: 'Run');
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.changedFields, {TaskDraftField.title});
      expect(diff.contains(TaskDraftField.title), isTrue);
      expect(diff.length, 1);
    });

    test('reports setting a previously unset field', () {
      const before = TaskDraft(title: 'Gym');
      const after = TaskDraft(title: 'Gym', time: '07:00');
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.changedFields, {TaskDraftField.time});
    });

    test('reports clearing a previously set field', () {
      const before = TaskDraft(title: 'Gym', durationMinutes: 45);
      const after = TaskDraft(title: 'Gym');
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.changedFields, {TaskDraftField.durationMinutes});
    });

    test('reports replacing a value', () {
      const before = TaskDraft(title: 'Gym', energy: Energy.light);
      const after = TaskDraft(title: 'Gym', energy: Energy.deep);
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.changedFields, {TaskDraftField.energy});
    });

    test('reports multiple changes at once', () {
      const before = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
        durationMinutes: 45,
      );
      const after = TaskDraft(
        title: 'Gym',
        date: '2026-11-06',
        time: '07:00',
        durationMinutes: 60,
      );
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.changedFields, {
        TaskDraftField.date,
        TaskDraftField.time,
        TaskDraftField.durationMinutes,
      });
      expect(diff.length, 3);
    });

    test('reports first-action and recurrence changes', () {
      const before = TaskDraft(title: 'Standup');
      const after = TaskDraft(
        title: 'Standup',
        firstAction: 'open Zoom',
        recurrenceRrule: 'FREQ=DAILY',
      );
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.changedFields, {
        TaskDraftField.firstAction,
        TaskDraftField.recurrenceRrule,
      });
    });

    test('reports every field when nothing matches', () {
      const before = TaskDraft(title: 'Gym');
      const after = TaskDraft(
        title: 'Run',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 30,
        energy: Energy.deep,
        firstAction: 'lace up',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.changedFields, TaskDraftField.values.toSet());
      expect(diff.length, TaskDraftField.values.length);
    });

    test('changedFields iterates in declaration order', () {
      const before = TaskDraft(title: 'A');
      const after = TaskDraft(
        title: 'B',
        date: '2026-11-05',
        durationMinutes: 30,
        energy: Energy.deep,
      );
      final diff = TaskDraftDiff.between(before, after);
      // Converting to a list preserves insertion order on LinkedHashSet,
      // which Set.unmodifiable wraps. We insert in TaskDraftField order
      // in the factory, so the output must match that order.
      expect(diff.changedFields.toList(), [
        TaskDraftField.title,
        TaskDraftField.date,
        TaskDraftField.durationMinutes,
        TaskDraftField.energy,
      ]);
    });

    test('changedFields set is unmodifiable', () {
      const before = TaskDraft(title: 'Gym');
      const after = TaskDraft(title: 'Run');
      final diff = TaskDraftDiff.between(before, after);
      expect(
        () => diff.changedFields.add(TaskDraftField.date),
        throwsUnsupportedError,
      );
    });

    test('equality is by changed-field set', () {
      const before = TaskDraft(title: 'Gym');
      const afterA = TaskDraft(title: 'Run');
      const afterB = TaskDraft(title: 'Swim');
      final a = TaskDraftDiff.between(before, afterA);
      final b = TaskDraftDiff.between(before, afterB);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      const afterC = TaskDraft(title: 'Run', time: '07:00');
      final c = TaskDraftDiff.between(before, afterC);
      expect(a, isNot(equals(c)));
    });

    test('toString reports field names, or "empty"', () {
      const before = TaskDraft(title: 'Gym');
      final empty = TaskDraftDiff.between(before, before);
      expect(empty.toString(), 'TaskDraftDiff(empty)');

      const after = TaskDraft(title: 'Run', time: '07:00');
      final diff = TaskDraftDiff.between(before, after);
      expect(diff.toString(), 'TaskDraftDiff(title, time)');
    });

    test('TaskDraftDiff.empty is the zero value', () {
      expect(TaskDraftDiff.empty.isEmpty, isTrue);
      expect(TaskDraftDiff.empty.length, 0);
      expect(TaskDraftDiff.empty.changedFields, isEmpty);
    });
  });
}
