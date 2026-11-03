# ADR 0004: Apple Calendar (EventKit, iOS)

- Status: accepted
- Issue: #14
- Code: `ios/Runner/AppleCalendarPlugin.swift`, `lib/features/calendar/apple/`,
  tests in `test/features/calendar/apple/`

> Numbering: `0004-design-system-a11y.md` also uses 0004. The integrator may
> renumber this file; nothing links to it by number except code comments.

## Context

Users who live in Apple Calendar need the same behaviour as Google users on
the phone: their events block time in the plan, and scheduled tasks can be
written back. Apple Calendar has no web API we can reach without a server
(iCloud CalDAV needs an app-specific password), so on-device EventKit is the
only practical route.

iOS 17 split calendar permission in two: **full access**
(`requestFullAccessToEvents`, read + write) and **write-only access**
(`requestWriteOnlyAccessToEvents`, add events, read nothing). Calling the old
`requestAccess(to:)` on iOS 17 without the new Info.plist keys crashes.

## Decision

**An in-house Swift plugin over EventKit**, about 300 lines, on a
`MethodChannel` named `grind/apple_calendar` plus an `EventChannel`
`grind/apple_calendar/changes`. Not `device_calendar`:

- We need eight calls. A dependency for eight calls costs more in upgrades
  and review than it saves.
- `device_calendar` has lagged on the iOS 17 permission split (it requests
  full access only, no write-only path) and exposes attendees, reminders and
  recurrence editing we do not want.
- Owning the Swift side lets us store the write-back marker where we choose
  and filter events the way the scheduler needs (busy vs free).

The plugin lives in the Runner target (registered in `AppDelegate.swift`
with `registrar(forPlugin: "AppleCalendarPlugin")`), not in a separate pub
package. It is registered for the main isolate only; background notification
isolates never touch the calendar.

### Channel surface

| Method | Arguments | Returns |
|---|---|---|
| `authorizationStatus` | - | `notDetermined` / `restricted` / `denied` / `fullAccess` / `writeOnly` |
| `requestFullAccess` | - | status after the prompt |
| `requestWriteOnlyAccess` | - | status after the prompt (full access prompt before iOS 17) |
| `listCalendars` | - | `[{id, title, allowsContentModifications, isPrimary}]` |
| `fetchEvents` | `calendarIds, fromMs, toMs` | `[{eventIdentifier, calendarIdentifier, title, startMs, endMs, isAllDay, isBusy, isRecurring, notes?, url?, createdMs?, updatedMs?}]` |
| `createEvent` | `calendarId?, title, startMs, endMs, notes?, taskId?` | `eventIdentifier` |
| `updateEvent` | `eventId, title, startMs, endMs, notes?, taskId?` | - |
| `deleteEvent` | `eventId` | - |

Errors are `FlutterError` codes `notFound`, `invalidArgs`, `eventKit`; Dart
maps them to `AppleCalendarException`. The event channel sends
`onStoreChanged` on every `EKEventStoreChanged` notification (any app edited
the calendar database). `swift_contract_test.dart` checks that the Swift file
handles every method name, map key and status the Dart side uses, so the two
sides cannot drift silently while nobody can compile Swift in CI.

The authorization status is read by raw value (0-4) so the file compiles for
the iOS 13 deployment target without `#available` around enum cases; the
request calls use `#available(iOS 17.0, *)` with `requestAccess(to: .event)`
as the fallback.

### Permission model

- `connect()` asks for **full access**: reading is what makes the plan
  correct. It never prompts when the status is `denied` or `restricted`
  (iOS would not show the prompt anyway); the UI should then point to
  Settings > Grind > Calendars.
- `connectWriteOnly()` asks for **write-only** access, for users who want
  their tasks in Calendar.app but not their events in Grind. Write-only
  cannot list calendars, read events, or look up an event by id, so it
  creates events in the default calendar and cannot update or delete them
  (`updateEvent` reports `notFound`).
- `isConnected()` = permission granted (full or write-only) and not
  disconnected this session. It does not read `Preferences`; which calendars
  are synced is the sync engine's choice (`Preferences.selectedCalendarIds`).
- `disconnect()` cannot revoke an iOS permission. It stops this provider for
  the session; `connect()` clears it.
- Denying access leaves every Apple call a graceful no (empty lists, false),
  so the app runs on Google or no calendar.

Usage strings (Info.plist), in Pip's voice and honest about what happens:
`NSCalendarsFullAccessUsageDescription`,
`NSCalendarsWriteOnlyAccessUsageDescription`, and the pre-iOS 17
`NSCalendarsUsageDescription`.

### Data mapping (`AppleCalendarProvider.toCalendarEvent`)

| EventKit | `CalendarEvent` |
|---|---|
| `eventIdentifier` | `externalId`; `id` = `apple:<eventIdentifier>` |
| recurring occurrence (`hasRecurrenceRules`) | `id` = `apple:<eventIdentifier>@<startMs>` (occurrences share the identifier) |
| `calendar.calendarIdentifier` | `calendarId` |
| `startDate` / `endDate` | `start` / `end`, UTC `DateTime` from epoch ms |
| `isAllDay` | `isAllDay` (the instants are local midnights, kept as-is) |
| `availability != .free` | `isBusy` (`notSupported` counts as busy) |
| URL / notes marker | `taskId` |
| `creationDate` / `lastModifiedDate` | `createdAt` / `updatedAt` (clock fallback) |
| - | `source = CalendarSource.apple` |

`fetchEvents` with no calendar ids returns nothing (EventKit would read all
calendars for an empty list). Events without an `eventIdentifier` are skipped.

### Write-back marker

A written-back task is marked twice:
- URL field: `grind://task/<taskId>` (set by Swift from `taskId`).
- Notes: the task's notes, a blank line, then `grindTaskId:<taskId>` (built in
  `WriteBackMarker.notesFor`).

On read, `WriteBackMarker.parse` prefers the URL (users rarely edit it) and
falls back to the last `grindTaskId:` in the notes. The sync engine (#13)
compares each fetched event that carries a `taskId` with the task: a new
start/end means the user moved it in Calendar.app; a task with
`calendarEventId` whose event no longer comes back means it was deleted.
Write-backs are timed events (`isAllDay = false`), saved with
`span: .thisEvent`, `commit: true`.

### Change detection

`AppleCalendarProvider.changes` (and `appleCalendarChangesProvider`) emit on
each `EKEventStoreChanged`. The sync engine re-pulls on that, on launch and on
return to foreground. EventKit posts the notification for our own writes too,
so the engine should debounce.

## Limitation: Apple events live on the phone

Grind has no backend (MVP). Apple events are read on the iPhone and never
leave it, so the **web app does not show Apple events**. The issue's
"mirror Apple events to the backend" item waits for #4 (backend). A user who
also adds their iCloud calendar to Google Calendar will see those events on
web through the Google provider.

## Consequences

- Swift code is not compiled in CI (no macOS runner). The contract test and
  the manual plan below are the safety net until a macOS CI job exists.
- `CalendarProvider` has no change stream; the sync engine reads
  `AppleCalendarProvider.changes` through `appleCalendarChangesProvider`. A
  generic `Stream<void> get changes` on the interface would remove that
  special case (proposal for the integrator).

## Manual test plan (Mac + iPhone, iOS 17 or later)

Setup
1. `flutter pub get`, then `cd ios && pod install`, open
   `ios/Runner.xcworkspace` in Xcode, select a team, run on a real iPhone
   (the simulator works too, with its Calendar app).
2. Check `AppleCalendarPlugin.swift` is in the Runner target (File
   Inspector > Target Membership). The build must have no errors; warnings
   about deprecated `requestAccess(to:)` are expected.
3. Make sure `main.dart` uses `appleCalendarOverride()` and the sync engine
   listens to it (integrator wiring).
4. In Calendar.app create, for today: a timed busy event "Dentist 10:00-11:00",
   an all-day event, a timed event with Show As = Free, and a repeating daily
   event.

A. Grant access, events appear
1. Fresh install. Connect Apple Calendar in Grind.
2. Expect the iOS prompt with the full-access usage string; tap Allow Full
   Access.
3. Expect the calendar list to show your calendars, the default one marked
   primary, read-only ones (Holidays, Birthdays) not writable.
4. Select the calendar. Plan for today shows Dentist blocking 10:00-11:00,
   the all-day event in the all-day row, the free event shown but not
   blocking, and today's occurrence of the repeating event.
5. Settings > Privacy & Security > Calendars > Grind shows "Full Access".

B. Write back a task
1. Schedule a task in Grind for 14:00-15:00 with write-back on.
2. In Calendar.app the event appears in the chosen calendar at 14:00. Open
   it: URL is `grind://task/<id>`, notes end with `grindTaskId:<id>`.

C. Move it in Calendar.app
1. With Grind in the background, drag that event to 16:00.
2. Return to Grind. Within a second or two (change notification or
   foreground sync) the task shows 16:00-17:00.
3. Delete the event in Calendar.app; return to Grind. The task is no longer
   linked to a calendar event (exact UI per #13).
4. Edit the event's notes and remove the marker line: it still maps to the
   task (URL marker). Clear the URL too: it becomes an ordinary event.

D. Live changes while open
1. Keep Grind open on Plan, add an event from Siri or another device (iCloud).
   Plan updates without a relaunch.

E. Deny access, app still usable
1. Delete and reinstall. Connect Apple Calendar, tap Don't Allow.
2. Grind shows no error screen; Plan works with no Apple events; Google (if
   connected) still works; tasks and reminders unaffected.
3. Tap connect again: no prompt appears (iOS remembers); the UI should point
   to Settings.
4. In Settings, switch Grind to Full Access, return: connect succeeds.

F. Write-only
1. Reinstall; trigger `connectWriteOnly()`. Expect the write-only prompt
   ("Add Events Only") with its usage string.
2. Write back a task: it lands in the default calendar. No Apple events show
   in Plan.
3. Then `connect()`: iOS asks to upgrade to full access.

G. Restricted (optional)
1. Screen Time > Content & Privacy Restrictions > Calendars > Don't Allow
   Changes. Connect returns false without a prompt; app keeps working.

H. iOS 16 device or simulator (optional)
1. One prompt (legacy usage string) for both connect paths; A-E behave the
   same.
