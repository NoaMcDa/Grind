import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/domain/domain.dart';
import 'package:grind/features/plan/scheduler/scheduler.dart';

import 'fixtures.dart';

/// One generated scenario.
class _Case {
  _Case(this.prefs, this.tasks, this.events, this.goals, this.now);

  final Preferences prefs;
  final List<Task> tasks;
  final List<CalendarEvent> events;
  final Map<String, Goal> goals;
  final DateTime now;
}

const _estimates = [10, 15, 25, 30, 45, 60, 90, 120, 180];

_Case _generate(Random r, int seed) {
  final prefs = prefsFixture.copyWith(
    bufferBetweenEventsMinutes: r.nextInt(4) * 5,
    dailyCushionMinutes: r.nextInt(4) * 30,
    maxDeepBlocksPerDay: 1 + r.nextInt(3),
    deepWindows: r.nextBool()
        ? const [TimeRange(startMinutes: 9 * 60, endMinutes: 12 * 60)]
        : const [
            TimeRange(startMinutes: 9 * 60, endMinutes: 11 * 60),
            TimeRange(startMinutes: 14 * 60, endMinutes: 16 * 60),
          ],
  );
  final now = at(r.nextInt(4), 7 + r.nextInt(8), r.nextInt(4) * 15);
  final goals = {
    'g1': goal('g1', 'Thesis', importance: 0.9, progress: 0.4),
    'g2': goal('g2', 'Fitness', importance: 0.3, lastProgressAt: at(-10, 9)),
  };
  final eventCount = r.nextInt(14);
  final taskCount = r.nextInt(r.nextInt(3) == 0 ? 40 : 14);
  final events = <CalendarEvent>[
    for (var i = 0; i < eventCount; i++)
      () {
        final s = at(r.nextInt(7), 7 + r.nextInt(12), r.nextInt(4) * 15);
        return event(
          'e$seed-$i',
          s,
          s.add(Duration(minutes: 15 * (1 + r.nextInt(12)))),
          busy: r.nextInt(7) != 0,
        );
      }(),
  ];
  final tasks = <Task>[];
  var lockedCursor = at(0, 19);
  for (var i = 0; i < taskCount; i++) {
    final minutes = _estimates[r.nextInt(_estimates.length)];
    final dueRoll = r.nextInt(4);
    DateTime? due;
    if (dueRoll > 0) {
      due = at(r.nextInt(10), 9 + r.nextInt(10));
    }
    final locked = r.nextInt(10) == 0;
    DateTime? ls, le;
    if (locked) {
      // Pinned evenings, never overlapping each other.
      ls = lockedCursor;
      le = ls.add(Duration(minutes: minutes));
      lockedCursor = DateTime(ls.year, ls.month, ls.day + 1, 19);
    }
    tasks.add(
      task(
        't$i',
        minutes: minutes,
        energy: r.nextInt(3) == 0 ? Energy.deep : Energy.light,
        due: due,
        priority: 1 + r.nextInt(3),
        goalId: [null, 'g1', 'g2'][r.nextInt(3)],
        splittable: r.nextInt(3) == 0,
        minChunk: [15, 25, 30][r.nextInt(3)],
        lockedStart: ls,
        lockedEnd: le,
        status: r.nextInt(12) == 0 ? TaskStatus.done : TaskStatus.open,
      ),
    );
  }
  return _Case(prefs, tasks, events, goals, now);
}

void main() {
  const runs = 200;

  test('$runs generated weeks keep every invariant', () {
    var totalPlaced = 0, totalUnplaced = 0, totalLocked = 0, totalDeferred = 0;
    for (var seed = 0; seed < runs; seed++) {
      final r = Random(seed);
      final c = _generate(r, seed);
      final horizon = defaultHorizonEnd(c.now, c.prefs);
      Plan run(List<Task> tasks, List<CalendarEvent> events) => plan(
        tasks: tasks,
        goals: c.goals,
        events: events,
        prefs: c.prefs,
        now: c.now,
      );
      final p = run(c.tasks, c.events);
      final reason = 'seed $seed';
      totalPlaced += p.placed.length;
      totalUnplaced += p.unplaced.length;
      totalLocked += p.placed.where((x) => x.locked).length;
      totalDeferred += p.deferralSuggestions.length;

      // Determinism: twice, and with shuffled inputs.
      expect(run(c.tasks, c.events), p, reason: reason);
      final shuffledTasks = [...c.tasks]..shuffle(Random(seed + 1000));
      final shuffledEvents = [...c.events]..shuffle(Random(seed + 2000));
      expect(run(shuffledTasks, shuffledEvents), p, reason: reason);

      final byId = {for (final t in c.tasks) t.id: t};
      final unlocked = p.placed.where((x) => !x.locked).toList();
      final buffer = Duration(minutes: c.prefs.bufferBetweenEventsMinutes);

      for (final x in p.placed) {
        expect(x.reasons.length, inInclusiveRange(1, 3), reason: reason);
        expect(byId[x.taskId]!.status, TaskStatus.open, reason: reason);
      }

      for (final x in unlocked) {
        final t = byId[x.taskId]!;
        // No overlap with busy events (including their buffers).
        for (final e in c.events.where((e) => e.isBusy)) {
          final padded = Slot(e.start.subtract(buffer), e.end.add(buffer));
          expect(x.slot.overlaps(padded), isFalse, reason: '$reason $x $e');
        }
        // Inside working hours, outside lunch, inside the horizon.
        final day = DateTime(x.start.year, x.start.month, x.start.day);
        final hours = c.prefs.workingHours[day.weekday] ?? const [];
        expect(
          hours.any(
            (h) => Slot(
              day.add(Duration(minutes: h.startMinutes)),
              day.add(Duration(minutes: h.endMinutes)),
            ).contains(x.slot),
          ),
          isTrue,
          reason: '$reason $x',
        );
        for (final l in c.prefs.lunch) {
          final lunch = Slot(
            day.add(Duration(minutes: l.startMinutes)),
            day.add(Duration(minutes: l.endMinutes)),
          );
          expect(x.slot.overlaps(lunch), isFalse, reason: '$reason $x');
        }
        expect(x.start.isBefore(c.now), isFalse, reason: '$reason $x');
        expect(x.end.isAfter(horizon), isFalse, reason: '$reason $x');
        // Never after the due date.
        if (t.dueAt != null) {
          expect(x.end.isAfter(t.dueAt!), isFalse, reason: '$reason $x');
        }
      }

      // No two placements overlap.
      for (var i = 0; i < p.placed.length; i++) {
        for (var j = i + 1; j < p.placed.length; j++) {
          expect(
            p.placed[i].slot.overlaps(p.placed[j].slot),
            isFalse,
            reason: '$reason ${p.placed[i]} ${p.placed[j]}',
          );
        }
      }

      // Deep blocks per day ≤ max.
      final deepPerDay = <DateTime, int>{};
      for (final x in unlocked) {
        if (byId[x.taskId]!.energy != Energy.deep) continue;
        final d = DateTime(x.start.year, x.start.month, x.start.day);
        deepPerDay[d] = (deepPerDay[d] ?? 0) + 1;
      }
      for (final n in deepPerDay.values) {
        expect(n, lessThanOrEqualTo(c.prefs.maxDeepBlocksPerDay));
      }

      // Total placed ≤ free.
      final locked = c.tasks
          .where((t) => isOpenTask(t) && isPinned(t))
          .toList();
      final free = freeSlots(
        from: c.now,
        to: horizon,
        prefs: c.prefs,
        events: c.events,
        lockedTasks: locked,
      ).fold(0, (s, x) => s + x.minutes);
      final placedMinutes = unlocked.fold(0, (s, x) => s + x.minutes);
      expect(placedMinutes, lessThanOrEqualTo(free), reason: reason);
      expect(
        placedMinutes,
        lessThanOrEqualTo(p.capacity.freeMinutes),
        reason: reason,
      );

      // Every open, unpinned task is fully accounted for, and every
      // unplaced one has a reason.
      for (final t in c.tasks.where((t) => isOpenTask(t) && !isPinned(t))) {
        final got = p.placementsFor(t.id).fold(0, (s, x) => s + x.minutes);
        final missing = p.unplaced
            .where((u) => u.taskId == t.id)
            .fold(0, (s, u) => s + u.minutes);
        expect(
          got + missing,
          adjustedMinutes(t, const UserStats()),
          reason: '$reason ${t.id}',
        );
      }
      for (final u in p.unplaced) {
        expect(u.reason, isNotEmpty, reason: reason);
      }

      // Deferrals never touch tasks due inside the horizon.
      for (final d in p.deferralSuggestions) {
        final due = byId[d.taskId]!.dueAt;
        expect(due == null || due.isAfter(horizon), isTrue, reason: reason);
      }
    }
    // The generator must actually exercise the scheduler.
    expect(totalPlaced, greaterThan(500));
    expect(totalUnplaced, greaterThan(20));
    expect(totalLocked, greaterThan(20));
    expect(totalDeferred, greaterThan(5));
  });

  test(
    're-plans of $runs generated weeks: pins stay, every move explained',
    () {
      for (var seed = 0; seed < runs; seed++) {
        final c = _generate(Random(seed), seed);
        final previous = plan(
          tasks: c.tasks,
          goals: c.goals,
          events: c.events,
          prefs: c.prefs,
          now: c.now,
        );
        // Mark the first open task done and push the first event an hour.
        final open = c.tasks
            .where((t) => isOpenTask(t) && !isPinned(t))
            .toList();
        final tasks = [
          for (final t in c.tasks)
            open.isNotEmpty && t.id == open.first.id
                ? t.copyWith(status: TaskStatus.done)
                : t,
        ];
        final events = [
          for (var i = 0; i < c.events.length; i++)
            i == 0
                ? c.events[i].copyWith(
                    start: c.events[i].start.add(const Duration(hours: 1)),
                    end: c.events[i].end.add(const Duration(hours: 1)),
                  )
                : c.events[i],
        ];
        final r = replan(
          previous: previous,
          tasks: tasks,
          goals: c.goals,
          events: events,
          prefs: c.prefs,
          now: c.now,
        );
        final reason = 'seed $seed';
        for (final l in previous.placed.where((p) => p.locked)) {
          expect(r.plan.placed, contains(l), reason: reason);
        }
        for (final m in r.diff.moved) {
          expect(m.reason, isNotEmpty, reason: reason);
          expect(
            previous.placementsFor(m.taskId).any((p) => p.locked),
            isFalse,
          );
        }
        for (final x in r.diff.removed) {
          expect(x.reason, isNotEmpty, reason: reason);
        }
        if (open.isNotEmpty &&
            previous.placementsFor(open.first.id).isNotEmpty) {
          expect(
            r.diff.removed.map((x) => x.taskId),
            contains(open.first.id),
            reason: reason,
          );
        }
      }
    },
  );
}
