import '../domain/calendar_event.dart';
import '../domain/energy.dart';
import '../domain/goal.dart';
import '../domain/preferences.dart';
import '../domain/task.dart';
import '../domain/time_range.dart';

/// The payload the assistant layer may send alongside an intent: the few
/// bits of app state a plan explanation or capture confirmation needs, with
/// nothing more. Pure data; no network, no identifiers that only mean
/// something to Grind, and no free-form notes unless the caller opts in.
///
/// The gateway built in PR #104 will carry this into its request; the
/// Settings "what is sent" copy slice (Epic #38) will render the same shape
/// so the user sees, before they turn the assistant on, exactly which
/// titles, times and counts leave the device.
///
/// Why this exists as its own type and not a Map:
/// - Explicit fields make the privacy rules reviewable at a glance.
/// - Size caps and ordering are centralised, so no caller can "accidentally
///   include everything".
/// - Future transports (edge function, Claude API) can serialize [toJson]
///   without each site re-deriving the same fields.
class AssistantContext {
  const AssistantContext({
    required this.nowUtc,
    required this.timeZoneName,
    required this.localeCode,
    required this.workingHoursToday,
    required this.openTasks,
    required this.todayEvents,
    required this.activeGoals,
    required this.totals,
    required this.includesTaskNotes,
    required this.includesGoalNotes,
    required this.includesEventTitles,
  });

  /// Now, in UTC. The scheduler and anything downstream converts back to
  /// the user's zone via [timeZoneName]; the wire form stays zone-free so
  /// it survives a trip through JSON.
  final DateTime nowUtc;

  /// IANA zone from [Preferences.timeZoneName] (e.g. `Asia/Jerusalem`).
  final String timeZoneName;

  /// Language the user reads the app in (e.g. `en`, `he`); lets the
  /// assistant match copy without inferring it from content.
  final String localeCode;

  /// Today's working windows in minutes-after-midnight pairs, in the user's
  /// zone. Empty on a day off. Small on purpose: the LLM never picks times.
  final List<AssistantTimeWindow> workingHoursToday;

  /// Up to [AssistantContextBuilder.maxOpenTasks] open tasks, in the order
  /// the user would see them in Today / Plan (priority, then deadline).
  final List<AssistantTaskSummary> openTasks;

  /// Calendar events whose window overlaps today's local day, oldest first.
  final List<AssistantEventSummary> todayEvents;

  /// Up to [AssistantContextBuilder.maxActiveGoals] goals the user is
  /// working on right now, highest-importance first.
  final List<AssistantGoalSummary> activeGoals;

  /// The pre-filter counts, so a prompt can say "and 7 more" honestly
  /// without the caller having to re-count. See [AssistantContextTotals].
  final AssistantContextTotals totals;

  /// True when task notes were included (opt-in).
  final bool includesTaskNotes;

  /// True when goal notes were included (opt-in).
  final bool includesGoalNotes;

  /// True when calendar event titles were included. Defaults on; turning
  /// it off keeps the windows so the assistant still sees busy time
  /// without seeing what the meeting is called.
  final bool includesEventTitles;

  /// True when any list was truncated by its cap.
  bool get truncated =>
      openTasks.length < totals.openTasks ||
      todayEvents.length < totals.todayEvents ||
      activeGoals.length < totals.activeGoals;

  Map<String, Object?> toJson() => {
    'nowUtc': nowUtc.toUtc().toIso8601String(),
    'timeZoneName': timeZoneName,
    'localeCode': localeCode,
    'workingHoursToday': [for (final w in workingHoursToday) w.toJson()],
    'openTasks': [for (final t in openTasks) t.toJson()],
    'todayEvents': [for (final e in todayEvents) e.toJson()],
    'activeGoals': [for (final g in activeGoals) g.toJson()],
    'totals': totals.toJson(),
    'includesTaskNotes': includesTaskNotes,
    'includesGoalNotes': includesGoalNotes,
    'includesEventTitles': includesEventTitles,
    'truncated': truncated,
  };
}

/// Pre-filter counts, so the context can say what was left out without
/// shipping the rest.
class AssistantContextTotals {
  const AssistantContextTotals({
    required this.openTasks,
    required this.todayEvents,
    required this.activeGoals,
  });

  final int openTasks;
  final int todayEvents;
  final int activeGoals;

  Map<String, Object?> toJson() => {
    'openTasks': openTasks,
    'todayEvents': todayEvents,
    'activeGoals': activeGoals,
  };
}

/// A minutes-after-midnight range, zone-interpreted via
/// [AssistantContext.timeZoneName].
class AssistantTimeWindow {
  const AssistantTimeWindow({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;

  Map<String, Object?> toJson() => {'start': startMinutes, 'end': endMinutes};
}

/// The task fields the assistant may read. No id, no reminder times, no
/// calendar-event back-pointer: nothing the assistant can't use.
class AssistantTaskSummary {
  const AssistantTaskSummary({
    required this.title,
    required this.estimatedMinutes,
    required this.priority,
    required this.energy,
    this.dueAtUtc,
    this.scheduledStartUtc,
    required this.linkedToGoal,
    this.notes,
  });

  final String title;
  final int estimatedMinutes;
  final int priority;
  final Energy energy;

  /// UTC; the caller converts to the user's zone for display.
  final DateTime? dueAtUtc;

  /// If the user or scheduler already placed it, the assistant can tell.
  final DateTime? scheduledStartUtc;

  /// Opt-out of the goal id — just whether it is tethered to a goal.
  final bool linkedToGoal;

  /// Only populated when the builder was told [includeTaskNotes] is true.
  final String? notes;

  Map<String, Object?> toJson() => {
    'title': title,
    'estimatedMinutes': estimatedMinutes,
    'priority': priority,
    'energy': energy.name,
    if (dueAtUtc != null) 'dueAtUtc': dueAtUtc!.toUtc().toIso8601String(),
    if (scheduledStartUtc != null)
      'scheduledStartUtc': scheduledStartUtc!.toUtc().toIso8601String(),
    'linkedToGoal': linkedToGoal,
    if (notes != null) 'notes': notes,
  };
}

/// What the assistant sees of a calendar event: enough to reason about
/// blocked time, no attendees, no description.
class AssistantEventSummary {
  const AssistantEventSummary({
    this.title,
    required this.startUtc,
    required this.endUtc,
    required this.isAllDay,
    required this.isBusy,
  });

  /// Absent when the builder was told [includeEventTitles] is false.
  final String? title;
  final DateTime startUtc;
  final DateTime endUtc;
  final bool isAllDay;
  final bool isBusy;

  Map<String, Object?> toJson() => {
    if (title != null) 'title': title,
    'startUtc': startUtc.toUtc().toIso8601String(),
    'endUtc': endUtc.toUtc().toIso8601String(),
    'isAllDay': isAllDay,
    'isBusy': isBusy,
  };
}

/// What the assistant sees of a goal: identity, how big it is, how far
/// along it is, no calibration or history.
class AssistantGoalSummary {
  const AssistantGoalSummary({
    required this.title,
    required this.horizon,
    required this.importance,
    required this.progress,
    this.area,
    this.targetDateUtc,
    this.metric,
    this.notes,
  });

  final String title;
  final GoalHorizon horizon;
  final double importance;
  final double progress;
  final String? area;
  final DateTime? targetDateUtc;
  final AssistantGoalMetric? metric;

  /// Only populated when the builder was told [includeGoalNotes] is true.
  final String? notes;

  Map<String, Object?> toJson() => {
    'title': title,
    'horizon': horizon.name,
    'importance': importance,
    'progress': progress,
    if (area != null) 'area': area,
    if (targetDateUtc != null)
      'targetDateUtc': targetDateUtc!.toUtc().toIso8601String(),
    if (metric != null) 'metric': metric!.toJson(),
    if (notes != null) 'notes': notes,
  };
}

/// Flat metric shape ("8 of 12 lessons"; "3 of 4 workouts this week").
class AssistantGoalMetric {
  const AssistantGoalMetric({
    required this.kind,
    this.target,
    this.current,
    this.unit,
    this.period,
  });

  final String kind;
  final int? target;
  final int? current;
  final String? unit;
  final String? period;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (target != null) 'target': target,
    if (current != null) 'current': current,
    if (unit != null) 'unit': unit,
    if (period != null) 'period': period,
  };
}

/// Builds an [AssistantContext] from the live app state the gateway cares
/// about. Pure and deterministic given its inputs — so the same user state
/// produces the same payload on iOS, web and in a unit test, and the
/// Settings "what is sent" screen can render the exact bytes the gateway
/// would hand out.
///
/// The defaults err on the side of less: no task notes, no goal notes,
/// titles kept. Callers flip a flag to loosen when a particular intent
/// needs more.
class AssistantContextBuilder {
  const AssistantContextBuilder({
    this.maxOpenTasks = 20,
    this.maxTodayEvents = 10,
    this.maxActiveGoals = 10,
    this.includeTaskNotes = false,
    this.includeGoalNotes = false,
    this.includeEventTitles = true,
  }) : assert(maxOpenTasks >= 0),
       assert(maxTodayEvents >= 0),
       assert(maxActiveGoals >= 0);

  final int maxOpenTasks;
  final int maxTodayEvents;
  final int maxActiveGoals;
  final bool includeTaskNotes;
  final bool includeGoalNotes;
  final bool includeEventTitles;

  /// Builds the context. [todayStart] / [todayEnd] come from the caller's
  /// `DayBounds` for the user's zone (`[start, end)` half-open), and
  /// [todayLocalDate] is that day's floating `DateTime(y, m, d)` (the
  /// `DayBounds.date` the Plan screens use). Staying zone-agnostic here
  /// lets the builder stay a pure function with no timezone database.
  AssistantContext build({
    required DateTime now,
    required DateTime todayStart,
    required DateTime todayEnd,
    required DateTime todayLocalDate,
    required Iterable<Task> tasks,
    required Iterable<Goal> goals,
    required Iterable<CalendarEvent> events,
    required Preferences preferences,
  }) {
    final open = <Task>[
      for (final t in tasks)
        if (t.deletedAt == null && t.status == TaskStatus.open) t,
    ]..sort(_taskOrder);

    final active = <Goal>[
      for (final g in goals)
        if (g.deletedAt == null && g.status == GoalStatus.active) g,
    ]..sort(_goalOrder);

    final todays = <CalendarEvent>[
      for (final e in events)
        if (e.deletedAt == null && _overlapsDay(e, todayStart, todayEnd)) e,
    ]..sort((a, b) => a.start.compareTo(b.start));

    final working =
        preferences.workingHours[todayLocalDate.weekday] ?? const <TimeRange>[];

    return AssistantContext(
      nowUtc: now.toUtc(),
      timeZoneName: preferences.timeZoneName,
      localeCode: preferences.localeCode,
      workingHoursToday: [
        for (final w in working)
          AssistantTimeWindow(
            startMinutes: w.startMinutes,
            endMinutes: w.endMinutes,
          ),
      ],
      openTasks: [for (final t in open.take(maxOpenTasks)) _summariseTask(t)],
      todayEvents: [
        for (final e in todays.take(maxTodayEvents)) _summariseEvent(e),
      ],
      activeGoals: [
        for (final g in active.take(maxActiveGoals)) _summariseGoal(g),
      ],
      totals: AssistantContextTotals(
        openTasks: open.length,
        todayEvents: todays.length,
        activeGoals: active.length,
      ),
      includesTaskNotes: includeTaskNotes,
      includesGoalNotes: includeGoalNotes,
      includesEventTitles: includeEventTitles,
    );
  }

  AssistantTaskSummary _summariseTask(Task t) => AssistantTaskSummary(
    title: t.title,
    estimatedMinutes: t.estimatedMinutes,
    priority: t.priority,
    energy: t.energy,
    dueAtUtc: t.dueAt?.toUtc(),
    scheduledStartUtc: t.scheduledStart?.toUtc(),
    linkedToGoal: t.goalId != null,
    notes: includeTaskNotes ? t.notes : null,
  );

  AssistantEventSummary _summariseEvent(CalendarEvent e) =>
      AssistantEventSummary(
        title: includeEventTitles ? e.title : null,
        startUtc: e.start.toUtc(),
        endUtc: e.end.toUtc(),
        isAllDay: e.isAllDay,
        isBusy: e.isBusy,
      );

  AssistantGoalSummary _summariseGoal(Goal g) => AssistantGoalSummary(
    title: g.title,
    horizon: g.horizon,
    importance: g.importance,
    progress: g.progress,
    area: g.area,
    targetDateUtc: g.targetDate?.toUtc(),
    metric: g.metricKind == null
        ? null
        : AssistantGoalMetric(
            kind: g.metricKind!,
            target: g.metricTarget,
            current: g.metricCurrent,
            unit: g.metricUnit,
            period: g.metricPeriod,
          ),
    notes: includeGoalNotes ? g.notes : null,
  );
}

int _taskOrder(Task a, Task b) {
  final byPriority = a.priority.compareTo(b.priority);
  if (byPriority != 0) return byPriority;
  final byDue = _compareNullableAsc(a.dueAt, b.dueAt);
  if (byDue != 0) return byDue;
  final bySched = _compareNullableAsc(a.scheduledStart, b.scheduledStart);
  if (bySched != 0) return bySched;
  return a.title.compareTo(b.title);
}

int _goalOrder(Goal a, Goal b) {
  final byImportance = b.importance.compareTo(a.importance);
  if (byImportance != 0) return byImportance;
  final byDeadline = _compareNullableAsc(a.targetDate, b.targetDate);
  if (byDeadline != 0) return byDeadline;
  return a.title.compareTo(b.title);
}

/// Nulls sort last, matching the Plan screen's "no deadline, at the bottom"
/// convention.
int _compareNullableAsc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

bool _overlapsDay(CalendarEvent e, DateTime startUtc, DateTime endUtc) {
  final a = e.start.toUtc();
  final b = e.end.toUtc();
  return a.isBefore(endUtc) && b.isAfter(startUtc);
}
