# Handoff — iOS Productivity App (working name: Pip)

Last updated: 2 Nov 2026 (Flutter decision) · Owner: Noa

## 1. What this is
A personal iOS app for managing productivity: reminders and calendar, short- and long-term goals with measurable progress, realistic weekly planning and prioritization, an AI assistant, and an encouraging (never guilt-based) tone. Started as "time management app"; the user clarified the goal is **productive** (not predictive).

**Background research:** see the downloaded doc *"Time Management Apps — Research & iOS Build Plan"* (market survey of 20 apps, feature catalogue, behavioral evidence, gap analysis, iOS stack, 4-layer design, architecture, roadmap, App Store notes, sources). Not repeated here.

## 2. Feature set (user's own spec, translated from Hebrew)
1. **Reminders + calendar** — two-way sync with Google/Apple Calendar (meetings/invites shown next to tasks); one-time and recurring reminders; tasks placed into free calendar slots.
2. **Short- and long-term goals** — near (week/month) and far (quarter/year+) horizons; areas e.g. learning (project management course), capital markets/investing, fitness, nutrition; long goals broken into milestones and weekly tasks.
3. **Goal metrics** — two types:
   - *Finite*: "X of Y" + % (e.g. 8 of 12 lessons).
   - *Recurring*: weekly quota that resets (e.g. 3 of 4 workouts this week, 5 of 7 days on nutrition plan) + trend over time.
4. **Highlights** — dashboard of all goals; flags completed / close to done / stalled; weekly recap.
5. **Realistic planning + prioritization** — estimate what fits this week from free calendar time and actual task durations; warn when overbooked and suggest what to defer; auto-rank by deadline, goal importance and progress, with manual override.

Carried over from earlier design decisions:
- **Reminders as if-then prompts** ("If it's 7:00, open the thesis file") with notification actions Done / Snooze / Start focus.
- **Focus sessions** (Pomodoro-style, adjustable), Live Activity on Lock Screen, optional "hard mode" app shielding (Screen Time API) later.
- **Cheering layer**: companion character "Pip"; **momentum** meter instead of streaks; misses never reset progress; no "you broke it" messaging; varied praise copy.
- **Assistant**: natural-language capture ("gym tomorrow 7am, 45 min" → task), plan-my-day, tool calling. **Decided 2 Nov: cloud LLM** (works on web too, better Hebrew); see §6.

## 3. Open questions
- Nutrition goals input: manual check-in ("hit my goal today") or numbers (calories/protein)?
- Workouts: manual count or auto from Apple Health?
- Final app name (Pip is a placeholder for the companion).

## 4. App store descriptions (approved drafts)
**Short (314 chars):**
> An iOS productivity app that syncs with your calendar, sends smart reminders, and tracks short- and long-term goals across learning, investing, fitness and nutrition. See progress as X of Y or weekly counts, get highlights, learn what's realistic this week, and let an encouraging AI assistant help you prioritize.

**Long (~300 words):** an encouraging iOS productivity app combining calendar, reminders and goals — sections: Reminders & calendar · Short- and long-term goals · Goal metrics (finite vs recurring) · Highlights · Realistic planning & prioritization · Assistant & encouragement · privacy (core runs on device). Full text in chat history of 2 Nov 2026.

## 5. Design (mockups)
Canvas: **"Time App Screens"** (Claude Design artifact) — 5 interactive phone screens (390×844), linked by a bottom tab bar (Today · Plan · Focus · Pip · Ask). PNG exports and source files are in this package.

| # | Screen | Layer | What it shows |
|---|---|---|---|
| 1 | Today | Reminders | If-then reminder card (Done / Snooze 15 / Start focus), momentum meter, "Up next" tickable tasks, add button |
| 2 | Day plan | Productive | Time-blocked 08:00–18:00 day, calendar events (dashed), deep vs light tasks, "Re-plan with Pip", "Add task" |
| 3 | Focus | Productive | Violet full-screen timer ring, Pip cheering, hard-mode pill, +5 / Pause / End, session dots, Lock Screen Live Activity preview |
| 4 | Pip | Cheering | Companion hero, momentum meter, weekly focus bars (rest day without shame), logged wins, cosmetic unlocks |
| 5 | Ask Pip | Assistant | On-device chat: NL → task card, "make it smaller" suggestion, quick prompts, composer |

**Visual system — "playful & bold" (user-chosen):**
- Fonts: Bricolage Grotesque (display 600/800), DM Sans (body 400/500/700).
- Colors: ground #F5F2FF · ink #17123A · muted #5A5478 · card #FFFFFF · violet #5B3DF5 (primary) · sun #FFC83D · mint #2EC4A6 · pink #FF7AB0 · sky #7FC8FF.
- Sticker style: 2.5px ink borders, 22px radius, 4px 4px 0 ink hard shadow; pill buttons ≥44px; stroke icons, no emoji.
- Pip: original character — round sun-yellow blob, ink outline, oval eyes with glints, pink cheeks, mint leaf on top.

**Not yet designed (from the new feature spec):** Goals screen (finite + recurring metrics), Highlights / weekly recap, "Is this week realistic?" capacity view, calendar sync settings.

## 6. Technical direction (updated 2 Nov 2026 — App Store **and** web)
The user wants the app on the App Store and on the web. That rules out the Swift-only plan in the research doc (§2A/2C), which assumed iOS only. Decision: **Flutter**, one codebase for iOS and web.

- **UI**: Flutter (Dart). Design tokens, typography and the sticker components live in `lib/theme` and `lib/widgets`; one feature folder per tab in `lib/features`. Fonts are bundled in `assets/fonts` (OFL).
- **Backend** (needed once web exists; SwiftData + CloudKit don't carry over): hosted Postgres with auth and realtime sync — Supabase (or Firebase). Google Calendar API works on both platforms; Apple Calendar is reachable only on iOS through EventKit via a plugin.
- **Assistant**: cloud LLM (Claude API) behind the backend, on both platforms. Apple Foundation Models don't exist on web, so the "on-device first" assumption is dropped; this also solves Hebrew. The "On-device · private" badge in the Ask mockup becomes "Cloud assistant"; privacy copy becomes "your tasks live in your own account".
- **iOS-only extras, via small native plugins**: Live Activity (ActivityKit), home-screen widgets and App Intents, Screen Time hard mode (FamilyControls, phase 3). On web the Focus tab is a plain timer and there is no app shielding.
- **Notifications**: flutter_local_notifications with Done / Snooze actions on iOS; web push later.
- **Still required to ship on iOS**: a Mac with Xcode, and the $99/yr Apple Developer Program. The web build needs neither.
- **Order**: web first (fast iteration in the browser, no review), then iOS from the same code plus the native plugins.

Roadmap stays MVP (reminders, plan, focus) → Cheering → Assistant → Sync & stats → Hard mode & Watch; the Goals/Highlights/Capacity layer from §2 is added after the MVP gate.

### Repo layout (2 Nov 2026)
```
lib/main.dart              app entry, theme
lib/theme/                 tokens (colors, radii, stroke, shadows), typography
lib/widgets/               StickerCard, PillButton/Pill/SectionLabel, MomentumMeter, PipAvatar
lib/shell/app_shell.dart   5-tab shell (Today · Plan · Focus · Pip · Ask), phone-width column on web
lib/features/<tab>/        one screen per tab, currently with mock data and local state
test/                      widget tests (load bundled fonts via test/test_fonts.dart)
assets/fonts/              DM Sans 400/500/700, Bricolage Grotesque 600/800
docs/handoff/              this package, research doc, mockups and renders
```

## 7. Suggested next steps
1. Answer the open questions in §3 (the assistant question is now settled: cloud).
2. Replace the mock data with a real task model + local persistence, then wire Supabase.
3. Design the missing screens (Goals, Highlights, Weekly capacity).
4. Update the research doc's feature set/roadmap with the goals & metrics layer.
5. Set up the iOS build on a Mac (Xcode, signing) and TestFlight.

## Package contents
- `HANDOFF.md` — this file
- `screens-png/` — 5 PNG exports (390×844) + `all-screens.png` overview
- `screens-source/` — the 5 `.dc.html` source files + `canvas.json` (open/edit in the Claude Design canvas)
