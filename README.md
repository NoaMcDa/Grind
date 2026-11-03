# Grind

An encouraging productivity app: calendar + reminders, short- and long-term goals with measurable progress, realistic weekly planning, and a companion (Pip) that cheers instead of nagging. Ships on iOS (App Store) and the web from one Flutter codebase.

An iOS productivity app that syncs with your calendar, sends smart reminders, and tracks short- and long-term goals across learning, investing, fitness and nutrition. See progress as X of Y or weekly counts, get highlights, learn what's realistic this week, and let an encouraging AI assistant help you prioritize.

## Run

```sh
flutter pub get
flutter run -d chrome        # web
flutter run                  # iOS simulator (needs a Mac with Xcode)
flutter test
flutter build web --release  # output in build/web
```

## Where things are

- `lib/theme` — design tokens and typography (the "playful & bold" system)
- `lib/widgets` — sticker cards, pill buttons, momentum meter, Pip
- `lib/shell` — the five-tab shell
- `lib/features/<tab>` — Today · Plan · Focus · Pip · Ask (mock data for now)
- `docs/handoff` — product handoff, market research, mockups and renders
