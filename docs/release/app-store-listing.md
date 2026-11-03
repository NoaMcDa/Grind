# App Store listing (draft)

Source: `docs/handoff/HANDOFF.md` section 4 (approved drafts). The final app name is still open (Pip is the companion's name, not necessarily the app's).

## Name, subtitle, category

- Name: Grind (30 characters max; check availability in App Store Connect)
- Subtitle (30 max): "Goals, reminders, calendar" (placeholder)
- Primary category: **Productivity**. Secondary: Health & Fitness (goals include fitness and nutrition) or Education.
- Support URL and privacy policy URL: required, to be hosted.

## Short description (promotional text / first paragraph)

> An iOS productivity app that syncs with your calendar, sends smart reminders, and tracks short- and long-term goals across learning, investing, fitness and nutrition. See progress as X of Y or weekly counts, get highlights, learn what's realistic this week, and let an encouraging AI assistant help you prioritize.

Note: this is 314 characters. App Store promotional text allows 170, so use it as the opening of the description and write a shorter promo line from it. Also, "AI assistant" must match what actually ships; if the planner is rule-based on device, say "a friendly assistant".

## Long description

The approved long text (about 300 words) is in the 2 Nov 2026 chat history and is not in the repo. Outline to reproduce it, with the sections in this order:

1. Reminders and calendar
2. Short- and long-term goals
3. Goal metrics (finite "X of Y" versus recurring weekly counts)
4. Highlights
5. Realistic planning and prioritisation
6. Assistant and encouragement (Pip)
7. Privacy: the core runs on your device

TODO(Noa): paste the approved text here before submission.

## Keywords (100 characters max, comma separated, no spaces)

`reminders,goals,habit,planner,calendar,focus,to-do,tasks,routine,productivity,study,fitness`

(92 characters. Do not repeat words that are in the name or category.)

## Age rating (questionnaire notes)

Expected result **4+**: no violence, no mature or suggestive content, no gambling, no user-generated content shared between users, no unrestricted web access, no medical or treatment advice (nutrition goals are user-entered counters). Answer "None" to every frequency question. Does not use location, no in-app purchases (for now).

## Screenshot plan

Required: 6.9" iPhone (1320x2868) set; 6.5" is optional but accepted as the fallback when 6.9" is provided. iPad (13", 2064x2752) only if iPad is a supported device family. Up to 10 per size; use 5 and the same order everywhere. Capture in the Simulator (Cmd+S), light mode, with the demo data, no status-bar clutter.

| # | Screen | Caption idea |
| --- | --- | --- |
| 1 | Today with Pip and the momentum meter | "Plan today, gently" |
| 2 | Reminder notification with actions and snooze | "Reminders that fit your day" |
| 3 | Plan: calendar view with scheduled tasks | "Your calendar, in sync" |
| 4 | Goals with X of Y progress and weekly counts | "Short and long goals, one place" |
| 5 | Focus session with Pip cheering | "Focus, then celebrate" |

| Device | Size (px) | Required |
| --- | --- | --- |
| iPhone 6.9" (16 Pro Max) | 1320x2868 | Yes |
| iPhone 6.5" (11 Pro Max / XS Max) | 1242x2688 | Only if no 6.9" set |
| iPad 13" (Pro M4) | 2064x2752 | Only if iPad is supported |

Background style for framed shots: ground `#F5F2FF`, ink `#17123A` captions in Fredoka/Nunito per the design system. Use the 1024 px icon from `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
