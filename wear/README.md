# Runterra Wear OS

Flutter companion app for Runterra running on Wear OS (Android smartwatches).

## Setup

This is a Flutter Wear OS project. The key files are created manually; for a full
compilable project you need to scaffold it with `flutter create` first:

```bash
# From the repo root
flutter create --platforms android --org com.runterra wear_scaffold
# Then replace the lib/ and android/app/src/main/ files with the ones from wear/
```

### Prerequisites

- Flutter SDK with Android toolchain
- Android Studio with Wear OS emulator (or physical Wear OS 3+ device)
- `applicationId` in `android/app/build.gradle` must match the phone app:
  `com.runterra.mobile` (for Wearable Data Layer to work)

## Building

```bash
cd wear
flutter pub get
flutter build apk --debug
```

## Installing on watch via ADB

```bash
adb -s <watch_serial> install build/app/outputs/flutter-apk/app-debug.apk
```

## Testing with emulators

1. Create Wear OS AVD in Android Studio (Small Round, API 30+)
2. Create a Phone AVD (Pixel 5, API 33)
3. Pair them via Device Manager → virtual watch → "Pair with phone"
4. Run phone app: `cd mobile && flutter run`
5. Run watch app: `cd wear && flutter run -d <wear_emulator_id>`
6. Tap Start on watch → run begins on phone
7. Stats appear on watch after 5s broadcast cycle

## Protocol

See `docs/changes/2026-02-24-wear-os-support.md` for full message protocol.

## Deploy Trigger Note

- 2026-03-05: no-op documentation touch to force `deploy-all` to detect wear changes.
