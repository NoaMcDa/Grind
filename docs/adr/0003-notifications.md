# ADR 0003: Notifications

- Status: accepted
- Issue: #5
- Code: `lib/core/notifications/`, tests in `test/core/notifications/`

## Context

Reminders are the backbone of Grind. iOS keeps at most **64 pending local
notification requests per app**; past that it keeps the soonest 64 and silently
drops the rest (RESEARCH.md Part 2A). Users can have hundreds of reminders, and
the Done / Snooze buttons must work from the Lock Screen without opening the
app. The web build has no background delivery without push (#47).

## Decision

### 1. Plan a rolling window, never mirror the database

`NotificationScheduler.plan` is pure Dart: open tasks with `remindAt` inside
the next `horizonDays` (7), plus recurrence occurrences passed in as `extra`
(#11), plus one morning planning prompt (08:00 local) and one evening review
prompt (20:30 local) per day. It sorts by `fireAt` and keeps the soonest
`cap` (50). The 14 slots between 50 and 64 are headroom for anything another
feature schedules directly and for timing races during a reschedule.

`LocalNotificationService.replaceAll` trims again to `maxPending` (60) as a
hard guard, then cancels all *pending* requests (`cancelAllPendingNotifications`,
not `cancelAll`, so delivered notifications stay in Notification Center) and
schedules the new set.

`NotificationSync` re-plans on every `TaskRepository.watchAll()` /
`PreferencesRepository.watch()` change (debounced 500 ms), on `refresh()` at
launch and on return to foreground (`bindAppLifecycle`). It skips `replaceAll`
when the plan is unchanged. Because each run looks 7 days ahead, any app open
during the week tops the queue up. A `BGAppRefreshTask` top-up is the next step
(`UIBackgroundModes: fetch` is already in Info.plist); it needs a native task
registration and is left for a follow-up.

Known trade-off: prompts take up to 14 slots. With more than ~36 task reminders
in one week, the furthest reminders wait for the next re-plan. If this bites,
switch the prompts to one repeating request each (`DateTimeComponents.time`,
one slot each) once quiet hours and per-day copy allow it.

### 2. Ids

Stable string ids, so a re-plan replaces instead of duplicating:

- `task:<taskId>:<fireAt epoch minutes>`
- `prompt:morning:<yyyy-mm-dd>`, `prompt:evening:<yyyy-mm-dd>` (local date)

The plugin needs ints: `platformIdFor` is a 31-bit FNV-1a hash of the string id,
with linear probing on a collision inside one batch. An index
`platformId -> {id, taskId}` is persisted as JSON
(`notification_index.json` in the app support directory) so `cancelForTask`
works after a relaunch. Every notification carries the payload
`{"taskId", "notificationId"}`; responses are decoded from the payload, never
from the int id.

### 3. Time zones, DST, quiet hours

Tasks store UTC instants. Prompt times and quiet hours are local clock times in
`Preferences.timeZoneName`, resolved with the `timezone` database
(`latest_10y`), so 07:00 stays 07:00 across a DST change (tested for
Asia/Jerusalem in March and October 2026). A notification inside
`Preferences.quietHours` moves to the end of the quiet range on the same local
day. `quietHours` is a single in-day `TimeRange`, so a range across midnight is
not expressible yet (would need a list in `Preferences`).

### 4. Copy

If the task has a `firstAction`, the title is the task and the body is the
if-then form `"07:00 — open the thesis file."`. Otherwise the title is "Grind"
and the body is the task title. Prompts are invitations. No guilt words; a test
checks a small blocklist.

### 5. Actions and the background response design

Category `GRIND_REMINDER` with actions `done` ("Done"), `snooze`
("Snooze 15") and `start_focus` ("Start focus", `foreground` option so it
opens the app). Prompts have no category.

When Done or Snooze is tapped, iOS runs the app in the background and the
plugin calls the top-level `@pragma('vm:entry-point')`
`grindNotificationBackgroundHandler` in a separate isolate:

1. If the main isolate is alive (process running), it looks up a `SendPort`
   registered in `IsolateNameServer` and hands the response over; the main
   isolate's `NotificationRouter` applies it immediately.
2. Otherwise it appends the response to a journal file
   (`pending_notification_responses.json`). On the next launch
   `LocalNotificationService` drains the journal and replays it on
   `responses` before live ones (plus the launch-tap response, if any).

Exactly one path is taken per response, so a snooze is never applied twice.

Why a journal instead of writing the task in the background isolate: the
database (#2) has not merged, and two isolates writing one SQLite file needs
care. Consequence today: after Done on the Lock Screen of a **killed** app, the
notification disappears at once but the task flips to done on the next launch.
Follow-up once #2 lands: open the database in the background handler and run
`NotificationRouter.handle` there (drift supports this with a shared
`DriftIsolate` or by opening the same file with WAL), keeping the journal as
the fallback.

`NotificationRouter`: `done` sets status done and `completedAt`; `snooze`
sets `remindAt` to 15 minutes after the later of the old reminder and now
(a late tap never snoozes into the past) and increments `snoozeCount`;
`startFocus` emits the task id on `focusRequests` for the app router to open
`/focus?taskId=`; body taps emit on `opened`.

### 6. Web

`WebNotificationService` uses the browser Notification API via
`dart:js_interop`: permission flow, one `Timer` per pending item while the tab
is open, re-armed on every `replaceAll`, click -> `responses` with no action.
Nothing fires while the tab is closed and there are no action buttons (those
need a service worker). Web push is #47. `createNotificationService()` picks
the implementation by conditional import (`dart.library.js_interop` vs
`dart.library.io`), so the web build never sees `dart:io` or the plugin
backend.

### 7. Permission

`DarwinInitializationSettings` requests no permission at launch. The
onboarding / reminders UI shows Pip's rationale screen first and then calls
`NotificationService.requestPermission()`.

## iOS manual test plan (for Noa, on a device)

Setup: build with the integrator's `main.dart` wiring, a real iPhone, iOS 17+.

1. **Permission.** Fresh install. Launch: no system prompt appears. Trigger the
   rationale screen and accept: the system prompt appears once. Settings > Grind
   > Notifications shows Allowed.
2. **64-slot limit.** Using a debug seed (or the capture UI), create 100 tasks
   with reminders spread over the next 30 days, the first one 2 minutes out.
   In the Xcode console or a debug screen, confirm 50 or fewer pending requests
   (`UNUserNotificationCenter.getPendingNotificationRequests`) and that all
   reminders of the next 7 days are among them.
3. **Delivery while killed.** Swipe the app away. The first reminder arrives on
   the Lock Screen with the task title / if-then body.
4. **Done on the Lock Screen.** Long-press the notification, tap **Done**. The
   app must not open. Relaunch: the task shows as done, its reminder is gone
   from pending, and the pending set was topped up.
5. **Done while backgrounded.** Repeat 4 with the app in the background (not
   killed). Reopen: task already done.
6. **Snooze 15.** On another reminder, tap **Snooze 15**. Relaunch: the task's
   reminder moved 15 minutes later and a new notification arrives then.
   Repeat once: `snoozeCount` is 2.
7. **Start focus.** Tap **Start focus**: the app opens on the focus screen for
   that task.
8. **Body tap** opens the app (task / today).
9. **Quiet hours.** Set quiet hours 22:00-24:00, add a reminder at 23:00: it
   arrives at 00:00.
10. **Time zone / DST.** Set the device to Asia/Jerusalem and a date just
    before a DST change; the morning prompt still arrives at 08:00 local.
11. **Foreground presentation.** With the app open, a reminder still shows a
    banner.

## Consequences

- Reminders beyond 7 days depend on the app being opened (or, later, a
  background fetch) within the week.
- Lock Screen Done on a killed app is applied on next launch until #2 lands.
- The `NotificationService` interface did not need to change; the time zone is
  passed through the optional `TimeZoneAware` interface in this folder.
