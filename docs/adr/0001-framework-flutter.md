# ADR 0001 — Use Flutter for the darts app

**Status:** Accepted
**Date:** 2026-06-29

## Context

The goal is a mobile app to play **darts games** (the sport) on a real dartboard, with the phone
keeping score. Requirements: single Android **APK**, fully **offline**, **no backend**, multiple
selectable game modes, and a rich tappable scoring UI (number pads / dartboard segments).

Candidates considered: Flutter, native Kotlin (Jetpack Compose), React Native.

## Decision

Use **Flutter** (Dart language).

## Rationale

- Single codebase → clean Android APK; can target iOS later with no rewrite.
- Excellent control over custom UI, ideal for scoreboards and tap-to-score number pads.
- Straightforward offline local storage (`shared_preferences` / `hive`).
- No backend needed; everything runs on-device.

Native Kotlin was a strong alternative (already had Android SDK + Java installed) but is
Android-only and more boilerplate. React Native added a heavier toolchain with no benefit for
this UI-heavy, offline use case.

## Consequences

- Must install the Flutter SDK (done; located at `C:\src\flutter`).
- Team works in Dart. (Note: "Dart" here is the programming language, unrelated to the darts
  sport the app is about.)
