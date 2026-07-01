# `claude/` — Working documentation for AI agents

This folder documents the work done by Claude (and any future AI agent) on this project.
It exists so that **the next agent can pick up with full context**, and so the human owner
has a readable trail of what was done and why.

## Structure

- **`sessions/`** — One markdown file per prompt/working session, named
  `YYYY-MM-DD-NN-short-title.md` (NN = session number that day). Each file records:
  - **Prompt** — what the user asked (paraphrased).
  - **What was done** — concrete changes (files, commands).
  - **Decisions & why** — any choices made and the reasoning.
  - **State / next steps** — where things stand, what's open.

## How to use this as the next agent

1. Read the root **`CLAUDE.md`** first — it's the high-level overview and conventions.
2. Skim **`docs/`** for architecture and build/release details.
3. Read the latest file(s) in **`sessions/`** to see the most recent work and open threads.
4. Check **`docs/adr/`** for *why* key decisions (framework, architecture) were made.

## Conventions

- Keep `CLAUDE.md` concise — it's auto-loaded into agent context every session.
- Put durable "why" decisions in `docs/adr/` as numbered ADRs.
- Put the per-session narrative here in `sessions/`.
