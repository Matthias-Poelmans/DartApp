# Build & Release

The app ships as a single Android APK that runs fully offline.

## Prerequisites

- Flutter SDK installed (this repo was set up with Flutter at `C:\src\flutter`).
- Android SDK + Java (already present on the dev machine: Java 21, Android SDK).
- Verify with: `flutter doctor`

## Run during development

```sh
flutter run            # launches on a connected device or running emulator
flutter analyze        # static analysis (keep clean)
```

## Build the release APK

```sh
flutter build apk --release
```

Output:

```
build\app\outputs\flutter-apk\app-release.apk
```

For smaller, ABI-specific APKs (optional):

```sh
flutter build apk --split-per-abi
# -> app-armeabi-v7a-release.apk, app-arm64-v8a-release.apk, app-x86_64-release.apk
# Most modern phones use arm64-v8a.
```

## Install on your phone

**Option A — USB (easiest if phone is connected):**

1. Enable Developer Options + USB debugging on the phone.
2. Connect via USB, accept the trust prompt.
3. Run: `flutter install` (or `flutter run` for a debug session).

**Option B — Manual side-load:**

1. Copy `app-release.apk` to the phone (USB transfer, cloud drive, or email).
2. On the phone, open the file and allow "install from unknown sources" if prompted.
3. Open the installed app.

## Notes

- The release APK is **unsigned with a debug key by default** for local use. For Play Store
  distribution you'd configure a proper signing key — out of scope while side-loading.
