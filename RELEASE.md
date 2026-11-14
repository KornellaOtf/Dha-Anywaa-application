# Release & OTA Update Process

How to build, tag, and ship a release for Dha Anywaa.

## Versioning

`pubspec.yaml` holds `version: <name>+<code>`, e.g. `1.9.2+2188`.

- **versionName** (`1.9.2`) — shown to users.
- **versionCode** (`2188`) — internal integer. Android requires it to be
  **strictly higher** than any versionCode already installed, or the update
  is rejected (`INSTALL_FAILED_VERSION_DOWNGRADE`).

> **Important:** versionCodes in the wild are already in the 2180s (a build
> shipped outside this repo used 2186). Always bump above the highest code
> known to be installed — currently **2188**. Do not drop back to the old
> `+18x` scheme or devices with newer builds cannot update.

## Build

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk (~91 MB)
```

## Release checklist

1. Bump `version:` in `pubspec.yaml`.
2. `flutter build apk --release`
3. Copy APK: `cp build/app/outputs/flutter-apk/app-release.apk .tmp_apk/dha-anywaa-vX.Y.Z.apk`
4. Update `manifest.json` (see below), commit, tag `vX.Y.Z`, push.
5. `gh release create vX.Y.Z .tmp_apk/dha-anywaa-vX.Y.Z.apk manifest.json --title "vX.Y.Z" --notes "..."`
6. **Both assets are required**: the APK *and* `manifest.json`. OTA reads
   `releases/latest/download/manifest.json` — without it, no device sees
   the update.

## manifest.json (OTA)

`ota_service.dart` fetches
`https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest/download/manifest.json`
on home-screen load, cached for **6 hours** (`_cacheTtlMs`). Settings →
"Check for updates" bypasses the cache (`forceCheck: true`).

Fields:

```json
{
  "version": "1.9.2",
  "versionCode": 2188,
  "apkUrl": "https://github.com/KornellaOtf/Dha-Anywaa-application/releases/download/v1.9.2/dha-anywaa-v1.9.2.apk",
  "sha256": "<sha256 of the APK>",
  "sizeBytes": <bytes>,
  "minSupportedVersionCode": 1,
  "mandatory": false,
  "releaseNotes": "See release notes on GitHub.",
  "developer": "Kornella Otf"
}
```

- `versionCode` must exceed the installed build or OTA reports "no update".
- `mandatory: true` forces the update path; `false` is a soft notification.
- `releases/latest` resolves to the most recently created release — creating
  a new release automatically retargets OTA.

## Installing on a test device

```bash
adb install -r .tmp_apk/dha-anywaa-vX.Y.Z.apk
```

Fails with `INSTALL_FAILED_VERSION_DOWNGRADE` if the phone has a higher
versionCode — bump and rebuild instead of uninstalling (keeps user data).

## Useful checks

```bash
flutter analyze                 # static analysis
flutter test test/anywaa_ai_test.dart  # Anywaa AI service tests
adb devices -l                  # attached devices
adb shell dumpsys package com.kornellaotf.learn_dha_anywaa | grep version
```
