import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/plan/scheduler/plan_diff_summary.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';
import 'package:grind/l10n/l10n.dart';

PlanMove _move(String id, [String reason = 'an earlier slot opened up']) =>
    PlanMove(taskId: id, from: const [], to: const [], reason: reason);

PlanRemoval _removal(String id, [String reason = 'done, nice work']) =>
    PlanRemoval(taskId: id, reason: reason);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final he = lookupAppLocalizations(const Locale('he'));

  group('empty diff', () {
    test('empty diff: Pip says nothing shifted (EN)', () {
      final s = summarizePlanDiff(diff: const PlanDiff(), l: en);
      expect(s.sentences, ['Nothing shifted. Your plan stays as is.']);
      expect(s.text, 'Nothing shifted. Your plan stays as is.');
    });

    test('empty diff: Pip says nothing shifted (HE)', () {
      final s = summarizePlanDiff(diff: const PlanDiff(), l: he);
      expect(s.sentences, ['שום דבר לא זז. התוכנית שלך נשארת כמו שהיא.']);
    });
  });

  group('one category fires', () {
    test('only moves: one sentence names the count (singular)', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(moved: [_move('a')]),
        l: en,
      );
      expect(s.sentences, ['One task moved to a new time.']);
    });

    test('only moves: plural form', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(moved: [_move('a'), _move('b'), _move('c')]),
        l: en,
      );
      expect(s.sentences, ['3 tasks moved to new times.']);
    });

    test('only added: singular form', () {
      final s = summarizePlanDiff(
        diff: const PlanDiff(added: ['a']),
        l: en,
      );
      expect(s.sentences, ['One task joined your plan.']);
    });

    test('only added: plural form', () {
      final s = summarizePlanDiff(
        diff: const PlanDiff(added: ['a', 'b']),
        l: en,
      );
      expect(s.sentences, ['2 tasks joined your plan.']);
    });

    test('only removed: singular form', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(removed: [_removal('a')]),
        l: en,
      );
      expect(s.sentences, ['One task came off your plan.']);
    });

    test('only removed: plural form', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(removed: [_removal('a'), _removal('b')]),
        l: en,
      );
      expect(s.sentences, ['2 tasks came off your plan.']);
    });
  });

  group('two categories: both sentences fire', () {
    test('moved + added: moved first, then added', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(moved: [_move('a')], added: const ['b']),
        l: en,
      );
      expect(s.sentences, [
        'One task moved to a new time.',
        'One task joined your plan.',
      ]);
    });

    test('moved + removed: moved first, then removed', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(moved: [_move('a')], removed: [_removal('b')]),
        l: en,
      );
      expect(s.sentences, [
        'One task moved to a new time.',
        'One task came off your plan.',
      ]);
    });

    test('added + removed (no moves): added first, then removed', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(added: const ['a'], removed: [_removal('b')]),
        l: en,
      );
      expect(s.sentences, [
        'One task joined your plan.',
        'One task came off your plan.',
      ]);
    });
  });

  group('three categories: least-impactful drops', () {
    test(
      'moved + added + removed: removed drops, summary stays at two sentences',
      () {
        final s = summarizePlanDiff(
          diff: PlanDiff(
            moved: [_move('a')],
            added: const ['b'],
            removed: [_removal('c')],
          ),
          l: en,
        );
        expect(s.sentences, [
          'One task moved to a new time.',
          'One task joined your plan.',
        ]);
      },
    );

    test('the summary is never more than two sentences', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(
          moved: [_move('a'), _move('b')],
          added: const ['c'],
          removed: [_removal('d'), _removal('e')],
        ),
        l: en,
      );
      expect(s.sentences.length, lessThanOrEqualTo(2));
    });
  });

  group('Hebrew localization', () {
    test('only moves in Hebrew: plural form carries the count', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(moved: [_move('a'), _move('b')]),
        l: he,
      );
      expect(s.sentences, ['2 משימות זזו לזמנים חדשים.']);
    });

    test('moved + added in Hebrew: two sentences, both localized', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(moved: [_move('a')], added: const ['b', 'c']),
        l: he,
      );
      expect(s.sentences, [
        'משימה אחת זזה לזמן חדש.',
        '2 משימות נכנסו לתוכנית שלך.',
      ]);
    });

    test('removed singular in Hebrew', () {
      final s = summarizePlanDiff(
        diff: PlanDiff(removed: [_removal('a')]),
        l: he,
      );
      expect(s.sentences, ['משימה אחת יצאה מהתוכנית שלך.']);
    });
  });

  group('tone', () {
    test('summary never says "late", "missed" or "overdue"', () {
      final diffs = [
        const PlanDiff(),
        PlanDiff(moved: [_move('a')]),
        const PlanDiff(added: ['a']),
        PlanDiff(removed: [_removal('a')]),
        PlanDiff(
          moved: [_move('a')],
          added: const ['b'],
          removed: [_removal('c')],
        ),
      ];
      for (final d in diffs) {
        final text = summarizePlanDiff(diff: d, l: en).text;
        expect(text, isNot(contains('late')));
        expect(text, isNot(contains('missed')));
        expect(text, isNot(contains('overdue')));
        expect(text, isNot(contains('again')));
      }
    });
  });
}
