import 'package:flutter/foundation.dart';

import '../../../core/core.dart';
import 'goal_progress.dart';
import 'goal_record.dart';

/// The Highlights groups (#28), in screen order.
enum HighlightGroup { completed, closeToDone, onTrack, stalled }

/// Days without progress after which an active goal reads "stalled",
/// relative to its horizon: a week goal goes quiet sooner than a year goal.
int stalledAfterDays(GoalHorizon h) => switch (h) {
  GoalHorizon.week => 3,
  GoalHorizon.month => 10,
  GoalHorizon.quarter => 21,
  GoalHorizon.year => 45,
};

/// One goal on the Highlights screen.
@immutable
class GoalHighlight {
  const GoalHighlight({
    required this.goal,
    required this.progress,
    required this.group,
    required this.lastMovedAt,
    required this.quietDays,
  });

  final GoalRecord goal;
  final GoalProgress progress;
  final HighlightGroup group;

  /// The last moment the goal moved (see [lastMovedAt]).
  final DateTime lastMovedAt;

  /// Whole days since [lastMovedAt] (0 = moved within the last 24 h).
  final int quietDays;
}

/// The last moment [goal] moved: its `lastProgressAt`, the latest
/// completion among its [tasks] (linked tasks and +1 ticks), or when it
/// was created.
DateTime lastMovedAt(GoalRecord goal, Iterable<Task> tasks) {
  var last = goal.lastProgressAt ?? goal.createdAt;
  for (final t in tasks) {
    final c = t.completedAt;
    if (t.deletedAt == null &&
        t.goalId == goal.id &&
        t.isDone &&
        c != null &&
        c.isAfter(last)) {
      last = c;
    }
  }
  return last;
}

/// Where [goal] goes on the Highlights screen.
///
/// Completed: marked done, or the target (or this period's quota) reached.
/// Close to done: 80 % or more. Stalled: active and quiet for at least
/// [stalledAfterDays] of its horizon. On track: everything else, paused
/// goals included (resting is never "stalled").
HighlightGroup classifyGoal({
  required GoalRecord goal,
  required GoalProgress progress,
  required int quietDays,
}) {
  if (progress.isCompleted) return HighlightGroup.completed;
  if (progress.isCloseToDone) return HighlightGroup.closeToDone;
  if (goal.status == GoalStatus.active &&
      quietDays >= stalledAfterDays(goal.horizon)) {
    return HighlightGroup.stalled;
  }
  return HighlightGroup.onTrack;
}

/// Every goal grouped for the Highlights screen. Always all four keys;
/// within a group, by importance then age.
Map<HighlightGroup, List<GoalHighlight>> groupHighlights({
  required Iterable<GoalRecord> goals,
  required Iterable<Task> tasks,
  required GoalProgress Function(GoalRecord goal) progressOf,
  required DateTime now,
}) {
  final out = {for (final g in HighlightGroup.values) g: <GoalHighlight>[]};
  final all = tasks.toList();
  for (final goal in goals) {
    if (goal.deletedAt != null) continue;
    final progress = progressOf(goal);
    final moved = lastMovedAt(goal, all);
    final quiet = now.difference(moved).inDays.clamp(0, 1 << 30);
    final group = classifyGoal(
      goal: goal,
      progress: progress,
      quietDays: quiet,
    );
    out[group]!.add(
      GoalHighlight(
        goal: goal,
        progress: progress,
        group: group,
        lastMovedAt: moved,
        quietDays: quiet,
      ),
    );
  }
  for (final list in out.values) {
    list.sort((a, b) {
      final i = b.goal.importance.compareTo(a.goal.importance);
      return i != 0 ? i : a.goal.createdAt.compareTo(b.goal.createdAt);
    });
  }
  return out;
}
