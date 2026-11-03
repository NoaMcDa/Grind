import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/plan/draft/day_draft.dart';
import 'package:grind/features/plan/draft/day_drafter.dart';
import 'package:grind/features/plan/plan_reasons_l10n.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';
import 'package:grind/features/tasks/day_bounds.dart';
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

DraftItem _item(
  String id,
  DateTime s,
  DateTime e,
  List<String> reasons, {
  Energy energy = Energy.light,
  DateTime? due,
}) => DraftItem(
  taskId: id,
  start: s,
  end: e,
  reasons: reasons,
  energy: energy,
  due: due,
);

void main() {
  group('fixture days', () {
    test('empty day: deep work in the focus window, light work after '
        'lunch, all before the cushion', () {
      final d = _draft([
        task('thesis', minutes: 90, energy: Energy.deep),
        task('email', minutes: 15, due: at(0, 17)),
        task('read', minutes: 45),
        task('call', minutes: 20, priority: 1),
      ]);
      expect(d.items, [
        _item('thesis', at(0, 9), at(0, 10, 30), const ['your focus window']),
        _item('email', at(0, 13), at(0, 13, 15), const [
          'due today',
          'keeps your focus window clear',
        ]),
        _item('call', at(0, 13, 15), at(0, 13, 35), const [
          'keeps your focus window clear',
        ]),
        _item('read', at(0, 13, 35), at(0, 14, 20), const [
          'keeps your focus window clear',
        ]),
      ]);
      expect(d.unplaced, isEmpty);
      expect(d.laterCount, 0);
      expect(d.freeMinutes, 360); // 09–12 and 13–16 (cushion 16–17)
      expect(d.plannedMinutes, 170);
      expect(d.day, at(0, 0));
    });

    test('meeting-heavy day: short tasks fill the gaps, what is due today '
        'and does not fit says why, the rest waits', () {
      final d = _draft(
        [
          task('slides', minutes: 90, energy: Energy.deep, due: at(3, 17)),
          task('expenses', minutes: 15, due: at(1, 17)),
          task('call', minutes: 20),
          task('essay', minutes: 60, due: at(1, 23)),
        ],
        events: meetingHeavyEvents,
        now: at(1, 8),
      );
      expect(d.freeMinutes, 60); // three 20-minute gaps
      expect(d.items.map((i) => i.taskId), ['call', 'expenses']);
      expect(d.items.first.reasons, const ['fills a 20-minute gap']);
      expect(d.items.last.start, at(1, 13));
      expect(d.unplaced, const [
        UnplacedTask(
          taskId: 'essay',
          minutes: 60,
          reason: "no free 60-minute slot before today's deadline",
        ),
      ]);
      expect(d.laterCount, 1); // the slides, due Friday
      // Nothing overlaps a meeting.
      for (final i in d.items) {
        for (final e in meetingHeavyEvents.where((e) => e.isBusy)) {
          expect(
            Slot(i.start, i.end).overlaps(Slot(e.start, e.end)),
            isFalse,
            reason: '${i.taskId} vs ${e.id}',
          );
        }
      }
    });

    test('overbooked day: the most urgent work fits, the rest is listed '
        'with a reason, nothing runs past the free time', () {
      final d = _draft([
        task('report', minutes: 150, energy: Energy.deep, due: at(0, 17)),
        task('deck', minutes: 120, energy: Energy.deep, due: at(0, 17)),
        task('grading', minutes: 150, due: at(0, 18)),
        task('forms', minutes: 30, due: at(0, 17)),
        task('misc', minutes: 30),
      ]);
      expect(d.items.map((i) => i.taskId), [
        'report',
        'forms',
        'grading',
        'misc',
      ]);
      expect(d.items.first.reasons, const ['due today', 'your focus window']);
      expect(d.plannedMinutes, lessThanOrEqualTo(d.freeMinutes));
      expect(d.unplaced.single.taskId, 'deck');
      expect(
        d.unplaced.single.reason,
        "no free 120-minute slot before today's deadline",
      );
      expect(d.items.last.end.isAfter(at(0, 16)), isFalse);
    });

    test('a day off drafts nothing', () {
      final d = _draft([task('t')], now: at(5, 8)); // Saturday
      expect(d.items, isEmpty);
      expect(d.freeMinutes, 0);
      expect(d.laterCount, 1);
    });

    test('pinned blocks stay and block their time', () {
      final d = _draft([
        task('mine', minutes: 60, lockedStart: at(0, 9), lockedEnd: at(0, 10)),
        task('deep', minutes: 60, energy: Energy.deep),
      ]);
      expect(d.kept.single.taskId, 'mine');
      expect(d.items.single.start, at(0, 10));
      expect(d.freeSlots.first.start, at(0, 10));
    });

    test('planning starts now, not at the start of the day', () {
      final d = _draft([task('t', minutes: 30)], now: at(0, 14, 5));
      expect(d.items.single.start, at(0, 14, 5));
    });
  });

  group('editing', () {
    final base = _draft([
      task('a', minutes: 30, due: at(0, 17)),
      task('b', minutes: 60),
      task('c', minutes: 45, energy: Energy.deep),
    ]);

    test('remove takes one block out and leaves the rest alone', () {
      final first = base.items.first.taskId;
      final d = base.remove(first);
      expect(d.items.map((i) => i.taskId), isNot(contains(first)));
      expect(d.items, base.items.skip(1).toList());
    });

    test('moving up swaps the order and re-fits the day', () {
      expect(base.items, [
        _item('c', at(0, 9), at(0, 9, 45), const [
          'your focus window',
        ], energy: Energy.deep),
        _item('b', at(0, 9, 45), at(0, 10, 45), const [
          'earliest free 60-minute gap',
        ]),
        _item('a', at(0, 13), at(0, 13, 30), const [
          'due today',
          'keeps your focus window clear',
        ], due: at(0, 17)),
      ]);
      final d = base.move('a', -1)!;
      expect(d.items.map((i) => i.taskId), ['c', 'a', 'b']);
      // c keeps its slot; a now starts where b did, b follows a.
      expect(d.items[0], base.items[0]);
      expect(d.items[1].start, at(0, 9, 45));
      expect(d.items[1].reasons, const ['due today', yourOrderReason]);
      expect(d.items[2].start, at(0, 10, 15));
      expect(d.items[2].reasons, const [yourOrderReason]);
    });

    test('moving deep work keeps the focus reason while it stays inside '
        'the window', () {
      final d = base.move('c', 1)!;
      expect(d.items.map((i) => i.taskId), ['b', 'c', 'a']);
      expect(d.items[0].start, at(0, 9));
      expect(d.items[1].start, at(0, 10));
      expect(d.items[1].reasons, const ['your focus window']);
    });

    test('edges and impossible moves return null', () {
      expect(base.move('c', -1), isNull);
      expect(base.move('a', 1), isNull);
      expect(base.move('nope', 1), isNull);
      // A block due at 09:20 cannot follow a 60-minute one.
      final tight = _draft([
        task('due', minutes: 20, due: at(0, 9, 20)),
        task('long', minutes: 60, energy: Energy.deep),
      ]);
      expect(tight.items.map((i) => i.taskId), ['due', 'long']);
      expect(tight.move('due', 1), isNull);
    });
  });

  group('draftCandidates', () {
    setUpAll(ensureTimeZones);
    final loc = locationFor('UTC');
    final day = dayBoundsOf(DateTime(2026, 11, 9), loc);
    final now = DateTime.utc(2026, 11, 9, 8);
    Task t(String id) => Task(
      id: id,
      title: id,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );

    test('keeps open unscheduled work, drops what is anchored elsewhere', () {
      final out = draftCandidates(
        [
          t('open'),
          t('done').copyWith(status: TaskStatus.done),
          t('gone').copyWith(deletedAt: now),
          t('tick').copyWith(category: 'metric-tick'),
          t('reminded').copyWith(remindAt: DateTime.utc(2026, 11, 9, 19)),
          t('past-reminder').copyWith(remindAt: DateTime.utc(2026, 11, 8, 9)),
          t('friday').copyWith(
            scheduledStart: DateTime.utc(2026, 11, 13, 9),
            scheduledEnd: DateTime.utc(2026, 11, 13, 10),
          ),
          t('stale').copyWith(
            scheduledStart: DateTime.utc(2026, 11, 6, 9),
            scheduledEnd: DateTime.utc(2026, 11, 6, 10),
            lockedStart: true,
          ),
          t('pinned').copyWith(
            scheduledStart: DateTime.utc(2026, 11, 9, 15),
            scheduledEnd: DateTime.utc(2026, 11, 9, 16),
            lockedStart: true,
          ),
        ],
        day,
        now,
      );
      final ids = out.map((x) => x.id).toList();
      expect(ids, ['open', 'past-reminder', 'stale', 'pinned']);
      final stale = out.firstWhere((x) => x.id == 'stale');
      expect(stale.isScheduled, isFalse);
      expect(stale.lockedStart, isFalse);
      expect(out.firstWhere((x) => x.id == 'pinned').lockedStart, isTrue);
    });
  });

  test('new reasons are localized', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final he = lookupAppLocalizations(const Locale('he'));
    for (final r in const [
      'fills a 20-minute gap',
      'keeps your focus window clear',
      'in the order you chose',
      'focus blocks are full today',
      'no free 600-minute slot today',
    ]) {
      expect(localizePlanReason(en, r), r, reason: r);
      expect(localizePlanReason(he, r), isNot(r), reason: r);
    }
    expect(localizePlanReason(he, 'fills a 20-minute gap'), contains('20'));
  });
}
