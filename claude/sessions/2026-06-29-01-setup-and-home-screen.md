# Session 2026-06-29-01 — Project setup & home screen

## Prompt (paraphrased)

The user wants a mobile app for playing **darts games** (the sport) on a real dartboard, with
the phone keeping score. Requirements: single offline Android APK, no backend, multiple game
modes selectable from a home screen. They want all work documented in a `claude/` folder, and
to end with an installable APK. First deliverable: **the home screen / menu only** — games will
be specified and added **one at a time** later.

(Initial misunderstanding: "dart" was first read as the Dart language; clarified to mean the
sport. Framework chosen on merits: Flutter.)

## Decisions

- **Framework: Flutter** — see `docs/adr/0001-framework-flutter.md`.
- **Architecture: minimal + modular, data-driven game registry** — see
  `docs/adr/0002-architecture.md`.
- **Docs: standard `docs/` + ADRs, plus a per-prompt log here in `claude/sessions/`** (combined
  the user's two requests).
- Home screen is **empty of games by design**; games added incrementally.

## What was done

1. **Installed Flutter SDK** (was missing). Shallow-cloned stable to `C:\src\flutter`,
   configured it to use the existing Android SDK (`flutter config --android-sdk`).
   `flutter doctor`: Flutter + Android device OK. Android `cmdline-tools` not installed and
   license status "unknown", but the `android-sdk-license` file is present and build-tools/
   platforms exist (proceeded; install cmdline-tools only if a build fails).
2. **Scaffolded the project** in place:
   `flutter create --org com.poelmans.darts --project-name darts_games --platforms android .`
   Added `go_router`. Updated pubspec description; set Android label to "Darts Games".
3. **Built the home screen** (data-driven):
   - `lib/games/game.dart` — `GameDefinition` model (id, title, description, icon, builder,
     min/maxPlayers, enabled). `route` getter → `/game/<id>`.
   - `lib/games/game_registry.dart` — the list of games (empty, with a commented example).
   - `lib/app/theme.dart` — dark dartboard-inspired theme.
   - `lib/app/router.dart` — go_router; home route + per-game routes generated from the registry.
   - `lib/home/home_screen.dart` — renders cards from the registry; empty-state when none.
   - `lib/home/widgets/game_card.dart` — tappable card (icon, title, description, player count,
     "Coming soon" badge when `enabled == false`).
   - `lib/main.dart` — `DartsGamesApp` using `MaterialApp.router`.
   - Updated `test/widget_test.dart` to a smoke test (title + empty state).
4. **Documentation**: created `CLAUDE.md`, `docs/architecture.md`, `docs/build-and-release.md`,
   ADRs 0001/0002, `claude/README.md`, and this session log.
5. **Verification**: `flutter analyze` → no issues; `flutter test` → passing. Release APK build
   run (see build-and-release.md for output path).

## State / next steps

- Home screen menu is complete and ready. Registry is empty.
- **Next:** the user will describe the first game; implement it under `lib/games/<id>/` and add
  one `GameDefinition` entry to `game_registry.dart`.
- If an Android build ever fails on licenses, install `cmdline-tools` and run
  `flutter doctor --android-licenses` (user accepts interactively).
