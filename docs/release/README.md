# iOS release guide (preparation, issue #48)

Nothing here has been run: it was written without a Mac or an Apple account.
Treat it as a checklist for the first real build.

## One-time setup (on a Mac)

1. **Apple Developer Program**: enrol at developer.apple.com/programs (99 USD/year). Approval can take a day or two.
2. **Tools**: Xcode (current stable), Flutter 3.35.5, CocoaPods, and optionally Ruby + `bundler` for fastlane (`gem install fastlane` or `brew install fastlane`).
3. **Bundle id**: the plan is `com.noa.grind`, but the Xcode project currently uses `com.noa.grind.grind` (and `.RunnerTests`). Decide once, then change it in `ios/Runner.xcodeproj` (Runner target > General > Bundle Identifier) and in `ios/fastlane/Appfile`. The id cannot be changed after the App Store Connect record exists.
4. **Signing**: `open ios/Runner.xcworkspace`, Runner target > Signing & Capabilities, tick "Automatically manage signing", pick your team.
5. **App Store Connect record**: appstoreconnect.apple.com > Apps > "+" > New App. Platform iOS, name, primary language, the bundle id above, SKU (anything unique, e.g. `grind-ios`).
6. **API key** (for fastlane, no password or 2FA prompts): App Store Connect > Users and Access > Integrations > App Store Connect API > generate a key with the "App Manager" role. Download the `.p8` once. Export:
   ```sh
   export ASC_KEY_ID=ABC123DEFG
   export ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000
   export ASC_KEY_CONTENT=$(base64 -i AuthKey_ABC123DEFG.p8)
   ```
   Never commit the key.
7. Fill the placeholders in `ios/fastlane/Appfile` (Apple id, team id).

## Building and TestFlight

Manual path (no fastlane):

```sh
flutter pub get
flutter build ipa --release        # build number comes from pubspec.yaml (0.1.0+N)
open build/ios/archive/Runner.xcarchive   # Organizer > Distribute App > App Store Connect
```

Or with fastlane:

```sh
cd ios
fastlane beta      # flutter build, build_app, upload_to_testflight
```

Then in App Store Connect > TestFlight: wait for processing (about 10 to 30 minutes), answer the export-compliance question (the app only uses standard OS encryption: "Yes, exempt"), add yourself as an internal tester, install through the TestFlight app. Every upload needs a higher build number: bump `+N` in `pubspec.yaml`.

Smoke test on a real device: onboarding, notification permission, a reminder firing with actions and snooze, calendar permission (full access) and Apple Calendar sync, focus session, backup export. The notification and calendar code paths are untested on iOS so far.

The optional workflow `.github/workflows/ios-build.yml` only checks that the app compiles without signing (manual run or `v*` tags).

## App Privacy ("nutrition labels") answers

Everything stays on the device: reminders, goals, settings and history are stored locally, there are no accounts, no analytics, no ads, no tracking, and no Grind server.

| Question | Answer |
| --- | --- |
| Do you or third-party partners collect data from this app? | **No** (data processed only on device is not "collected") |
| Data types collected | None |
| Tracking (ATT) | No, no `NSUserTrackingUsageDescription` needed |

Caveats to re-check before submission:

- **Calendar access** is requested only when the user connects a calendar. Events are read on device and not sent anywhere. The usage strings are in `ios/Runner/Info.plist`.
- **Google Calendar** (web) talks to Google directly from the browser with the user's own consent; it is not part of the iOS app.
- If the optional cloud planner (HANDOFF section 6) ships, this answer changes: user content sent to a server must be declared.
- A **privacy policy URL** is required in App Store Connect (guideline 5.1.1) and should also be reachable inside the app. Host a short page (GitHub Pages works) saying the above.

## Before pressing "Submit for Review"

- Listing text and screenshots: `docs/release/app-store-listing.md`.
- Age rating questionnaire, category, support URL, privacy policy URL.
- Review notes: explain that calendar access is optional and how to reach every tab; no login is needed.
- Final icon check: the 1024 px icon has no alpha channel (it is saved as RGB).
