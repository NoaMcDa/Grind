# Standard agent brief

You are one of several agents building the Grind MVP in parallel. You work in your own git worktree on your own branch. The integrator merges.

## Read first (in this order)
1. Your GitHub issue (number given in your task). Its scope checklist and acceptance criteria are the definition of done.
2. `docs/plans/ownership.md` — the folders you may edit. Do not edit anything else.
3. `lib/core/core.dart` and the files it exports — the contracts. Code against the interfaces; use the `InMemory*` / `Fake*` implementations where your dependency has not merged yet.
4. `docs/handoff/HANDOFF.md` (product + visual system) and, if your issue references it, `docs/research/replanning-architecture.md`.
5. `README.md` for how to run things.

## Environment
- Flutter SDK: `export PATH="/tmp/claude-0/-home-user-Grind/70ad071e-9ce9-5596-9fab-1471b67c98ac/scratchpad/sdk/flutter/bin:$PATH"` (Flutter 3.35.5, Dart 3.9). `flutter` warns about running as root; ignore it.
- No Mac, no iOS simulator, no device. iOS-native code is written carefully and left with a test plan for Noa; the Dart side must still analyze and test.
- No backend, no credentials. The app is a pure client; data lives in local storage.
- Network goes through a proxy; `pub get` works. Some sites are blocked.

## Rules
- Only edit paths you own. Shared files (`pubspec.yaml`, `lib/main.dart`, `lib/shell/app_shell.dart`, `lib/core/**`) are integrator-only: write what you need changed in your report.
- Keep the design system: tokens in `lib/theme`, components in `lib/widgets`. No emoji, stroke icons only, 44 px targets, Pip's tone in copy (never guilt).
- Tests are part of the scope. Unit-test pure logic; widget-test screens with `test/test_fonts.dart`'s `loadAppFonts()` in `setUpAll` so layout uses real fonts.
- Small, well-named commits on your branch. Do not rewrite history.

## Before you report
Run all four and make them pass:
```sh
dart format lib test
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```
Then commit, `git push -u origin <your-branch>`, and open a pull request against `main` with title `<type>: <summary> (#<issue>)` and a body containing `Closes #<issue>`, what you built, what you could not verify (e.g. iOS), and any requests for the integrator.

## Report format (your final message, ≤ 15 lines)
- Branch and PR URL
- What is done vs the issue checklist (tick list)
- What is not done and why
- Requests for the integrator (shared-file edits, interface changes, new dependencies)
- Anything the next wave must know
