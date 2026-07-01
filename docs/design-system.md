# Design System

The visual language of Dartillect: colours, typography, and component styling.
Everything here has a **single source of truth in code** — change the constant, and it
updates everywhere. Do not hard-code hex values or font names in widgets; reference the
central definitions instead.

## Colours — `lib/app/colors.dart`

All colours are defined once in `AppColors` and flow through the app in two ways:

- Most widgets read them indirectly via `Theme.of(context).colorScheme.*` (wired up in
  `lib/app/theme.dart`).
- Where a specific brand colour is needed directly, widgets reference `AppColors.*`.

| Constant | Hex | Role |
|----------|-----|------|
| `AppColors.blue` | `#1B4965` | Primary — app bar, titles, icons on the yellow badge |
| `AppColors.yellow` | `#FFC857` | Accent — game icon badges, "Coming soon" chip |
| `AppColors.softWhite` | `#F5F3EE` | Scaffold background (warm off-white, not pure white) |
| `AppColors.surface` | `#FFFFFF` | Cards |
| `AppColors.ink` | `#14202B` | Primary text |
| `AppColors.inkMuted` | `#5A6B78` | Secondary / subtitle text |

## Typography — `lib/app/fonts.dart`

- **`AppFonts.display` = `Bungee`** — the chunky display font used for the app name
  ("Dartillect"), the home "Choose a game" heading, and each game's title. Bungee is
  **bundled locally** at
  `assets/fonts/Bungee-Regular.ttf` and declared in `pubspec.yaml` so the app stays fully
  offline (no runtime font fetch). Bungee ships a single regular weight — don't apply
  `FontWeight.bold` to it; adjust size / letter-spacing instead.
- **Body text** uses the Material default via the theme's text theme, coloured `AppColors.ink`.

## Theme — `lib/app/theme.dart`

`AppTheme.light` builds a Material 3 light theme entirely from `AppColors`:

- `scaffoldBackgroundColor` = soft white; `ColorScheme` seeded from blue with yellow as
  secondary.
- **App bar:** blue background, soft-white foreground, centred.
- **Cards:** 20px rounded corners, white surface, a subtle blue-tinted shadow. No sharp
  90° corners anywhere.

Applied once in `lib/main.dart` via `theme: AppTheme.light`.

## Startup / splash

On launch the app opens on a **splash screen** (`lib/home/splash_screen.dart`): the Dartillect
logo centred on a plain white background. After `SplashScreen.duration` (3.2s) it navigates to
the games overview. Routing: `/` = splash → `/home` = overview (`lib/app/router.dart`).

- The logo is bundled at **`assets/images/dartillect_logo.png`** (declared in `pubspec.yaml`),
  keeping the app fully offline.
- The launcher **app name** is `Dartillect` (`android:label` in
  `android/app/src/main/AndroidManifest.xml`).
- The launcher **icon** is generated from the same logo via `flutter_launcher_icons` (config in
  `pubspec.yaml`; brand-blue adaptive background). Regenerate with
  `dart run flutter_launcher_icons` after changing the logo.

## Components

- **Game card** (`lib/home/widgets/game_card.dart`): rounded white card, yellow circular
  icon badge with a blue icon, game title in Bungee (blue), muted description, chevron.
  Disabled games are dimmed and show a yellow "Coming soon" chip.
- **Home header** (`lib/home/home_screen.dart`): a blue "Choose a game" heading above the
  list.
- **Placeholder game screen** (`lib/games/placeholder/placeholder_game_screen.dart`): shared
  "coming soon" screen for games whose scoring isn't built yet; title in Bungee.

## Adding to the palette or type scale

1. Add the constant to `AppColors` / `AppFonts`.
2. If it's a semantic role (primary, accent, …), wire it into the `ColorScheme` in
   `theme.dart` so widgets can read it via `colorScheme`.
3. Reference the constant from widgets — never a raw hex or family string.
