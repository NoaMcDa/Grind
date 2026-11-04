import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/plan/plan_reason_category.dart';

void main() {
  // Each test here is one scheduler reason template (from
  // `lib/features/plan/scheduler/planner.dart`,
  // `lib/features/plan/scheduler/replan.dart`, and the `DayDraft` reorder
  // helper) mapped to its bucket. New templates added to the scheduler
  // should be mirrored here so the classifier stays in step with the
  // reasons the planner actually writes.

  group('exact templates', () {
    test('pinned-by-user reason', () {
      expect(
        categorizePlanReason('you placed this here'),
        ReasonCategory.pinnedByUser,
      );
    });

    test('focus-window reason', () {
      expect(
        categorizePlanReason('your focus window'),
        ReasonCategory.focusWindow,
      );
    });

    test('focus-clear reason', () {
      expect(
        categorizePlanReason('keeps your focus window clear'),
        ReasonCategory.focusClear,
      );
    });

    test('user-order reason', () {
      expect(
        categorizePlanReason('in the order you chose'),
        ReasonCategory.userOrder,
      );
    });

    test('task-state reasons', () {
      const overdue = 'the due date has passed, want to pick a new one?';
      expect(categorizePlanReason(overdue), ReasonCategory.taskState);
      expect(
        categorizePlanReason('this one is already done'),
        ReasonCategory.taskState,
      );
    });

    test('end-of-week deadline-pressure reason', () {
      expect(
        categorizePlanReason('no free gap before the end of the week'),
        ReasonCategory.deadlinePressure,
      );
    });
  });

  group('parameterized placement templates', () {
    test('due <day>', () {
      for (final s in [
        'due today',
        'due tomorrow',
        'due Thursday',
        'due Nov 12',
      ]) {
        expect(categorizePlanReason(s), ReasonCategory.deadline, reason: s);
      }
    });

    test('part of <goal>', () {
      expect(categorizePlanReason('part of Thesis'), ReasonCategory.partOfGoal);
      expect(
        categorizePlanReason('part of Launch roadmap'),
        ReasonCategory.partOfGoal,
      );
    });

    test('chunk labels', () {
      for (final s in [
        'first 45 of 90 min',
        'next 45 of 90 min',
        'last 30 of 90 min',
      ]) {
        expect(categorizePlanReason(s), ReasonCategory.chunk, reason: s);
      }
    });

    test('gap-fit without deadline pressure', () {
      expect(
        categorizePlanReason('earliest free 25-minute gap'),
        ReasonCategory.gapFit,
      );
      expect(
        categorizePlanReason('fills a 20-minute gap'),
        ReasonCategory.gapFit,
      );
    });

    test('deadline-pressure placements', () {
      const samples = [
        "earliest free 25-minute gap before today's deadline",
        'earliest free 45-minute gap before the Thursday deadline',
        'focus blocks are full this week',
        'focus blocks are full before the Friday deadline',
        "only 30 of 60 min fit before tomorrow's deadline",
        'only 15 of 60 min fit today',
        'no free 45-minute slot this week',
        'no free 45-minute slot before Nov 12',
      ];
      for (final s in samples) {
        expect(
          categorizePlanReason(s),
          ReasonCategory.deadlinePressure,
          reason: s,
        );
      }
    });
  });

  group('re-plan diff templates', () {
    test('move reasons bucket as replanMove', () {
      const samples = [
        'that time has passed',
        'your hours changed',
        'an earlier slot opened up',
        "reshuffled around today's changes",
        'you put Dentist there',
        'made room for Essay outline',
        'Team sync now takes that time',
      ];
      for (final s in samples) {
        expect(categorizePlanReason(s), ReasonCategory.replanMove, reason: s);
      }
    });

    test('removal reasons bucket as replanRemove', () {
      const samples = [
        'no longer on your list',
        'done, nice work',
        'skipped for now',
        'no longer fits this week',
      ];
      for (final s in samples) {
        expect(categorizePlanReason(s), ReasonCategory.replanRemove, reason: s);
      }
    });
  });

  group('edges', () {
    test('empty and whitespace-only inputs read as other', () {
      expect(categorizePlanReason(''), ReasonCategory.other);
      expect(categorizePlanReason('   '), ReasonCategory.other);
      expect(categorizePlanReason('\t\n'), ReasonCategory.other);
    });

    test('whitespace around a known template is tolerated', () {
      expect(
        categorizePlanReason('  your focus window  '),
        ReasonCategory.focusWindow,
      );
      expect(categorizePlanReason('\tdue tomorrow\n'), ReasonCategory.deadline);
    });

    test('unknown free-form string reads as other', () {
      expect(
        categorizePlanReason('because I felt like it'),
        ReasonCategory.other,
      );
      expect(categorizePlanReason('???'), ReasonCategory.other);
    });

    test('a title containing a template word does not match that template', () {
      // Part-of is matched only when the string begins with "part of ";
      // a goal titled "part of me" is unusual but legal, and the "part of"
      // template reads the whole string, not a prefix of a longer one.
      expect(categorizePlanReason('part of Thesis'), ReasonCategory.partOfGoal);
      // A string that merely mentions "due" is not the "due <day>" template.
      expect(categorizePlanReason('overdue later'), ReasonCategory.other);
      // "earliest free gap" without the minute count is not the placement
      // template; the scheduler always writes the digits.
      expect(categorizePlanReason('earliest free gap'), ReasonCategory.other);
    });
  });

  test('every enum value has a distinct int index (schema guard)', () {
    final seen = <int>{};
    for (final v in ReasonCategory.values) {
      expect(seen.add(v.index), isTrue, reason: '${v.name} is not unique');
    }
  });
}
