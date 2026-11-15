# Audit 04 — OTA Updater & Release Pipeline

## Findings

### OTA-01 — Version comparison is correct for the current scheme
- **Severity:** Info
- **Evidence:** `ota_service.dart:139` compares `versionCode` (int) remote vs `PackageInfo.buildNumber` local; `remoteCode <= localCode` → no update. Equal versions and downgrades correctly ignored. Malformed manifest → `json.decode`/`as num` throws inside try → returns null (silent, acceptable). Missing manifest fields default safely (`mandatory:false`, empty strings). Cache timestamp saved only after successful parse — verified.
- **Note:** `versionName` is never compared — only `versionCode`. Correct choice.

### OTA-02 — Download path is robust
- **Severity:** Info
- **Evidence:** `background_downloader` task with `retries: 3`, `allowPause`, foreground-service notification; `OtaService.initialize()` re-attaches to in-flight tasks after process death; cancel path (`cancelDownload`) cancels task + notification + resets state (added in v1.9.10, verified); completed-file reuse verifies size+sha256 before offering install; size and SHA-256 both verified in `_onComplete`, bad files deleted.
- **Residual:** see SEC-04 — `dir` null edge case and unguarded `_sha256OfFile`.

### OTA-03 — Package-name migration is historical, not current
- **Severity:** Info
- **Evidence:** `applicationId`/`namespace` = `com.kornellaotf.learn_dha_anywaa` (`android/app/build.gradle:33,52`); MainActivity.kt matches; google-services.json `package_name` matches. Old package `com.bellaTech.dha_anywaaa` documented in `docs/RELEASE_NOTES_v1.2.26.md` — users on the OLD package cannot OTA (Android blocks cross-package install) and must reinstall once; this was a deliberate, documented one-time migration. No stale references to the old package remain in Gradle/manifest/Kotlin.
- **Caveat:** `docs/RELEASE_NOTES_v1.2.26.md` is the only place the old name appears — fine.

### OTA-04 — Release pipeline sync verified for v2.0.2
- **Severity:** Info
- **Evidence:** `pubspec.yaml` `version: 2.0.2+2202`; built APK `versionCode='2202' versionName='2.0.2'` (aapt verified); `manifest.json` versionCode 2202, sha256 `44c39346…` matches GitHub asset digest `sha256:44c39346…` exactly; `releases/latest/download/manifest.json` serves 2.0.2. Tag v2.0.2 pushed; commit `09d2839`.
- **Historical note:** v1.9.10's hosted APK digest did NOT match its manifest sha256 (same size, different hash — likely a stale asset). Superseded by 2.x; recommend not relying on the v1.9.10 tag for rollback.

### OTA-05 — Signing config present but depends on local keystore
- **Severity:** Low
- **Evidence:** `build.gradle:61-77` release signing from `android/key.properties` + `upload-keystore.jks` (both gitignored — good). If the keystore is lost, OTA updates become impossible forever (signature mismatch). No backup/CI signing documented in repo.
- **Fix:** Document keystore backup procedure in RELEASE.md; consider Play App Signing if ever distributed via Play.

### OTA-06 — `minifyEnabled`/`shrinkResources` ON with hand-written keep rules
- **Severity:** Low
- **Evidence:** `proguard-rules.pro` keeps Flutter/Firebase/audioplayers + `Signature`/`*Annotation*` attributes. Groq/http/shared_preferences are pure Dart (unaffected by R8). Risk is low but a missing keep rule would break silently at runtime — recommend a smoke test of release APK covering: AI chat, OTA download, notifications, audio playback.

## Summary table

| ID | Severity | Area |
|----|----------|------|
| OTA-01..04 | Info | Version/download/install/pipeline all verified working |
| OTA-05 | Low | Keystore loss = permanent OTA death |
| OTA-06 | Low | R8 keep-rule coverage unverified on device |

## Top fixes
1. Smoke-test the v2.0.2 release APK end-to-end on a real device (AI chat + OTA + notifications + audio).
2. Back up `upload-keystore.jks` + `key.properties` somewhere safe and document it.
