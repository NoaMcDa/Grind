# Changelog

All notable changes to Grind are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses `0.x.y+build` versions.

## [Unreleased]

### Added
- Reminders with notification actions (done, snooze) and smart snooze.
- Recurring reminders.
- Google Calendar sync (web) and Apple Calendar sync (iOS).
- Calendar views for planning.
- Scheduler that places tasks around existing events.
- Onboarding and settings.
- Backup and restore of local data.
- Focus sessions with a timer and a cheering Pip.
- Pip mood and momentum meter.
- Evening review.
- Goals with X of Y and weekly-count progress.
- Release preparation: Pip app icons (iOS, PWA, favicon), launch screen, fastlane lanes, optional iOS compile-check workflow, and release docs under `docs/release`.
- Design system: tokens, typography and the sticker-style widgets (StickerCard, PillButton, Pill, SectionLabel, MomentumMeter, PipAvatar).
- Five-tab shell with Today, Plan, Focus, Pip and Ask screens (mock data).
- Core contracts and in-memory implementations under `lib/core`.
- Web build and iOS project from one Flutter codebase.
- CI (format, analyze, test, web build), GitHub Pages deploy, PR and issue templates, Dependabot.
