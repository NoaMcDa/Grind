# MVP execution: parallel agents

Approved 3 Nov 2026. Source of truth for who builds what, in which order. Issue numbers refer to GitHub; #50 is the roadmap index.

## Decisions
- Grind is a **pure client**: data lives permanently in the device's local storage, no account, no server (#4 closed). Backup/restore is part of #2.
- iOS-native code is written now and verified on Noa's Mac later.
- Google Calendar needs a free OAuth client id from Google Cloud Console; code reads it from `--dart-define` and ships with a placeholder.
- Up to 7 agents in parallel; integrator (Claude in the main session) merges PRs in dependency order.
- Models: Opus for concurrency / platform channels / schema / algorithms, Sonnet for UI, config and refactors against the contracts.

## Dependency graph
```
Step 0 contracts ──┬─► #2 persistence ─┐
                   ├─► #3 architecture ─┼─► #8 task capture ─┬─► #9 if-then ──┐
                   ├─► #5 notifications ┘                    ├─► #10 actions ─┼─► #12 smart snooze
                   ├─► #16 scheduler core                    └─► #11 recurring┘
                   ├─► #6 design/l10n ──► (#7 onboarding runs on fakes in wave 1)
                   └─► #7 onboarding ──┬─► #13 Google sync ─┐
#1 CI (independent)                    └─► #14 Apple sync ──┴─► #15 calendar views ─► #16 wired into Plan
```

## Step 0 (done by the integrator)
Contracts in `lib/core` (domain, repositories, services, DI with fakes), all MVP dependencies in `pubspec.yaml`, `docs/plans/ownership.md`, `docs/plans/agent-brief.md`, merged to `main`.

## Wave 1 — backbone + scheduler core (7 agents)
| Agent | Issue(s) | Model | Owns |
|---|---|---|---|
| W1-A | #1 CI, #49 deploy skeleton | Sonnet | `.github/`, `CHANGELOG.md` |
| W1-B | #2 persistence + backup | Opus | `lib/core/data/` |
| W1-C | #3 architecture | Sonnet | `lib/app/`, wiring in `lib/features/*` |
| W1-D | #5 notifications infra | Opus | `lib/core/notifications/`, iOS plist |
| W1-E | #6 design system, l10n, a11y | Sonnet | `lib/theme/`, `lib/widgets/`, `lib/l10n/` |
| W1-F | #7 onboarding & settings | Sonnet | `lib/features/onboarding/`, `lib/features/settings/` |
| W1-G | #16 scheduler core | Opus | `lib/features/plan/scheduler/` |

Merge order: W1-A → W1-E → W1-B → W1-C → W1-D → W1-G → W1-F (UI last so it rebases onto the real providers).

## Wave 2 — MVP features (6 agents, after wave 1 is on main)
| Agent | Issue(s) | Model |
|---|---|---|
| W2-A | #8 task capture | Sonnet |
| W2-B | #9 + #10 + #12 reminder content, actions, smart snooze | Opus |
| W2-C | #11 recurring reminders | Sonnet |
| W2-D | #13 Google Calendar sync (client-side OAuth) | Opus |
| W2-E | #14 Apple Calendar plugin (Swift, unverified here) | Opus |
| W2-F | #15 calendar views | Sonnet |

## Wave 3 — integration & MVP gate
- W3-A (Opus): wire the scheduler into Plan, end-to-end widget tests, web build + screenshots vs mockups, integration fixes.
- W3-B (Sonnet): code review and security review of every PR, copy audit.
- Gate: analyze clean, tests green, web build runs, screenshots match the design, iOS build on Noa's Mac, a week of daily use.

## Protocol
See `docs/plans/agent-brief.md`. Every agent: worktree, branch `feat/<issue>-<slug>`, four checks green, PR with `Closes #n`, 15-line report.

## Still needed from Noa (not blocking)
1. Google Cloud OAuth client ids (iOS + web) before Google sync can be tested.
2. A Mac with Xcode for the Apple Calendar plugin, background notification actions and the App Store.
