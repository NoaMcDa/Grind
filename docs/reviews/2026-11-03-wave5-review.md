# Wave 4 and 5 review

Reviewer: W6-F. Scope: everything merged since the MVP review (`f7bd65a`) up to `3d26da8`: `lib/features/{analytics,capacity,companion,pip,goals,review,focus,calendar,settings,recurrence,onboarding}`, `lib/core/data` (schema v3, backup), `lib/core/notifications`, `lib/app`, `lib/widgets`, the Swift plugin, `Info.plist`, `web/index.html`. Format follows `2026-11-03-mvp-review.md`.

Method: every finding below was read in the code. Four of the correctness findings (C1, C2, C3, C5) were also reproduced with a throwaway test (deleted afterwards); the output is quoted. Nothing here is speculative; where something could not be run (Swift, a browser, iOS isolates) it says so.

Severity: **high** a user hits it in normal use or it contradicts a promise in the privacy copy; **medium** real but narrower; **low** polish and hygiene.
Status: **fixed** (in this PR, with a test), **proposed** (fix described, owner named), **open**.
Owners use the wave 6 map in `docs/plans/ownership.md`: W6-A l10n 3a, W6-B plan drafting, W6-C milestones, W6-D notifications and recurrence, W6-E Live Activity and focus, W6-G l10n 3b, or **integrator** (`lib/core`, `lib/app`, `pubspec.yaml`, `main.dart`, ARB merge).

No critical findings. 6 high, 13 medium, 6 low. 7 items fixed here (listed at the end).

## Correctness

### C1. High. Lock Screen "Done" and the review's "done" on a recurring task do not record progress: `COUNT` series never end, Today does not tick. Proposed (W6-D)
- `lib/core/notifications/notification_router.dart` `_handleRecurring` and `lib/features/review/evening_review_flow.dart` `_confirmDone` call `completeOccurrence(...)`, the task-only wrapper. Its own doc comment says to prefer `completeSeriesOccurrence` and store the rule, because otherwise "`lastCompletedAt` is not recorded and `COUNT` restarts from the moved `remindAt`". `TaskActions.setDone` (Today path, `task_actions.dart:83`) does it right.
- Scenario (run): `FREQ=DAILY;COUNT=3`, anchor 1 Nov 07:00, the user taps Done on each notification. Result: **6 completions and the series was still open** (loop cap), `rule.lastCompletedAt == null`. Each Done moves `remindAt`, and with no DTSTART pinned the next expansion counts `COUNT` from the new anchor. Second effect: Today derives "done" from `lastCompletedAt` (`isOccurrenceDone`), so an occurrence finished from the Lock Screen still shows as open on Today.
- Fix: both callers should call `completeSeriesOccurrence`, then `upsert` the task and `reminderRepository.upsert` the rule (the router already holds `_reminders`; the review flow reads `reminderRepositoryProvider`). Tests: a COUNT=3 series completed through the router ends after 3; Today shows the occurrence done.

### C2. High. Analytics counts paused time as focus time. Proposed (analytics path: W6-G)
- `lib/core/domain/focus_session.dart:48` `actualMinutes = endedAt - startedAt` ("pauses included"), used by `focusMinutesPerDay` (`analytics/stats.dart`, which carries a "Later: subtract pausedMs" comment). Since schema v3 `pausedMs` is persisted, and `FocusController._finish` already credits the task with `focused` (pauses removed).
- Scenario (run): 25 minute session with a 10 minute pause: the controller credits the task 15 minutes, the "Focus minutes" chart shows **25**. The two numbers in one app disagree, and the chart inflates the number Pip calls "just what happened".
- Fix: `focusMinutesPerDay` uses `((end - start) - paused).inMinutes` (clamped at 0), or `FocusSession` gets a `focusedMinutes` getter and `actualMinutes` is documented as wall time. Also filter `kind == focus` now, so a future break row cannot be summed.

### C3. High. The evening review never offers planner-placed tasks. Proposed (W6-D, `lib/features/review`)
- `rollover.dart` `reviewTasksFor` keeps tasks whose `remindAt ?? dueAt` falls on the day. A task the planner scheduled (`scheduledStart` set, no reminder, no due date, which is what the wave 3 scheduler produces) matches neither. `rolloverTask` and `fitsDeadline` do handle `scheduledStart` (`_reference`), so the intent was to include it.
- Scenario (run): open task scheduled today 10:00 to 11:00, nothing else: `reviewTasksFor(...)` returns **0** tasks. The user sees "nothing to move" while the plan still shows yesterday's undone blocks.
- Fix: `final at = t.remindAt ?? t.scheduledStart ?? t.dueAt`; include a test with a scheduled-only task.

### C4. Medium. Recurring tasks can be rolled or snoozed into a shifted series. Proposed (W6-D)
- Notification Snooze / Tonight / Tomorrow on a recurring task are ignored (documented in the router), but the buttons are still on the notification, so a tap silently does nothing and the reminder is gone. The evening review excludes recurring tasks from "moves on" (`_movable`) correctly.
- Fix: for a rule, ship the category without Snooze (a `GRIND_RECURRING` category with Done and Start focus), or add a one-off snooze field to `ReminderRule` (already proposed in the MVP review, H1). Until then, hide what does not work.

### C5. Medium. The preference log can lose entries; the capacity JSON files are not part of backup or delete. Proposed (capacity is W6-F's path: see "Fixed" below for the part done; rest integrator)
- `capacity/preference_log.dart` `record`: read, append, write, with `_cache` set only after the first `all()` resolves. Two `record` calls in flight both read the same list. Scenario (run): `Future.wait([record(a), record(b)])` leaves **1 entry**. A fast double drag is enough. Not fixed here because the real fix (a serialised queue) is a few lines but needs a design choice on failure handling; low impact (it is a hint log). Open.
- Bigger: see P1 below (the file is not covered by Delete all data).

### C6. Medium. "Later this week" is "two days later". Proposed (W6-D)
- `rollover.dart` `RolloverChoice.laterThisWeek` calls `rolloverTask(t, 2)`. On a Friday it lands on Sunday (next week for a Sunday-start user, Saturday is rest). The label promises "this week". Use the week end from `Preferences.weekStart`, or rename the option "In two days".

### C7. Medium. Day and week windows are computed once and never refreshed. Proposed (integrator / W6-G)
- `focusWeekProvider` (`analytics_providers.dart`) and `capacityWeekRangeProvider` read `clockProvider.now()` once at build. `clockProvider` is a plain `Provider<Clock>`, so nothing invalidates them at midnight. Scenario: app left open on Saturday night; at Sunday 00:05 the Capacity screen still shows last week's range because `weekReportProvider` watches the range provider, which only re-runs when preferences change. Same shape in `todayReviewTasksProvider` and `eveningReviewDueProvider`.
- Fix: one `dayTickProvider` (a stream that emits at the next local midnight and on app resume) watched by every provider that reads `now()` for a window.

### C8. Medium. Review uses device-local days, everything else uses the preference zone. Proposed (W6-D)
- `rollover.dart` `dayKey`/`shiftDays` call `toLocal()`. Wave 5 made the preference zone follow the device by default (`syncDeviceTimeZone`), which hides this, but a user who picked a zone by hand (the new picker) gets reminders in one zone and the review day in another. This is MVP finding M8 reaching a new module. Use `zoneLocationProvider` as the capacity providers now do (`taskToWall`, `zoneWall`).

### C9. Low. Smaller correctness items
- `weekday_hours_editor.dart` `_edit` replaced the day's list with one range, dropping the others (a split shift imported from a backup). Fixed here, test added.
- `evening_review_flow.dart` `RolloverChoice.drop` calls `repo.delete` straight from a radio-like choice with no undo, and leaves the task's `ReminderRule` (MVP L10). It is a soft delete, but nothing in the UI restores it. Add the same undo toast as Today.
- `capacity_providers.dart` `deferToNextWeek` unschedules and sets `notBefore` for tasks that may have a Google/Apple write-back event: confirm `pushPending` deletes the event when a task loses its slot (not tested in `test/features/capacity`).
- `analytics/stats.dart` `completionRatePerWeek` counts a recurring task once (its `remindAt` anchor), so completed occurrences do not appear in the rate at all.
- `ReorderableListView` drag in `priority_list.dart` writes a pin ("high") but the order is still decided by score, so a row dropped between two high-scoring neighbours can jump back. By design ("the score still decides"), but there is no message saying so. Product call.

## Security and privacy

### P1. High. "Delete all data" and "Import" leave data behind, and the privacy page says otherwise. Proposed (integrator; copy W6-G)
- `DriftBackupActions.deleteAllData` wipes Drift and resets the calendar providers. It does not touch the JSON files from `capacity/json_doc_store*.dart`: `grind_preference_log.json` (up to 2000 pairs of task ids with the score features of each task: hours to due, estimated minutes, goal importance) and `grind_capacity_settings.json` (weights and the ids of tasks pinned to the top). On web they sit in `localStorage` under `grind_preference_log` and `grind_capacity_settings`. `docs/privacy.md` says Delete all data "removes everything Grind holds on the device". After an import the file refers to task ids that no longer exist.
- Also not covered: the device time zone memory (`deviceTimeZoneMemoryProvider`) and the notification journal file (`FileNotificationStore`, task titles and bodies in the documents folder).
- Fix: add `JsonDocStore.clear()` (delete `preference_log` and `capacity_settings`), call it from `DataResetService`, and add the two documents to the backup or say in `privacy.md` that they are not backed up. Test: after `deleteAllData`, `preferenceLogProvider.all()` is empty.

### P2. High. Task titles appear on the Lock Screen and there is no way to hide them. Proposed (W6-D, copy W6-G)
- `reminders/reminder_copy.dart` puts `task.title` (and `firstAction`) in the notification title and body. A task like "Call the clinic" is readable on a locked phone. `docs/privacy.md` does not mention it. iOS offers "Show previews: when unlocked" system-wide, but Grind should not rely on it silently.
- Fix: a Settings switch "Hide task names in notifications" (default off), implemented in `ReminderCopy` with a neutral title ("A reminder from Pip"); mention it in `privacy.md`.

### P3. Medium. Welcome and Done copy say "Nothing leaves it" / "Everything stays on this device". Proposed (ARB: integrator or W6-G; wording below)
Checked `lib/l10n/app_en.arb` and `app_he.arb` against `docs/privacy.md`. `privacy.md` is accurate (Google is the one exception, calendar events are mirrored locally, backups contain calendar titles). The in-app strings are not:

| Key | Today | Problem |
|---|---|---|
| `onboardingWelcomeBody` | "Grind keeps your plans on this phone. Nothing leaves it." | false once Google is connected, and on web it is not "this phone" |
| `onboardingCalRationale` | "... Events are read on this device and stay here." | Google events come from Google's servers; a local copy is kept |
| `onboardingDoneBody` | "Everything stays on this device. ..." | same as the welcome line |
| `settingsPrivacyCopy` | "Everything stays on this device. No account, no sign-in." | "no sign-in" is false when Google is connected |

Proposed replacements (singular, gender-neutral Hebrew):

- `onboardingWelcomeBody` EN "Your plans stay on this device. There is no account and no Grind server." HE "התוכניות שלך נשארות במכשיר הזה. אין חשבון ואין שרת של Grind."
- `onboardingCalRationale` EN "Connecting a calendar lets me plan around meetings you already have. Google events are fetched from Google, Apple events are read on this device, and a copy stays here. Only the tasks you schedule are written back." HE "חיבור יומן מאפשר לי לתכנן סביב פגישות שכבר יש לך. אירועי Google נשלפים מ־Google, אירועי Apple נקראים במכשיר, ועותק נשאר כאן. רק משימות שתזמנת נכתבות חזרה."
- `onboardingDoneBody` EN "Your plans stay on this device. You can change any of this in Settings, whenever you like." HE "התוכניות שלך נשארות במכשיר הזה. אפשר לשנות כל דבר בהגדרות, מתי שנוח."
- `settingsPrivacyCopy` EN "Your plans stay on this device. No Grind account, no analytics. If you connect a calendar, its events are read to plan around them and only the tasks you schedule are written back." HE "התוכניות שלך נשארות במכשיר הזה. בלי חשבון Grind ובלי ניתוח נתונים. כשמחברים יומן, האירועים נקראים כדי לתכנן סביבם, ורק משימות שתזמנת נכתבות חזרה."
- `Info.plist` calendar strings say "Your events stay on this phone": accurate for Apple Calendar, leave.
- `lib/features/settings/settings_strings.dart` `privacyCopy` is already the honest version; the ARB should match it.

### P4. Medium. Calendar mirror survives reinstall on iOS; titles still in Keychain / `localStorage`. Open (integrator)
- `key_value_store_io.dart` documents "Survives app restarts, not reinstalls". flutter_secure_storage items in the iOS Keychain **do** survive an app delete by default. After reinstall `grind.google.connected` and the mirrored events (other people's meeting titles) are still there while Drift is empty. Fix: on first launch with an empty database (onboarding not done), run `deletePrefix('grind.')`; or store with `IOSOptions(accessibility: ...)` plus a launch marker. The mirror in the Keychain also repeats MVP M5 (titles outside Drift, outside backup).

### P5. Medium. The Apple plugin updates or deletes any event by id. Proposed (W6-E owns `ios/**`)
- `AppleCalendarPlugin.swift` `updateEvent` / `deleteEvent` look the event up with `store.event(withIdentifier:)` and write, with no check that it is a Grind write-back (`event.url` starting `grind://task/`). The Dart side only passes ids it created, so there is no known path today, but one stale `externalId` (a recurring occurrence id `<id>@<ms>` reaching `deleteEvent` after a future change) would remove a user's own meeting. Add `guard event.url?.scheme == "grind"` to both. Swift could not be compiled here.
- Also: `fetchEvents` returns `notes` of every event to Dart (needed for the marker); only the marker is used. Return `hasGrindMarker` instead and keep notes native.

### P6. Low. Security hygiene
- `plan_task_sheet.dart` `calendarDayUrl` opens any `https` `htmlLink`. A hand-edited backup can carry `https://evil.example/...` and the Plan sheet will open it on tap. Restrict to `calendar.google.com` / `www.google.com`.
- CSP review (`web/index.html`): `default-src 'self'`, no `unsafe-eval`, no inline script (pinned by the new `test/web/csp_test.dart`), `object-src 'none'`. Open points: (a) `fonts.gstatic.com` in `connect-src` (item F1 below); (b) `style-src 'unsafe-inline'` is needed by Flutter, fine; (c) GIS is not covered by SRI by design; (d) token revocation (`signOut`) may call `oauth2.googleapis.com`, which the CSP does not allow: untested because there is no real client id here. If revoke fails silently, `connect-src https://oauth2.googleapis.com` is the fix.
- `GoogleSignInAuth` stores no token (good, matches `privacy.md`); `lastError` strings contain Google's exception text and are developer-facing only.
- Backups are plaintext JSON through the share sheet. The Export row should say it contains calendar titles (MVP M10, still open).

### F1. Roboto and the CSP font host. Confirmed, proposed (integrator, `pubspec.yaml` + one asset)
- `web/index.html` allows `https://fonts.gstatic.com` in `connect-src`. I read the engine that ships with Flutter 3.35.5 (`flutter_web_sdk/lib/_engine/engine/canvaskit/fonts.dart`): at startup `loadAssetFonts` downloads **Roboto** from `fonts.gstatic.com` unless the font manifest has a family named `Roboto` (`loadedRoboto`). Grind does not bundle Roboto (only DM Sans, Bricolage Grotesque, Heebo), so every web start makes that request. `fonts.googleapis.com` is not used anywhere (no `google_fonts`, not in the CSP): nothing to remove there.
- Fix, exactly: copy a Roboto Regular TTF (Apache-2.0, 171 KB; the same file ships at `devtools_app_shared/fonts/Roboto/Roboto-Regular.ttf` in the pub cache) to `assets/fonts/Roboto-Regular.ttf` with its licence as `assets/fonts/OFL-Roboto.txt` (name it `LICENSE-Roboto.txt`, it is Apache), and add to `pubspec.yaml`:
  ```yaml
      - family: Roboto
        fonts:
          - asset: assets/fonts/Roboto-Regular.ttf
            weight: 400
  ```
  Then delete `https://fonts.gstatic.com` from `connect-src` in `web/index.html`, the sentence about it in the comment above the CSP and in `docs/privacy.md` ("Web build"), and the matching lines in `test/web/csp_test.dart` (the origin set and the "font hosts" test).
- Trade-off to decide first: the same host serves the Noto fallbacks CanvasKit fetches for glyphs none of the bundled fonts has (emoji, CJK, symbols typed into a task title). With the host removed those render as empty boxes instead of loading. If that is not acceptable, keep the host and accept that only a font file is requested (no user data is sent). I did not change `index.html`, because without the pubspec entry the CSP would block the Roboto download and the app could fail to boot.

## Accessibility

### A1. High. Almost nothing outside the tab bar is keyboard-operable (web). Fixed for widgets and onboarding; rest proposed
- ~35 `GestureDetector(onTap:)` sites (`PillButton`, `ChoicePills`, `TimePill`, Today rows, Plan timeline blocks, goal cards, task form chips, recurrence picker, Pip accessories ...) are not focusable: Tab skips them and Enter/Space do nothing. The web build is a shipped target. Only `InkWell` sites (tab bar, settings rows, pin chip) work.
- Fixed: new `lib/widgets/focus_tap.dart` (`FocusTap`: focusable, Enter and Space activate, 3 px violet focus ring, pointer cursor, disabled = not focusable). Used by `PillButton`, `ChoicePills` (also `inMutuallyExclusiveGroup`), `TimePill`. Tests: `test/widgets/components_test.dart` (focus, ring, Enter, Space, disabled not focusable), `test/features/onboarding/onboarding_flow_test.dart` (Enter picks Monday).
- Proposed (owners of those paths, one-line swaps): replace `GestureDetector` with `FocusTap` in `lib/features/{today,plan,goals,tasks,recurrence,pip,focus,ask,settings}`. Today and Plan rows are the priority.

### A2. Medium. Weight sliders had no accessible name. Fixed
- `capacity/priority_list.dart` `WeightsSection`: the label `Text` sat beside the `Slider`; VoiceOver read "40%, slider" four times. Now the slider announces "Deadline 40%" and the visual label and number are excluded to avoid double reading. Test: `week_capacity_screen_test.dart` (EN and HE).

### A3. Medium. Hard-coded English in semantics and labels. Part fixed
- `PipAvatar` default label "Pip, your companion" and `MomentumMeter` default "Momentum" were English in the Hebrew UI (21 call sites use the default, e.g. onboarding welcome and done). Fixed: both fall back to the existing `pipSemanticLabel` / `momentumSemantic` keys. Test in `components_test.dart` (HE).
- Open, need ARB keys (append): onboarding and review progress dots `'Step ${i+1} of $n'` (`onboarding_flow.dart:130`, `evening_review_flow.dart:486`): proposed key `stepOfCount` EN "Step {n} of {count}", HE "שלב {n} מתוך {count}". Pip screen button `'Your numbers'` (`pip_screen.dart:220`): proposed `pipYourNumbers` EN "Your numbers", HE "המספרים שלך". The analytics screen is entirely `AnalyticsStrings` (English constants): W6-G.

### A4. Medium. Text scale is clamped to 1.3. Open (integrator, `lib/app/app.dart`)
- `TextScaleClamp(maxScale: 1.3)` wraps the whole app. iOS Accessibility sizes go to about 3.1 and WCAG 1.4.4 asks for 200%. Users who set a larger size get 1.3. Fixed-height widgets (`PillButton` 44, `Pill` 26) are why the clamp exists. Proposal: raise the clamp to 2.0 and give `PillButton`/`Pill` `minHeight` with `IntrinsicHeight` instead of a fixed height; add a 2.0 scale golden for Today and Settings.

### A5. Low. Other gaps found
- `PillButton` has no disabled look (same colours as enabled); only semantics change. Add 0.5 opacity when `onPressed == null` (design call).
- `PillButton._target` guarantees 44 px height only; a short label with `height < 44` can be narrower than 44 px.
- Week bars: the "Packed" label is 10 px, scaled down by `FittedBox`, muted colour; under 11 px and low contrast. Overbooked state is carried by border colour and that label, which is acceptable, but make the label 11 px minimum.
- `ProgressDots` margins and the onboarding header used `EdgeInsets` (left/right), so in RTL the dots had their gap on the wrong side. Fixed (`EdgeInsetsDirectional`), test with the dots' rects in RTL.
- RTL otherwise: the capacity, pip and onboarding screens use directional insets and `AlignmentDirectional`; the existing RTL tests (onboarding, capacity) pass. `PipToast` uses symmetric `fromLTRB(16, 0, 16, 16)`, which is fine.
- Reduced motion: confetti and Pip bounce honour `disableAnimations` (`celebration_bus.dart`); onboarding page transitions and the review flow `AnimatedContainer`s do not (short, 200 to 250 ms; low).
- `MomentumMeter` at value 0 drew a 3 px ink bar (a `0.0001` fraction with an end border). Tone guide rule 6 says an empty meter is an empty track. Fixed (nothing drawn at 0), test added.

## Tone

Checked all EN strings in `app_en.arb` and the `*_strings.dart` files against the banned list, and the HE ARB against the substring list.

- T1. Medium. Hebrew substring `שוב` inside `חשוב` in four strings: `focusCheerStart2` ("... שום דבר אחר לא חשוב עכשיו"), `capacityPrioTitle`, `capacityReasonGoalMatters`, `capacityPinTitle`. The tone guide names exactly this trap, and the automated check covers only the praise and reminder pools. Meaning is fine ("important"); fix the guard (test below) so it ignores `חשוב`/`חשובה`, or reword. W6-A/W6-G (ARB).
- T2. Medium. `capacityReasonGoalStalled` "Its goal hasn't moved in a while" and `capacityReasonOverdue` "Past its date, so it comes first" are comparisons with a target (tone rules 1 and 2). Suggest "Its goal could use a little attention" and "This one has been waiting, so it comes first". Hebrew to match.
- T3. Low. Imperatives in capacity copy: "Breathe." (`capacityMovedMany`), "Enjoy the quiet." (`capacityPrioEmpty`). Rule 7: invite. Suggest "Moved {count} to next week. That is room to breathe." and "Nothing open. A quiet moment."
- T4. Low. "Overbooked by {over}" (`capacityVerdictOver`, and the state label "Overbooked") reads as a verdict on the user. The follow-up sentence is kind; "Over by {over}" or "A lot this week: {over} more than fits" is neutral.
- T5. Low. Analytics: subtitle "Just what happened. No grades." next to a "Completion rate" percentage chart; the chart is a grade. The note ("Share of each week's tasks you finished") should say the week's open tasks are not counted against anything, and the bar should not be coloured by the rate. `settings_strings.dart` `connectFailed` and `errors.dart` still use "try again" ("again" is on the banned list for Pip copy): MVP L1, still open.
- T6. Pass: Pip praise pool, reminder pool, evening review copy ("Repeats on its own, so it stays put", "That's planning, and it counts"), recap lines ("Everything stayed on its day"), onboarding notification-denied copy ("No problem. Grind works fine without notifications"), rest day wording in analytics.

## Test gaps

1. No test over the whole ARB for banned words (EN) or banned substrings (HE). The two lists live in `praise.dart` and `reminder_copy.dart`. Add `test/l10n/tone_test.dart` that loads both ARBs, skips `@` keys, and applies the tone guide lists with the `חשוב` exception. It would fail today on T1 and the `capacityReasonOverdue` case.
2. `NotificationRouter` recurring Done is tested for "does not complete the series" but not for COUNT or `lastCompletedAt` (C1). Same for the evening review.
3. No test that Delete all data clears every store the app writes (P1): enumerate stores and assert empty.
4. `test/core/data/migration_test.dart` exists; confirm it covers v1 to v3 with rows in `focus_sessions` and `goals` (those tables gained columns with `addColumn`), not only an empty database.
5. Provider windows across midnight (C7): no test with a `FakeClock` that advances.
6. `focusMinutesPerDay` has no test with `pausedMs` (C2).
7. Keyboard operation of Today, Plan and Goals (A1) is untested.
8. `FileJsonDocStore` / `LocalStorageJsonDocStore` have no tests (the web one cannot run on the VM; the file one can with a temp directory).
9. Swift plugin: no unit tests (no Mac). The ADR 0006 manual plan should add "delete a non-Grind event by a stale id fails with `notFound`" once P5 is fixed.

## Fixed in this PR

| # | Change | Test |
|---|---|---|
| A1 | `FocusTap` (new, `lib/widgets/focus_tap.dart`) used by `PillButton`, `ChoicePills`, `TimePill` | `components_test.dart`, `onboarding_flow_test.dart` |
| A2 | Slider names for the capacity weights | `week_capacity_screen_test.dart` |
| A3 | `PipAvatar`, `MomentumMeter` localized default labels | `components_test.dart` |
| A5 | `MomentumMeter` empty track at 0 | `components_test.dart` |
| A5 | Onboarding header and progress dots RTL-safe | `onboarding_flow_test.dart` |
| C9 | Weekday editor keeps a day's extra ranges | `onboarding_flow_test.dart` |
| P6 | CSP guard (origins, no unsafe-eval, no inline script) | `test/web/csp_test.dart` |

## Prioritized fix list

| # | Item | Owner path |
|---|---|---|
| 1 | C1: Done on a recurring task from the notification and the review must call `completeSeriesOccurrence` and save the rule | W6-D: `lib/core/notifications/notification_router.dart` (router edit is `lib/core`: integrator applies), `lib/features/review/evening_review_flow.dart` |
| 2 | P1: Delete all / Import also clear the capacity JSON documents (and decide on backup) | integrator: `lib/app/backup_actions_adapter.dart`, `lib/features/settings/data_reset_service.dart` (W6-G); `lib/features/capacity/json_doc_store*.dart` (add `clear`, W6-F follow-up) |
| 3 | C2: focus minutes subtract `pausedMs` | W6-G: `lib/features/analytics/stats.dart` |
| 4 | C3: review includes scheduled-only tasks | W6-D: `lib/features/review/rollover.dart` |
| 5 | P2: option to hide task names in notifications | W6-D: `lib/features/reminders/reminder_copy.dart`; W6-G: settings row; integrator: `docs/privacy.md` |
| 6 | P3: replace the four privacy strings | integrator (ARB merge) with the wording above |
| 7 | A1: `FocusTap` in the remaining tap targets | W6-A (tasks, plan sheets, recurrence), W6-B (today), W6-C (goals), W6-E (focus), W6-G (settings, calendar) |
| 8 | F1: bundle Roboto, then drop `fonts.gstatic.com` from the CSP | integrator: `pubspec.yaml`, `assets/fonts/`; then W6-F: `web/index.html`, `test/web/csp_test.dart` |
| 9 | P4: clear the Keychain mirror when the database is empty on launch | integrator: `lib/app`, `lib/features/calendar/google/key_value_store_io.dart` (W6-G) |
| 10 | P5: Swift guard on update/delete; return a marker flag instead of notes | W6-E: `ios/Runner/AppleCalendarPlugin.swift` |
| 11 | C4: hide Snooze on recurring reminders (or one-off snooze field) | W6-D: `lib/core/notifications/flutter_local_notifications_backend.dart` (integrator), `lib/features/recurrence` |
| 12 | C7/C8: day tick provider and preference-zone days in review | integrator: `lib/core/di.dart`; W6-D, W6-G |
| 13 | A3: ARB keys `stepOfCount`, `pipYourNumbers` and the HE strings | integrator (ARB merge); then W6-F: onboarding and pip |
| 14 | A4: raise the text scale clamp to 2.0 and make pills grow | integrator: `lib/app/app.dart`; W6-F: `lib/widgets/pill.dart` |
| 15 | T1 to T5: tone rewrites, plus the ARB tone test | W6-A, W6-G (ARB); test `test/l10n/tone_test.dart` |
| 16 | C5, C6, C9 rest, P6 URL host check | W6-F (preference log queue), W6-D (laterThisWeek), W6-B (plan sheet host check) |

## What is solid

- Schema v3 migration: one ordered `if (from < 3)` block, every added column has a default or is nullable, new tables created with `createTable`; backup format 2 reads format 1 and validates every row before writing, in one transaction; review tables are in `tablesChildrenFirst` so delete and import cover them.
- Period maths for goals and analytics use the preference zone and are tested across DST and week starts; `focusMinutesPerDay` zero-fills and shows rest days, never a failure.
- The Google provider stores no token, only a flag and sync state; disconnect clears the prefix; the sync engine's write-back handling from the MVP review is intact.
- Swift: no force unwraps, typed argument checks, store observer removed in `deinit`, empty calendar list returns no events instead of "all calendars".
- Reduced motion and no-guilt rules are respected in the celebration layer; `PipToast` is a live region; the capacity bars carry a text summary for each day.
- Capacity feature is pure maths plus providers with a clean test surface; the week report converts UTC instants to zone wall-clock at one boundary (`taskToWall`).

## Verification

`dart format lib test` (no changes), `flutter analyze` (no issues), `flutter test` (730 passed), `flutter build web --release --no-web-resources-cdn` (built; the built `index.html` has no inline script, so the CSP holds for it). The throwaway reproduction test was removed; its output: `occurrences completed: 6`, `rule lastCompletedAt: null`, `analytics minutes: 25`, `review tasks: 0`, `log entries: 1`. Not verifiable here: Swift, iOS Keychain persistence after reinstall (P4 is from the library's documented behaviour, confirm on a device), GIS revoke under the CSP, a real browser run of the CSP.
