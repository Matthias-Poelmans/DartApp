# Killer — implementation notes

How the Killer game (rules in `docs/game-explanations/killer.md`) is built.

## Files

- `lib/games/dartboard.dart` — shared board geometry: the 20 numbers in clockwise
  order and neighbour/`firstAvailable`/`alternatives` helpers (used to resolve duplicate
  number picks by walking to the nearest free wedge).
- `lib/games/killer/killer_models.dart` — `KillerPlayer` and `KillerRules` (pure,
  side-effect-free life/rank math) plus the `Multiplier` enum. Unit-tested.
- `lib/games/killer/killer_game_screen.dart` — the screen and all phases/UI.

The game is reached through the normal flow: home → player setup → intro → `game.builder`,
which is now `KillerGameScreen`. It loads the players from `PlayerRoster` (the roster cached
when Play was pressed).

## Phases (`_Phase`)

1. **assigning** — each player throws one dart (non-dominant hand) to claim a number.
   - Free number → assigned. Taken number → pick the nearest free wedge each way
     (`Dartboard.alternatives`, a dialog when the two differ).
   - **Bull** → deferred (`_pendingBull`). **Miss** → up to 3 attempts, then deferred
     (`_pendingFailed`).
2. **resolving** — deferred players choose any remaining number: Bull players first in
   random order, then missed players. (The "group decides" step is modelled as a free pick.)
3. **playing** — turn order = players sorted by assigned number ascending; dead players are
   skipped. The **scoreboard is fixed and never scrolls** (rows share the height evenly); the
   input board is pinned beneath it. The current turn shows its 3 darts **horizontally**.
   - The input body has **two parts**: a swappable **scoring section** on top and a shared
     **`_BullMissControls`** (Bull/D-Bull row + full-width Miss) pinned below. Only the scoring
     section changes when a player toggles Killer state; Bull/Miss stay identical and in place.
   - **Non-Killer scoring (`_NonKillerScore`):** three big Single/Double/Triple buttons for the
     player's *own* number (the only number they can score on).
   - **Killer scoring (`_KillerScore`):** a Single/Double/Triple selector plus only the
     **numbers that have an effect** (alive players' numbers), spread max 4 per row.
   - Bull/D-Bull grant +1/+2 lives for a non-Killer and act as the remove-lives joker for a
     Killer; the label is neutral so the control is identical in both states.
   - After the 3rd dart the turn **auto-advances** (short pause, `_autoAdvanceDelay`).
     A single **◂ Back** control handles corrections: if any dart has been entered this turn it
     erases the last one; with none entered it steps back to the previous player's turn (restoring
     the state at its start). A per-turn snapshot stack backs both.
   - The input body has a **fixed height** (`_GameInput._bodyHeight`) so it never grows/shrinks
     between turns; during the between-turns pause it shows a centred three-dot loader instead of
     collapsing.
4. **finished** — when only one player is alive, the winner screen shows.

## Rule math (`KillerRules`)

- **Killer status is dynamic**, not sticky: `KillerPlayer.isKiller` is a getter, `lives == 5`.
  A player is a Killer exactly while at the 5-life cap. If a Killer is hit and drops below 5,
  they immediately stop being a Killer and go back to gaining lives on their own number. This
  keeps the two states' scoring consistent — the only switch is whether lives are at the cap.
- **Gain** (own number, while not a Killer): `single/double/triple = +1/+2/+3`, bounces off the
  5-life cap (`4 + triple → 3`). Landing on exactly 5 makes the player a Killer.
- **Damage** (Killer attacks, being hit, or a Killer hitting their own number): `-1/-2/-3`,
  bounces off 0 (`1 - 3 → 2`); exactly 0 = death, number removed from play.
- Because a Killer always sits at exactly 5 lives, a self-hit (`5 - 1/2/3 = 4/3/2`) can never
  reach 0, so there's **one** `damage` function — no separate self-damage rule. A Killer's own
  number simply costs lives (dropping them out of Killer status), and Bull acts as a joker to
  remove lives from a chosen opponent.

> Note: `killer.md`'s "Hitting Yourself as a Killer" example says a Killer at 2 lives that hits a
> triple on themselves "returns to 5 Lives". Under the dynamic model a Killer is never at 2 lives
> (they'd no longer be a Killer), so this case doesn't arise; the consistent **Exact Zero** bounce
> rule governs everywhere.
