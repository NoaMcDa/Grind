import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/energy.dart';
import 'package:grind/features/assistant/assistant.dart';

void main() {
  group('TaskDraftMerger.merge', () {
    test('overlay fills in fields the base left blank', () {
      const base = TaskDraft(title: 'Gym');
      const overlay = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
        firstAction: 'pack your bag',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      expect(TaskDraftMerger.merge(base, overlay), overlay);
    });

    test('overlay nulls leave base fields untouched', () {
      const base = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
        firstAction: 'pack your bag',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      const overlay = TaskDraft(title: 'Run');
      expect(
        TaskDraftMerger.merge(base, overlay),
        const TaskDraft(
          title: 'Run',
          date: '2026-11-05',
          time: '07:00',
          durationMinutes: 45,
          energy: Energy.light,
          firstAction: 'pack your bag',
          recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO',
        ),
      );
    });

    test('overlay values win on conflict, per field', () {
      const base = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
        time: '07:00',
        durationMinutes: 45,
        energy: Energy.light,
      );
      const overlay = TaskDraft(
        title: 'Gym',
        time: '08:00',
        durationMinutes: 60,
        energy: Energy.deep,
      );
      expect(
        TaskDraftMerger.merge(base, overlay),
        const TaskDraft(
          title: 'Gym',
          date: '2026-11-05', // from base; overlay said nothing.
          time: '08:00', // overlay wins.
          durationMinutes: 60, // overlay wins.
          energy: Energy.deep, // overlay wins.
        ),
      );
    });

    test('title always comes from overlay', () {
      const base = TaskDraft(title: 'Old title', time: '07:00');
      const overlay = TaskDraft(title: 'New title');
      expect(TaskDraftMerger.merge(base, overlay).title, 'New title');
    });

    test('merging with itself is the identity', () {
      const d = TaskDraft(
        title: 'Standup',
        date: '2026-11-05',
        time: '09:30',
        durationMinutes: 15,
        energy: Energy.light,
        firstAction: 'open Zoom',
        recurrenceRrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      );
      expect(TaskDraftMerger.merge(d, d), d);
    });

    test('merge is not commutative', () {
      const a = TaskDraft(title: 'Gym', time: '07:00');
      const b = TaskDraft(title: 'Gym', time: '08:00');
      expect(TaskDraftMerger.merge(a, b).time, '08:00');
      expect(TaskDraftMerger.merge(b, a).time, '07:00');
    });

    test('empty overlay fields cannot clear base fields', () {
      // The merger is additive — overlay saying nothing means "keep
      // whatever the base said". The chat edit flow clears a field
      // through an explicit copyWith, not through a merge.
      const base = TaskDraft(title: 'Gym', durationMinutes: 45);
      const overlay = TaskDraft(title: 'Gym');
      expect(
        TaskDraftMerger.merge(base, overlay).durationMinutes,
        45,
      );
    });

    test('first action and recurrence follow the same rule', () {
      const base = TaskDraft(
        title: 'Run',
        firstAction: 'lace up',
      );
      const overlay = TaskDraft(
        title: 'Run',
        firstAction: 'fill water bottle',
        recurrenceRrule: 'FREQ=DAILY',
      );
      final merged = TaskDraftMerger.merge(base, overlay);
      expect(merged.firstAction, 'fill water bottle');
      expect(merged.recurrenceRrule, 'FREQ=DAILY');
    });
  });

  group('TaskDraftMerger.mergeAll', () {
    test('returns a single-entry list unchanged', () {
      const d = TaskDraft(title: 'Gym', time: '07:00');
      expect(TaskDraftMerger.mergeAll(const [d]), d);
    });

    test('folds a sequence left-to-right', () {
      const first = TaskDraft(title: 'Gym');
      const second = TaskDraft(title: 'Gym', date: '2026-11-05');
      const third = TaskDraft(
        title: 'Gym',
        time: '07:00',
        durationMinutes: 45,
      );
      final merged = TaskDraftMerger.mergeAll(const [first, second, third]);
      expect(
        merged,
        const TaskDraft(
          title: 'Gym',
          date: '2026-11-05',
          time: '07:00',
          durationMinutes: 45,
        ),
      );
    });

    test('later entries override earlier ones on the same field', () {
      const a = TaskDraft(title: 'Gym', time: '07:00');
      const b = TaskDraft(title: 'Gym', time: '08:00');
      const c = TaskDraft(title: 'Gym', time: '09:00');
      expect(TaskDraftMerger.mergeAll(const [a, b, c]).time, '09:00');
    });

    test('throws ArgumentError on an empty list', () {
      expect(
        () => TaskDraftMerger.mergeAll(const []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('diff from base to merge(base, overlay) is overlay-set fields', () {
      // Sanity-check the contract against TaskDraftDiff.
      const base = TaskDraft(
        title: 'Gym',
        date: '2026-11-05',
      );
      const overlay = TaskDraft(
        title: 'Gym',
        time: '07:00',
        durationMinutes: 45,
      );
      final merged = TaskDraftMerger.merge(base, overlay);
      final diff = TaskDraftDiff.between(base, merged);
      expect(diff.changedFields, {
        TaskDraftField.time,
        TaskDraftField.durationMinutes,
      });
    });
  });
}
