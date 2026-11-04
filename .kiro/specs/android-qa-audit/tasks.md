# Implementation Plan: Android QA Audit

## Overview

Automated four-phase QA audit pipeline for the **Learn Dha Anywaa** Flutter app
(`com.kornellaotf.learn_dha_anywaa`) at `/home/kornella/Dha-Anywaa-application`.
All output is confined to `audit/` and `scripts/`. Source files are read-only.
No property tests. No optional tasks.

---

## Tasks

- [ ] 1. Create directory structure and scripts/lib.sh
  - Run `mkdir -p scripts/ audit/screens/` inside `/home/kornella/Dha-Anywaa-application`
  - Write `scripts/lib.sh` with:
    - `check_write_path()`: resolves the target to an absolute path; aborts with exit 2 if the resolved path is outside `audit/` or `scripts/` directories
    - `rg_or_grep()`: uses `rg -n` if available, falls back to `grep -rn`
    - `log()` helper: prints `[audit] <message>` to stdout
    - `die()` helper: prints `[audit] ERROR: <message>` to stderr, exits 1
    - Export `REPO_ROOT`, `AUDIT_DIR`, `SCRIPTS_DIR` pointing to their respective absolute paths under `/home/kornella/Dha-Anywaa-application`
  - _Requirements: 11.1, 11.2_

- [ ] 2. Implement scripts/build_check.sh
  - Source `lib.sh` at top of script
  - Change to `/home/kornella/Dha-Anywaa-application` before running Flutter
  - Run: `flutter build apk --debug 2>&1 | tee /tmp/_dha_build_full.txt`; capture `BUILD_EXIT=${PIPESTATUS[0]}`
  - Call `check_write_path` for `audit/build_output.txt`; write `tail -80 /tmp/_dha_build_full.txt > audit/build_output.txt`; remove `/tmp/_dha_build_full.txt`
  - If `BUILD_EXIT != 0`: extract the first error line from `audit/build_output.txt` as citation; print error to stderr; exit `$BUILD_EXIT`
  - If `BUILD_EXIT == 0`: verify APK at `build/app/outputs/flutter-apk/app-debug.apk`; log APK size via `du -h`
  - Exit with `$BUILD_EXIT`
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 3. Implement scripts/static_analysis.sh
  - Source `lib.sh` at top of script
  - Emit all 12 pre-confirmed findings to `audit/findings.json` as a JSON array using `python3 -c` to write valid JSON (no `jq`):
    - `BUILD-001` P1: `android/build.gradle:2` — Kotlin version conflict (`ext.kotlin_version = '1.8.0'` vs hardcoded `kotlin-gradle-plugin:1.9.22` at line 13); fix: remove `1.9.22` classpath line
    - `BUILD-002` P2: `android/build.gradle` — duplicate `classpath 'com.android.tools.build:gradle:8.2.2'` declarations; fix: remove one
    - `BUILD-003` P1: `android/app/build.gradle:36` and `:49` — duplicate `defaultConfig` blocks; fix: merge into one
    - `BUILD-004` P1: `android/app/build.gradle:24` and `:36` — duplicate `compileSdk` declarations (`flutter.compileSdkVersion` + hardcoded `34`); fix: remove hardcoded `compileSdk 34`
    - `BUILD-005` P1: `android/app/build.gradle:37` and `:51–52` — conflicting `targetSdk 34`, `targetSdkVersion 33`, and `targetSdkVersion flutter.targetSdkVersion`; fix: single `defaultConfig`, keep only `targetSdkVersion flutter.targetSdkVersion`
    - `SEC-001` P1: `android/app/src/main/AndroidManifest.xml` — `android:allowBackup` absent (run `grep -q android:allowBackup` to confirm absence; record absence as citation); fix: add `android:allowBackup="false"`
    - `SEC-002` P2: `android/app/src/main/AndroidManifest.xml:3` — `INTERNET` permission declared but no `res/xml/network_security_config.xml` exists; fix: create config file, reference via `android:networkSecurityConfig`
    - `SEC-003` P2: `lib/home_page.dart` — `launchUrl()` called without confirmation dialog (grep for line number and record it as citation); fix: show `AlertDialog` before `launchUrl`, handle `PlatformException`
    - `DART-001` P1: `lib/pages/page1.dart:100` and `:115` — `(await player.getDuration()) as int` throws `TypeError` at runtime; fix: `(await player.getDuration())?.inMilliseconds ?? 0`
    - `DART-002` P1: `lib/home_page.dart:~93` — `bool themeValue = false` dead variable; `lib/main.dart:29–31` has no `darkTheme:` property; fix: remove or wire to `SharedPreferences` + `ThemeMode`
    - `UI-001` P2: `lib/home_page.dart:~220–250` — `GestureDetector` phone-grid cards lack `Semantics`; fix: wrap with `Semantics(label: '${anyName} — ${engName}')`
    - `UI-002` P2: `lib/pages/page1.dart:~170` — `TextButton` alphabet letters have no `Semantics` label; fix: wrap with `Semantics(label: '${capitalLetter} ${smallLetter}')`
  - Run supplemental greps for UNVERIFIED items; append results to `audit/findings.json`:
    - `rg_or_grep 'darkTheme' lib/` — expect 0 matches → UNVERIFIED `dark_mode`; record command + raw output as citation
    - `rg_or_grep 'firebase_messaging\|flutter_local_notifications' pubspec.yaml` — expect 0 matches → UNVERIFIED `notifications`; record command + raw output as citation
    - `rg_or_grep 'Connectivity\|sqflite' lib/` — expect 0 matches → UNVERIFIED `offline_mode`; record command + raw output as citation
  - Call `check_write_path` before writing `audit/findings.json`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 4.1, 4.2, 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 7.1, 7.2, 7.3, 7.4_

- [ ] 4. Implement scripts/screen_capture.sh
  - Source `lib.sh` at top of script
  - **Hard stop**: run `adb devices`; if no line matches `<serial>\tdevice` pattern → print `ERROR: No ADB device connected. Connect your phone and re-run.` to stderr → exit 1; no fallback, no UNVERIFIED placeholders
  - Capture `ADB_SERIAL` from the first connected device line
  - Install APK: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`; if APK not found → exit 1 with error
  - Initialise `audit/screens/manifest.json` as empty JSON array using `python3 -c` (call `check_write_path` first)
  - For each of 19 screens × 3 conditions = 57 slots:
    - Named-route screens (15): `root`, `number`, `alphabet`, `word`, `shape`, `reading`, `quiz`, `home_page`, `name_entry`, `colors`, `body`, `fish`, `animal`, `bird`, `clothes`
    - Drawer-only screens (4): `vowel_letter`, `body_widget`, `about`, `help`
    - Conditions: `standard`, `dark`, `font_1_3`
  - Per-slot capture procedure:
    - `standard`: navigate via `adb shell am start -n com.kornellaotf.learn_dha_anywaa/.MainActivity`; sleep 1.5s
    - `dark`: `adb shell cmd uimode night yes` before capture; `adb shell cmd uimode night no` after
    - `font_1_3`: `adb shell settings put system font_scale 1.3` before capture; `adb shell settings put system font_scale 1.0` after
    - Capture: `adb -s $ADB_SERIAL shell screencap -p /sdcard/tmp_cap.png`
    - Call `check_write_path` for `audit/screens/<screen>_<condition>.png`
    - Pull: `adb -s $ADB_SERIAL pull /sdcard/tmp_cap.png audit/screens/<screen>_<condition>.png`
    - Cleanup: `adb -s $ADB_SERIAL shell rm /sdcard/tmp_cap.png`
    - Compute `bytes` via `wc -c < audit/screens/<screen>_<condition>.png`
    - Append entry to `audit/screens/manifest.json`: `{ "screen", "condition", "file", "timestamp" (ISO-8601 UTC), "device_serial", "bytes" }`
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8, 9.9_

- [ ] 5. Implement scripts/report_generator.py
  - Load `audit/findings.json`; drop any finding object whose `citation` field is empty or missing
  - Load `audit/screens/manifest.json` if it exists; if absent treat all 57 screenshot slots as PARTIAL
  - Read `BUILD_EXIT` from environment; if not set, infer from presence of error keywords in `audit/build_output.txt`
  - Generate `audit/AUDIT.md` with sections in this exact order (use `check_write_path` equivalent via Python path check before writing):
    1. `## Top 5 Fixes First` — sort all findings P0→P1→P2; take first 5; if `BUILD_EXIT != 0` insert a synthetic P0 `BUILD-FAIL` entry (first error line from `audit/build_output.txt` as citation) at position 1; each entry includes: tier label, finding ID, one-line description, file:line citation, exact remediation
    2. `## Build Result` — embed full contents of `audit/build_output.txt`, exit code, APK path and size (if build succeeded)
    3. `## Build Configuration Findings` — table with columns Finding | Tier | Description | Citation | Fix; rows for BUILD-001 through BUILD-005
    4. `## Security Findings` — table for SEC-001 through SEC-003 in priority order; note `MainActivity android:exported=true` with explicit intent-filter as EXPECTED (not a finding)
    5. `## Dart / Runtime Findings` — table for DART-001 and DART-002
    6. `## UI / Accessibility Findings` — table for UI-001 and UI-002
    7. `## Feature Status` — table with columns Feature | Status | Evidence | Citation; apply `resolve_status()`: return BROKEN if feature has a known-broken finding (DART-001, DART-002); return PARTIAL if build failed or no screenshot; return WORKING only if corresponding `_standard.png` exists with `bytes > 0`; cover all 9 features from the design baseline
    8. `## Settings Audit` — table with columns Setting | Persistence | Write (file:line) | Read (file:line) | Expected | Status | Citation; hard-coded 3 rows: User Name (PARTIAL), themeValue/Theme toggle (BROKEN), All others (UNVERIFIED with grep evidence)
    9. `## Screenshot Coverage` — table of all 57 slots (screen × condition) showing file path, bytes, and captured/missing status
    10. `## What I Could NOT Verify and Why` — one entry per UNVERIFIED feature listing the grep command run and its full raw output
  - Generate `audit/gallery.html`:
    - Valid HTML5 `<!DOCTYPE html>`; all styles in a `<style>` block inside `<head>`; no external CDN or network resource references
    - Group images by screen name using `<h2>` section headings (19 sections)
    - 3 condition slots per screen = 57 image slots total
    - For each slot: if PNG exists and `bytes > 0` → render `<img src="screens/<file>" alt="<screen>_<condition>">`; otherwise render `<p class="placeholder">Screenshot not available — adb device not connected.</p>`
    - Image `src` paths are relative from `audit/gallery.html` (e.g., `screens/alphabet_standard.png`)
  - _Requirements: 1.1, 1.4, 1.5, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 9.7, 9.8, 9.9, 10.1, 10.2, 10.3, 10.4_

- [ ] 6. Implement scripts/audit_runner.sh and wire lib.sh into all scripts
  - Check `python3` is available; call `die()` if not found
  - Run `mkdir -p audit/screens` to ensure output directories exist
  - Initialise `audit/findings.json` as empty JSON array `[]` using `python3 -c` before Phase 2
  - **Phase 1**: `bash scripts/build_check.sh`; capture `BUILD_EXIT=$?`; `export BUILD_EXIT`
  - **Phase 2**: `bash scripts/static_analysis.sh`
  - **Phase 3**: if `BUILD_EXIT != 0` → `log "Screen capture skipped — build failed"`; else `bash scripts/screen_capture.sh`
  - **Phase 4**: `python3 scripts/report_generator.py`
  - On success: print absolute paths of `audit/AUDIT.md` and `audit/gallery.html`
  - Verify each sub-script (`build_check.sh`, `static_analysis.sh`, `screen_capture.sh`) begins with `source "$(dirname "$0")/lib.sh"` — add the line if missing
  - _Requirements: 2.5, 2.6, 9.9, 11.1_

- [ ] 7. End-to-end validation checkpoint
  - Run `bash scripts/audit_runner.sh` from `/home/kornella/Dha-Anywaa-application`; confirm it exits without unexpected errors
  - Open `audit/AUDIT.md`; confirm `## Top 5 Fixes First` heading appears at a byte offset strictly before every other `## ` heading in the file
  - Confirm all 12 finding IDs (BUILD-001, BUILD-002, BUILD-003, BUILD-004, BUILD-005, SEC-001, SEC-002, SEC-003, DART-001, DART-002, UI-001, UI-002) appear in `audit/AUDIT.md` with non-empty citation fields
  - Confirm `audit/build_output.txt` is non-empty and contains the last 80 lines of `flutter build apk --debug` output
  - Test ADB hard-stop: run `bash scripts/screen_capture.sh` with no device connected; confirm exit code is 1 and stderr contains `ERROR: No ADB device connected. Connect your phone and re-run.`
  - Confirm no file was written outside `audit/` or `scripts/` directories (inspect `check_write_path` invocations or run `find /home/kornella/Dha-Anywaa-application -newer audit/AUDIT.md -not -path '*/audit/*' -not -path '*/scripts/*'`)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 8.1, 9.1, 11.1, 11.2_

---

## Notes

- No optional tasks — all tasks are required
- No property-based tests — only end-to-end validation
- Target project: `/home/kornella/Dha-Anywaa-application` (package `com.kornellaotf.learn_dha_anywaa`)
- Source files under `/home/kornella/Dha-Anywaa-application` are read-only; scripts may only write to `audit/` and `scripts/`
- Use `python3 -c` for all JSON generation; `jq` is not required
- `rg_or_grep()` uses `rg -n` when available, falls back to `grep -rn`
- Each script must source `lib.sh` and call `check_write_path` before every file write

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1"] },
    { "id": 1, "tasks": ["2", "3"] },
    { "id": 2, "tasks": ["4"] },
    { "id": 3, "tasks": ["5"] },
    { "id": 4, "tasks": ["6"] },
    { "id": 5, "tasks": ["7"] }
  ]
}
```
