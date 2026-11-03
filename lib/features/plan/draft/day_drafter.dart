import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/core.dart';
import '../../../core/notifications/time_zones.dart';
import '../../analytics/analytics_providers.dart';
import '../../capacity/capacity_providers.dart';
import '../../goals/domain/metric_ticks.dart';
import '../../tasks/day_bounds.dart';
import 'day_draft.dart';

/// A [DayDraft] plus what the sheet needs to show and apply it.
class DayDraftProposal {
  const DayDraftProposal({
    required this.draft,
    required this.tasks,
    required this.events,
    required this.location,
  });

  /// The draft as wall-clock values in [location].
  final DayDraft draft;

  /// The tasks the draft talks about, by id (UTC, as stored).
  final Map<String, Task> tasks;

  /// Today's busy calendar events from now on, as wall-clock values in
  /// [location], by start (shown between the blocks for context).
  final List<CalendarEvent> events;

  /// The user's zone when the draft was made.
  final tz.Location location;

  String titleOf(String taskId) => tasks[taskId]?.title ?? '';
}

/// The tasks a day draft may place, for the day [day] at [nowUtc] (UTC
/// tasks in, UTC tasks out):
///
/// - open, not deleted, not a goal metric tick;
/// - not anchored to a reminder still ahead (`remindAt` after now: the
///   user already picked its time);
/// - not scheduled on a later day (that day has its plan);
/// - a block that already ended (yesterday, or earlier today) comes back
///   unscheduled, so it can be drafted afresh.
///
/// Blocks pinned today stay as they are and block their time.
List<Task> draftCandidates(Iterable<Task> all, DayBounds day, DateTime nowUtc) {
  final out = <Task>[];
  for (final t in all) {
    if (t.status != TaskStatus.open || t.deletedAt != null) continue;
    if (isMetricTick(t)) continue;
    if (t.remindAt != null && t.remindAt!.isAfter(nowUtc)) continue;
    if (t.isScheduled) {
      if (!t.scheduledStart!.isBefore(day.end)) continue;
      if (!t.scheduledEnd!.isAfter(nowUtc)) {
        out.add(
          t.copyWith(
            scheduledStart: null,
            scheduledEnd: null,
            lockedStart: false,
          ),
        );
        continue;
      }
    }
    out.add(t);
  }
  return out;
}

/// Connects [draftDay] to the repositories, the clock and the user's zone,
/// the same way `PlanScheduler` does for the week: UTC instants become
/// wall-clock fields in `Preferences.timeZoneName` on the way in, and
/// placements go back through [fromZoneWall] on the way out.
class DayDrafter {
  DayDrafter(this._ref);

  final Ref _ref;

  TaskRepository get _tasks => _ref.read(taskRepositoryProvider);
  CalendarRepository get _events => _ref.read(calendarRepositoryProvider);
  DateTime get _nowUtc => _ref.read(clockProvider).now().toUtc();

  /// Drafts today, from now to midnight in the user's zone.
  Future<DayDraftProposal> propose() async {
    final prefs = await _ref.read(preferencesRepositoryProvider).get();
    final loc = locationFor(prefs.timeZoneName);
    final nowUtc = _nowUtc;
    final bounds = localDayBoundsIn(nowUtc, loc);
    final input = draftCandidates(await _tasks.getAll(), bounds, nowUtc);
    final events = await _events.getBetween(
      utcOf(bounds.start),
      utcOf(bounds.end),
    );
    final localEvents = [for (final e in events) _wallEvent(e, loc)];
    final now = zoneWall(nowUtc, loc);
    final draft = draftDay(
      tasks: [for (final t in input) _wallTask(t, loc)],
      goals: const {},
      events: localEvents,
      prefs: prefs,
      now: now,
      stats: _ref.read(userStatsProvider),
      weights: _ref.read(capacityConfigProvider).weights,
    );
    final shown = [
      for (final e in localEvents)
        if (e.isBusy && e.deletedAt == null && e.taskId == null && !e.isAllDay)
          if (e.end.isAfter(now)) e,
    ]..sort((a, b) => a.start.compareTo(b.start));
    return DayDraftProposal(
      draft: draft,
      tasks: {for (final t in input) t.id: t},
      events: shown,
      location: loc,
    );
  }

  /// Writes [draft]'s blocks (as UTC). Tasks finished, deleted or pinned
  /// since the draft was made are left alone. Returns how many changed.
  Future<int> apply(DayDraftProposal proposal, DayDraft draft) async {
    final nowUtc = _nowUtc;
    final loc = proposal.location;
    final updates = <Task>[];
    for (final i in draft.items) {
      final t = await _tasks.getById(i.taskId);
      if (t == null || t.status != TaskStatus.open || t.deletedAt != null) {
        continue;
      }
      if (t.lockedStart && t.isScheduled) continue;
      final start = fromZoneWall(i.start, loc);
      final end = fromZoneWall(i.end, loc);
      if (t.scheduledStart == start && t.scheduledEnd == end) continue;
      updates.add(
        t.copyWith(
          scheduledStart: start,
          scheduledEnd: end,
          lockedStart: false,
          updatedAt: nowUtc,
        ),
      );
    }
    if (updates.isNotEmpty) await _tasks.upsertAll(updates);
    return updates.length;
  }
}

DateTime? _wall(DateTime? t, tz.Location loc) =>
    t == null ? null : zoneWall(t, loc);

Task _wallTask(Task t, tz.Location loc) => t.copyWith(
  dueAt: _wall(t.dueAt, loc),
  remindAt: _wall(t.remindAt, loc),
  scheduledStart: _wall(t.scheduledStart, loc),
  scheduledEnd: _wall(t.scheduledEnd, loc),
  notBefore: _wall(t.notBefore, loc),
);

CalendarEvent _wallEvent(CalendarEvent e, tz.Location loc) =>
    e.copyWith(start: zoneWall(e.start, loc), end: zoneWall(e.end, loc));

final dayDrafterProvider = Provider<DayDrafter>(DayDrafter.new);
