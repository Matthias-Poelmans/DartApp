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
    <game_id>/               # one folder per game, self-contained
  home/
    home_screen.dart         # renders the menu from game_registry
    widgets/game_card.dart   # a single tappable game card
```

## The game-module pattern (how games are added)

Games are added **one at a time**. Each new game is:

1. A new folder `lib/games/<game_id>/` containing that game's screen(s) and logic,
   self-contained (its own scoring state via `setState`).
2. A single `GameDefinition` entry appended to `game_registry.dart` (id, title, description,
   icon, player count, route builder).

The home screen renders itself from `game_registry`, so adding the entry makes the game appear
on the menu automatically. **No central file needs structural changes** beyond that one entry.

> Current status: the home screen / menu is built and empty of games by design. Games will be
> specified by the user one by one and implemented individually.

## Constraints

- **No network.** Nothing in the app should make HTTP calls or require connectivity.
- **Offline persistence** (match history, players) will use a local store (`shared_preferences`
  or `hive`) and is added only when a game needs it.
