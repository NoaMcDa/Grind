import 'package:grind/core/domain/domain.dart';
import 'package:grind/core/services/clock.dart';

import 'models.dart';
import 'planner.dart' as planner;
import 'replan.dart' as replanner;

/// The scheduler with `now` taken from an injected [Clock]. No logic of its
/// own; see [planner.plan] and [replanner.replan].
class SchedulerService {
  const SchedulerService(this.clock);

  final Clock clock;

  Plan plan({
    required List<Task> tasks,
    required Map<String, Goal> goals,
    required List<CalendarEvent> events,
    required Preferences prefs,
    UserStats stats = const UserStats(),
    SchedulerWeights weights = const SchedulerWeights(),
    DateTime? horizonEnd,
    Map<String, List<Slot>> prevPlacements = const {},
  }) => planner.plan(
    tasks: tasks,
    goals: goals,
    events: events,
    prefs: prefs,
    now: clock.now(),
    stats: stats,
    weights: weights,
    horizonEnd: horizonEnd,
    prevPlacements: prevPlacements,
  );

  replanner.ReplanResult replan({
    required Plan previous,
    required List<Task> tasks,
    required Map<String, Goal> goals,
    required List<CalendarEvent> events,
    required Preferences prefs,
    UserStats stats = const UserStats(),
    SchedulerWeights weights = const SchedulerWeights(),
    DateTime? horizonEnd,
    Map<String, List<Slot>> prevPlacements = const {},
  }) => replanner.replan(
    previous: previous,
    tasks: tasks,
    goals: goals,
    events: events,
    prefs: prefs,
    now: clock.now(),
    stats: stats,
    weights: weights,
    horizonEnd: horizonEnd,
    prevPlacements: prevPlacements,
  );
}
