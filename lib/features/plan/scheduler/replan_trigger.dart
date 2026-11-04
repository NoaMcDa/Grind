import 'package:grind/core/domain/domain.dart';

import 'free_slots.dart';
import 'models.dart';
import 'time_math.dart';

/// Why the app would offer "Re-plan with Pip" without being asked.
///
/// The ordering is also the priority: when more than one reason fits, the
/// first in this list wins, because a task the user closed or skipped
/// changes their intent more than a calendar wobble.
enum ReplanReason {
  /// Nothing noteworthy changed since [previous] was drafted.
  none,

  /// An open task is overrunning its scheduled block — it is still running
  /// past the end the plan gave it.
  taskOverrun,

  /// A scheduled task was marked [TaskStatus.done] *after* its scheduled end,
  /// so the plan after it is now wrong (slid, or the next block started in
  /// the middle of this one).
  taskDoneLate,

  /// A scheduled task was marked [TaskStatus.skipped] — its block is empty
  /// and the rest of the day can compress.
  taskSkipped,

  /// A busy calendar event was added inside the remaining plan horizon and
  /// overlaps something the scheduler had placed.
  calendarEventAdded,

  /// An existing event the scheduler planned around moved (start/end) and
  /// now clashes with a placement, or vacated one.
  calendarEventMoved,
}

/// "Should we offer to re-plan?" with one reason, in Pip's tone.
///
/// Pure data: pass the same inputs twice and get the same answer.
class ReplanTrigger {
  const ReplanTrigger({
    required this.reason,
    required this.summary,
    this.taskId,
    this.eventId,
  });

  /// Nothing changed; do not nudge the user.
  static const none = ReplanTrigger(reason: ReplanReason.none, summary: '');

  final ReplanReason reason;

  /// One short sentence, Pip's voice: "the seminar ran over",
  /// "a new meeting lands at 15:00", "you skipped the reading".
  /// Empty when [reason] is [ReplanReason.none].
  final String summary;

  /// The task that caused the trigger, when [reason] points at a task.
  final String? taskId;

  /// The event that caused the trigger, when [reason] points at an event.
  final String? eventId;

  /// True when the app should surface the "Re-plan with Pip" affordance.
  bool get needed => reason != ReplanReason.none;

  @override
  bool operator ==(Object other) =>
      other is ReplanTrigger &&
      other.reason == reason &&
      other.summary == summary &&
      other.taskId == taskId &&
      other.eventId == eventId;

  @override
  int get hashCode => Object.hash(reason, summary, taskId, eventId);

  @override
  String toString() =>
      'ReplanTrigger($reason, "$summary", task: $taskId, event: $eventId)';
}

/// Classifies the current world against the last [previous] plan and says
/// whether a re-plan is worth offering, with the one reason that best
/// explains why.
///
/// Pure: `(previous, tasks, events, now)` → one [ReplanTrigger]. No clock
/// reads, no I/O. The caller already has these inputs for the next
/// `replan(...)` call, so this is a cheap early filter that skips the
/// re-plan when nothing user-visible changed.
///
/// Rules:
///
/// - If any task that was [TaskStatus.open] in [previous] but is now
///   [TaskStatus.skipped] has a placement in [previous] that still touches
///   the future (end > now), trigger [ReplanReason.taskSkipped].
/// - Else, if a scheduled task was marked [TaskStatus.done] whose placement
///   ended before [completedAt] by more than [latenessGraceMinutes], trigger
///   [ReplanReason.taskDoneLate].
/// - Else, if an open task's placement started before [now] and still has
///   not finished (end > now) and the task is not pinned, trigger
///   [ReplanReason.taskOverrun]: the scheduled block is overrunning and
///   the rest of the day needs to slide.
/// - Else, if a busy calendar event has been added (its id was not in
///   [previousEvents]) that overlaps a placement at or after [now], trigger
///   [ReplanReason.calendarEventAdded].
/// - Else, if an existing busy event's `start`/`end` moved between
///   [previousEvents] and [events] and the new range overlaps a future
///   placement, or the old range is no longer there and a placement had
///   been fitted around it, trigger [ReplanReason.calendarEventMoved].
/// - Else, [ReplanReason.none].
///
/// All-day events and events with `isBusy == false` never trigger; they do
/// not block the scheduler either, so a change to them changes no plan.
/// Events written back from Grind tasks (`taskId != null`) also never
/// trigger: the user's own task does not fight itself.
///
/// [latenessGraceMinutes] matches the scheduler's `minSlotMinutes`: a task
/// closing one minute late does not deserve a nudge, but ten minutes does.
ReplanTrigger replanTrigger({
  required Plan previous,
  required List<Task> tasks,
  required List<CalendarEvent> events,
  required List<CalendarEvent> previousEvents,
  required DateTime now,
  int latenessGraceMinutes = minSlotMinutes,
}) {
  final nowLocal = now.toLocal();
  final byId = {for (final t in tasks) t.id: t};
  final placementsByTask = <String, List<Placement>>{};
  for (final p in previous.placed) {
    (placementsByTask[p.taskId] ??= []).add(p);
  }

  // 1) A task the user just skipped, whose block is still ahead.
  for (final id in placementsByTask.keys) {
    final task = byId[id];
    if (task == null) continue;
    if (task.status != TaskStatus.skipped) continue;
    final blocks = placementsByTask[id]!;
    if (!blocks.any((b) => b.end.isAfter(nowLocal))) continue;
    return ReplanTrigger(
      reason: ReplanReason.taskSkipped,
      summary: _skipSummary(task),
      taskId: id,
    );
  }

  // 2) A task finished well after its scheduled end.
  for (final id in placementsByTask.keys) {
    final task = byId[id];
    if (task == null) continue;
    if (task.status != TaskStatus.done) continue;
    final completed = task.completedAt?.toLocal();
    if (completed == null) continue;
    final blocks = placementsByTask[id]!;
    final end = blocks.map((b) => b.end).reduce((a, b) => a.isAfter(b) ? a : b);
    final lateBy = completed.difference(end).inMinutes;
    if (lateBy < latenessGraceMinutes) continue;
    return ReplanTrigger(
      reason: ReplanReason.taskDoneLate,
      summary: _overrunSummary(task, lateBy),
      taskId: id,
    );
  }

  // 3) An open task whose block started before `now` and is overrunning
  // (end is still ahead): the rest of the day needs to slide.
  for (final id in placementsByTask.keys) {
    final task = byId[id];
    if (task == null) continue;
    if (task.status != TaskStatus.open) continue;
    final blocks = placementsByTask[id]!;
    final first = blocks.reduce((a, b) => a.start.isBefore(b.start) ? a : b);
    final last = blocks.reduce((a, b) => a.end.isAfter(b.end) ? a : b);
    if (!first.start.isBefore(nowLocal)) continue;
    final overBy = nowLocal.difference(last.end).inMinutes;
    if (overBy < latenessGraceMinutes) continue;
    if (first.locked) continue;
    return ReplanTrigger(
      reason: ReplanReason.taskOverrun,
      summary: _overrunSummary(task, overBy),
      taskId: id,
    );
  }

  // 4) Calendar: compare blocking events only.
  final oldBlocking = {
    for (final e in previousEvents.where(blocksTime)) e.id: e,
  };
  final newBlocking = {for (final e in events.where(blocksTime)) e.id: e};

  for (final id in newBlocking.keys) {
    if (oldBlocking.containsKey(id)) continue;
    final e = newBlocking[id]!;
    if (!_touchesFuturePlacement(previous, e, nowLocal)) continue;
    return ReplanTrigger(
      reason: ReplanReason.calendarEventAdded,
      summary: _addedSummary(e, nowLocal),
      eventId: id,
    );
  }

  for (final id in oldBlocking.keys) {
    final oldEvent = oldBlocking[id]!;
    final newEvent = newBlocking[id];
    if (newEvent == null) {
      // Removed events never block — free time opened up, and the next
      // scheduler run will use it. We do not nudge for pure deletions.
      continue;
    }
    if (newEvent.start == oldEvent.start && newEvent.end == oldEvent.end) {
      continue;
    }
    if (!_touchesFuturePlacement(previous, newEvent, nowLocal)) continue;
    return ReplanTrigger(
      reason: ReplanReason.calendarEventMoved,
      summary: _movedSummary(newEvent, oldEvent, nowLocal),
      eventId: id,
    );
  }

  return ReplanTrigger.none;
}

bool _touchesFuturePlacement(Plan previous, CalendarEvent e, DateTime now) {
  final s = e.start.toLocal();
  final en = e.end.toLocal();
  if (!en.isAfter(now)) return false;
  for (final p in previous.placed) {
    if (!p.end.isAfter(now)) continue;
    if (p.start.isBefore(en) && s.isBefore(p.end)) return true;
  }
  return false;
}

String _skipSummary(Task t) => 'you skipped ${t.title}';

String _overrunSummary(Task t, int minutes) {
  if (minutes < 60) return '${t.title} ran $minutes min over';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${t.title} ran ${h}h over';
  return '${t.title} ran ${h}h ${m}m over';
}

String _addedSummary(CalendarEvent e, DateTime now) {
  final s = e.start.toLocal();
  return '${e.title} lands at ${hm(s)}';
}

String _movedSummary(CalendarEvent next, CalendarEvent prev, DateTime now) {
  final nextStart = next.start.toLocal();
  final prevStart = prev.start.toLocal();
  final sameDay = startOfDay(nextStart) == startOfDay(prevStart);
  if (sameDay) return '${next.title} moved to ${hm(nextStart)}';
  return '${next.title} moved to ${dayWord(nextStart, now)} ${hm(nextStart)}';
}
