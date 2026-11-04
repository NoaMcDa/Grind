import 'package:grind/core/domain/domain.dart';

import 'free_slots.dart';
import 'models.dart';
import 'planner.dart';
import 'time_math.dart';

/// True iff [t] has recorded progress and should be treated as "already
/// underway". The re-plan path leaves started tasks where they are, so a
/// task you have put minutes into is not snatched from under you.
///
/// Pure function of the task's own fields; `Task.minutesDone` is Grind's
/// only "started" signal (see also `effort_score.dart`).
bool isStarted(Task t) => t.minutesDone > 0;

/// True iff the re-plan path is allowed to move [t]: open, not deleted, not
/// pinned, not already started.
///
/// From epic #18:
///
/// > completed and pinned items are untouched; only unstarted tasks move
///
/// Pure: no clock, no events, no plan — only the task's own fields.
bool isReplanCandidate(Task t) =>
    isOpenTask(t) && !isPinned(t) && !isStarted(t);

/// A task list split by what the re-plan path may do with each one.
///
/// [movable] is what the scheduler is free to re-place; [untouched] is
/// everything the re-plan keeps where it is (pinned, started) or drops
/// (done, skipped, deleted). The caller hands [movable] to `plan(...)` and
/// leaves [untouched] alone.
class ReplanPartition {
  const ReplanPartition({required this.movable, required this.untouched});

  static const empty = ReplanPartition(movable: [], untouched: []);

  final List<Task> movable;
  final List<Task> untouched;

  @override
  bool operator ==(Object other) =>
      other is ReplanPartition &&
      sameList(other.movable, movable) &&
      sameList(other.untouched, untouched);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(movable), Object.hashAll(untouched));

  @override
  String toString() =>
      'ReplanPartition(movable: ${movable.map((t) => t.id).toList()}, '
      'untouched: ${untouched.map((t) => t.id).toList()})';
}

/// Splits [tasks] into [ReplanPartition.movable] (the re-plan may re-place
/// these) and [ReplanPartition.untouched] (leave verbatim or drop). The
/// input order is kept inside each list — the diff that the re-plan surface
/// renders is deterministic.
ReplanPartition partitionForReplan(Iterable<Task> tasks) {
  final movable = <Task>[];
  final untouched = <Task>[];
  for (final t in tasks) {
    (isReplanCandidate(t) ? movable : untouched).add(t);
  }
  return ReplanPartition(movable: movable, untouched: untouched);
}

/// A task whose blocks changed between two plans, with the one reason why.
class PlanMove {
  const PlanMove({
    required this.taskId,
    required this.from,
    required this.to,
    required this.reason,
  });

  final String taskId;
  final List<Slot> from;
  final List<Slot> to;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is PlanMove &&
      other.taskId == taskId &&
      other.reason == reason &&
      sameList(other.from, from) &&
      sameList(other.to, to);

  @override
  int get hashCode =>
      Object.hash(taskId, reason, Object.hashAll(from), Object.hashAll(to));

  @override
  String toString() => 'PlanMove($taskId $from -> $to: $reason)';
}

/// A task that was on the previous plan and is not on the new one.
class PlanRemoval {
  const PlanRemoval({required this.taskId, required this.reason});

  final String taskId;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is PlanRemoval && other.taskId == taskId && other.reason == reason;

  @override
  int get hashCode => Object.hash(taskId, reason);

  @override
  String toString() => 'PlanRemoval($taskId: $reason)';
}

/// What changed between two plans. Feeds "Re-plan with Pip".
class PlanDiff {
  const PlanDiff({
    this.moved = const [],
    this.added = const [],
    this.removed = const [],
  });

  final List<PlanMove> moved;

  /// Task ids placed now that were not placed before.
  final List<String> added;
  final List<PlanRemoval> removed;

  bool get isEmpty => moved.isEmpty && added.isEmpty && removed.isEmpty;

  @override
  String toString() =>
      'PlanDiff(moved: $moved, added: $added, removed: $removed)';
}

class ReplanResult {
  const ReplanResult({required this.plan, required this.diff});

  final Plan plan;
  final PlanDiff diff;
}

/// Re-plans after the day changed: [plan] again with done/skipped tasks
/// dropped and locked tasks kept where they are, plus a [PlanDiff] against
/// [previous] that gives every move one reason.
///
/// Minimal-change bias: pass [prevPlacements] (or let it default to
/// [prevPlacementsFromPlan] of [previous]) to keep a task at its previous
/// slots whenever they still fit — the plan that moves the fewest items.
/// Pass an empty map to drop the bias and re-fit every open task from
/// scratch (the pre-#18 behaviour, kept for tests and callers that want it).
ReplanResult replan({
  required Plan previous,
  required List<Task> tasks,
  required Map<String, Goal> goals,
  required List<CalendarEvent> events,
  required Preferences prefs,
  required DateTime now,
  UserStats stats = const UserStats(),
  SchedulerWeights weights = const SchedulerWeights(),
  DateTime? horizonEnd,
  Map<String, List<Slot>> prevPlacements = const {},
}) {
  final next = plan(
    tasks: tasks.where(isOpenTask).toList(),
    goals: goals,
    events: events,
    prefs: prefs,
    now: now,
    stats: stats,
    weights: weights,
    horizonEnd: horizonEnd,
    prevPlacements: prevPlacements,
  );
  return ReplanResult(
    plan: next,
    diff: diffPlans(
      previous: previous,
      next: next,
      tasks: tasks,
      events: events,
      prefs: prefs,
      now: now,
    ),
  );
}

/// Compares two plans task by task. Ids are reported in the order they first
/// appear in the plans, so the diff is deterministic.
PlanDiff diffPlans({
  required Plan previous,
  required Plan next,
  required List<Task> tasks,
  required List<CalendarEvent> events,
  required Preferences prefs,
  required DateTime now,
}) {
  final before = _slotsByTask(previous);
  final after = _slotsByTask(next);
  final byId = {for (final t in tasks) t.id: t};
  final unplacedReason = {for (final u in next.unplaced) u.taskId: u.reason};

  final moved = <PlanMove>[];
  final removed = <PlanRemoval>[];
  for (final id in before.keys) {
    final old = before[id]!;
    final now_ = after[id];
    if (now_ == null) {
      removed.add(
        PlanRemoval(
          taskId: id,
          reason: _removalReason(
            byId[id],
            unplacedReason[id],
            passed: old.every((s) => !s.end.isAfter(now)),
          ),
        ),
      );
    } else if (!sameList(old, now_)) {
      moved.add(
        PlanMove(
          taskId: id,
          from: old,
          to: now_,
          reason: _moveReason(
            taskId: id,
            old: old,
            next: next,
            byId: byId,
            events: events,
            prefs: prefs,
            now: now,
          ),
        ),
      );
    }
  }
  final added = [
    for (final id in after.keys)
      if (!before.containsKey(id)) id,
  ];
  return PlanDiff(moved: moved, added: added, removed: removed);
}

/// The unlocked placements of [plan], grouped by task id, for feeding
/// [replan]'s minimal-change bias. Locked placements are skipped: the
/// planner already keeps them verbatim.
Map<String, List<Slot>> prevPlacementsFromPlan(Plan plan) {
  final out = <String, List<Slot>>{};
  for (final p in plan.placed) {
    if (p.locked) continue;
    (out[p.taskId] ??= []).add(p.slot);
  }
  for (final l in out.values) {
    l.sort(compareSlots);
  }
  return out;
}

Map<String, List<Slot>> _slotsByTask(Plan p) {
  final out = <String, List<Slot>>{};
  for (final pl in p.placed) {
    (out[pl.taskId] ??= []).add(pl.slot);
  }
  for (final l in out.values) {
    l.sort(compareSlots);
  }
  return out;
}

String _removalReason(Task? t, String? unplaced, {required bool passed}) {
  if (t == null || t.deletedAt != null) return 'no longer on your list';
  if (t.status == TaskStatus.done) return 'done, nice work';
  if (t.status == TaskStatus.skipped) return 'skipped for now';
  if (passed) return 'that time has passed';
  return unplaced ?? 'no longer fits this week';
}

String _moveReason({
  required String taskId,
  required List<Slot> old,
  required Plan next,
  required Map<String, Task> byId,
  required List<CalendarEvent> events,
  required Preferences prefs,
  required DateTime now,
}) {
  if (old.any((s) => s.start.isBefore(now))) return 'that time has passed';

  final buffer = Duration(minutes: prefs.bufferBetweenEventsMinutes);
  final clashing =
      events
          .where(blocksTime)
          .where(
            (e) => old.any(
              (s) => s.overlaps(
                Slot(
                  e.start.toLocal().subtract(buffer),
                  e.end.toLocal().add(buffer),
                ),
              ),
            ),
          )
          .toList()
        ..sort((a, b) {
          final c = a.start.compareTo(b.start);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
  if (clashing.isNotEmpty) return '${clashing.first.title} now takes that time';

  final stillWorkable = old.every(
    (s) => freeSlotsForDay(
      day: s.start,
      prefs: prefs,
      events: const [],
      lockedTasks: const [],
    ).any((f) => f.contains(s)),
  );
  if (!stillWorkable) return 'your hours changed';

  final newPlacements = next.placementsFor(taskId);
  final movedEarlier =
      newPlacements.isNotEmpty &&
      newPlacements.first.start.isBefore(old.first.start);

  // A pin the user placed explains a move better than another task does;
  // a task that moved earlier was not pushed by whoever took its old spot.
  for (final locked in [true, false]) {
    if (!locked && movedEarlier) break;
    for (final p in next.placed) {
      if (p.taskId == taskId || p.locked != locked) continue;
      if (old.any((s) => s.overlaps(p.slot))) {
        final title = byId[p.taskId]?.title ?? 'another task';
        return locked ? 'you put $title there' : 'made room for $title';
      }
    }
  }

  if (movedEarlier) return 'an earlier slot opened up';
  return 'reshuffled around today\'s changes';
}
