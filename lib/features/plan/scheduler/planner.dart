import 'dart:math' as math;

import 'package:grind/core/domain/domain.dart';

import 'capacity.dart';
import 'free_slots.dart';
import 'models.dart';
import 'scoring.dart';
import 'time_math.dart';

/// Places open tasks into free calendar time. Pure and deterministic: the
/// same inputs always give an identical [Plan], on every platform.
///
/// - Horizon: `[now, horizonEnd)`. Default: the end of the current week
///   (by `prefs.weekStart`) or 7 days from [now], whichever is later.
/// - Locked tasks (`lockedStart` and scheduled) that touch the horizon are
///   copied verbatim and their time is taken out of the free slots.
/// - Every other open task is queued by score (desc), due (asc, undated
///   last), adjusted minutes (asc), id (asc), and placed earliest-fit, never
///   before [now] and never ending after its `dueAt`.
/// - Deep tasks look in `prefs.deepWindows` first (any day before the due
///   date), then anywhere; at most `maxDeepBlocksPerDay` deep blocks a day.
///   While deep tasks are still waiting in the queue, light tasks keep out
///   of the focus windows when the same day has room elsewhere.
/// - Splittable tasks are chunked, no chunk shorter than `minChunkMinutes`
///   (except a final remainder).
/// - Every placement has 1–3 reasons; every task (or remainder) that did not
///   fit is in [Plan.unplaced] with a reason.
///
/// Time zone: pass local [DateTime]s. `Preferences` clock ranges are read on
/// the local calendar day of each slot; conversion is the caller's job.
Plan plan({
  required List<Task> tasks,
  required Map<String, Goal> goals,
  required List<CalendarEvent> events,
  required Preferences prefs,
  required DateTime now,
  UserStats stats = const UserStats(),
  SchedulerWeights weights = const SchedulerWeights(),
  DateTime? horizonEnd,
}) {
  final start = now.toLocal();
  final end = (horizonEnd ?? defaultHorizonEnd(start, prefs)).toLocal();
  final window = Slot(start, end);
  if (!end.isAfter(start)) return Plan.empty;

  final open = tasks.where(isOpenTask).toList();
  final locked = <Task>[];
  final queue = <Task>[];
  for (final t in open) {
    if (isPinned(t)) {
      if (Slot(t.scheduledStart!, t.scheduledEnd!).overlaps(window)) {
        locked.add(t);
      }
    } else {
      queue.add(t);
    }
  }
  locked.sort(
    (a, b) => _cmpChain([
      a.scheduledStart!.compareTo(b.scheduledStart!),
      a.id.compareTo(b.id),
    ]),
  );

  final baseCapacity = weekCapacity(
    from: start,
    to: end,
    prefs: prefs,
    events: events,
    tasks: open,
    stats: stats,
  );
  final avgHours = avgFreeHoursPerDay(baseCapacity);

  final scores = {
    for (final t in queue)
      t.id: scoreBreakdown(t, goals[t.goalId], start, stats, weights, avgHours),
  };
  queue.sort(
    (a, b) => _cmpChain([
      scores[b.id]!.total.compareTo(scores[a.id]!.total),
      _cmpDue(a.dueAt, b.dueAt),
      adjustedMinutes(a, stats).compareTo(adjustedMinutes(b, stats)),
      a.id.compareTo(b.id),
    ]),
  );

  final placed = <Placement>[
    for (final t in locked)
      Placement(
        taskId: t.id,
        start: t.scheduledStart!.toLocal(),
        end: t.scheduledEnd!.toLocal(),
        reasons: const ['you placed this here'],
        locked: true,
      ),
  ];
  final unplaced = <UnplacedTask>[];

  var slots = freeSlots(
    from: start,
    to: end,
    prefs: prefs,
    events: events,
    lockedTasks: locked,
  );
  final deepUsed = <DateTime, int>{};
  for (final t in locked.where((t) => t.energy == Energy.deep)) {
    final day = startOfDay(t.scheduledStart!);
    deepUsed[day] = (deepUsed[day] ?? 0) + 1;
  }

  for (var qi = 0; qi < queue.length; qi++) {
    final task = queue[qi];
    final goal = goals[task.goalId];
    final breakdown = scores[task.id]!;
    final need = adjustedMinutes(task, stats);
    final deep = task.energy == Energy.deep;
    final due = task.dueAt?.toLocal();
    final deadline = due == null ? end : minTime(due, end);
    final protectFocus =
        !deep && queue.skip(qi + 1).any((t) => t.energy == Energy.deep);
    // Urgent work takes the earliest fit; the rest may wait for a gap it
    // fills, keeping longer gaps whole for longer tasks.
    final preferSnug = breakdown.urgency <= urgentAbove;

    final chunks = <Slot>[];
    final chunkNotes = <_Option>[];
    var remaining = need;
    while (remaining > 0) {
      final minLen = task.splittable
          ? math.min(task.minChunkMinutes, remaining)
          : remaining;
      final option = _bestOption(
        slots: slots,
        prefs: prefs,
        notBefore: start,
        deadline: deadline,
        minLen: minLen,
        fitMinutes: remaining,
        preferSnug: preferSnug,
        deep: deep,
        protectFocus: protectFocus,
        deepUsed: deepUsed,
        ignoreDeepCap: false,
      );
      if (option == null) break;
      var chunk = task.splittable
          ? math.min(remaining, option.slot.minutes)
          : remaining;
      final rest = remaining - chunk;
      if (task.splittable &&
          rest > 0 &&
          rest < task.minChunkMinutes &&
          remaining - task.minChunkMinutes >= minLen) {
        chunk = remaining - task.minChunkMinutes;
      }
      final s = Slot(
        option.slot.start,
        option.slot.start.add(Duration(minutes: chunk)),
      );
      chunks.add(s);
      chunkNotes.add(option);
      remaining -= chunk;
      slots = subtractSlots(slots, [
        s,
      ]).where((x) => x.minutes >= minSlotMinutes).toList();
      if (deep) {
        final day = startOfDay(s.start);
        deepUsed[day] = (deepUsed[day] ?? 0) + 1;
      }
    }

    final multi = chunks.length > 1 || remaining > 0;
    for (var i = 0; i < chunks.length; i++) {
      final c = chunks[i];
      String? chunkWord;
      if (multi) {
        final label = i == 0
            ? 'first'
            : (i == chunks.length - 1 && remaining == 0 ? 'last' : 'next');
        chunkWord = '$label ${c.minutes} of $need min';
      }
      placed.add(
        Placement(
          taskId: task.id,
          start: c.start,
          end: c.end,
          reasons: _reasons(
            task: task,
            goal: goal,
            breakdown: breakdown,
            chunk: c,
            chunkWord: chunkWord,
            option: chunkNotes[i],
            prefs: prefs,
            now: start,
          ),
        ),
      );
    }

    if (remaining > 0) {
      unplaced.add(
        UnplacedTask(
          taskId: task.id,
          minutes: remaining,
          reason: _unplacedReason(
            task: task,
            need: need,
            remaining: remaining,
            deadline: deadline,
            due: due,
            horizonEnd: end,
            now: start,
            canFitWithoutDeepCap:
                deep &&
                _bestOption(
                      slots: slots,
                      prefs: prefs,
                      notBefore: start,
                      deadline: deadline,
                      minLen: task.splittable
                          ? math.min(task.minChunkMinutes, remaining)
                          : remaining,
                      fitMinutes: remaining,
                      preferSnug: preferSnug,
                      deep: deep,
                      protectFocus: false,
                      deepUsed: deepUsed,
                      ignoreDeepCap: true,
                    ) !=
                    null,
          ),
        ),
      );
    }
  }

  placed.sort(
    (a, b) =>
        _cmpChain([a.start.compareTo(b.start), a.taskId.compareTo(b.taskId)]),
  );

  final capacity = weekCapacity(
    from: start,
    to: end,
    prefs: prefs,
    events: events,
    tasks: open,
    stats: stats,
    placements: placed,
  );
  final draft = Plan(placed: placed, unplaced: unplaced, capacity: capacity);
  return Plan(
    placed: placed,
    unplaced: unplaced,
    capacity: capacity,
    deferralSuggestions: deferralSuggestions(
      draft,
      tasks: open,
      goals: goals,
      now: start,
      horizonEnd: end,
      stats: stats,
      weights: weights,
    ),
  );
}

/// Urgency above which a task is "due soon": it says so in its reasons and
/// takes the earliest fit instead of waiting for a snug gap.
const urgentAbove = 0.6;

/// Open, not deleted.
bool isOpenTask(Task t) => t.status == TaskStatus.open && t.deletedAt == null;

/// Pinned by the user: `lockedStart` and a scheduled range.
bool isPinned(Task t) =>
    t.lockedStart &&
    t.isScheduled &&
    t.scheduledEnd!.isAfter(t.scheduledStart!);

/// End of the current week (next `prefs.weekStart`, local midnight) or
/// 7 days after [now], whichever is later.
DateTime defaultHorizonEnd(DateTime now, Preferences prefs) {
  final l = now.toLocal();
  var d = (prefs.weekStart - l.weekday) % 7;
  if (d == 0) d = 7;
  final endOfWeek = addDays(startOfDay(l), d);
  final sevenDays = DateTime(
    l.year,
    l.month,
    l.day + 7,
    l.hour,
    l.minute,
    l.second,
    l.millisecond,
    l.microsecond,
  );
  return maxTime(endOfWeek, sevenDays);
}

/// Horizon end for a mid-day "Re-plan with Pip": the rest of today, unless a
/// deadline allows tomorrow (epic #18).
///
/// Returns:
///
/// - local midnight after [now] by default (the rest of today), so re-plan
///   never pushes work into tomorrow when every task can still land today;
/// - extended to local midnight after the latest `dueAt` on any movable task
///   (open and not pinned) that is after end-of-today, so a task due tomorrow
///   or later gets the days it needs;
/// - clamped to [defaultHorizonEnd] so we never plan past the week.
///
/// Pinned tasks (`lockedStart`) don't push the horizon: the planner keeps
/// them where they are, so their deadlines are already met. Completed and
/// skipped tasks are ignored for the same reason. Pure, deterministic, no
/// clock reads: hand it the `now` the scheduler gets.
DateTime rePlanHorizonEnd({
  required DateTime now,
  required Iterable<Task> tasks,
  required Preferences prefs,
}) {
  final endOfToday = addDays(startOfDay(now), 1);
  final cap = defaultHorizonEnd(now, prefs);
  var latest = endOfToday;
  for (final t in tasks) {
    if (!isOpenTask(t) || isPinned(t)) continue;
    final due = t.dueAt;
    if (due == null) continue;
    final local = due.toLocal();
    if (!local.isAfter(endOfToday)) continue;
    final endOfDue = addDays(startOfDay(local), 1);
    if (endOfDue.isAfter(latest)) latest = endOfDue;
  }
  return minTime(latest, cap);
}

class _Option {
  const _Option(
    this.slot, {
    required this.inDeep,
    required this.touchesDeep,
    this.snug = false,
    this.keptFocusClear = false,
  });

  final Slot slot;

  /// Entirely inside a deep window.
  final bool inDeep;

  /// Overlaps a deep window at all.
  final bool touchesDeep;

  /// The task fills the gap: what is left over is shorter than
  /// [minSlotMinutes], so no other task could use it.
  final bool snug;

  /// A light task placed outside the focus windows although an earlier
  /// option on the same day touched one (kept clear for deep work).
  final bool keptFocusClear;

  _Option copyWith({bool? snug, bool? keptFocusClear}) => _Option(
    slot,
    inDeep: inDeep,
    touchesDeep: touchesDeep,
    snug: snug ?? this.snug,
    keptFocusClear: keptFocusClear ?? this.keptFocusClear,
  );
}

_Option? _bestOption({
  required List<Slot> slots,
  required Preferences prefs,
  required DateTime notBefore,
  required DateTime deadline,
  required int minLen,
  required int fitMinutes,
  required bool preferSnug,
  required bool deep,
  required bool protectFocus,
  required Map<DateTime, int> deepUsed,
  required bool ignoreDeepCap,
}) {
  _Option? best;
  DateTime? bestDay;
  // Earliest start per day among every usable option (for "kept clear").
  final earliestTouching = <DateTime, DateTime>{};
  int cmp(_Option o, DateTime day, _Option b, DateTime bDay) {
    if (deep) {
      return _cmpChain([
        (o.inDeep ? 0 : 1).compareTo(b.inDeep ? 0 : 1),
        o.slot.start.compareTo(b.slot.start),
      ]);
    }
    return _cmpChain([
      day.compareTo(bDay),
      if (protectFocus)
        (o.touchesDeep ? 1 : 0).compareTo(b.touchesDeep ? 1 : 0),
      // Duration fit: a gap the task fills beats one it would fragment.
      if (preferSnug) (o.snug ? 0 : 1).compareTo(b.snug ? 0 : 1),
      o.slot.start.compareTo(b.slot.start),
    ]);
  }

  for (final s in slots) {
    final eff = Slot(maxTime(s.start, notBefore), minTime(s.end, deadline));
    if (eff.minutes < minLen) continue;
    final day = startOfDay(eff.start);
    if (deep &&
        !ignoreDeepCap &&
        (deepUsed[day] ?? 0) >= prefs.maxDeepBlocksPerDay) {
      continue;
    }
    final windows = [for (final r in prefs.deepWindows) rangeOn(day, r)];
    final options = <_Option>[];
    var touches = false;
    var inside = false;
    for (final w in windows) {
      final i = intersect(eff, w);
      if (i == null) continue;
      touches = true;
      if (i == eff) inside = true;
      options.add(_Option(i, inDeep: true, touchesDeep: true));
    }
    if (!inside) {
      for (final part in subtractSlots([eff], windows)) {
        options.add(_Option(part, inDeep: false, touchesDeep: false));
      }
      if (touches) options.add(_Option(eff, inDeep: false, touchesDeep: true));
    }
    for (final raw in options) {
      if (raw.slot.minutes < minLen) continue;
      final o = raw.copyWith(
        snug: raw.slot.minutes - fitMinutes < minSlotMinutes,
      );
      if (o.touchesDeep) {
        final e = earliestTouching[day];
        if (e == null || o.slot.start.isBefore(e)) {
          earliestTouching[day] = o.slot.start;
        }
      }
      final b = best;
      if (b == null || cmp(o, day, b, bestDay!) < 0) {
        best = o;
        bestDay = day;
      }
    }
  }
  final b = best;
  if (b == null || deep || !protectFocus || b.touchesDeep) return b;
  final e = earliestTouching[bestDay!];
  return e != null && e.isBefore(b.slot.start)
      ? b.copyWith(keptFocusClear: true)
      : b;
}

List<String> _reasons({
  required Task task,
  required Goal? goal,
  required ScoreBreakdown breakdown,
  required Slot chunk,
  required String? chunkWord,
  required _Option option,
  required Preferences prefs,
  required DateTime now,
}) {
  final due = task.dueAt;
  final deep = task.energy == Energy.deep;
  final others = <String>[
    if (due != null && breakdown.urgency > urgentAbove)
      'due ${dayWord(due, now)}',
    if (goal != null && breakdown.importance > 0.7) 'part of ${goal.title}',
    if (deep && _inDeepWindow(chunk, prefs)) 'your focus window',
    if (!deep && option.keptFocusClear) 'keeps your focus window clear',
    if (!deep && option.snug && chunkWord == null)
      'fills a ${option.slot.minutes}-minute gap',
  ];
  final out = <String>[...others.take(chunkWord == null ? 3 : 2), ?chunkWord];
  if (out.isEmpty) {
    out.add(
      due == null
          ? 'earliest free ${chunk.minutes}-minute gap'
          : 'earliest free ${chunk.minutes}-minute gap before '
                '${deadlineWord(due, now)}',
    );
  }
  return out;
}

bool _inDeepWindow(Slot s, Preferences prefs) {
  final day = startOfDay(s.start);
  return prefs.deepWindows.any((r) => rangeOn(day, r).contains(s));
}

String _unplacedReason({
  required Task task,
  required int need,
  required int remaining,
  required DateTime deadline,
  required DateTime? due,
  required DateTime horizonEnd,
  required DateTime now,
  required bool canFitWithoutDeepCap,
}) {
  if (due != null && !due.isAfter(now)) {
    return 'the due date has passed, want to pick a new one?';
  }
  final dueInside = due != null && !due.isAfter(horizonEnd);
  final oneDay = !horizonEnd.isAfter(addDays(startOfDay(now), 1));
  final by = dueInside
      ? 'before ${deadlineWord(due, now)}'
      : oneDay
      ? 'today'
      : (calendarDaysBetween(startOfDay(now), startOfDay(horizonEnd)) <= 8
            ? 'this week'
            : 'before ${dayWord(horizonEnd, now)}');
  if (canFitWithoutDeepCap) {
    return 'focus blocks are full $by';
  }
  if (remaining < need) {
    return 'only ${need - remaining} of $need min fit $by';
  }
  final len = task.splittable ? math.min(task.minChunkMinutes, need) : need;
  return 'no free $len-minute slot $by';
}

int _cmpDue(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _cmpChain(List<int> results) {
  for (final r in results) {
    if (r != 0) return r;
  }
  return 0;
}
