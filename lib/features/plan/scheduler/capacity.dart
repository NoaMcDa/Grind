import 'dart:math' as math;

import 'package:grind/core/domain/domain.dart';

import 'free_slots.dart';
import 'models.dart';
import 'scoring.dart';
import 'time_math.dart';

/// "Is this week realistic?" (research §5): free minutes per day inside
/// working hours, minus busy events, buffers, lunch and the daily cushion,
/// versus the adjusted estimates of every open task in [tasks].
///
/// Locked tasks are *not* subtracted from free time; they count as demand
/// instead (a locked task outside the window does not count). [placements]
/// fill each day's [DayCapacity.demandMinutes]; leave it empty to get the
/// free side only.
WeekCapacity weekCapacity({
  required DateTime from,
  required DateTime to,
  required Preferences prefs,
  required List<CalendarEvent> events,
  required List<Task> tasks,
  UserStats stats = const UserStats(),
  List<Placement> placements = const [],
}) {
  final window = Slot(from.toLocal(), to.toLocal());
  final days = <DayCapacity>[];
  var free = 0;
  var deepCap = 0;
  for (var day = startOfDay(from); day.isBefore(to); day = addDays(day, 1)) {
    final next = addDays(day, 1);
    final dayFree = totalMinutes(
      freeSlots(
        from: maxTime(day, window.start),
        to: minTime(next, window.end),
        prefs: prefs,
        events: events,
        lockedTasks: const [],
      ),
    );
    final dayDeep = math.min(
      dayFree,
      prefs.maxDeepBlocksPerDay * prefs.deepBlockMinutes,
    );
    final dayDemand = placements
        .where((p) => startOfDay(p.start) == day)
        .fold(0, (sum, p) => sum + p.minutes);
    days.add(
      DayCapacity(
        date: day,
        freeMinutes: dayFree,
        deepCapacityMinutes: dayDeep,
        demandMinutes: dayDemand,
      ),
    );
    free += dayFree;
    deepCap += dayDeep;
  }

  var demand = 0;
  var deepDemand = 0;
  for (final t in tasks) {
    if (t.status != TaskStatus.open || t.deletedAt != null) continue;
    final int m;
    if (t.lockedStart && t.isScheduled) {
      final s = Slot(t.scheduledStart!.toLocal(), t.scheduledEnd!.toLocal());
      if (!s.overlaps(window)) continue;
      m = s.minutes;
    } else {
      m = adjustedMinutes(t, stats);
    }
    demand += m;
    if (t.energy == Energy.deep) deepDemand += m;
  }

  return WeekCapacity(
    days: days,
    freeMinutes: free,
    demandMinutes: demand,
    deepCapacityMinutes: deepCap,
    deepDemandMinutes: deepDemand,
    overbooked: demand > free || deepDemand > deepCap,
  );
}

/// Average free hours on the days that have any free time; 1.0 when none.
/// Feeds the slack term of the score.
double avgFreeHoursPerDay(WeekCapacity capacity) {
  final days = capacity.days.where((d) => d.freeMinutes > 0).length;
  if (days == 0) return 1;
  return capacity.freeMinutes / days / 60;
}

/// What could move to next week when [plan] is overbooked.
///
/// Lowest score first (ties: latest due, longest, id), whole tasks only,
/// until demand ≤ free (and deep demand ≤ deep capacity). Never suggests a
/// task due on or before [horizonEnd], nor a locked task. Empty when the
/// week fits.
List<DeferralSuggestion> deferralSuggestions(
  Plan plan, {
  required List<Task> tasks,
  required Map<String, Goal> goals,
  required DateTime now,
  required DateTime horizonEnd,
  UserStats stats = const UserStats(),
  SchedulerWeights weights = const SchedulerWeights(),
}) {
  final cap = plan.capacity;
  if (!cap.overbooked) return const [];
  final avg = avgFreeHoursPerDay(cap);
  final candidates = [
    for (final t in tasks)
      if (t.status == TaskStatus.open &&
          t.deletedAt == null &&
          !(t.lockedStart && t.isScheduled) &&
          (t.dueAt == null || t.dueAt!.isAfter(horizonEnd)))
        t,
  ];
  final scores = {
    for (final t in candidates)
      t.id: score(t, goals[t.goalId], now, stats, weights, avg),
  };
  candidates.sort((a, b) {
    final s = scores[a.id]!.compareTo(scores[b.id]!);
    if (s != 0) return s;
    final ad = a.dueAt, bd = b.dueAt;
    if (ad != bd) {
      if (ad == null) return -1;
      if (bd == null) return 1;
      final d = bd.compareTo(ad);
      if (d != 0) return d;
    }
    final m = adjustedMinutes(b, stats).compareTo(adjustedMinutes(a, stats));
    if (m != 0) return m;
    return a.id.compareTo(b.id);
  });

  var over = cap.demandMinutes - cap.freeMinutes;
  var deepOver = cap.deepDemandMinutes - cap.deepCapacityMinutes;
  final out = <DeferralSuggestion>[];
  for (final t in candidates) {
    if (over <= 0 && deepOver <= 0) break;
    final deep = t.energy == Energy.deep;
    if (over <= 0 && !deep) continue;
    final m = adjustedMinutes(t, stats);
    out.add(
      DeferralSuggestion(
        taskId: t.id,
        minutes: m,
        reason: t.dueAt == null
            ? 'no deadline, so next week works'
            : 'not due until ${dayWord(t.dueAt!, now)}',
      ),
    );
    over -= m;
    if (deep) deepOver -= m;
  }
  return out;
}

/// One line in Pip's tone: "You have 14 hours free and 19 hours of plans.
/// Two things could move to next week."
String capacitySummary(WeekCapacity capacity, {int deferrals = 0}) {
  final head =
      'You have ${_hours(capacity.freeMinutes)} free and '
      '${_hours(capacity.demandMinutes)} of plans.';
  if (!capacity.overbooked) return '$head It fits, with room to breathe.';
  if (deferrals == 0) return '$head A lighter week might help.';
  final n = deferrals < _numbers.length ? _numbers[deferrals] : '$deferrals';
  final things = deferrals == 1 ? 'thing' : 'things';
  return '$head $n $things could move to next week.';
}

const _numbers = [
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
];

String _hours(int minutes) {
  if (minutes < 60) return '$minutes minutes';
  final h = (minutes / 60).round();
  return h == 1 ? '1 hour' : '$h hours';
}
