# Manual checks for Noa

Everything in this list needs a Mac, an iPhone, a Google account or the repo
settings, so nothing here could be run by the agents. Work through it in
order: part A unblocks parts B to E.

Full detail for each block lives in the linked ADR; this page is the index
and the order.

## A. One-time setup (about an hour)

1. **Mac tools**: Xcode (current stable), Flutter 3.35.5, CocoaPods.
   `flutter doctor` must be clean for iOS.
2. **Clone and build once**:
   ```sh
   git clone https://github.com/NoaMcDa/Grind && cd Grind
   flutter pub get
   cd ios && pod install && cd ..
   open ios/Runner.xcworkspace
   ```
   Runner target > Signing & Capabilities: tick automatic signing, pick
   your team. Build to a real iPhone (iOS 17+). The first goal is simply
   "it compiles and launches": the Swift plugins were never compiled.
3. **Bundle id decision**: the project uses `com.noa.grind.grind`; the plan
   said `com.noa.grind`. Decide now; it cannot change after the App Store
   Connect record exists (`docs/release/README.md`, step 3).
4. **Live Activity extension** (Xcode only, no code): follow the ten steps
   in `docs/adr/0007-live-activity.md` ("Xcode steps for Noa"). Without
   them the app still builds; the Lock Screen countdown just never shows.
5. **Google OAuth client ids** (`docs/adr/0005-google-calendar.md`,
   "OAuth setup"): Cloud project, enable Calendar API, consent screen in
   Testing with your account as a test user, one Web client id (origins
   `http://localhost:5000` and `https://noamcda.github.io`), one iOS client
   id. Then add the reversed iOS client id as a URL scheme in
   `ios/Runner/Info.plist` (snippet in the ADR) and run with
   `--dart-define=GOOGLE_CLIENT_ID_IOS=…` / `GOOGLE_CLIENT_ID_WEB=…`.
6. **Repo settings**: Settings > Pages > Source = "GitHub Actions"; add the
   repository variable `GOOGLE_CLIENT_ID_WEB`; protect `main` (require the
   CI check). After the next push the web app is at
   `https://noamcda.github.io/Grind/`.

## B. iOS smoke run (30 minutes, fresh install)

Do this before the detailed plans; if any step fails, stop and send me the
Xcode console output.

1. Fresh install, launch: no system prompts appear before onboarding asks.
2. Onboarding: notification rationale, then the iOS prompt once; calendar
   connect (Apple), working hours; land on Today.
3. Add a task with a reminder 2 minutes out; lock the phone; the reminder
   arrives with Done / Snooze 15 / Start focus.
4. Tap Done on the Lock Screen without opening the app, then open it: the
   task is done.
5. Plan tab shows today's Apple Calendar events; "Re-plan with Pip" places
   the task; Focus tab runs a session (Lock Screen shows the Live Activity
   if step A4 was done).
6. Settings: export a backup, delete all data, import the backup.
7. Switch the language to Hebrew: every screen is RTL and translated.

## C. Detailed device plans (one evening)

| Plan | Where | Covers |
|---|---|---|
| Notifications | `docs/adr/0003-notifications.md`, "iOS manual test plan", steps 1 to 11 | permission, the 64-slot cap, Done/Snooze/Tonight/Tomorrow from a killed app, smart snooze on the third reminder, quiet hours, DST, foreground banner |
| Apple Calendar | `docs/adr/0006-apple-calendar.md`, "Manual test plan", blocks A to F (G and H optional) | full access, events in Plan, write-back of a scheduled task, moves and deletes made in Calendar.app, live changes, denied access, write-only mode |
| Live Activity | `docs/adr/0007-live-activity.md`, "Manual test plan", steps 1 to 13 | Lock Screen and Dynamic Island, pause/resume/+5, tap opens Focus, run-out, restart, old iOS, VoiceOver |
| Google Calendar | `docs/adr/0005-google-calendar.md`, "Test plan", steps 1 to 6 | connect, pull, write-back, move and delete in Google, reconnect on web after a reload |

Two things the plans do not list yet, added in wave 6:

- Recurring reminders: tap Done on a repeating reminder from the Lock
  Screen; the series advances (the next occurrence is pending, Today shows
  the done row). Same from the evening review.
- Weekly recap: on the last day of your week, an hour before the evening
  prompt, one notification leads with the biggest win; tapping it opens
  Highlights. A quiet week sends nothing.

## D. Web checks (15 minutes, after A6)

1. Open `https://noamcda.github.io/Grind/` in Safari on the iPhone and in
   Chrome on the Mac: onboarding, add a task, reload: it persists.
2. "Add to Home Screen" on iOS: the Pip icon, opens full screen.
3. Google Calendar connect on web (needs the web client id): the token lasts
   one browser session; after a reload the reconnect message shows.
4. Notifications on web fire only while the tab is open (by design).

## E. A week of daily use

The MVP gate ends with a week of real use. Watch for: reminders that never
arrive, Plan placements that feel wrong, copy that reads as guilt, anything
in Hebrew that reads oddly. Note each one in a GitHub issue with the
`phase 1` label, or just paste them to me.

## Decisions still open (not blocking the checks)

- #31 Apple Health as a metric input (HealthKit entitlement; needs a yes/no).
- #38 the assistant: where an API key lives without a backend (your own key
  typed into Settings, or no assistant for now).
- App Store listing text: paste the long description into
  `docs/release/app-store-listing.md`.
