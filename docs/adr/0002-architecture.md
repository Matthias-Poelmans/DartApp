# ADR 0002 — Minimal, modular, data-driven game architecture

**Status:** Accepted
**Date:** 2026-06-29

## Context

The app will host multiple darts game modes, added **incrementally one at a time**. We need an
architecture that keeps each game isolated, makes adding a game trivial, and avoids premature
complexity.

## Decision

- **State management:** plain Flutter `setState` scoped within each game module. No global state
  library (Riverpod/Provider/Bloc) until a concrete need arises.
- **Navigation:** `go_router`, one route per screen.
- **Game registration:** a **data-driven registry**. Each game is described by a
  `GameDefinition` and listed in `game_registry.dart`. The home screen renders its menu from
  that list.

## Rationale

- Lowest friction to start and to add games one by one.
- Each game is self-contained → easy to reason about, test, and remove.
- The home screen never needs editing to add a game — just append a `GameDefinition`.

## Consequences

- Adding a game = new `lib/games/<id>/` folder + one entry in `game_registry.dart`.
- If a game later needs complex shared/persistent state, that game can adopt a heavier pattern
  locally without forcing it on the rest of the app. Revisit a global solution only if multiple
  games converge on the same need.
