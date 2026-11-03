import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/draft/day_draft.dart';
import 'package:grind/features/plan/draft/plan_explainer.dart';
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

/// A built-by-hand DayDraft used when the test cares about the trailer
/// logic (laterCount vs unplaced vs focus), not about the scheduler's
/// placements. Mirrors how `DayDraft` is constructed inside `draftDay`,
/// and keeps the test independent of the planner's heuristics.
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

  group('edge cases', () {
    test('no open tasks and free time: Pip offers the day back', () {
      final e = explainDayDraft(draft: _syntheticDraft(), l: en);
      expect(e.sentences, [
        'Nothing to plan right now. Your day is yours.',
      ]);
      expect(e.text, 'Nothing to plan right now. Your day is yours.');
    });

    test('no open tasks and no free time: Pip points to tomorrow', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(freeMinutes: 0),
        l: en,
      );
      expect(e.sentences, [
        "No room left on today's calendar. Tomorrow is a fresh page.",
      ]);
    });

    test('tone: nothing to plan never names "overdue" or "missed"', () {
      final text = explainDayDraft(draft: _syntheticDraft(), l: en).text;
      expect(text, isNot(contains('overdue')));
      expect(text, isNot(contains('missed')));
      expect(text, isNot(contains('failed')));
    });
  });

  group('full day from the fixture', () {
    test('focus day: header, range line with planned total, focus trailer', () {
      // Same fixture as day_draft_test "empty day": deep block
      // 09:00–10:30 in the focus window, then three short tasks
      // 13:00–14:20 after lunch. Total planned = 170 min → 3 h.
      final draft = _draft([
        task('thesis', minutes: 90, energy: Energy.deep),
        task('email', minutes: 15, due: at(0, 17)),
        task('read', minutes: 45),
        task('call', minutes: 20, priority: 1),
      ]);
      final e = explainDayDraft(draft: draft, l: en);
      expect(e.sentences, [
        'Here is your day.',
        '4 blocks between 09:00 and 14:20, 3 h in all.',
        'Deep work lands in your focus window.',
      ]);
    });

    test('Hebrew: header, blocks and focus all localize', () {
      final draft = _draft([
        task('thesis', minutes: 90, energy: Energy.deep),
        task('call', minutes: 20),
      ]);
      final e = explainDayDraft(draft: draft, l: he);
      expect(e.sentences[0], 'הנה היום שלך.');
      expect(e.sentences[1], contains(' בלוקים בין '));
      expect(e.sentences[1], endsWith(' סך הכול.'));
      expect(e.sentences[2], 'עבודה עמוקה נוחתת בחלון הפוקוס שלך.');
    });

    test('2–3 sentences, never four', () {
      final draft = _draft([
        task('thesis', minutes: 90, energy: Energy.deep),
        task('email', minutes: 15, due: at(0, 17)),
        task('call', minutes: 20),
        task('later', minutes: 30),
      ]);
      final e = explainDayDraft(draft: draft, l: en);
      expect(e.sentences.length, inInclusiveRange(2, 3));
    });
  });

  group('trailer logic', () {
    test('a deep block in the focus window wins over the later note', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          items: [
            _item(
              start: at(0, 9),
              end: at(0, 10),
              reasons: const ['your focus window'],
              energy: Energy.deep,
            ),
          ],
          laterCount: 2,
        ),
        l: en,
      );
      expect(e.sentences, [
        'Here is your day.',
        'One block between 09:00 and 10:00, 1 h in all.',
        'Deep work lands in your focus window.',
      ]);
    });

    test('no deep block but open tasks wait: later-day note is the trailer',
        () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          items: [
            _item(start: at(0, 13), end: at(0, 13, 30)),
          ],
          laterCount: 2,
        ),
        l: en,
      );
      expect(e.sentences.length, 3);
      expect(e.sentences[2], '2 more things can wait for another day.');
    });

    test('no deep block, nothing for later, only the unplaced: trailer names '
        'that count', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          items: [
            _item(start: at(0, 13), end: at(0, 13, 30)),
          ],
          unplaced: const [
            UnplacedTask(
              taskId: 'u',
              reason: "no free 60-minute slot before today's deadline",
              minutes: 60,
            ),
          ],
        ),
        l: en,
      );
      expect(e.sentences.length, 3);
      expect(e.sentences[2], 'One task does not fit today.');
    });

    test('plain day: just two sentences, no trailer', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          items: [
            _item(start: at(0, 13), end: at(0, 13, 30)),
            _item(start: at(0, 14), end: at(0, 14, 45)),
          ],
        ),
        l: en,
      );
      expect(e.sentences.length, 2);
      expect(e.sentences[1], startsWith('2 blocks between '));
    });

    test('one block uses the singular form', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          items: [_item(start: at(0, 13), end: at(0, 13, 45))],
        ),
        l: en,
      );
      expect(e.sentences[1], 'One block between 13:00 and 13:45, 45 min in all.');
    });

    test('a deep block OUTSIDE a focus window does not trigger the focus '
        'trailer; later note takes over', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          items: [
            // Energy.deep but reasons do NOT contain 'your focus window'.
            _item(
              start: at(0, 14),
              end: at(0, 15),
              energy: Energy.deep,
              reasons: const ['earliest free 60-minute gap'],
            ),
          ],
          laterCount: 1,
        ),
        l: en,
      );
      expect(e.sentences[2], 'One more thing can wait for another day.');
    });
  });

  group('unplaced-only', () {
    test('nothing placed, something could not fit: one sentence names the '
        'count', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          freeMinutes: 0,
          unplaced: const [
            UnplacedTask(
              taskId: 'u',
              reason: "no free 60-minute slot before today's deadline",
              minutes: 60,
            ),
          ],
        ),
        l: en,
      );
      expect(e.sentences, [
        'No room on the calendar today; one task will wait for another day.',
      ]);
    });

    test('Hebrew plural form of unplaced-only', () {
      final e = explainDayDraft(
        draft: _syntheticDraft(
          freeMinutes: 0,
          unplaced: const [
            UnplacedTask(taskId: 'a', reason: 'r', minutes: 30),
            UnplacedTask(taskId: 'b', reason: 'r', minutes: 30),
          ],
        ),
        l: he,
      );
      expect(e.sentences.single, startsWith('אין מקום ביומן היום'));
      expect(e.sentences.single, contains('2 משימות'));
    });
  });
}
