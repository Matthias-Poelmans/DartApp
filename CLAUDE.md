# CLAUDE.md — Darts Games App

> Read this first. It's the high-level map for any AI agent or developer working on this repo.
> Keep it concise; deep detail lives in `docs/` and the per-session log in `claude/sessions/`.

## What this is

An **offline Android app for playing darts games** (the sport — 501/301, Cricket, Around the
Clock, etc.) where the **phone keeps score**. Built with **Flutter**. Distributed as a single
APK. **No backend, no network, fully offline.**

> Note: "Dart" is the programming language Flutter uses. The app is about the **sport** darts.
> These are unrelated — don't confuse them.

## Key facts

- **Framework:** Flutter 3.44.x (Dart). SDK installed at `C:\src\flutter`.
- **Scoring:** manual tap, **pass-and-play**, 1–N local players on one device.
- **State:** plain `setState` per game module. No global state library (see `docs/adr/0002`).
- **Navigation:** `go_router`.
- **Toolchain:** Java 21 + Android SDK already installed. Android SDK at
  `%LOCALAPPDATA%\Android\Sdk` (Flutter configured to use it).

## How games are added (the core pattern)

Games are added **one at a time**, as the user specifies each one. To add a game:

1. Create `lib/games/<id>/` with the game's screen(s) and logic (self-contained).
2. Append one `GameDefinition` to `lib/games/game_registry.dart`.

That's it — the home screen menu and the router are both generated from `game_registry.dart`,
so the new game appears automatically. See `lib/games/game.dart` for the model and
`docs/architecture.md` for the full pattern.

> The registry currently holds three **placeholder** games (Killer, Halve It, Tag Team) that
> open a shared "coming soon" screen — their scoring isn't built yet. The home screen still
> handles an empty registry gracefully via its empty-state.

## Project layout

```
lib/
  main.dart                 # entry: theme + router
  app/router.dart           # go_router (home + per-game routes from the registry)
  app/theme.dart            # light theme built from AppColors (see docs/design-system.md)
  app/colors.dart           # central colour palette (single source of truth)
  app/fonts.dart            # central font families (Bungee display font)
  games/game.dart           # GameDefinition model (the extension point)
  games/game_registry.dart  # <-- ADD GAMES HERE
  games/dartboard.dart      # shared board layout (number order, neighbours)
  games/killer/             # Killer game (see docs/killer-implementation.md)
  games/players/            # shared player-setup + intro flow
  home/splash_screen.dart   # startup splash (logo on white) -> /home
  home/home_screen.dart     # menu rendered from the registry
  home/widgets/game_card.dart
docs/                       # architecture, design-system, build/release, ADRs (the "why")
assets/fonts/               # bundled fonts (Bungee) — kept local for offline use
assets/images/              # bundled images (app logo) — kept local for offline use
claude/sessions/            # one md per prompt/session (the "what happened")
```

## Common commands

```sh
# Put Flutter on PATH first (Git Bash):  export PATH="/c/src/flutter/bin:$PATH"
flutter run                  # run on device/emulator
flutter analyze              # static analysis — keep clean
flutter test                 # run tests
flutter build apk --release  # -> build/app/outputs/flutter-apk/app-release.apk
```

See `docs/build-and-release.md` for installing the APK on a phone.

## Conventions

- Keep everything offline — no HTTP, no connectivity assumptions.
- Each game self-contained under `lib/games/<id>/`.
- Document each working session in `claude/sessions/` and durable decisions as ADRs in
  `docs/adr/`.
