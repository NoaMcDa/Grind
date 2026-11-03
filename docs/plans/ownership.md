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
| Owner | Paths |
|---|---|
| W2-A task capture (#8) | `lib/features/tasks/**` (new), `lib/features/today/**`, tests |
| W2-B reminders (#9, #10, #12) | `lib/features/reminders/**` (new), tests |
| W2-C recurrence (#11) | `lib/features/recurrence/**` (new), tests |
| W2-D Google Calendar (#13) | `lib/features/calendar/google/**` (new), tests |
| W2-E Apple Calendar (#14) | `lib/features/calendar/apple/**`, `ios/Runner/Plugins/**` or a `packages/apple_calendar/` plugin, tests |
| W2-F calendar views (#15) | `lib/features/plan/**` except `scheduler/`, tests |

## Shared rules
- New code reads contracts through `package:grind/core/core.dart`.
- Riverpod providers for a feature live in that feature's folder; `lib/core/di.dart` only holds the interface providers.
- Keep the visual system: use `StickerCard`, `PillButton`, `Pill`, `SectionLabel`, `MomentumMeter`, `PipAvatar` from `lib/widgets` and the tokens in `lib/theme`.
- Tests next to the code they test, under the matching `test/` path.
