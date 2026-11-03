# Folder ownership for parallel agents

Several agents work on the repo at the same time, each in its own git worktree and branch. To keep merges clean, every path has one owner per wave. An agent edits only what it owns; anything else goes into its final report as a request for the integrator.

## Always integrator-only
- `pubspec.yaml`, `pubspec.lock` — all MVP dependencies are already declared. Need another? Say so in your report.
- `lib/main.dart`, `lib/shell/app_shell.dart` — wiring of real implementations and tabs.
- `lib/core/**` — the contracts. If an interface is missing something, add a **new** file in your own folder (an extension, a helper, a subclass) and describe the proposed interface change in your report. Never edit `lib/core` in a feature branch.
- `docs/handoff/**`, `docs/research/**`, `docs/plans/**`.

## Wave 1
| Owner | Paths |
|---|---|
| W1-A CI (#1, #49) | `.github/**`, `CHANGELOG.md`, `web/` hosting config files only |
| W1-B persistence (#2) | `lib/core/data/**` (new), `test/core/data/**`, `docs/adr/0001-local-database.md`, `web/sqlite3.wasm` + `web/drift_worker.js` if needed |
| W1-C architecture (#3) | `lib/app/**` (new: router, test app, providers scope), `lib/features/*/` **wiring only** (replace constants with providers, no visual changes), `test/app/**`, `docs/adr/0002-state-management.md` |
| W1-D notifications (#5) | `lib/core/notifications/**` (new), `test/core/notifications/**`, `ios/Runner/Info.plist` additions, `ios/Runner/AppDelegate.swift` if needed, `web/` notification helpers |
| W1-E design system (#6) | `lib/theme/**`, `lib/widgets/**`, `lib/l10n/**` (new), `l10n.yaml`, `test/widgets/**`, `test/theme/**` |
| W1-F onboarding (#7) | `lib/features/onboarding/**`, `lib/features/settings/**` (new), `test/features/onboarding/**`, `test/features/settings/**` |
| W1-G scheduler (#16) | `lib/features/plan/scheduler/**` (new), `test/features/plan/scheduler/**` |

## Wave 2
Wave 1 is merged, so `lib/app/**`, `lib/core/data/**`, `lib/core/notifications/**`, `lib/theme/**`, `lib/widgets/**`, `lib/l10n/**` and `lib/features/{onboarding,settings}/**` exist. Read them; edit only what the table gives you.

| Owner | Paths |
|---|---|
| W2-A task capture (#8) | `lib/features/tasks/**` (new), `lib/features/today/**`, `test/features/tasks/**`, `test/features/today/**` |
| W2-B reminders (#9, #10, #12) | `lib/features/reminders/**` (new), `lib/core/notifications/**` (inherited from W1-D), `test/features/reminders/**`, `test/core/notifications/**` |
| W2-C recurrence (#11) | `lib/features/recurrence/**` (new), `test/features/recurrence/**` |
| W2-D Google Calendar (#13) | `lib/features/calendar/google/**`, `lib/features/calendar/sync/**` (generic pull/write-back engine over `CalendarProvider`), `web/index.html` (GIS script tag only), tests under `test/features/calendar/{google,sync}/**` |
| W2-E Apple Calendar (#14) | `lib/features/calendar/apple/**`, `ios/Runner/AppleCalendarPlugin.swift` (new), `ios/Runner/AppDelegate.swift` (register the plugin only), `ios/Runner/Info.plist` (usage strings only), `test/features/calendar/apple/**` |
| W2-F calendar views (#15) | `lib/features/plan/**` except `lib/features/plan/scheduler/**`, `test/features/plan/**` except `scheduler/` |

Strings: do **not** edit `lib/l10n/*.arb` (merge conflicts). Keep new UI strings in a `<feature>_strings.dart` file in your folder; the integrator moves them into the ARB files after the wave. Use `context.l10n` for strings that already exist there.

## Shared rules
- New code reads contracts through `package:grind/core/core.dart`.
- Riverpod providers for a feature live in that feature's folder; `lib/core/di.dart` only holds the interface providers.
- Keep the visual system: use `StickerCard`, `PillButton`, `Pill`, `SectionLabel`, `MomentumMeter`, `PipAvatar` from `lib/widgets` and the tokens in `lib/theme`.
- Tests next to the code they test, under the matching `test/` path.
