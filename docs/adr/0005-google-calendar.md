# ADR 0005: Google Calendar sync (client-side OAuth, two-way)

- Status: accepted
- Issue: #13
- Code: `lib/features/calendar/google/` (provider), `lib/features/calendar/sync/`
  (provider-agnostic engine and scheduler); tests under
  `test/features/calendar/{google,sync}/`

## Context

Grind has no backend. Meetings from Google Calendar must show next to tasks on
iOS and web, and tasks placed on the timeline should appear in Google. Tokens
must never leave the device.

## Decision

### 1. OAuth on the device with `google_sign_in` 7.x

- `GoogleSignIn.instance.initialize(clientId: <platform id>, serverClientId: null)`
  once, then on **Connect**:
  - iOS: `authenticate()` then `account.authorizationClient.authorizeScopes(scopes)`.
  - Web: `GoogleSignIn.instance.authorizationClient.authorizeScopes(scopes)`
    (Google Identity Services token client, popup; `authenticate()` is not
    supported on web).
- Later calls use `authorizationForScopes(scopes)` without UI. If that returns
  null, sync shows "Pip needs a fresh hello from your calendar. Reconnect it in
  Settings." and the user taps Connect again.
- `extension_google_sign_in_as_googleapis_auth` turns the authorization into an
  authenticated HTTP client for `googleapis`' `CalendarApi` (v3).
- Scopes: `https://www.googleapis.com/auth/calendar.events` (read and write
  events) and `https://www.googleapis.com/auth/calendar.readonly` (calendar
  list).
- Client ids are not secrets for installed and browser apps; they come from
  `--dart-define=GOOGLE_CLIENT_ID_IOS=...` and `--dart-define=GOOGLE_CLIENT_ID_WEB=...`.
  While the placeholder (`REPLACE_ME_...`) is in place, `connect()` returns
  false and `GoogleCalendarProvider.lastError` points to this file.

### 2. What is stored where

| Data | iOS | Web |
|---|---|---|
| OAuth refresh token | Keychain, by the Google Sign-In SDK | none (GIS issues no refresh token to browser apps) |
| Access token | memory + SDK cache | memory, browser session only |
| "connected" flag, sync token and mirrored window per calendar (`grind.google.*`) | Keychain via `flutter_secure_storage` | `window.localStorage` |
| Mirrored events, write-back links | local database (`CalendarRepository`, `Task.calendarEventId`) | same (IndexedDB/OPFS) |

The `KeyValueStore` interface (`key_value_store.dart`) hides the platform
store; tests use `InMemoryKeyValueStore`. Disconnect revokes the grant
(`disconnect()`), deletes every `grind.google.*` key, and the next sync clears
Google events from the local mirror.

"Delete all data" and backup import call the same disconnect for every
calendar provider through `DataResetService` (`lib/features/settings`), clear
the mirrored events and the stored calendar choice, and reset the sync
engines' in-memory state, so the next sync starts clean
(review 2026-11-03, H4). Connecting triggers an immediate pull
(`SyncScheduler.runNow`), and Settings shows the sync status. The web build
ships a Content-Security-Policy meta tag (`web/index.html`); see
`docs/privacy.md` for the user-facing description.

### 3. Sync

- Window: the past 7 days to the next 30 days (whole UTC days).
- Calendars read: `Preferences.selectedCalendarIds[CalendarSource.google]`; when
  the user never chose, the primary calendar. An empty list reads nothing.
- Incremental: the first fetch per calendar is a full `events.list` with
  `timeMin`/`timeMax` (window + 7 days slack) and `singleEvents=true`; Google
  returns a `nextSyncToken`, stored with the window and the mirrored events.
  Later fetches send only the `syncToken` and apply changes (`status:
  cancelled` removes). **HTTP 410** (token expired) or a window that moved past
  the stored one triggers a full resync. Changes are applied only after every
  page arrived, so a failure leaves the last consistent state.
- Mapping: timed events become UTC instants. All-day events cover local
  midnight to local midnight of Google's dates (end exclusive), stored in UTC,
  `isAllDay = true`. `transparency: transparent` and invites the user declined
  become `isBusy = false` (shown, not blocking). Untitled events read
  "(No title)".
- The engine (`CalendarSyncEngine`) upserts by `(source, externalId)`, keeps the
  local id, skips unchanged rows, and soft-deletes events that vanished from the
  window.

### 4. Write-back and conflict policy

- A scheduled, open task inside the window becomes an event in the primary
  calendar (or, if that is read-only, the first writable selected one) with
  `extendedProperties.private.grindTaskId = <task id>`, a "Planned with Grind."
  line in the description, and Google's default reminders off (Grind reminds).
  The Google event id goes into `Task.calendarEventId`; the mirrored
  `CalendarEvent.taskId` points back. The scheduler (#16) ignores events with a
  `taskId` when finding free time, so a task does not block itself.
- Moving or renaming the task in Grind patches the event; unscheduling,
  skipping or deleting the task deletes it. A done task keeps its event.
- **The calendar wins for time, the app wins for task fields.** If the event
  was moved in Google since the last sync, the task takes the new start/end and
  is pinned (`lockedStart = true`, a person placed it). If it was deleted in
  Google, the task is unscheduled (it stays open). Title and notes always come
  from Grind and are pushed back on the next run. A move is only taken from the
  calendar when the event changed there, so an edit made in Grind is never
  undone by a stale copy.
- If an event Grind wants to update is gone (404/410), a new one is created.
- Only Google writes back (`Task.calendarEventId` is one field). Apple Calendar
  (#14) runs through the same engine with `writeBack: false`.

### 5. When it runs

`SyncScheduler`: on start, on return to the foreground
(`WidgetsBindingObserver`), every 15 minutes while open, and 2 s after task
edits (push only). Runs never overlap. Status (`idle` / `syncing` / `error`
with a friendly message) is exposed as `syncStatusProvider`.

## Limits

- **No sync while the app is closed** (no server). iOS background fetch could
  be added later; web cannot.
- Web: the access token lasts for the browser session (about an hour). After a
  reload or expiry the user taps Connect again; until then sync shows the
  reconnect message and keeps the last mirror.
- An event moved in Google to a time outside the window reads as deleted: the
  task is unscheduled.
- Recurring events are expanded into instances (`singleEvents=true`); Grind
  never writes recurring events.
- While the OAuth consent screen is in *Testing*, only listed test users can
  sign in and Google expires their grants after 7 days.

## OAuth setup

Steps for Noa (once). Nothing here goes into the repo except the client ids,
which are passed at build time.

1. **Project.** <https://console.cloud.google.com/> → project picker → *New
   project* "Grind".
2. **API.** *APIs & Services → Library* → "Google Calendar API" → *Enable*.
3. **Consent screen.** *APIs & Services → OAuth consent screen* (Google Auth
   Platform → Branding / Audience / Data access):
   - User type *External*, app name "Grind", support email, developer email.
   - Data access → *Add or remove scopes*: `.../auth/calendar.events` and
     `.../auth/calendar.readonly`.
   - Audience: keep **Testing**; add your Google account (and testers) under
     *Test users*. Publishing later needs Google's verification for these
     sensitive scopes.
4. **Web client id.** *Credentials → Create credentials → OAuth client ID →
   Web application*, name "Grind web".
   - *Authorized JavaScript origins*:
     - `http://localhost:5000` (and any other port you use with
       `flutter run -d chrome --web-port 5000`; GIS needs a fixed port)
     - `http://localhost:8080`
     - `https://noamcda.github.io` (GitHub Pages; the origin has no path, the
       app is served under `/Grind/`)
   - *Authorized redirect URIs*: none needed (GIS token popup).
   - Copy the id → `--dart-define=GOOGLE_CLIENT_ID_WEB=<id>`.
5. **iOS client id.** *Create credentials → OAuth client ID → iOS*, bundle id
   from `ios/Runner.xcodeproj` (`PRODUCT_BUNDLE_IDENTIFIER`). Copy the client id
   and the *iOS URL scheme* (the reversed client id,
   `com.googleusercontent.apps.<number>-<hash>`).
   - Build with `--dart-define=GOOGLE_CLIENT_ID_IOS=<id>`.
   - Add the reversed client id as a URL scheme in `ios/Runner/Info.plist`
     (integrator, once the id exists) so the sign-in redirect returns to the
     app:

     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleTypeRole</key>
         <string>Editor</string>
         <key>CFBundleURLSchemes</key>
         <array>
           <string>com.googleusercontent.apps.REPLACE_WITH_REVERSED_IOS_CLIENT_ID</string>
         </array>
       </dict>
     </array>
     ```

     (If `CFBundleURLTypes` already exists, add the `<dict>` to it.) Optionally
     also `GIDClientID` = the iOS client id; the Dart `clientId` already covers
     it.
6. **Run.**

   ```sh
   flutter run -d chrome --web-port 5000 \
     --dart-define=GOOGLE_CLIENT_ID_WEB=<web id>
   flutter run -d <iphone> \
     --dart-define=GOOGLE_CLIENT_ID_IOS=<ios id>
   ```

   For the Pages deploy, store the web id as a repository variable
   `GOOGLE_CLIENT_ID_WEB` and pass it in `.github/workflows/deploy-web.yml`.

## Test plan (needs real accounts; not run in CI)

1. Settings → Google Calendar → Connect → consent → the calendar list appears.
2. Create an event in Google → it shows on Plan within one sync (foreground the
   app or wait 15 min).
3. Schedule a task in Grind → an event "Planned with Grind." appears in Google.
4. Drag that event in Google → after the next sync the task has the new time.
5. Delete it in Google → the task is unscheduled.
6. Web: reload the page → the reconnect message → Connect → sync resumes.
