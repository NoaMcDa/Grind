# ADR 0007: Live Activity and Dynamic Island for focus sessions (ActivityKit, iOS)

- Status: accepted (Swift not compiled yet: no Mac in the agent environment)
- Issue: #20
- Code: `ios/Runner/LiveActivityPlugin.swift`, `ios/GrindLiveActivity/`,
  `lib/features/focus/live_activity/`, calls in
  `lib/features/focus/focus_controller.dart`; tests in
  `test/features/focus/live_activity/`

## Context

The Focus mockup has a "Lock Screen preview": while a session runs, the
countdown and Pip should sit on the Lock Screen and in the Dynamic Island.
That is ActivityKit. A Live Activity is drawn by a **widget extension** (a
separate target with its own bundle id), started and updated by the app.
`ActivityContent` and the current `request`/`update`/`end` API need iOS
16.2; the app's deployment target is 13.0, and the web build has nothing of
the kind.

## Decision

**An in-house Swift plugin in the Runner target plus a widget extension**, in
the same shape as the EventKit bridge (ADR 0006): a `MethodChannel`
`grind/live_activity`, a Dart interface with a method-channel implementation
on iOS and a no-op everywhere else, picked by a conditional import. No pub
package (`live_activities` would need an App Group and a generic
dictionary-based layout; we need three calls and our own SwiftUI).

### Channel surface (epoch milliseconds)

| Method | Arguments | Returns |
|---|---|---|
| `start` | `taskTitle, endDateMs, accessory, pausedAtMs?, focusingLabel, pausedLabel` | `true` if shown; `false` below iOS 16.2 or with Live Activities turned off |
| `update` | `paused, endDateMs, pausedAtMs?` | - |
| `end` | - | - |

- `start` first ends every Grind activity still showing (one session at a
  time; also clears one left by a killed app), then requests a new one.
- `endDateMs` is always "when the timer reaches zero if it keeps running";
  pauses and +5 min move it. `pausedAtMs` freezes the countdown.
- Below iOS 16.2 all three answer at once (`false` / `nil`). Errors are
  `FlutterError` `invalidArgs` / `activityKit`; the Dart side logs and
  swallows them, and a missing plugin is a no-op, so the timer never fails
  because of the Lock Screen.
- `swift_contract_test.dart` checks the Swift files use every method, key,
  availability guard and the deep link the Dart side relies on.

### What the controller sends

`FocusController` queues the calls in order (`_liveChain`) so the slow first
call (task title and preferences lookups) cannot be overtaken by a quick
pause:

| Controller | Live Activity |
|---|---|
| `start` | `start` (task title or the localized "Free focus", Pip's accessory, localized "Focusing"/"Paused") |
| `pause`, `resume`, `extend` | `update` |
| `end`, timer reaching zero (`tick`), `start` over a running session | `end` |
| launch with an active session (restart) | `start`, frozen when paused |
| launch with no active session | `end` (clean up after a killed app) |

Breaks show no activity. Off iOS `liveActivityServiceProvider` is
`NoopLiveActivityService` and the controller skips the lookups entirely; no
override is needed in `main.dart`.

### The widget

- `FocusActivityAttributes`: `taskTitle`, `accessory`, the two labels
  (fixed); `ContentState`: `startDate`, `endDate`, `pausedAt?`.
- Countdown: `Text(timerInterval: start...end, pauseTime: pausedAt,
  countsDown: true)`; the system ticks it every second without the app.
  The range lower bound is the earliest of now, end and the pause time, so it
  can never be inverted (that traps).
- Lock Screen: violet background, Pip (cheering while running), status in
  sun yellow, task title in white, the countdown on a sun sticker with a
  2.5 pt ink border and a hard 3 pt ink shadow (white sticker while paused).
- Dynamic Island: compact leading Pip, compact trailing countdown in sun,
  minimal Pip; expanded: Pip, status + title, big countdown, progress bar.
- Pip is drawn with SwiftUI paths (`PipView.swift`), a port of
  `lib/widgets/pip_avatar.dart` in the same 100 x 100 box, with the scarf,
  sunglasses, party hat and crown accessories. No image asset needed.
- `staleDate` is the end date while running: if the app is not opened when
  the timer hits zero, iOS dims the activity until the app ends it on the
  next `tick` (foreground). Ending it from the background would need push
  updates, out of scope.

### Deep link

Tapping the activity opens **`grind:///focus`** (scheme `grind`, empty host,
path `/focus`). The Info.plist did not declare a URL scheme, so this change
adds `CFBundleURLTypes` with `grind` and sets `FlutterDeepLinkingEnabled`
(the default since Flutter 3.27; explicit here). Flutter hands the URL to
go_router, which matches on the path. The issue text says `grind://focus`,
but that parses as host `focus` with an empty path, which go_router
normalizes to `/` and redirects to `/today`; the triple slash needs no
router change.

## Xcode steps for Noa (one time, on the Mac)

The agent could not edit `Runner.xcodeproj` reliably by hand, so the files
exist on disk but are not in the project yet.

1. `flutter pub get`, then open `ios/Runner.xcworkspace`.
2. **Runner target, plugin file**: File > Add Files to "Runner"... >
   `ios/Runner/LiveActivityPlugin.swift`, target **Runner** only.
3. **Create the extension**: File > New > Target... > iOS > **Widget
   Extension**. Product Name `GrindLiveActivity`, tick **Include Live
   Activity**, untick Include Configuration App Intent, Embed in Application
   **Runner**. Click Activate when asked about the scheme.
4. Xcode created a `GrindLiveActivity` group with template files. Delete
   every template Swift file (Move to Trash) and the template `Info.plist`
   if it made one, but **keep its `Assets.xcassets`** (needed for
   AccentColor/WidgetBackground; unused otherwise).
5. Add the repo files to the extension: File > Add Files to "Runner"... >
   select in `ios/GrindLiveActivity/`: `GrindLiveActivityBundle.swift`,
   `FocusLiveActivity.swift`, `PipView.swift`, `GrindTheme.swift`,
   `FocusActivityAttributes.swift`, `Info.plist`,
   `GrindLiveActivity.xcconfig`. Untick "Copy items if needed". Target
   membership: **GrindLiveActivity** for the four view files.
6. **Shared attributes**: select `FocusActivityAttributes.swift`, File
   inspector > Target Membership: tick **both Runner and GrindLiveActivity**.
   (Both targets must compile the same type or the activity never shows.)
   `Info.plist` and the `.xcconfig` must have **no** target membership.
7. **Extension build settings** (target GrindLiveActivity):
   - Project > Info > Configurations: for Debug, Release and Profile set
     the GrindLiveActivity base configuration to `GrindLiveActivity.xcconfig`
     (gives the app's version numbers via Flutter's `Generated.xcconfig`).
   - Build Settings: Product Bundle Identifier
     **`com.noa.grind.grind.LiveActivity`** (the app is
     `com.noa.grind.grind`); iOS Deployment Target **16.2**; Info.plist File
     `GrindLiveActivity/Info.plist`; Generate Info.plist File **No**.
     Delete (select, Backspace) any target-level value that overrides the
     xcconfig with something else.
   - Signing & Capabilities: same team as Runner, automatic signing.
8. **Runner target**: General > Frameworks, Libraries, and Embedded Content
   (or Build Phases > Link Binary With Libraries): add `ActivityKit.framework`
   and set it to **Optional**, so the app still launches on iOS 13-16.0.
   Check Build Phases > Embed Foundation Extensions lists
   `GrindLiveActivity.appex`, and that this phase sits **above** "Thin Binary"
   / "Run Script" (Flutter builds fail with a dependency cycle otherwise:
   drag it up if needed).
9. Build and run on a device or an iPhone 15 Pro simulator (Dynamic Island)
   running iOS 17 or later.
10. In the Apple Developer portal the new bundle id is created by automatic
    signing; no App Group or push capability is needed.

Troubleshooting: Runner fails to compile with "cannot find
'FocusActivityAttributes'" when step 6 was missed. `start` failing with
`activityKit` "Target does not include NSSupportsLiveActivities" means the
key is missing from `ios/Runner/Info.plist`; an activity that is requested
but never appears usually means the extension is not embedded (step 8) or
its deployment target is above the device's iOS.

## Manual test plan

Device or simulator with iOS 17+ (Dynamic Island: iPhone 14 Pro or later
simulator). Settings > Grind > Live Activities on.

1. **Start**: Focus tab, pick a task, Start. Lock the phone: the Lock Screen
   shows Pip (cheering, wearing the accessory chosen on the Pip tab), the
   status "FOCUSING", the task title and a counting-down 25:00 on a sun
   sticker. Free session: title "Free focus" (Hebrew UI: Hebrew title and
   status).
2. **Dynamic Island**: unlock, go home. Compact: Pip left, countdown right
   in yellow. Long-press: expanded view with Pip, status, title, big
   countdown and a filling progress bar. With another app's activity also
   running, Grind shows minimal (Pip only).
3. **Pause**: Pause in the app. The countdown freezes at the same value as
   the app, status "PAUSED", the sticker turns white, Pip stops cheering.
   Wait a minute: still frozen. **Resume**: counts again, matching the app to
   the second.
4. **+5 min**: the countdown jumps up 5 minutes, running and paused.
5. **Tap**: tap the Lock Screen activity and the compact island, with the
   app in the background and after force-quitting it: Grind opens on the
   Focus tab (not Today). Also run `xcrun simctl openurl booted
   grind:///focus`.
6. **End early**: End. The activity disappears at once.
7. **Run out**: start a 5-minute session, lock the phone, wait. At 0:00 the
   activity dims (stale). Open the app: the end-of-session sheet shows and
   the activity disappears. The break shows no activity.
8. **Restart**: start, pause, force-quit, relaunch: one activity (not two),
   frozen at the paused time. Start, force-quit, relaunch: one activity,
   still counting.
9. **Replace**: with a session running, start one on another task: the
   activity switches to the new title, never two at once.
10. **Turned off**: Settings > Grind > Live Activities off, start a session:
    no activity, the timer works normally, no error.
11. **Old iOS**: on an iOS 15 or 16.0 simulator the app launches (ActivityKit
    weak-linked, step 8) and focus sessions work without an activity.
12. **Web**: `flutter run -d chrome`: the Focus tab works as before (the
    service is the no-op).
13. **Dark/light and a11y**: Lock Screen activity readable in both; VoiceOver
    reads "Pip", the status, the title and the time.

## Consequences

- Home-screen widgets (phase 2) can join `GrindLiveActivityBundle`.
- The labels are sent from Dart because the extension cannot read the ARB
  files; new strings in the widget follow the same path.
- Ending the activity exactly at 0:00 while the app is suspended would need
  ActivityKit push updates (server); today it goes stale and is ended on the
  next foreground.
