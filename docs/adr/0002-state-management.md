# ADR 0002: State management and routing

Status: accepted. Issue: #3.

## Decision

- **State and DI: Riverpod** (`flutter_riverpod`).
- **Routing: `go_router`**, five tabs in a `StatefulShellRoute.indexedStack`.

## Why

- Riverpod gives dependency injection and state in one mechanism. Every
  interface in `lib/core` has a provider in `lib/core/di.dart` whose default is
  an in-memory fake, so any screen runs in a widget test with no platform
  channels, and `main.dart` swaps in real implementations via `overrides`.
- Providers are compile-safe, testable without a widget tree
  (`ProviderContainer`), and streams from repositories (`watchAll`,
  `watchBetween`) become `StreamProvider`s the UI watches directly.
- `go_router` gives URL-based deep links (`/task/:id`, `/focus?taskId=`) that
  notifications, widgets and the web build can open, and `indexedStack` keeps
  each tab's state alive, as the old `IndexedStack` shell did.

## Conventions

Providers
- Interface providers live only in `lib/core/di.dart` (`taskRepositoryProvider`,
  `clockProvider`, ...). Name: `<thing>Provider`.
- Feature providers live in the feature folder, in `<feature>_providers.dart`
  (or `presentation/providers.dart`). Derived values read well as nouns:
  `todayTasksProvider`, `planDayProvider`.
- Live repository data: `StreamProvider` over `watchX`. One-shot queries:
  `FutureProvider`, re-run by `ref.watch`ing the stream provider they depend on.
  Use `.autoDispose` for anything keyed to a screen. Stateful logic with
  actions: `AsyncNotifier`.
- Widgets read with `ref.watch`, act with `ref.read` (never `watch` in a
  callback). Mutations go through repositories, never into widget state.
- Time comes from `clockProvider`, never `DateTime.now()`.

Routing
- Tab paths: `/today`, `/plan`, `/focus`, `/pip`, `/ask`. Deep links outside
  the shell: `/task/:id`. Navigate with `context.go(path)`.
- Router lives in `lib/app/router.dart`; the app root is `GrindApp(overrides:)`.

Errors and logging
- Expected failures are `AppException` subclasses (`lib/app/errors.dart`) with a
  `displayMessage` in Pip's tone. Report with `reportError`; log with
  `log()` from `lib/app/logging.dart`.

Tests
- `pumpGrindApp(tester, overrides:, initialLocation:)` from
  `lib/app/test_app.dart` wires in-memory repositories (seeded with the demo
  day) and a `FixedClock`.

## Feature folder convention

```
lib/features/<name>/
  data/          repository implementations, DTOs, platform adapters
  domain/        pure Dart: entities, use cases, rules (no Flutter imports)
  presentation/  screens, widgets, providers
```

Shared model and interfaces stay in `lib/core`. Existing screens still sit
directly in `lib/features/<name>/`; they move into `presentation/` as each
feature is next touched, not in a bulk refactor.

## Consequences

- Screens must run under a `ProviderScope` (`GrindApp` provides one).
- Riverpod 2.x is used; the 3.x migration is a later, mechanical chore.
