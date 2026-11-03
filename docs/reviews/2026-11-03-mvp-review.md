# MVP review: waves 1 and 2

Reviewer: W3-B. Scope: PRs #52 to #73 as merged on `main` (60d2a9b). Read: `lib/core/**`, `lib/features/{reminders,recurrence,calendar,settings,onboarding}/**`, the Swift plugin, `Info.plist`, `web/index.html`, the workflows, and a skim of the rest. `flutter analyze` was clean and all tests passed before any change.

Severity: **critical** loses or leaks data for everyone; **high** a user hits it in normal use; **medium** real but narrower, or a missing safeguard; **low** polish and hygiene.

Status: **fixed** (in this PR, with a test that fails before and passes after), **proposed** (fix described, not made), **W3-A** (in `lib/features/{plan,today,tasks}`, `lib/app`, `test/app`: not touched here, for the other agent or the integrator).

No critical findings. 4 high, 11 medium, 12 low.

## High

### H1. "Done" on a recurring reminder ends the whole series; "Snooze" shifts the series. Fixed (notification path), W3-A (Today path)
- `lib/core/notifications/notification_router.dart` (`handle`, done / snooze / move cases); `lib/features/recurrence/occurrence_completion.dart` (`completeOccurrence`, used nowhere).
- A daily 07:00 task anchored on 1 Nov. On 3 Nov the user taps Done on the Lock Screen (or on the Today card): the task becomes `done`, the series stops, tomorrow's reminder is cancelled. Tapping Snooze 15 at 07:01 set `remindAt = now + 15 min` and bumped `snoozeCount`; `remindAt` is the series anchor, so every later occurrence moved to 07:16 for good, and after two snoozes the whole series got the "move this instead" copy.
- Fix: `NotificationRouter` takes an optional `ReminderRepository`. With a rule, Done calls `completeOccurrence` (anchor advances to the next occurrence, task stays open, pending occurrences are not cancelled), and Snooze / Tonight / Tomorrow leave the series alone. Wired in `notificationRouterProvider`, `reminderActionsProvider` and `applyResponseInBackground`. Tests in `notification_router_test.dart` and `background_response_test.dart`.
- Left: snoozing one occurrence now does nothing for recurring tasks (the button is still shown). A real one-off snooze needs a field on `ReminderRule` (for example `snoozedUntil`). The Today checkbox and the detail screen's Complete still call `TaskActions.setDone`, which completes the series (W3-A: use `completeOccurrence` when `reminderRepository.getForTask(id) != null`).

### H2. Apple Calendar: only the first occurrence of a recurring event is mirrored. Fixed
- `lib/features/calendar/apple/apple_calendar_provider.dart` (`toCalendarEvent`), `lib/features/calendar/sync/calendar_sync_engine.dart:206` (`seen.add(e.externalId)`).
- EventKit returns each occurrence of a weekly meeting with the same `eventIdentifier`. The provider made the local `id` unique but kept `externalId` equal, and the engine keys and de-duplicates on `(source, externalId)`. Input: weekly standup, two occurrences in the window → one mirrored, the other silently dropped, so the planner schedules tasks over the meeting.
- Fix: recurring occurrences get `externalId = '<eventIdentifier>@<startMs>'` (same as the local id suffix). Write-backs are never recurring, so update / delete by `externalId` is unaffected. Test: provider + engine round trip; the old test expectation for `externalId` was updated.

### H3. Write-backs into an unselected calendar are treated as "deleted in the calendar", and re-created every sync. Fixed
- `calendar_sync_engine.dart` `pull` (removal loop) with `writeCalendarId` (primary when writable, regardless of selection).
- User reads only the "Work" calendar. A scheduled task is written to the primary calendar. The next pull does not fetch the primary calendar, sees the mirrored write-back as vanished, unschedules the task and clears `calendarEventId`; `pushPending` then creates a second Google event. Result: a new duplicate in Google every 15 minutes, and the task keeps losing its slot.
- Fix: write-backs (events with a `taskId`) in a calendar that was not asked for are kept. Test with a provider that honours `calendarIds`.

### H4. "Delete all data" leaves Google connected and the calendar mirror on the device. W3-A (`lib/app/backup_actions_adapter.dart`)
- `BackupService.deleteAllData` wipes Drift only. `GoogleCalendarProvider` keeps the `connected` flag and, per calendar, the sync token and every mirrored event (title, time) in `localStorage` (web) or the Keychain (iOS). The next sync re-fills the events, and the confirm dialog promises "removes all tasks, plans and settings from this device".
- Fix (proposed): in `DriftBackupActions.deleteAllData`, also `googleCalendarProvider.disconnect()` (clears the prefix and revokes) and `appleCalendarProvider.disconnect()`, then `NotificationService.replaceAll([])`. Same for Import: after a restore the stored sync tokens describe a database that no longer exists.

## Medium

### M1. A failed `replaceAll` was remembered as success. Fixed
- `notification_sync.dart` `_replan`: `_lastSignature` was set before `replaceAll`. If the OS refused one request, `cancelAllPending` had already run, the pending set stayed empty or partial, and every later identical plan was skipped. Now the signature is stored after success. Test with a service that throws once.

### M2. Daily prompts are English for Hebrew users. Fixed (prompts), proposed (action buttons)
- `PromptSettings` defaults are English and `withPreferences` kept them. Now `localeCode == he` selects Hebrew copy (`hebrewMorningTitle` and friends). Test added.
- The iOS action buttons ("Done", "Snooze 15", "Start focus", "Tonight", "Tomorrow", "Pick a time") are hard-coded English in `flutter_local_notifications_backend.dart:104-130`. Categories are registered once at `initialize`, so they need the locale at startup. W3-C.

### M3. Quiet hours cannot cross midnight, and the default pushes reminders to 00:00. Proposed
- `TimeRange` asserts `end > start` and `end <= 24:00`; the settings switch creates 22:00-24:00. `_outOfQuietHours` moves a 22:30 reminder to `TZDateTime(..., 24, 0)`, which is midnight, not morning. The doc comment ("may cross midnight by using two") has no implementation: `Preferences.quietHours` is a single range.
- Proposal: a `QuietHours` value type with wrap-around (`start > end`), default 22:00-07:00, and `_outOfQuietHours` returning the next `end`. Touches `Preferences`, the mapper, the settings row and the scheduler; too wide for this PR.

### M4. "Nothing leaves it" is not quite true on the web build; no CSP. Proposed
- `web/index.html:37` loads `accounts.google.com/gsi/client` for every visitor, and `google_sign_in_web` loads it again from its constructor (`loadWebSdk`), so removing the tag does not stop the request. A third-party script runs in the app's origin with access to `localStorage` and the DOM. There is no Content-Security-Policy and no SRI (GIS cannot be pinned).
- Proposal: (a) keep the privacy sentence honest: "Your plans stay on this device" and say that connecting Google talks to Google; (b) add a CSP meta (`script-src 'self' 'wasm-unsafe-eval' https://accounts.google.com`, `connect-src 'self' https://*.googleapis.com https://accounts.google.com`, `frame-src https://accounts.google.com`, `style-src 'self' 'unsafe-inline'`) and test it with the Pages build before shipping; (c) if web ships without Google, drop `google_sign_in` on web (integrator, `pubspec.yaml`).

### M5. Calendar titles and sync tokens in `localStorage` / Keychain. Proposed
- `google_calendar_provider.dart:36` `GoogleSyncState.encode` writes full event titles. OAuth tokens are not stored by Grind (good), but event titles are readable by any script on the origin, are not covered by backup or delete-all, and double the data held. Proposal: store only the token plus event ids and re-read titles from Drift, or keep the mirror in memory and do a full sync after a cold start.

### M6. Sync problems are invisible, and nothing syncs right after Connect. W3-A / settings
- `syncStatusProvider` is read nowhere. On web the access token lives only for the session, so after every reload `isConnected()` is true (flag) but `gateway()` is null: each sync ends in `CalendarAuthException` and the Plan tab is silently empty. Connecting in Settings does not trigger `SyncScheduler.runNow()`: events appear at the next 15 minute tick. `appleCalendarChangesProvider` is never listened to (EventKit changes do not trigger a pull).
- Proposal: a one-line status under the calendar row (`SyncStatus.error.userMessage` is already calm copy), call `ref.read(calendarSyncSchedulerProvider).runNow()` after `connect()` and after calendar selection changes, and listen to `appleCalendarChangesProvider` in `startCalendarSync`.

### M7. A Lock Screen action can be lost between isolates. Proposed
- `flutter_local_notifications_backend.dart:48`: if the main isolate's port exists, the handler sends and returns. If iOS suspends and then kills the app before the main isolate runs the message, the Done / Snooze tap is gone (no journal, no ack).
- Proposal: always append to the journal first, send over the port, and have the main isolate delete the entry when handled (idempotent by `(notificationId, action)`), or apply directly with Drift when no ack arrives within a short timeout.

### M8. Day boundaries use the device zone, notifications use `Preferences.timeZoneName`. W3-A
- `task_providers.dart` `todayTasksProvider` (`toLocal`), `plan_providers.dart` (`dateOnly`, `DateTime(y, m, d)`), `today_providers.dart` `formatClock`. With the device in another zone than the preference (travel, CI in UTC), the Today list says one day while reminders are scheduled for another. The scheduler and recurrence code do it right (`locationFor`). Proposal: one `tz.Location` provider from preferences, used for "start of day" everywhere; tests under `TZ=America/New_York` and `Asia/Jerusalem`.

### M9. Recurring tasks appear on Today only on the anchor day. W3-A
- `todayTasksProvider` tests `remindAt` / `dueAt`; for a series `remindAt` is the next occurrence only after H1's completion advance, and past days are never expanded. A weekly task never shows on its other days. Use `expandOccurrences` for the day.

### M10. Backup import edge cases. Proposed
- Release builds skip `assert`s, so `TimeRange.fromJson` accepts `end <= start` or values above 1440; a hand-edited backup can poison working hours. Validate in `preferencesFromJson` (`_guard` only catches exceptions).
- A focus session whose `taskId` is missing from the file fails the foreign key and the whole import is refused ("inconsistent"); acceptable, but the message is developer text. `BackupFormatException.message` strings are not shown today (the UI uses `actionFailed`); keep it that way.
- `SharePlus.share` on iPad needs `sharePositionOrigin` or it throws; `Info.plist` lists iPad orientations, so decide: drop iPad from `TARGETED_DEVICE_FAMILY` or pass an origin.
- The backup also contains mirrored calendar events (other people's meeting titles). Say so in the Export row or leave events out.

### M11. Mock tabs show invented data. Integrator
- Focus, Pip and Ask still render the design mocks: "Wednesday was a rest day", "Hard mode on · 3 apps shielded", "Cloud assistant", fake momentum and unlocks. "Cloud assistant" contradicts the privacy copy. Hide the tabs or label them "preview" for the MVP gate.

## Low

- L1. Copy: "again" appears in `snoozeHint` ("Snooze again and Pip will offer to move it instead."), `calFailed`, `connectFailed`, the generic error and `genericError`. The reminder pool bans the word; the rest of the app does not follow the same rule (see the copy table). Open.
- L2. `RemindersStrings` and `app_*.arb` both define Done, Snooze, Undo, `snoozeHint`; the Hebrew wording differs ("עוד 15 דק׳" vs "דחייה ב־15"). W3-C should keep one source.
- L3. `deploy-web.yml` gave `pages: write` and `id-token: write` to the build job that runs third-party actions and tests, and interpolated a repository variable into a shell line. Fixed: permissions moved to the deploy job, variable passed through `env`.
- L4. Actions are pinned by tag (`@v4`, `@v2`), not commit SHA. Dependabot is configured; pinning is optional.
- L5. `web/index.html` still has the template `description` ("A new Flutter project."). Integrator (the file is in this review's reach but the text is product copy).
- L6. `Info.plist` declares `UIBackgroundModes: fetch` and nothing implements it; App Review may ask. Remove until background sync exists.
- L7. `notification_sync_test.dart` "debounces a burst" uses a 60 ms debounce and failed once on a cold start; widen the margin.
- L8. `LocalNotificationService.responses` copies the backlog, then yields; a response arriving while the consumer is suspended between items goes to a backlog nobody drains. Narrow window; attach to `_live` first.
- L9. `completeOccurrence` restarts `COUNT` from the new anchor (documented). A series "5 times" never ends. Store completions on the rule when the field is added (H1).
- L10. Deleting a task leaves its `ReminderRule` live. Harmless today (the task list gates it) but `getAll` grows; delete rules with the task, or on undo restore both.
- L11. Swift: `store.events(matching:)` runs on the main thread. A 38 day window is fast; move to a background queue if a user has thousands of events. No force unwraps, arguments are validated, empty calendar lists are handled, the store observer is removed in `deinit`.
- L12. `unawaited(sync.refresh())` in `app.dart` can surface an unhandled async error; add `.catchError` that reports.

## What is solid

- Persistence: UTC milliseconds everywhere; every repository query filters `deletedAt`; `getById` too; import and delete-all are single transactions with rollback; schema migration step exists.
- Soft delete does not leak into sync or notifications (`pushPending` reads `getAll`, the scheduler skips `deletedAt`).
- Time zones: `NotificationScheduler`, `RescheduleTimes` and the recurrence expander compute in the user's IANA zone, with wall-clock math for DST ("07:00 stays 07:00"), spring-forward gaps handled, and tests for Asia/Jerusalem.
- Notification service: serial queue, atomic file writes, journal fallback, 60 of 64 slots, deterministic platform ids with probing. The background isolate only opens Drift when no foreground isolate answers, so there is no concurrent writer in practice.
- Sync engine: "calendar wins for time, app wins for fields" is implemented and tested (moves taken only when the event changed there since the last mirror; titles overwritten from the task).
- Secrets: no OAuth token is persisted by Grind; the Google client id is a build-time define; nothing is logged beyond a debug print.
- Swift plugin: no force unwraps, typed argument checks, `invalidArgs` / `notFound` / `eventKit` error codes, permission via the iOS 17 APIs with a fallback, main-thread completion for the permission result.
- CI: `permissions: contents: read`, `pull_request` (not `pull_request_target`).
- Reminder copy: the pool is banned-word tested for EN and HE, rotates deterministically, never mentions snooze counts.

## Copy audit

Voice rule: no guilt, no "should / failed / missed / again / behind / overdue", invitations rather than commands, Pip in first person.

| String | Where | Verdict | Action |
|---|---|---|---|
| "Snooze again and Pip will offer to move it instead." | `reminders_strings.dart:55`, `app_en.arb` `snoozeAgainHint` | "again" reads as a nudge about snoozing | Suggest "Need more time? Pip can move it for you." |
| "That did not work this time. You can try again, or skip it for now." | `onboarding_strings.dart` `calFailed` | OK tone, "again" | Suggest "That did not connect this time. Try once more whenever you like." |
| "That did not work this time. You can try again whenever you like." | `settings_strings.dart` `connectFailed` | same | same |
| "Something went sideways. Pip is on it, try again in a moment." | `lib/app/errors.dart` | a command, claims Pip is acting | W3-A: "That did not go through. Your plan is safe." |
| "Pip couldn't save that. Your plan is safe, try once more." | `errors.dart` | fine | none |
| "Pip couldn't reach your calendar just now. It will try again soon." | `calendar_sync_strings.dart` | fine (promise is true) | none |
| "Pip needs a fresh hello from your calendar. Reconnect it in Settings." | same | warm, clear | none |
| "Give it a short name and you are set." | `tasks_strings.dart` | fine | none |
| "Nothing due today" / "Add one small thing and Pip will remind you." | tasks | fine | none |
| "Delete everything? ... It cannot be undone." | settings | factual, acceptable | none |
| "Off. Grind keeps working; turn them on if you want reminders." | settings | fine | none |
| "Grind keeps your plans on this phone. Nothing leaves it." | onboarding welcome | untrue once Google is connected, and on web | "Your plans stay on this phone. Calendars you connect are read, not copied away." |
| "Everything stays on this device. No account, no sign-in." | settings Privacy | "no sign-in" is wrong once Google sign-in exists | same rewrite |
| "Events are read on this device and stay here." | onboarding | true for Apple; for Google they are fetched from Google | "Events are read to plan around them." |
| Prompt copy "Good morning / Want to plan the day together?", "Evening check-in / One minute to look back on today?" | `PromptSettings` | good invitations | Hebrew added in this PR |
| Reminder pool EN (20 lines) | `reminder_copy.dart` | all passes the banned list; "Future you will be glad." is the closest to pressure | keep or swap for "Future you says thanks." |
| Reminder pool HE (20 lines) | same | reads natively, gender-neutral forms | none |
| Move offer "Want to move this instead?" / "\"X\" can have a calmer moment." | same | good | none |
| "Weekly chart: Wednesday was a rest day." | `app_en.arb` `weeklyChartSemantics` | mock data | integrator, M11 |
| HE: "כשתרצו" / "הקישו" (plural) next to "שלך" (singular) | `app_he.arb` | mixed address | W3-C: choose one (singular neutral) |
| HE action labels on the iOS category | native | missing | M2 |
| Onboarding, settings, tasks, plan, sync strings | `*_strings.dart` | English only; a Hebrew UI mixes languages | W3-C |

## Findings inside the W3-A paths (not touched)

1. H1 (Today path): `TaskActions.setDone` completes a recurring series.
2. H4: `lib/app/backup_actions_adapter.dart` does not disconnect calendar providers or clear sync state on delete-all / import.
3. M6: no sync status display, no `runNow()` after connect, `appleCalendarChangesProvider` unused (`lib/app/app.dart` `startCalendarSync` is the place).
4. M8: device zone instead of `Preferences.timeZoneName` for day boundaries (`task_providers.dart`, `plan_providers.dart`, `today_providers.dart`).
5. M9: recurring tasks only show on the anchor day.
6. `TaskActions.deleteWithUndo` leaves the `ReminderRule` (L10) and its undo restores only the task row.
7. `errors.dart` copy (table above).
8. `todayLabelProvider` formats `clock.now()` without `toLocal()`; correct today only because `SystemClock` returns local time.
9. `lib/app/demo_seed.dart` / `core/data/seed.dart` seed only in debug (`kDebugMode`); fine for release, but delete-all in debug re-seeds on the next launch, which looks like a failed delete when testing.

## Verification

`dart format lib test` (no changes), `flutter analyze` (no issues), `flutter test` (361 passed), `flutter build web --release --no-web-resources-cdn` (built). Not verifiable here: Swift (no Mac), iOS background isolate behaviour (M7), Google sign-in on a real client id, CSP against the Pages build.
