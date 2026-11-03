# Scheduler core (#16)

A deterministic, explainable gap-filler. Pure Dart: every function is a pure
function of `(tasks, events, prefs, stats, now)`. No I/O, no `DateTime.now()`,
no Riverpod (except the one provider in `providers.dart`). The spec is
`docs/research/replanning-architecture.md` §5–6.

## Calling it

```dart
import 'package:grind/features/plan/scheduler/scheduler.dart';

final result = plan(
  tasks: tasks,                 // all tasks; done/skipped/deleted are ignored
  goals: {for (final g in goals) g.id: g},
  events: events,               // busy events block; isBusy == false is ignored
  prefs: prefs,
  now: clock.now(),             // local time, injected
  // stats: UserStats(...),     // optional, gated by sample counts
  // weights: SchedulerWeights(...),
  // horizonEnd: ...,           // default: end of week or now + 7 days, later wins
);

result.placed;               // List<Placement>, sorted, each with 1–3 reasons
result.unplaced;             // List<UnplacedTask>, each with a reason
result.capacity;             // WeekCapacity: free vs demand, per day
result.deferralSuggestions;  // only when overbooked; never in-week deadlines
capacitySummary(result.capacity, deferrals: result.deferralSuggestions.length);
// "You have 14 hours free and 19 hours of plans. Two things could move to next week."
```

From widgets, use `ref.read(schedulerProvider).plan(...)` (`providers.dart`); it
takes `now` from `clockProvider`.

"Re-plan with Pip" is `replan(previous: oldPlan, ...)`: the same `plan()` with
completed/skipped tasks dropped and pinned tasks kept, plus a `PlanDiff`
(`moved`, `added`, `removed`), one reason per change ("Team sync now takes that
time", "an earlier slot opened up", "done, nice work").

Lower-level pieces: `freeSlots(...)`, `weekCapacity(...)`,
`deferralSuggestions(plan, ...)`, `score(...)` / `scoreBreakdown(...)`,
`adjustedMinutes(task, stats)`.

## Rules, in short

- Free time = working hours − busy events (merged, padded by
  `bufferBetweenEventsMinutes` both sides) − lunch − pinned tasks, then
  `dailyCushionMinutes` taken from the end of each day; gaps < 15 min dropped.
  Deleted events and events with a `taskId` (Grind write-backs) do not block.
- Pinned = `lockedStart && isScheduled`: copied verbatim, never moved. Pinned
  tasks entirely in the past drop out of the plan.
- Queue: score desc, due asc (undated last), adjusted minutes asc, id asc.
- Earliest fit, never before `now`, never ending after `dueAt` or the horizon.
- Deep tasks try the deep windows first (any day before the deadline), then any
  slot; at most `maxDeepBlocksPerDay` deep blocks a day (each chunk counts).
- While deep tasks are still waiting, light tasks keep out of the deep windows
  when the same day has room elsewhere (protects the focus window). This is
  the one rule beyond the research pseudocode. Such a placement says
  "keeps your focus window clear".
- Duration fit (#17): on the same day, a light task that is not urgent
  (urgency ≤ 0.6) prefers a gap it fills (less than 15 minutes left over)
  to one it would fragment, so longer gaps stay whole for longer tasks
  ("fills a 30-minute gap"). Urgent tasks keep the earliest fit.
- A one-day horizon (`horizonEnd` = next midnight) words misses as "today"
  ("no free 45-minute slot today", "focus blocks are full today").
- Splittable tasks are chunked; no chunk shorter than `minChunkMinutes` except
  a final remainder.
- `days_left` in the score is fractional (minutes / 1440) instead of whole
  days, so tasks due the same day still order deterministically.
- Capacity: locked tasks count as demand, not as lost free time. Demand is the
  sum of adjusted estimates of every open task passed in, so pass the tasks
  that are meant for this horizon.

## Day drafts

`../draft/day_draft.dart` runs `plan()` with `horizonEnd` = end of today
for "Your day, drafted" (#17); the review sheet reorders by re-fitting the
blocks in the chosen order into the same free slots.

## Time zone assumption

Everything is local wall-clock time. Callers pass local `DateTime`s (the
domain stores UTC; convert with `.toLocal()` or the `timezone` package before
calling). `Preferences.workingHours`, `deepWindows` and `lunch` are read as
local clock ranges on the calendar day of each slot, using DST-safe
`DateTime(y, m, d, 0, minutes)` construction. Instants are compared as
instants, so a stray UTC value still compares correctly, but day boundaries
come from the device's local zone, not `Preferences.timeZoneName`. Output
`Placement` times are local.

The app wiring (`plan_scheduler.dart`) therefore does not pass `.toLocal()`
values: it passes wall-clock fields in the user's zone
(`zoneWall(instant, locationFor(prefs.timeZoneName))`, see
`lib/features/tasks/day_bounds.dart`) and converts placements back with
`fromZoneWall`. The core's "local" day is then the user's day, whatever zone
the device is in. Callers outside the app wiring should do the same.

## Fields the domain model is missing

Proposed additions to `lib/core` (integrator), none required today:

- `Task.notBefore` (`DateTime?`): earliest allowed start. Today the earliest
  start is always `now`.
- `Task.minutesDone` (`int`, default 0): progress on long tasks, so the
  scheduler plans only what is left. Today it plans the full estimate.
- `Preferences.minSlotMinutes` (`int`, default 15) and
  `Preferences.deepWindowsByWeekday` (`Map<int, List<TimeRange>>?`) if focus
  windows ever differ per day.
- `Goal.lastProgressAt` exists; the stalled bonus depends on someone setting it.
- A `UserStats` store (phase 2): duration ratios per `Task.category` and
  completion counts per (hour band, energy), fed from `FocusSession` and
  `Task.actualMinutes`.
