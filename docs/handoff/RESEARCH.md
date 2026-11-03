# Time Management Apps — Research & iOS Build Plan

Oct 29, 2026 · @Noa David

> **Update, 2 Nov 2026.** The app must ship on the App Store *and* on the web, so the native-Swift recommendation in Part 2A/2C no longer holds. The build moves to **Flutter** (iOS + web from one codebase) with a hosted backend and a cloud assistant; iOS-only frameworks (ActivityKit, App Intents, Screen Time) are reached through small native plugins. The research, feature catalogue, behavioural evidence and layer design still apply. Details in `HANDOFF.md` §6.

## Part 1A — The landscape: 20 apps, four camps

The iOS time-management market in late 2026 splits into four camps, and no single app covers all four of your goals (reminders, cheering, productivity, assistant). Task managers own capture and reminders; AI planners own scheduling; focus blockers own distraction; companion apps own encouragement. Prices below are as listed by the cited pages in 2026 and change often.

| App | Camp | Price (2026) | Platforms | What it does best | Encouragement style |
| --- | --- | --- | --- | --- | --- |
| [Todoist](https://dupple.com/learn/best-task-management-apps) | Task manager | Free / Pro \~$5/mo | All | Natural-language capture, Karma points, AI assist | Karma score, light |
| [Things 3](https://www.softwares.com/compare/things-vs-ticktick) | Task manager | $9.99 iPhone, $49.99 Mac, one-time | Apple only | Today/Evening/Anytime structure, progress rings | Progress rings, calm |
| [TickTick](https://dupple.com/learn/best-task-management-apps) | All-in-one | Free / $35.99/yr | All | Tasks + calendar + habits + Pomodoro in one app | Habit streaks, basic |
| [Apple Reminders](https://www.zapier.com/blog/best-iphone-ipad-to-do-list-apps) | Task manager | Free | Apple | Siri, location reminders, deepest OS integration | None |
| [Structured](https://lifestack.ai/blog/best-task-manager-app-for-iphone) | Visual day planner | Free / Pro (AI needs Pro) | iOS, Mac | Drag-block timeline of the day | Visual, none |
| [Sorted³](https://www.zapier.com/blog/best-iphone-ipad-to-do-list-apps) | Time blocking | Paid | Apple | "Hyper-scheduling" tasks into time slots | None |
| [Sunsama](https://kronoprompt.it.com/blog/7-best-ai-daily-planner-apps-2026/) | Daily ritual planner | $17–22/mo, no free plan | Web, iOS, Android | Guided morning planning and evening shutdown ritual | Reflection prompts |
| [Motion](https://arahi.ai/blog/time-blocking-apps-compared) | AI auto-scheduler | $19–29/mo | Web, iOS, Android | Rebuilds your day automatically around deadlines | None |
| [Reclaim.ai](https://arahi.ai/blog/time-blocking-apps-compared) | AI calendar defense | Free tier / $10/seat | Web (Google/Outlook) | Protects focus time and habits on the calendar | None |
| [Akiflow](https://www.lindy.ai/blog/ai-planner) | Command-bar planner | $19/mo annual, $34 monthly | Web, iOS, Android, Mac | Keyboard-driven inbox aggregation + time slots | None |
| [Lifestack](https://lifestack.ai/blog/best-ai-planning-assistant) | Energy-aware AI planner | From $7/mo | iOS | Schedules around sleep and energy data | Data-driven |
| [Forest](https://softpicker.com/best-focus-apps/) | Focus timer | $3.99 one-time (mobile) | iOS, Android | Grow a tree during a focus session, plant real trees | Loss-aversion (tree dies) |
| [Habitica](https://habi.app/insights/finch-alternatives/) | Gamified habits | Free / premium | All | Full RPG: XP, gear, quests, party boss battles | Heavy gamification |
| [Finch](https://makeheadway.com/blog/finch-app-review/) | Self-care companion | Free / $9.99/mo or $69.99/yr | iOS, Android | Pet bird grows from your completed goals; no shame | Warm companion |
| [Streaks](https://goalsandprogress.com/life-goals-program-vs-strides-streaks-productive/) | Habit tracker | Paid | Apple | Cleanest Apple Watch habit app | Streak chain, resets on miss |
| [SoftHabits](https://apps.apple.com/app/id6763462911) | Gentle habits | Free / subscription | iOS | No streaks by design; missed days are data | Self-compassion |
| [Opal](https://softpicker.com/best-focus-apps/) | Screen-time blocker | Free / $9.99/mo | iOS, Mac | Scheduled blocking with hard mode | None |
| [one sec](https://habitdoom.com/blog/opal-alternatives) | Friction blocker | $4.99/mo | iOS, Android | Breathing pause before opening a distracting app | Gentle friction |
| [Freedom](https://lifestack.ai/blog/freedom-focus-app) | Cross-device blocker | Free / $3.33/mo annual | All | Blocks sites and apps on every device at once | None |
| [Fantastical](https://lifestack.ai/blog/productivity-apps-for-iphone) | Calendar | Subscription | Apple | Natural-language events, best iOS calendar UI | None |

Two observations shape the gap analysis in 1C. First, the "cheering" column is empty for every planner and focus tool; encouragement lives only in habit and self-care apps that have no planning or focus features. Second, the AI planners (Motion, Reclaim, Akiflow) are web-first, subscription-priced at $10–34/mo, and built for meeting-heavy knowledge workers, not students.

## Part 1B — Feature catalogue

The table maps every recurring feature across the surveyed apps to one of your four goals, and marks which iOS framework delivers it (details in 2A). Features marked *core* appear in nearly every app; *differentiator* features appear in one or two.

| Feature | Goal served | Status in market | Who does it well | iOS framework |
| --- | --- | --- | --- | --- |
| Time-based reminders, recurring, snooze | Reminders | Core | Todoist, Reminders, TickTick | UserNotifications |
| Location-based reminders | Reminders | Common | Apple Reminders | UserNotifications + CoreLocation |
| Notification actions (Done / Snooze 10 min) | Reminders | Common | Things 3, Reminders | UNNotificationCategory |
| Natural-language task entry ("gym tmrw 7am") | Assistant | Core | Todoist, Fantastical | Foundation Models or regex parser |
| Calendar integration | Productive | Core | Fantastical, TickTick, Akiflow | EventKit |
| Time blocking (tasks on a timeline) | Productive | Common | Structured, Sorted³, Sunsama | EventKit + custom UI |
| AI auto-scheduling | Assistant | Differentiator | Motion, Reclaim | Custom logic + EventKit |
| Daily planning + evening review ritual | Productive | Differentiator | Sunsama | App logic |
| Focus / Pomodoro timer | Productive | Common | Forest, TickTick, Focus Keeper | ActivityKit (Live Activity) |
| Distraction blocking during focus | Productive | Differentiator | Opal, Forest, one sec | FamilyControls + ManagedSettings + DeviceActivity |
| Habit tracking | Productive | Common | Streaks, TickTick, Finch | SwiftData |
| Progress analytics (time per project, completion rate) | Productive | Common | TickTick, Rize | Swift Charts |
| Streaks | Cheering | Core in habit apps | Streaks, Duolingo-style | App logic |
| Companion character that grows | Cheering | Differentiator | Finch, Forest, Habitica | SwiftUI animation |
| Celebratory feedback (confetti, haptics, progress rings) | Cheering | Common | Things 3, Finch | SwiftUI + CoreHaptics |
| Encouraging notification copy | Cheering | Rare | Finch | UserNotifications |
| AI chat assistant | Assistant | Emerging | Todoist AI assist, Structured AI | Foundation Models / cloud LLM |
| Home-screen and lock-screen widgets | All | Core | Things 3, Todoist, Streaks | WidgetKit |
| Siri and Shortcuts | Assistant | Core | Reminders, Things 3 | App Intents |
| Live Activity / Dynamic Island timer | Productive | Common | Forest, Focus timers | ActivityKit |
| Apple Watch | All | Common | Streaks, Things 3 | WatchKit / SwiftUI |

Three features matter most for your concept and are rare in combination: encouraging notification copy, a companion that reacts to productivity (not just self-care), and a planning ritual that an assistant drives rather than a form the user fills in.

## Part 1C — What works, what users hate, and the gap

The evidence favours structured focus intervals, if-then planning, and positive reinforcement, and warns against guilt-based streaks. Users' complaints cluster around four failures: notification fatigue, streak guilt, week-three abandonment, and over-complexity.

**What the research supports**

- Pomodoro-style structured breaks: a 2025 scoping review in [BMC Medical Education](https://link.springer.com/article/10.1186/s12909-025-08001-0) found time-structured intervals consistently improved focus and reduced fatigue versus self-paced breaks; a [2026 controlled study](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC13405840/) adds that flexibility in break timing matters, so let the user adjust interval length.
- Implementation intentions ("If it is 7am, then I open the thesis file"): Gollwitzer's if-then planning raises task completion by a medium-to-large effect size ([summary](https://scheduleu.org/?p=133)). Design reminders as if-then prompts tied to a time and a first action, not bare titles.
- Streaks cut both ways: Silverman's studies in the *Journal of Consumer Research* and *OBHDP* show streaks signal commitment and raise confidence, but reminders about a broken streak make people feel they are failing; the author advises apps not to emphasise broken streaks ([University of Delaware](https://lerner.udel.edu/seeing-opportunity/lerner-professor-researches-how-streaks-motivate-us/)). Even repairable streaks still motivate, so a "streak freeze" costs little.
- Self-determination theory: points and badges supply extrinsic motivation only; apps that control rather than support reduce initiative ([critique](https://networkcultures.org/blog/2026/01/19/baby-please-dont-break-the-streak/)). Pair rewards with autonomy (user picks the goal) and competence feedback (show real progress).
- Self-compassion after a miss predicts trying again rather than quitting; the all-or-nothing "I already failed" spiral is the mechanism behind week-five deletion ([habit-app analysis](https://goalsandprogress.com/life-goals-program-vs-strides-streaks-productive/)).

**What users complain about (1–3 star review analyses)**

| Complaint | Where it shows | Design implication |
| --- | --- | --- |
| "Worked for a week, then stopped" | [Opal, Forest, Freedom, one sec](https://unstar.app/vi/blog/opal-forest-freedom-one-sec-jomo-screen-time-apps-ranked-2026) | Novelty fades by week three; vary rewards and add a weekly review that resets goals |
| Streak guilt, red zero on a missed day | Streaks, Duolingo-style apps | Treat misses as data; no "you broke it" notifications |
| Pet care feels like another chore | [Finch](https://neurospicynomnoms.beehiiv.com/p/digital-pet-bestie-for-self-care-610618d407f7afef) | Companion must never demand; it reacts, it does not nag |
| Premium gating of reminders and Siri | Todoist (Dec 2025 price rise), TickTick | Keep reminders free; charge for analytics or AI |
| Subscription fatigue, $10–34/mo | Motion, Sunsama, Akiflow | One-time or low-cost tier wins goodwill (Things 3, Forest) |
| Too complex to maintain (Habitica) | [Habitica](https://chiltonm.bearblog.dev/everyone-i-know-is-addicted-to-the-bird-app/) | Default to three visible actions per screen |
| Blockers are easy to bypass | Opal, Freedom | Screen Time API shielding is OS-level; use it for "hard mode" |

**Gap analysis**

No app on iOS combines (a) a planning assistant that proposes the day, (b) focus sessions with OS-level blocking, and (c) a warm, non-punitive companion that celebrates productivity rather than self-care. Finch has the tone but no productivity tools; Motion and Reclaim have the automation but no warmth and a corporate price; Forest has the loss-aversion hook that reviewers say stops working. The opening for your app is a **student-priced, encouragement-first planner**: an assistant that drafts a realistic day from your tasks and calendar, runs focus sessions, and reacts to what you actually did with praise calibrated to effort, never guilt.

## Part 2A — Tech stack and Apple frameworks

Build native: Swift 6 + SwiftUI, minimum target iOS 17 (iOS 26 for the on-device LLM), SwiftData for storage, CloudKit for sync. Every feature you want maps to a first-party framework, and three of them (Screen Time, Live Activities, Foundation Models) have no equivalent in Flutter or React Native without native bridges.

**Hardware and accounts**

- A Mac with Apple Silicon, running macOS 26 (Tahoe) and Xcode 26, is required to build for iOS 26 and to use Foundation Models ([guide](https://levelup.gitconnected.com/integrating-apples-on-device-llm-a-step-by-step-guide-to-foundation-models-47d84a7a347a)).
- Apple Developer Program: $99/year. The free tier can run on your own iPhone but cannot use push notifications, iCloud, App Groups (needed for widgets), or the Family Controls entitlement ([magora](https://magora-systems.com/apple-developer-fee/)).

**Framework map**

| Need | Framework | Key facts and limits |
| --- | --- | --- |
| Reminders | UserNotifications | Local notifications with `UNCalendarNotificationTrigger` (date/time, repeating), `UNTimeIntervalNotificationTrigger`, `UNLocationNotificationTrigger`. Hard OS limit of **64 pending requests per app**; the system keeps the soonest 64 and drops the rest; a repeating request counts as one ([Apple forums](https://developer.apple.com/forums/thread/811171)). Strategy: schedule only the next 7 days and reschedule on launch and in a background task. |
| Snooze / Done buttons on a notification | UNNotificationCategory + UNNotificationAction | Define categories once at launch; handle actions in `UNUserNotificationCenterDelegate`. |
| Calendar and Apple Reminders access | EventKit | Read/write events for time blocking; iOS 17+ offers write-only access that needs no full permission prompt. |
| Persistence | SwiftData (+ CloudKit) | Swift-native models with `@Model`; iCloud sync is a checkbox. Core Data is the older alternative. |
| Widgets | WidgetKit | Home/Lock-screen widgets via `TimelineProvider`; interactive buttons via App Intents (iOS 17+); needs an App Group to share data with the main app. |
| Siri and Shortcuts | App Intents | Expose "Add task", "Start focus", "Plan my day" as intents; they also power interactive widgets and Spotlight. |
| Focus timer on Lock Screen / Dynamic Island | ActivityKit | Set `NSSupportsLiveActivities` = YES, define `ActivityAttributes` with a `ContentState`, use `Text(date, style: .timer)` for a live countdown ([tutorial](https://www.createwithswift.com/implementing-live-activities-in-a-swiftui-app/)). |
| Distraction blocking | FamilyControls + ManagedSettings + DeviceActivity | Requires the Family Controls entitlement (request from Apple for distribution) and a paid account. `ManagedSettingsStore.shield.applications` shields apps at OS level ([Apple forums](https://developer.apple.com/forums/thread/715365)). Blocking must survive force-quit and reboot, so one developer recommends three independent re-blocking paths: shield extension, DeviceActivity monitor, main app ([Habit Doom](https://habitdoom.com/blog/apple-screen-time-api-guide)). Defer to phase 3. |
| Background refresh | BackgroundTasks | `BGAppRefreshTask` to top up the notification queue and recompute the day plan. |
| On-device assistant | Foundation Models (iOS 26) | Free, offline, \~3B-parameter model via `LanguageModelSession`; supports `@Generable` structured output and tool calling; 15 languages at launch and a context-window limit, so check `SystemLanguageModel.default.availability` at runtime ([developer guide](https://rss.boorghani.com/?p=418048), [HackerNoon](https://share.transistor.fm/s/0b175ccc)). Hebrew support should be verified on device before relying on it. |
| Charts | Swift Charts | Declarative bar/line charts for weekly focus minutes and completion rates. |
| Haptics and celebration | CoreHaptics, SwiftUI animations | Custom haptic patterns on completion; particle effects via `Canvas` or a small SpriteKit scene. |
| Apple Watch | watchOS SwiftUI | Optional; start/stop focus and tick tasks from the wrist. |

**Given your background**: Swift's syntax will feel close to Python with types; SwiftUI is declarative like React. The main adjustments are value semantics (structs), optionals, and Swift concurrency (`async/await`, actors), which you will meet immediately in notification and EventKit APIs.

## Part 2B — Designing the four layers

Each of your four goals becomes one module with a clear contract; the cheering layer listens to events from the other three rather than owning any feature of its own.

**1. Reminders layer**

- Store every task with an optional `dueDate`, `remindAt`, `recurrenceRule`, and a one-line `firstAction` ("open the thesis file"). The notification body is the if-then form: "7:00 — open the thesis file. 25 minutes is enough to start."
- A `NotificationScheduler` keeps at most \~50 of the 64 slots: next 7 days of reminders plus a daily planning prompt and an evening review prompt. Reschedule on app launch, on every task edit, and in a `BGAppRefreshTask`.
- Category actions: **Done**, **Snooze 15 min**, **Start focus**. Handle them in the delegate without opening the app.
- Smart snooze: when a reminder is snoozed twice, the assistant offers to move the task instead of nagging again.

**2. Productive layer**

- Daily plan: tasks have a `estimatedMinutes` and `energy` tag (light/deep). The planner reads today's EventKit events, fills free gaps with tasks ordered by deadline and energy, and writes the result as a local timeline (and optionally as calendar events).
- Focus sessions: configurable work/break lengths (default 25/5, adjustable per the 2026 break-timing evidence). Start a Live Activity so the countdown sits on the Lock Screen and Dynamic Island; log `FocusSession(task, start, end, completed)` to SwiftData.
- Evening review: three questions (what got done, what moves to tomorrow, one win). This is the Sunsama ritual, compressed to under a minute.
- Analytics: Swift Charts for focus minutes per day, completion rate per week, and estimated-vs-actual duration per task. The last one is where your ML background can add a simple per-user duration correction in a later phase, but a running median per task category is enough for v1.
- Hard mode (phase 3): shield chosen apps during a focus session via ManagedSettings.

**3. Cheering layer**

- Companion: a small character with a mood state driven by a rolling 7-day effort score, not by consecutive days. The score counts started focus sessions and completed tasks; it decays slowly, so one bad day never flips the mood. Finch's rule applies: the companion never asks for anything.
- Feedback events: task completed (haptic + short confetti), focus session finished (character animation + line of praise), weekly goal reached (new cosmetic for the character). Vary the praise copy from a pool of 40–60 lines so it stays fresh past week three.
- Streak policy: show a "momentum" meter rather than a streak count, and never send a notification about a miss. If you do show streaks, give two free freezes a week; the research shows repairable streaks still motivate.
- Notification tone: morning prompt is an invitation ("Want to plan the day together?"), not a command. Evening prompt leads with the win logged that day.

**4. Assistant layer**

- Natural-language capture: send "gym tomorrow 7am, 45 min" to a `LanguageModelSession` with a `@Generable` `TaskDraft` struct (title, date, duration, energy). On devices without Apple Intelligence, fall back to a regex/date-parser so capture never breaks.
- Plan-my-day: give the model today's events and open tasks as structured input and ask for an ordered plan with reasons; keep the final placement in your own deterministic scheduler so results are explainable and testable.
- Tool calling: register tools so the model can call `addTask`, `moveTask`, `startFocus`, and `createCalendarEvent` (EventKit) in response to chat.
- Cloud option: a Claude or OpenAI API call gives a stronger model and reliable Hebrew, at the cost of a network dependency, per-request cost, and sending task text off device. A sensible split: on-device for capture and praise copy, cloud (opt-in) for the daily plan.

**Privacy**: everything above runs on device except the optional cloud planner. State that plainly in onboarding; it is also a selling point against the web-first AI planners.

## Part 2C — Architecture, roadmap, App Store, learning path

Ship a four-week MVP with reminders, a daily plan, and a focus timer, then add the companion and the assistant; leave Screen Time blocking and Watch for last because each needs an extra entitlement or target.

&#91;embedded content: app architecture · 4 services, 1 store, 5 Apple frameworks\]

Views call the four services; Tasks drives the notification scheduler, Planner drives the assistant, and every service writes to one SwiftData store that the widget and Live Activity read through an App Group.

**Architecture**: MVVM with SwiftUI views, `@Observable` view models, and four service modules (Tasks, Planner, Focus, Companion) behind protocols so each can be unit-tested with an in-memory SwiftData container. A `NotificationScheduler` and an `AssistantService` (Foundation Models, with a parser fallback) sit beside them. A widget extension and a Live Activity share the SwiftData store through an App Group.

&#91;embedded content: roadmap · 5 phases, 5 gates\]

Each phase ends at a gate you can test yourself; the week counts are estimates for a solo developer new to Swift and will stretch if the MVP gate takes longer.

**MVP scope (phase 1)**: tasks with due date and reminder; daily plan view; focus timer with Live Activity; Done/Snooze notification actions; one home-screen widget; local storage only. No sync, no companion, no AI. This is enough to use daily and to learn the three hardest APIs (UserNotifications, EventKit, ActivityKit) early.

**App Store requirements**

- $99/yr Apple Developer Program; TestFlight before submission; budget one or two review rounds on a first release ([magora](https://magora-systems.com/publish-app-on-app-store/)).
- Guideline 5.1.1: privacy policy link in App Store Connect and inside the app; fill the privacy nutrition labels (if everything stays on device, most answers are "no data collected").
- Notifications must not be required for the app to work and must not be used for marketing without consent (Guideline 4.5.4).
- Family Controls entitlement for app blocking must be requested from Apple separately and justified; distribution approval can take weeks ([pub.dev notes](https://pub.dev/documentation/managed_settings_ios/latest)).
- Avoid medical or mental-health claims in the listing; "encouraging" is fine, "treats anxiety" triggers Guideline 1.4 scrutiny.

**Native vs cross-platform**: Flutter and React Native would need native plugins for Live Activities, App Intents, Foundation Models, and Screen Time; the Screen Time plugin on pub.dev is at version 0.1 and iOS-only. With no Android requirement and heavy reliance on these frameworks, native Swift is the shorter path.

**Learning path (in order)**

1. [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui) (Hacking with Swift) — free, project-based; days 1–50 cover everything the MVP needs.
2. Apple's [SwiftUI tutorials](https://developer.apple.com/tutorials/swiftui) and the SwiftData sample.
3. WWDC sessions: "Meet ActivityKit", "Bring widgets to life" (App Intents), "Meet the Foundation Models framework" (WWDC25), "Meet the Screen Time API" (WWDC21/22).
4. Stanford [CS193p](https://cs193p.stanford.edu) for architecture depth once the MVP works.
5. [Create with Swift](https://www.createwithswift.com/implementing-live-activities-in-a-swiftui-app/) and [AppCoda's Foundation Models chapter](https://www.appcoda.com/learnswiftui/swiftui-foundational-model.html) for the two newest frameworks.

## Sources

Pages opened for this report, as of 29 Oct 2026. App prices are as quoted on these pages and change often.

- [AI time blocking apps compared (arahi.ai)](https://arahi.ai/blog/time-blocking-apps-compared)
- [7 best AI daily planner apps 2026 (Krono Prompt)](https://kronoprompt.it.com/blog/7-best-ai-daily-planner-apps-2026/)
- [6 best AI planners (Lindy)](https://www.lindy.ai/blog/ai-planner)
- [Best AI planning assistant apps (Lifestack)](https://lifestack.ai/blog/best-ai-planning-assistant)
- [Best task manager app for iPhone (Lifestack)](https://lifestack.ai/blog/best-task-manager-app-for-iphone)
- [Things 3 vs TickTick pricing (softwares.com)](https://www.softwares.com/compare/things-vs-ticktick)
- [Best task management apps 2026 (Dupple)](https://dupple.com/learn/best-task-management-apps)
- [Finch app review (Headway)](https://makeheadway.com/blog/finch-app-review/)
- [Finch review, neurodivergent perspective](https://neurospicynomnoms.beehiiv.com/p/digital-pet-bestie-for-self-care-610618d407f7afef)
- [Finch alternatives incl. Habitica (habi.app)](https://habi.app/insights/finch-alternatives/)
- [Opal, Forest, Freedom, one sec review analysis (Unstar)](https://unstar.app/vi/blog/opal-forest-freedom-one-sec-jomo-screen-time-apps-ranked-2026)
- [Best focus apps 2026 (Softpicker)](https://softpicker.com/best-focus-apps/)
- [Opal alternatives (Habit Doom)](https://habitdoom.com/blog/opal-alternatives)
- [SoftHabits on the App Store](https://apps.apple.com/app/id6763462911)
- [Streaks research, Silverman (University of Delaware)](https://lerner.udel.edu/seeing-opportunity/lerner-professor-researches-how-streaks-motivate-us/)
- [Productivity apps and self-determination theory (Institute of Network Cultures)](https://networkcultures.org/blog/2026/01/19/baby-please-dont-break-the-streak/)
- [Habit-app comparison with Stawarz 2015 audit (Goals and Progress)](https://goalsandprogress.com/life-goals-program-vs-strides-streaks-productive/)
- [Pomodoro scoping review, BMC Medical Education 2025](https://link.springer.com/article/10.1186/s12909-025-08001-0)
- [Systematic vs self-regulated breaks, 2026 study (PMC)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC13405840/)
- [Implementation intentions summary (ScheduleU)](https://scheduleu.org/?p=133)
- [64 pending notification limit (Apple Developer Forums)](https://developer.apple.com/forums/thread/811171)
- [Screen Time API shielding vs blocking (Apple Developer Forums)](https://developer.apple.com/forums/thread/715365)
- [Apple's Screen Time API, 97-day build log (Habit Doom)](https://habitdoom.com/blog/apple-screen-time-api-guide)
- [Family Controls entitlement notes (pub.dev)](https://pub.dev/documentation/managed_settings_ios/latest)
- [Foundation Models step-by-step guide (Level Up Coding)](https://levelup.gitconnected.com/integrating-apples-on-device-llm-a-step-by-step-guide-to-foundation-models-47d84a7a347a)
- [Developer's guide to Foundation Models in iOS 26](https://rss.boorghani.com/?p=418048)
- [Foundation Models overview, \~3B model (HackerNoon)](https://share.transistor.fm/s/0b175ccc)
- [Live Activities tutorial (Create with Swift)](https://www.createwithswift.com/implementing-live-activities-in-a-swiftui-app/)
- [Apple Developer Program fee and free-tier limits (Magora)](https://magora-systems.com/apple-developer-fee/)
- [Publishing on the App Store, guidelines checked Oct 2026 (Magora)](https://magora-systems.com/publish-app-on-app-store/)
