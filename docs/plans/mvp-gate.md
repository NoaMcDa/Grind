# MVP gate

Status of the phase 1 MVP after wave 3 integration (W3-A, #16 UI). Every
line below was run on Linux (Flutter 3.35.5, Dart 3.9) on
`feat/16-scheduler-ui-integration`; nothing here was checked on a Mac or a
device.

## Checklist

| Gate | Status | How |
|---|---|---|
| Format | pass | `dart format lib test` (0 changed) |
| Analyze | pass | `flutter analyze` — no issues |
| Unit + widget tests | pass | `flutter test` — 372 tests, incl. `test/app/e2e_mvp_test.dart` and `test/features/plan/plan_scheduler_test.dart`; the scheduler wiring tests also pass with `TZ=Asia/Jerusalem`, `America/Los_Angeles` and `Pacific/Auckland` |
| Web release build | pass | `flutter build web --release --no-web-resources-cdn` |
| Web smoke test | pass | Playwright (Chromium, 390×844, DPR 2) against `build/web` on a static server; screenshots below |
| iOS build / device | **not run** | needs a Mac — see below |
| Google Calendar against a real account | **not run** | needs OAuth client ids — see below |

## End-to-end tests (`test/app/e2e_mvp_test.dart`)

In-memory fakes and a `FixedClock` via `pumpGrindApp`:

1. Create a task from Today → it shows in Up next → task detail →
   "Schedule it for me" places it at 09:00 (the toast gives the reason) →
   it is on Plan at that time → Done from the Today row moves momentum
   (1 of 5 → 2 of 5).
2. Reminder card at 12:35 for the 12:30 lab: open → Snooze 15 → "See you
   at…" → Undo → Done → "Nice start!", momentum 1 of 4 → 2 of 4.
3. Plan → "Re-plan with Pip": the sheet lists each placement with its
   reasons and the task that cannot fit with why; Apply writes UTC slots and
   leaves the impossible task unscheduled; drag the placed block by 15 min
   (locks it); the next re-plan keeps it ("One thing you placed yourself
   stays put") and does not offer to move it.
4. Settings reachable from the gear on the Today header, and back.
5. Onboarding gate: a new user skips through onboarding and lands on Today.

The drag tests in `test/features/plan/plan_screen_test.dart` stay as they
were and pass.

## Web smoke test (screenshots)

Fresh browser profile, real build (drift on IndexedDB, no demo seed in
release). Steps: onboarding Skip ×5, "Take me to Today", `+`, type a title,
Save, Plan tab, "Re-plan with Pip", Apply, reload the page.

| File | What it shows |
|---|---|
| `docs/handoff/screens-mvp/01-onboarding.png` | First onboarding step |
| `docs/handoff/screens-mvp/02-today-empty.png` | Today after onboarding, empty state, settings gear |
| `docs/handoff/screens-mvp/03-new-task.png` | Quick-add sheet with a title typed |
| `docs/handoff/screens-mvp/04-today-with-task.png` | The task in Up next |
| `docs/handoff/screens-mvp/05-plan-before.png` | Plan, empty day, capacity line ("… free · nothing planned yet") |
| `docs/handoff/screens-mvp/06-replan-sheet.png` | Re-plan review sheet: placement, slot and reason, Apply / Not now |
| `docs/handoff/screens-mvp/07-plan-applied.png` | Task placed on the timeline, capacity updated, Pip toast |
| `docs/handoff/screens-mvp/08-after-reload.png` | After a page reload: the task is still scheduled (local storage persists) |
| `docs/handoff/screens-mvp/10-plan-task.png` | Plan task sheet: Mark done, Schedule it for me, Details, Unschedule |
| `docs/handoff/screens-mvp/11-settings.png` | Settings opened from the Today gear |

The Playwright driver lives outside the repo (a scratch script that taps
CSS-pixel coordinates); rerun it by serving `build/web` and repeating the
steps above.

## What still needs a Mac or credentials

- **iOS build and run** (`flutter build ios`, simulator, device): local
  notifications with actions (Done / Snooze / Start focus) from the Lock
  Screen, the notification permission flow in onboarding, background
  responses.
- **Apple Calendar** (EventKit plugin, `ios/Runner/AppleCalendarPlugin.swift`):
  permission prompt, reading events into Plan, the Swift ↔ Dart contract.
  "Open in calendar" is disabled for Apple events (no web URL); a
  `calshow:` deep link is a follow-up for iOS.
- **Google Calendar with a real account**: needs the web and iOS OAuth
  client ids in `google_config.dart` / `Info.plist`. Unverified: sign-in,
  pull, write-back of scheduled tasks, and the sync error toast on Plan
  with a real error.
- **Time zones on device**: the scheduler wiring converts UTC ↔ device local
  time at the boundary; day boundaries come from the device zone, not
  `Preferences.timeZoneName` (scheduler README). Check a device whose zone
  differs from the preference.

## Known limits (by design for v1)

- A task holds one `scheduledStart`/`scheduledEnd`, so the wiring plans each
  task as a single block (`splittable` is ignored when planning).
- "Re-plan with Pip" plans the selected week from now (or the week's start
  for a later week); a past week gives an empty draft. Unlocked scheduled
  tasks may move; tasks dragged by hand stay put.
- "Open in calendar" opens Google Calendar's web day view on the event's
  date, because `CalendarEvent` has no per-event link yet.
