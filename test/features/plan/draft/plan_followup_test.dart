import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/draft/day_draft.dart';
import 'package:grind/features/plan/draft/plan_followup.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';
import 'package:grind/l10n/l10n.dart';

import '../scheduler/fixtures.dart';

DayDraft _draft(
  List<Task> tasks, {
  List<CalendarEvent> events = const [],
  DateTime? now,
}) => draftDay(
  tasks: tasks,
  goals: const {},
  events: events,
  prefs: prefsFixture,
  now: now ?? at(0, 8),
);

DayDraft _syntheticDraft({
  List<DraftItem> items = const [],
  List<UnplacedTask> unplaced = const [],
  int laterCount = 0,
  int freeMinutes = 240,
}) => DayDraft(
  day: at(0, 0),
  from: at(0, 8),
  items: items,
  kept: const [],
  unplaced: unplaced,
  laterCount: laterCount,
  freeSlots: const [],
  freeMinutes: freeMinutes,
  deepWindows: const [],
);

DraftItem _item({
  String id = 'x',
  required DateTime start,
  required DateTime end,
  List<String> reasons = const [],
  Energy energy = Energy.light,
}) => DraftItem(
  taskId: id,
  start: start,
  end: end,
  reasons: reasons,
  energy: energy,
);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final he = lookupAppLocalizations(const Locale('he'));

  group('WhyTaskHere', () {
    test('placed task: names start time and localized reasons', () {
      final draft = _draft([
        task('thesis', minutes: 90, energy: Energy.deep),
        task('email', minutes: 15, due: at(0, 17)),
      ]);
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskHere('thesis'),
        l: en,
      );
      expect(a.sentences, ['It is at 09:00, because your focus window.']);
    });

    test(
      'placed task with several reasons: joined with commas, capped at 3',
      () {
        final draft = _syntheticDraft(
          items: [
            _item(
              start: at(0, 13),
              end: at(0, 13, 30),
              reasons: const [
                'due today',
                'keeps your focus window clear',
                'earliest free 30-minute gap',
                'fills a 30-minute gap',
              ],
            ),
          ],
        );
        final a = answerPlanQuestion(
          draft: draft,
          question: const WhyTaskHere('x'),
          l: en,
        );
        // Only the first three reasons survive the cap.
        expect(a.sentences.single, startsWith('It is at 13:00, because '));
        expect(
          a.sentences.single,
          contains(
            'due today, keeps your focus window clear, '
            'earliest free 30-minute gap',
          ),
        );
        expect(a.sentences.single, isNot(contains('fills a 30-minute gap')));
      },
    );

    test('placed task with no reasons: just the start time', () {
      final draft = _syntheticDraft(
        items: [_item(start: at(0, 14), end: at(0, 14, 30))],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskHere('x'),
        l: en,
      );
      expect(a.sentences, ['It is at 14:00.']);
    });

    test('duplicate reasons are not repeated', () {
      final draft = _syntheticDraft(
        items: [
          _item(
            start: at(0, 10),
            end: at(0, 10, 30),
            reasons: const ['due today', 'due today'],
          ),
        ],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskHere('x'),
        l: en,
      );
      expect(a.sentences.single, 'It is at 10:00, because due today.');
    });

    test(
      'unplaced task asked as "why here": answers with the unplaced reason',
      () {
        final draft = _syntheticDraft(
          unplaced: const [
            UnplacedTask(
              taskId: 'u',
              reason: "no free 60-minute slot before today's deadline",
              minutes: 60,
            ),
          ],
        );
        final a = answerPlanQuestion(
          draft: draft,
          question: const WhyTaskHere('u'),
          l: en,
        );
        expect(a.sentences.single, startsWith('That one did not fit today — '));
      },
    );

    test('unknown task: safe unknown line', () {
      final a = answerPlanQuestion(
        draft: _syntheticDraft(),
        question: const WhyTaskHere('ghost'),
        l: en,
      );
      expect(a.sentences, ['I do not have that one on today\'s plan.']);
    });

    test('Hebrew: start time and reason localize', () {
      final draft = _draft([task('thesis', minutes: 90, energy: Energy.deep)]);
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskHere('thesis'),
        l: he,
      );
      expect(a.sentences.single, startsWith('זה ב-09:00'));
      expect(a.sentences.single, contains('חלון הפוקוס'));
    });
  });

  group('WhyTaskNotPlaced', () {
    test('unplaced task: one sentence with the localized reason', () {
      final draft = _syntheticDraft(
        unplaced: const [
          UnplacedTask(
            taskId: 'u',
            reason: "no free 60-minute slot before today's deadline",
            minutes: 60,
          ),
        ],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskNotPlaced('u'),
        l: en,
      );
      expect(a.sentences, [
        'That one did not fit today — no free 60-minute slot before '
            "today's deadline.",
      ]);
    });

    test('unplaced task with an empty reason: the bare line', () {
      final draft = _syntheticDraft(
        unplaced: const [UnplacedTask(taskId: 'u', reason: '', minutes: 30)],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskNotPlaced('u'),
        l: en,
      );
      expect(a.sentences, ['That one did not fit today.']);
    });

    test('placed task asked as "why not placed": redirect to the time', () {
      final draft = _syntheticDraft(
        items: [_item(start: at(0, 15), end: at(0, 15, 30))],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskNotPlaced('x'),
        l: en,
      );
      expect(a.sentences, ['It is in today\'s plan at 15:00.']);
    });

    test('unknown task: unknown line', () {
      final a = answerPlanQuestion(
        draft: _syntheticDraft(),
        question: const WhyTaskNotPlaced('ghost'),
        l: en,
      );
      expect(a.sentences, ['I do not have that one on today\'s plan.']);
    });

    test('Hebrew unplaced: bare line localizes', () {
      final draft = _syntheticDraft(
        unplaced: const [UnplacedTask(taskId: 'u', reason: '', minutes: 30)],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhyTaskNotPlaced('u'),
        l: he,
      );
      expect(a.sentences, ['זה לא נכנס היום.']);
    });
  });

  group('WhenTaskStarts', () {
    test('placed task: start and end', () {
      final draft = _syntheticDraft(
        items: [_item(start: at(0, 13), end: at(0, 13, 45))],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhenTaskStarts('x'),
        l: en,
      );
      expect(a.sentences, ['It starts at 13:00 and runs until 13:45.']);
    });

    test('unplaced task: bare "did not fit" line', () {
      final draft = _syntheticDraft(
        unplaced: const [UnplacedTask(taskId: 'u', reason: 'r', minutes: 30)],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhenTaskStarts('u'),
        l: en,
      );
      expect(a.sentences, ['That one did not fit today.']);
    });

    test('unknown task: unknown line', () {
      final a = answerPlanQuestion(
        draft: _syntheticDraft(),
        question: const WhenTaskStarts('ghost'),
        l: en,
      );
      expect(a.sentences, ['I do not have that one on today\'s plan.']);
    });

    test('Hebrew: start and end localize', () {
      final draft = _syntheticDraft(
        items: [_item(start: at(0, 9), end: at(0, 10))],
      );
      final a = answerPlanQuestion(
        draft: draft,
        question: const WhenTaskStarts('x'),
        l: he,
      );
      expect(a.sentences.single, startsWith('זה מתחיל ב-09:00'));
      expect(a.sentences.single, contains('10:00'));
    });
  });

  group('tone guardrails', () {
    test('no answer mentions "overdue", "missed" or "failed"', () {
      final draft = _syntheticDraft(
        items: [
          _item(
            start: at(0, 14),
            end: at(0, 14, 30),
            reasons: const ['due today'],
          ),
        ],
        unplaced: const [
          UnplacedTask(
            taskId: 'u',
            reason: 'the due date has passed, want to pick a new one?',
            minutes: 30,
          ),
        ],
      );
      for (final q in const [
        WhyTaskHere('x'),
        WhyTaskHere('u'),
        WhyTaskHere('ghost'),
        WhyTaskNotPlaced('x'),
        WhyTaskNotPlaced('u'),
        WhyTaskNotPlaced('ghost'),
        WhenTaskStarts('x'),
        WhenTaskStarts('u'),
        WhenTaskStarts('ghost'),
      ]) {
        final text = answerPlanQuestion(draft: draft, question: q, l: en).text;
        expect(text, isNot(contains('overdue')), reason: '$q leaked "overdue"');
        expect(text, isNot(contains('missed')), reason: '$q leaked "missed"');
        expect(text, isNot(contains('failed')), reason: '$q leaked "failed"');
      }
    });

    test('every answer is at most two sentences', () {
      final draft = _syntheticDraft(
        items: [
          _item(
            start: at(0, 13),
            end: at(0, 13, 30),
            reasons: const [
              'due today',
              'keeps your focus window clear',
              'earliest free 30-minute gap',
            ],
          ),
        ],
      );
      for (final q in const [
        WhyTaskHere('x'),
        WhyTaskNotPlaced('x'),
        WhenTaskStarts('x'),
      ]) {
        final a = answerPlanQuestion(draft: draft, question: q, l: en);
        expect(
          a.sentences.length,
          inInclusiveRange(1, 2),
          reason: '$q had ${a.sentences.length} sentences',
        );
      }
    });
  });
}
