# ADR 0003: Notifications

- Status: accepted
- Issues: #5; updated for #9, #10, #12 (wave 2)
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

### 4. Copy (#9)

`ReminderCopy` (`lib/features/reminders/reminder_copy.dart`) builds every task
reminder, for the notification and the Today card alike:

- With a `firstAction`: title = task title, body
  `"<HH:mm> — <firstAction>. <encouraging line>"` (time in
  `Preferences.timeZoneName`).
- Without: title "Grind", body `"<task title>. <encouraging line>"`.
- The line comes from a pool of 20 per language (English, Hebrew written in
  gender-neutral forms). Rotation is deterministic:
  `(fnv(taskId) + localDay * 7) mod 20`; 7 is coprime with 20, so a task sees
  every line before any repeats (never the same line within 5 days).
- `ReminderCopy.bannedWords` ("should", "failed", "again", "missed", ... and
  Hebrew equivalents) is enforced over the whole pool by a test.

`NotificationScheduler.copyFor(task, prefs, fireAt)` is the public entry point
(also for recurrence occurrences, #11). Ids and ordering are unchanged.

**Fire time.** `Task.remindAt` is the fire time. Only a task with a due *time*
and no `remindAt` gets a reminder at `dueAt - defaultReminderLeadMinutes`; a
date-only due (local midnight or 23:59) gets none
(`NotificationScheduler.reminderTimeFor`). Tasks with a `ReminderRule` skip
`remindAt` (their occurrences come through `extra`), and `NotificationSync`
watches `ReminderRepository` so rule-only edits re-plan.

### 5. Actions and the background response design (#10, #12)

Two categories, both registered at launch:

- `GRIND_REMINDER`: `done` ("Done"), `snooze` ("Snooze 15"), `start_focus`
  ("Start focus", `foreground`).
- `GRIND_RESCHEDULE` (smart snooze, #12): `move_tonight` ("Tonight"),
  `move_tomorrow` ("Tomorrow"), `pick_time` ("Pick a time", `foreground`;
  decodes to no action, so it behaves as a body tap and opens `/task/<id>`).

The scheduler picks `GRIND_RESCHEDULE` once `snoozeCount >= 2`
(`smartSnoozeAfter`): snooze twice and the third notification reads "Want to
move this instead? «task» can have a calmer moment." It never mentions the
snoozes. Prompts have no category. `categoryFor(actions)` maps actions to the
category.

`NotificationRouter`:

- `done`: status done, `completedAt` now, then
  `NotificationService.cancelForTask` (best effort) so the task's other
  pending requests go at once.
- `snooze`: `remindAt` = 15 minutes after the later of the old reminder and
  now (a late tap never snoozes into the past), `snoozeCount + 1`.
- `moveToTonight`: today 20:00 local, or tomorrow 20:00 when that has passed
  (after midnight "today" is the new day); `snoozeCount = 0`.
- `moveToTomorrow`: the reminder's local clock time on the day after now's
  local date; `snoozeCount = 0`. Both DST-safe (`RescheduleTimes`).
- `startFocus`: emits on `focusRequests` (`/focus?taskId=`).
- body tap / Pick a time: emits on `opened`; `openLocation` gives
  `/task/<id>` (null for prompts).

The Today card (`ReminderNowCard`) applies its buttons through the same
router, so iOS, web and the card behave identically.

When an action without the `foreground` option is tapped, iOS runs
`grindNotificationBackgroundHandler` in a background isolate:

1. Main isolate alive: hand the response over the `IsolateNameServer` port;
   the main router applies it.
2. Otherwise: open the Drift database (`AppDatabase(openConnection())`) and
   run `applyResponseInBackground` (same router, Drift repositories). After a
   snooze or move it re-plans only that task's own reminders
   (`LocalNotificationService.replaceTaskReminders`, ids `task:<id>:…`) with a
   service that skips `initialize` and the journal, so the next reminder
   (or the reschedule offer) is pending without opening the app. Prompts and
   recurrence occurrences wait for the app's next full re-plan.
3. If opening or writing the database throws, append to the journal
   (`pending_notification_responses.json`), replayed on the next launch as
   before. Notification errors after a successful write are swallowed, so a
   response is never applied twice.

Two connections to one SQLite file (background isolate plus a main isolate
that started at the same time) are safe for these single-row writes; a
locked database falls back to the journal. A running main isolate's drift
streams do not see a write from the other connection until its next own
write; `NotificationSync` re-reads the repositories on resume
(`refresh(reload: true)`). The UI stream can be nudged on resume with
`db.markTablesUpdated({db.tasks})` (integrator, `main.dart`).

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
4. **Done on the Lock Screen (killed app).** Long-press the notification,
   tap **Done**. The app must not open. Without relaunching, check pending
   requests (Xcode console): none left for that task. Relaunch: the task
   shows as done at once and the journal file
   (`pending_notification_responses.json`) does not exist.
5. **Done while backgrounded.** Repeat 4 with the app in the background (not
   killed). Reopen: task already done.
6. **Snooze 15 (killed app).** On another reminder, tap **Snooze 15** and do
   not open the app. A new notification arrives 15 minutes later with the
   normal actions. Snooze it again: the third notification reads "Want to
   move this instead?" with **Tonight / Tomorrow / Pick a time**.
6a. **Tonight.** Tap **Tonight** (before 20:00): the next reminder arrives at
   20:00 with Done / Snooze 15 / Start focus again. After 20:00 it moves to
   20:00 the next day.
6b. **Tomorrow.** Tap **Tomorrow**: the reminder arrives at the same clock
   time the next day.
6c. **Pick a time.** Tap it: the app opens on the task (`/task/<id>`).
6d. **Copy.** A task with a first action reads
   "07:00 — open the thesis file. <line>"; switch the language to Hebrew,
   relaunch, and the next reminder reads in Hebrew (action button titles stay
   English until the categories are localised).
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
- Lock Screen actions on a killed app are written to the database directly;
  only a database failure leaves them to the journal and the next launch.
- iOS action button titles are registered once, in English; localising them
  needs the locale at launch (follow-up).
- The `NotificationService` interface did not need to change; the time zone is
  passed through the optional `TimeZoneAware` interface in this folder.
