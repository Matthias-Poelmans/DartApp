# Architecture

## Overview

A fully **offline** Flutter app for scoring **darts games** (the sport) on a real dartboard.
The phone is the scorekeeper. No backend, no network calls. Distributed as a single Android APK.

- **Scoring model:** manual tap, pass-and-play for 1–N local players on one shared device.
- **State management:** minimal — plain Flutter `setState` within each game module. No global
  state library unless a future need justifies it.
- **Navigation:** `go_router`, one route per screen.

## Project layout

```
lib/
  main.dart                  # app entry: theme + router
  app/
    router.dart              # go_router config (home + per-game routes)
    theme.dart               # app-wide theme
  games/
    game.dart                # GameDefinition model — the single extension point
    game_registry.dart       # the list of available games  <-- add a game here
    players/                 # shared pre-game flow (see below)
      player_setup_screen.dart # add/remove players, gates Play
      game_intro_screen.dart   # animated "reveal" before the game
      player_avatar.dart       # person + dart-accent avatar (shared)
      player_roster.dart       # caches the roster (shared_preferences)
    <game_id>/               # one folder per game, self-contained
  home/
    splash_screen.dart       # startup splash -> /home
    home_screen.dart         # renders the menu from game_registry
    widgets/game_card.dart   # a single tappable game card
```

## The player-setup flow (shared by every game)

Every game passes through the **same** pre-game screen before it starts, so setup lives once in
`lib/games/players/` rather than in each game:

- Route shape (generated from the registry in `router.dart`, so games get it for free):
  `/game/<id>` → `PlayerSetupScreen`; nested `/game/<id>/intro` → `GameIntroScreen`; nested
  `/game/<id>/play` → the game itself (`game.builder`).
- **Setup** (`player_setup_screen.dart`): game title, the player list in an `AnimatedList`
  (each row = person avatar + dart accent + remove), a yellow **Add player** button beneath the
  list (dialog with a focused text field → keyboard), and a **Play** bar. Removing a player
  plays a red exit animation; adding animates the new row in.
- **Play gate:** enabled only when the player count is within the game's `minPlayers`–
  `maxPlayers` (currently 3–8 for all games). Pressing Play caches the roster and pushes the
  intro, passing the players via the route's `extra`.
- **Intro** (`game_intro_screen.dart`): a full-yellow screen with the title in blue; each player
  pops in one by one, placed in shuffled, non-overlapping grid cells below the title. Once all
  are in, a blue **Play** button pops in and pulses toward bright white; tapping it
  `pushReplacement`s to the game.
- **Roster caching:** `PlayerRoster` persists the names via `shared_preferences`, so setup
  auto-fills them at the next game's startup (survives app restarts). One shared roster across
  all games.

## The game-module pattern (how games are added)

Games are added **one at a time**. Each new game is:

1. A new folder `lib/games/<game_id>/` containing that game's screen(s) and logic,
   self-contained (its own scoring state via `setState`).
2. A single `GameDefinition` entry appended to `game_registry.dart` (id, title, description,
   icon, player count, route builder).

The home screen renders itself from `game_registry`, so adding the entry makes the game appear
on the menu automatically. **No central file needs structural changes** beyond that one entry.

> Current status: the menu lists three placeholder games (Killer, Halve It, Tag Team). They run
> through the real player-setup flow, then open a "coming soon" screen — their scoring logic is
> implemented later, one game at a time.

## Constraints

- **No network.** Nothing in the app should make HTTP calls or require connectivity.
- **Offline persistence** (match history, players) will use a local store (`shared_preferences`
  or `hive`) and is added only when a game needs it.
