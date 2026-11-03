import 'package:grind/core/domain/domain.dart';

import '../scheduler/scheduler.dart' as scheduler;
import '../scheduler/scheduler.dart'
    show Placement, SchedulerWeights, Slot, UnplacedTask, UserStats;
import '../scheduler/time_math.dart';

/// One proposed block of "Your day, drafted".
class DraftItem {
  const DraftItem({
    required this.taskId,
    required this.start,
    required this.end,
    required this.reasons,
    required this.energy,
    this.due,
  });

  final String taskId;
  final DateTime start;
  final DateTime end;

  /// 1–3 English reasons from the scheduler (see `localizePlanReason`).
  final List<String> reasons;
  final Energy energy;

  /// The task's deadline (local), so a reorder never pushes past it.
  final DateTime? due;

  int get minutes => end.difference(start).inMinutes;

  DraftItem at(DateTime newStart, List<String> newReasons) => DraftItem(
    taskId: taskId,
    start: newStart,
    end: newStart.add(Duration(minutes: minutes)),
    reasons: newReasons,
    energy: energy,
    due: due,
  );

  @override
  bool operator ==(Object other) =>
      other is DraftItem &&
      other.taskId == taskId &&
      other.start == start &&
      other.end == end &&
      sameList(other.reasons, reasons);

  @override
  int get hashCode => Object.hash(taskId, start, end, Object.hashAll(reasons));

  @override
  String toString() => 'DraftItem($taskId ${hm(start)}-${hm(end)} $reasons)';
}

/// "Your day, drafted": today's placements from now to the end of the day,
/// around the calendar, each with its reasons. Pure and immutable; the
/// review sheet edits it with [remove] and [move]. All times are local
/// wall-clock values (the caller converts, see `DayDrafter`).
class DayDraft {
  const DayDraft({
    required this.day,
    required this.from,
    required this.items,
    required this.kept,
    required this.unplaced,
    required this.laterCount,
    required this.freeSlots,
    required this.freeMinutes,
    required this.deepWindows,
  });

  /// Local midnight of the drafted day.
  final DateTime day;

  /// Planning starts here (now, or the start of the day).
  final DateTime from;

  /// Proposed blocks, by start.
  final List<DraftItem> items;

  /// Blocks the user placed by hand today; never moved.
  final List<Placement> kept;

  /// Tasks due today that did not fit, each with why.
  final List<UnplacedTask> unplaced;

  /// Open tasks with a later (or no) deadline that wait for another day.
  final int laterCount;

  /// Free time the draft fills (after events, buffers, lunch, cushion and
  /// the kept blocks). [move] re-fits the items into these.
  final List<Slot> freeSlots;
  final int freeMinutes;
  final List<TimeRange> deepWindows;

  DateTime get dayEnd => addDays(day, 1);

  int get plannedMinutes => items.fold(0, (a, i) => a + i.minutes);

  bool get isEmpty => items.isEmpty && unplaced.isEmpty;

  DayDraft _with(List<DraftItem> next) => DayDraft(
    day: day,
    from: from,
    items: next,
    kept: kept,
    unplaced: unplaced,
    laterCount: laterCount,
    freeSlots: freeSlots,
    freeMinutes: freeMinutes,
    deepWindows: deepWindows,
  );

  /// The draft without [taskId]'s block; the task stays unscheduled.
  DayDraft remove(String taskId) => _with([
    for (final i in items)
      if (i.taskId != taskId) i,
  ]);

  /// Moves [taskId] one place earlier (`delta < 0`) or later (`delta > 0`)
  /// in the day's order, then re-fits every block, in the new order, into
  /// the free time: each block starts at the first free moment after the
  /// one before it and still ends by its deadline. Blocks whose time
  /// changes keep their stable reasons ("due today", "part of …") and get
  /// "in the order you chose" in place of slot-specific ones. Returns null
  /// when the new order does not fit (or there is nowhere to move).
  DayDraft? move(String taskId, int delta) {
    final i = items.indexWhere((x) => x.taskId == taskId);
    if (i < 0 || delta == 0) return null;
    final j = i + delta.sign;
    if (j < 0 || j >= items.length) return null;
    final order = [...items];
    final moved = order.removeAt(i);
    order.insert(j, moved);

    final out = <DraftItem>[];
    var cursor = from;
    for (final item in order) {
      final deadline = item.due == null || item.due!.isAfter(dayEnd)
          ? dayEnd
          : item.due!;
      DateTime? start;
      for (final s in freeSlots) {
        final a = maxTime(s.start, cursor);
        final b = minTime(s.end, deadline);
        if (b.difference(a).inMinutes >= item.minutes) {
          start = a;
          break;
        }
      }
      if (start == null) return null;
      final original = items.firstWhere((x) => x.taskId == item.taskId);
      out.add(
        start == original.start
            ? original
            : item.at(start, _reorderedReasons(item, start)),
      );
      cursor = out.last.end;
    }
    return _with(out);
  }

  List<String> _reorderedReasons(DraftItem item, DateTime start) {
    final slot = Slot(start, start.add(Duration(minutes: item.minutes)));
    final inFocus = deepWindows.any((r) => rangeOn(day, r).contains(slot));
    final stable = [
      for (final r in item.reasons)
        if (r.startsWith('due ') || r.startsWith('part of ')) r,
    ];
    return [
      ...stable.take(2),
      if (item.energy == Energy.deep && inFocus) 'your focus window',
      if (item.energy != Energy.deep || !inFocus) yourOrderReason,
    ];
  }
}

/// The reason a block gets once the user reorders the draft.
const yourOrderReason = 'in the order you chose';

/// Drafts the day that contains [now], from [now] to local midnight, with
/// the scheduler core (`scheduler.plan` with `horizonEnd` = end of today).
///
/// [tasks] are local wall-clock tasks: every open one the user might do
/// today. Pinned ones (`lockedStart`) block their time and are listed in
/// [DayDraft.kept]; everything else may be placed. Each task becomes one
/// block (a task holds a single scheduled range). Tasks that do not fit and
/// are due today land in [DayDraft.unplaced]; the rest only count towards
/// [DayDraft.laterCount].
DayDraft draftDay({
  required List<Task> tasks,
  required Map<String, Goal> goals,
  required List<CalendarEvent> events,
  required Preferences prefs,
  required DateTime now,
  UserStats stats = const UserStats(),
  SchedulerWeights weights = const SchedulerWeights(),
}) {
  final day = startOfDay(now);
  final end = addDays(day, 1);
  final input = [for (final t in tasks) t.copyWith(splittable: false)];
  final result = scheduler.plan(
    tasks: input,
    goals: goals,
    events: events,
    prefs: prefs,
    now: now,
    stats: stats,
    weights: weights,
    horizonEnd: end,
  );
  final byId = {for (final t in input) t.id: t};
  final items = [
    for (final p in result.placed)
      if (!p.locked)
        DraftItem(
          taskId: p.taskId,
          start: p.start,
          end: p.end,
          reasons: p.reasons,
          energy: byId[p.taskId]?.energy ?? Energy.light,
          due: byId[p.taskId]?.dueAt?.toLocal(),
        ),
  ];
  final unplaced = <UnplacedTask>[];
  var later = 0;
  for (final u in result.unplaced) {
    final due = byId[u.taskId]?.dueAt;
    if (due != null && !due.isAfter(end)) {
      unplaced.add(u);
    } else {
      later++;
    }
  }
  final pinned = [
    for (final t in input)
      if (scheduler.isOpenTask(t) && scheduler.isPinned(t)) t,
  ];
  final free = scheduler.freeSlots(
    from: now,
    to: end,
    prefs: prefs,
    events: events,
    lockedTasks: pinned,
  );
  return DayDraft(
    day: day,
    from: now,
    items: items,
    kept: [
      for (final p in result.placed)
        if (p.locked) p,
    ],
    unplaced: unplaced,
    laterCount: later,
    freeSlots: free,
    freeMinutes: totalMinutes(free),
    deepWindows: prefs.deepWindows,
  );
}
