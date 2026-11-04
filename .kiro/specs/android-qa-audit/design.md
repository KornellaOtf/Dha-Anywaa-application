# Design Document — Android QA Audit

## Overview

The Android QA Audit is a four-phase automated pipeline that produces structured,
evidence-gated quality findings for the **Learn Dha Anywaa** Flutter app
(`com.kornellaotf.learn_dha_anywaa`) at `/home/kornella/Dha-Anywaa-application`.

The pipeline is orchestrated by a single entry-point shell script (`scripts/audit_runner.sh`)
that calls three specialist scripts in sequence and then invokes a Python report generator.
All output is confined to the `audit/` directory. Source files are treated as read-only.

---

## Architecture

```
audit_runner.sh
  │
  ├─── Phase 1: build_check.sh
  │        flutter build apk --debug 2>&1 | tee /tmp/_dha_build_full.txt
  │        writes last 80 lines → audit/build_output.txt
  │        sets BUILD_EXIT; gates Phase 3 on exit 0
  │
  ├─── Phase 2: static_analysis.sh
  │        emits pre-confirmed findings (no grep needed for confirmed findings)
  │        runs supplemental greps for UNVERIFIED items
  │        writes structured findings data for report_generator.py
  │
  ├─── Phase 3: screen_capture.sh   (skipped if BUILD_EXIT ≠ 0)
  │        adb devices hard-stop check (EXIT 1 if no device)
  │        19 screens × 3 conditions → 57 PNG files → audit/screens/
  │
  └─── Phase 4: report_generator.py
           reads audit/build_output.txt
           reads findings data from Phase 2
           reads audit/screens/ for screenshot inventory
           writes audit/AUDIT.md
           writes audit/gallery.html
```

### Key architectural constraints

- `audit_runner.sh` passes `BUILD_EXIT` to `screen_capture.sh` via environment variable.
  If `BUILD_EXIT` is not `0`, Phase 3 is skipped entirely; all screen statuses are set to
  PARTIAL with the note "runtime evidence absent — build did not succeed."
- `screen_capture.sh` performs a **hard stop** (exit 1) when `adb devices` returns no
  connected device. It never silently continues or emits UNVERIFIED placeholders.
- `lib.sh` provides shared helpers: `check_write_path`, `rg_or_grep`, `log`, `die`.
- `report_generator.py` uses only the Python 3 standard library (`json`, `os`, `pathlib`,
  `datetime`, `subprocess`). `python3 -c` one-liners are used where inline JSON parsing is
  needed; `jq` is not required.

---

## Components

### `scripts/lib.sh` — Shared Helpers

**Purpose:** Centralise reusable shell utilities to avoid duplication across scripts.

```bash
# Write-path guard — abort if target is outside audit/ or scripts/
check_write_path() {
    local target="$1"
    case "$target" in
        */audit/*|*/scripts/*) ;;
        *) echo "ABORT: write to '$target' is outside audit/ and scripts/" >&2; exit 2 ;;
    esac
}

# ripgrep with grep fallback
rg_or_grep() {
    if command -v rg >/dev/null 2>&1; then
        rg -n "$@"
    else
        grep -rn "$@"
    fi
}

# Logging
log()  { echo "[audit] $*"; }
die()  { echo "[audit] ERROR: $*" >&2; exit 1; }
```

`check_write_path` is called by every script before writing any file.

---

### `scripts/build_check.sh` — Phase 1

**Purpose:** Compile the app and record the result as build evidence.

**Inputs:** None (operates on the project at the fixed path
`/home/kornella/Dha-Anywaa-application`).

**Outputs:**
- `audit/build_output.txt` — last 80 lines of combined stdout+stderr from
  `flutter build apk --debug`.
- Exit code exported as `BUILD_EXIT` to the calling orchestrator.

**Algorithm:**
1. Run `flutter build apk --debug 2>&1 | tee /tmp/_dha_build_full.txt`.
2. Capture `${PIPESTATUS[0]}` as `BUILD_EXIT`.
3. Write `tail -80 /tmp/_dha_build_full.txt` to `audit/build_output.txt` (guarded by
   `check_write_path`).
4. Exit with `$BUILD_EXIT`.

**APK path:** `build/app/outputs/flutter-apk/app-debug.apk`

---

### `scripts/static_analysis.sh` — Phase 2

**Purpose:** Produce all static findings. Pre-confirmed findings are emitted directly (no
grep required). Supplemental greps populate UNVERIFIED items.

**Outputs:**
- `audit/findings.json` — machine-readable array of finding objects (consumed by Phase 4).

**Finding object schema:**

```
{
  "id":          string,          // e.g. "BUILD-001"
  "tier":        "P0"|"P1"|"P2",
  "category":    "BUILD"|"DART"|"SEC"|"UI"|"FEATURE",
  "title":       string,
  "description": string,
  "citation":    string,          // MUST be non-empty; format "file:line" or verbatim output
  "fix":         string
}
```

**Pre-confirmed findings (hard-coded — no grep needed):**

| ID        | Tier | Citation                                                    |
|-----------|------|-------------------------------------------------------------|
| BUILD-001 | P1   | `android/build.gradle:2` and `:13`                          |
| BUILD-002 | P2   | `android/build.gradle:11` and `:13`                         |
| BUILD-003 | P1   | `android/app/build.gradle:36` and `:49`                     |
| BUILD-004 | P1   | `android/app/build.gradle:24` and `:36`                     |
| BUILD-005 | P1   | `android/app/build.gradle:37` and `:51–52`                  |
| SEC-001   | P1   | `android/app/src/main/AndroidManifest.xml` (absence of `android:allowBackup`) |
| SEC-002   | P2   | `android/app/src/main/AndroidManifest.xml:3`                |
| SEC-003   | P2   | `lib/home_page.dart` (line containing `launchUrl`)          |
| DART-001  | P1   | `lib/pages/page1.dart:100` and `:115`                       |
| DART-002  | P1   | `lib/home_page.dart:~93`                                    |
| UI-001    | P2   | `lib/home_page.dart:~220–250`                               |
| UI-002    | P2   | `lib/pages/page1.dart:~170`                                 |

**Supplemental grep tasks (for UNVERIFIED classification):**

```bash
# Dark theme
rg_or_grep 'darkTheme' lib/          # expect 0 matches → UNVERIFIED
# FCM / notifications
rg_or_grep 'firebase_messaging\|flutter_local_notifications' pubspec.yaml
# Offline / connectivity
rg_or_grep 'Connectivity\|sqflite' lib/
```

Each grep is run, and the command + raw output is stored as the citation for the
corresponding UNVERIFIED feature row.

---

### `scripts/screen_capture.sh` — Phase 3

**Purpose:** Capture 57 screenshots (19 screens × 3 conditions) from a connected ADB device.

**Hard-stop entry check:**

```bash
DEVICES=$(adb devices | grep -v "^List" | grep "device$")
if [ -z "$DEVICES" ]; then
    echo "ERROR: No ADB device connected. Connect your phone and re-run." >&2
    exit 1
fi
ADB_SERIAL=$(echo "$DEVICES" | head -1 | awk '{print $1}')
```

No fallback path exists. The script must exit 1 if no device is present.

**Screen inventory (19 screens):**

Named-route screens (15):
`root`, `number`, `alphabet`, `word`, `shape`, `reading`, `quiz`, `home_page`,
`name_entry`, `colors`, `body`, `fish`, `animal`, `bird`, `clothes`

Drawer-only screens (4):
`vowel_letter`, `body_widget`, `about`, `help`

**Conditions (3):** `standard`, `dark`, `font_1_3`

**Capture loop per screen per condition:**

```
standard:
  1. adb shell am start -n com.kornellaotf.learn_dha_anywaa/.MainActivity (navigate to screen)
  2. sleep 1.5
  3. adb -s $ADB_SERIAL shell screencap -p /sdcard/tmp_cap.png
  4. adb -s $ADB_SERIAL pull /sdcard/tmp_cap.png audit/screens/<screen>_standard.png
  5. adb -s $ADB_SERIAL shell rm /sdcard/tmp_cap.png
  6. Record timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ) and serial=$ADB_SERIAL

dark:
  1. adb shell cmd uimode night yes
  2. (navigate + sleep + screencap + pull as above → <screen>_dark.png)
  3. adb shell cmd uimode night no

font_1_3:
  1. adb shell settings put system font_scale 1.3
  2. (navigate + sleep + screencap + pull as above → <screen>_font_1_3.png)
  3. adb shell settings put system font_scale 1.0
```

**Output metadata file:** `audit/screens/manifest.json`

Each successfully captured screenshot appends an entry:
```json
{
  "screen": "alphabet",
  "condition": "standard",
  "file": "audit/screens/alphabet_standard.png",
  "timestamp": "2025-07-14T10:23:01Z",
  "device_serial": "emulator-5554",
  "bytes": 148320
}
```

`bytes` is computed from `wc -c` after pull; a zero-byte file records `bytes: 0` and the
status for that slot is PARTIAL in the final report.

---

### `scripts/report_generator.py` — Phase 4

**Purpose:** Produce `audit/AUDIT.md` and `audit/gallery.html` from structured inputs.

**Inputs:**
- `audit/build_output.txt` (Phase 1 output)
- `audit/findings.json` (Phase 2 output)
- `audit/screens/manifest.json` (Phase 3 output, may be absent if build failed)
- Environment variable `BUILD_EXIT`

**AUDIT.md section order (mandatory):**

```
## Top 5 Fixes First
## Build Result
## Build Configuration Findings
## Security Findings
## Dart / Runtime Findings
## UI / Accessibility Findings
## Feature Status
## Settings Audit
## Screenshot Coverage
## What I Could NOT Verify and Why
```

The `Top 5 Fixes First` section is written first by the generator. Its byte offset in the
output file is always less than any other `## ` section heading.

**Top-5 ranking algorithm:**
1. Collect all findings from `findings.json` sorted by tier (P0 < P1 < P2).
2. Take the top 5. If `BUILD_EXIT` ≠ 0, prepend a synthetic P0 entry citing
   `audit/build_output.txt` (first error line).
3. Each entry contains: tier label, finding ID, one-line description, file:line citation,
   and exact remediation.

**Feature status resolution:**

```python
def resolve_status(feature, screenshots, build_exit):
    if feature.known_broken:          # DART-001, DART-002 impacts
        return "BROKEN"
    if build_exit != 0:
        return "PARTIAL"              # no runtime evidence possible
    png = screenshots.get(f"{feature.screen_name}_standard")
    if png and png["bytes"] > 0:
        return "WORKING"
    return "PARTIAL"
```

**gallery.html generation:**

- Valid HTML5 with all styles in a `<style>` block in `<head>`.
- No external CDN or network resource references.
- Screens grouped by `<h2>` section headings (screen name).
- Each image slot shows the PNG if it exists and has `bytes > 0`; otherwise renders:
  `<p class="placeholder">Screenshot not available — adb device not connected.</p>`
- Images are referenced by relative path from `audit/gallery.html` (e.g.,
  `screens/alphabet_standard.png`).

---

## Data Models

### Finding

```
Finding {
    id:          string          // "BUILD-001" | "SEC-001" | "DART-001" | "UI-001" …
    tier:        P0 | P1 | P2
    category:    BUILD | DART | SEC | UI | FEATURE
    title:       string
    description: string
    citation:    string          // non-empty; "file:line" or verbatim command output
    fix:         string
}
```

Citation format rules:
- Source file reference: `path/to/file.ext:LINE` (e.g., `lib/pages/page1.dart:100`)
- Absence finding: `android/app/src/main/AndroidManifest.xml (android:allowBackup absent)`
- Command output: verbatim excerpt of the grep/adb command and its stdout

### FeatureRow

```
FeatureRow {
    feature:    string           // human-readable name
    status:     WORKING | PARTIAL | BROKEN | UNVERIFIED
    evidence:   string           // description of evidence used to assign status
    citation:   string           // file:line or grep command + output
}
```

### ScreenshotEntry

```
ScreenshotEntry {
    screen:         string       // e.g. "alphabet"
    condition:      standard | dark | font_1_3
    file:           string       // relative path from project root
    timestamp:      string       // ISO-8601 UTC
    device_serial:  string
    bytes:          int          // 0 = capture failed
}
```

### SettingsRow

```
SettingsRow {
    setting:     string
    persistence: string
    write_loc:   string          // file:line or "none"
    read_loc:    string          // file:line or "none"
    expected:    string
    status:      WORKING | PARTIAL | BROKEN | UNVERIFIED
    citation:    string
}
```

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| `adb devices` returns no device | `screen_capture.sh` prints error to stderr, exits 1. Phase 3 never starts. |
| `flutter build apk --debug` exits non-zero | `build_check.sh` saves output, exits non-zero. `audit_runner.sh` skips Phase 3. Report generator marks all screens PARTIAL, adds P0 build-failure entry to Top 5. |
| A single screenshot capture fails (adb pull error) | Entry recorded in `manifest.json` with `bytes: 0`. Status for that slot is PARTIAL. Other captures continue. |
| `findings.json` absent when report generator runs | `report_generator.py` exits with error message "findings.json not found — run static_analysis.sh first". |
| Write attempt outside `audit/` or `scripts/` | `check_write_path` in `lib.sh` prints ABORT message, exits 2. |
| `audit/screens/manifest.json` absent | Report generator treats all screenshot slots as PARTIAL (no runtime evidence). |

---

## Audit Isolation

All scripts source `lib.sh` and call `check_write_path "$TARGET"` before every write.
The guard checks that the resolved absolute path starts with either
`/home/kornella/Dha-Anywaa-application/audit/` or
`/home/kornella/Dha-Anywaa-application/scripts/`.

Source files under `/home/kornella/Dha-Anywaa-application` are accessed only via:
- `cat`, `head`, `tail`, `wc -l`, `grep -n`, `rg -n` — all read-only.
- No `sed -i`, `tee` to source paths, or any redirect operator targeting source paths.

ADB operations on the device are limited to:
- `adb shell screencap` + `adb pull` (writes only to `audit/screens/`)
- `adb shell rm` (removes temporary screencap from device sdcard)
- `adb shell cmd uimode` and `adb shell settings put system font_scale` (transient system
  settings, restored after each capture)

---

## Pre-Confirmed Findings Detail

### Build / Gradle Findings

**BUILD-001 (P1) — Kotlin version conflict**
- `android/build.gradle:2`: `ext.kotlin_version = '1.8.0'`
- `android/build.gradle:13`: `classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22"`
- `resolutionStrategy` forces `kotlin-stdlib:1.8.0` and `kotlin-reflect:1.8.0`
- Fix: remove the `1.9.22` classpath line; rely solely on `$kotlin_version`.

**BUILD-002 (P2) — Duplicate AGP classpath**
- Two identical `classpath 'com.android.tools.build:gradle:8.2.2'` lines in `android/build.gradle`
- Fix: remove one.

**BUILD-003 (P1) — Duplicate `defaultConfig` blocks**
- `android/app/build.gradle` ~line 36: first `defaultConfig` block (`targetSdk 34`)
- `android/app/build.gradle` ~line 49: second `defaultConfig` block (`minSdkVersion 21`,
  `targetSdkVersion 33`, `applicationId`, `targetSdkVersion flutter.targetSdkVersion`)
- Gradle resolves to last parsed value; behaviour is ambiguous.
- Fix: merge into a single `defaultConfig` block.

**BUILD-004 (P1) — Duplicate `compileSdk` declarations**
- `compileSdkVersion flutter.compileSdkVersion` and `compileSdk 34` both declared.
- Fix: remove hardcoded `compileSdk 34`.

**BUILD-005 (P1) — Conflicting `targetSdk` values**
- `targetSdk 34` in first block; `targetSdkVersion 33` then `targetSdkVersion flutter.targetSdkVersion` in second.
- Fix: single `defaultConfig`, keep only `targetSdkVersion flutter.targetSdkVersion`.

### Security Findings

**SEC-001 (P1) — `android:allowBackup` absent**
- `android/app/src/main/AndroidManifest.xml` `<application>` element has no `android:allowBackup`.
- Android defaults to `true`; ADB backup exposes SharedPreferences (persisted user name).
- Fix: add `android:allowBackup="false"` to `<application>`.

**SEC-002 (P2) — INTERNET permission without `network_security_config.xml`**
- `android/app/src/main/AndroidManifest.xml:3` declares `INTERNET` permission.
- No `res/xml/network_security_config.xml` exists.
- Fix: create the config file; reference it via `android:networkSecurityConfig`.

**SEC-003 (P2) — `launchUrl()` without confirmation dialog**
- `lib/home_page.dart` (line containing `launchUrl`) opens `https://dha-anywaa-app.netlify.app/`
  directly on tap.
- Fix: show `AlertDialog` before calling `launchUrl`; handle `PlatformException`.

### Dart / Runtime Findings

**DART-001 (P1) — `getDuration()` cast crash**
- `lib/pages/page1.dart:100` and `:115`: `(await player.getDuration()) as int`
- In `audioplayers ^5.2.1`, `getDuration()` returns `Duration?`, not `int`.
- This throws a `TypeError` at runtime on every letter tap.
- Fix: `(await player.getDuration())?.inMilliseconds ?? 0`

**DART-002 (P1) — Dead `themeValue` variable**
- `lib/home_page.dart:~93`: `bool themeValue = false`
- Never written to `SharedPreferences`; never used to alter the app theme.
- `lib/main.dart:29–31`: `theme: ThemeData(...)` only — no `darkTheme:` property.
- Fix: remove `themeValue` or wire to `SharedPreferences` + `ThemeMode`.

### UI / Accessibility Findings

**UI-001 (P2) — Missing Semantics on phone-grid cards**
- `lib/home_page.dart:~220–250`: `GestureDetector` cards in the phone grid lack `Semantics`.
- Fix: wrap with `Semantics(label: '${anyName} — ${engName}')`.

**UI-002 (P2) — Missing Semantics on alphabet letter buttons**
- `lib/pages/page1.dart:~170`: `TextButton` per letter has no `Semantics` label.
- Fix: wrap with `Semantics(label: '${capitalLetter} ${smallLetter}')`.

---

## Feature Status (Static Analysis Baseline)

All statuses below are the baseline from static analysis. `WORKING` is only assigned after
Phase 3 confirms a non-zero-byte screenshot exists.

| Feature                   | Static baseline | Govering finding |
|---------------------------|-----------------|------------------|
| Name persistence          | PARTIAL         | savedData.dart:7–15 confirmed; no runtime screenshot |
| Home page category grid   | PARTIAL         | home_page.dart renders GridView; no screenshot |
| Alphabet page audio       | BROKEN          | DART-001 |
| Drawer navigation         | PARTIAL         | Navigator.push wired; no screenshots |
| Quiz screen               | PARTIAL         | Page4() registered; no defects found |
| Dark mode                 | UNVERIFIED      | no `darkTheme:` in main.dart; DART-002 |
| `themeValue` toggle       | BROKEN          | DART-002 |
| Notification support      | UNVERIFIED      | no FCM/notification dependency in pubspec.yaml |
| Offline mode              | UNVERIFIED      | no Connectivity or sqflite in codebase |

---

## Settings Audit (Hard-coded from source)

| Setting           | Persistence              | Write              | Read               | Status  |
|-------------------|--------------------------|--------------------|--------------------|---------|
| User Name (`name`)| SharedPreferences        | savedData.dart:11  | savedData.dart:7   | PARTIAL |
| Theme (`themeValue`) | none                 | none               | none               | BROKEN  |
| All others        | —                        | —                  | —                  | UNVERIFIED |

No other persisted settings exist in the codebase (no language toggle, no audio volume
preference, no notification setting). Evidence: grep commands returning 0 matches (to be
recorded in `audit/AUDIT.md` under "What I Could NOT Verify and Why").

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions
of a system — essentially, a formal statement about what the system should do. Properties serve
as the bridge between human-readable specifications and machine-verifiable correctness
guarantees.*

### Property 1: Citation Integrity

*For any* finding emitted to `audit/AUDIT.md`, its `citation` field must be non-empty, and
for any finding that references a Dart, Kotlin, or Gradle source file, the citation must
match the pattern `path/to/file.ext:LINE` (non-zero line number).

**Validates: Requirements 1.1, 1.3**

---

### Property 2: Status Enum Constraint

*For any* feature row written to the Feature Status table in `audit/AUDIT.md`, its status
value must be exactly one of: `WORKING`, `PARTIAL`, `BROKEN`, or `UNVERIFIED`. No other
value is permitted.

**Validates: Requirements 1.5, 6.1**

---

### Property 3: Feature Table Completeness

*For any* feature name in the canonical feature list (name persistence, home page category
grid, alphabet page audio, drawer navigation, quiz screen, dark mode, themeValue toggle,
notification support, offline mode, and all 15 named routes), a corresponding row must exist
in the Feature Status table in `audit/AUDIT.md`.

**Validates: Requirements 6.1**

---

### Property 4: Top-5 Section Byte-Offset Priority

*For any* valid `audit/AUDIT.md` produced by `report_generator.py`, the byte offset of the
`## Top 5 Fixes First` heading must be strictly less than the byte offset of every other
`## ` section heading in the same file.

**Validates: Requirements 8.1, 8.2**

---

### Property 5: ADB Hard-Stop

*For any* execution of `scripts/screen_capture.sh` in which `adb devices` returns no line
matching the pattern `<serial>\tdevice`, the script must terminate with exit code 1 and must
not write any PNG file to `audit/screens/` or produce any UNVERIFIED placeholder entry.

**Validates: Requirements 9.1**

---

### Property 6: Screenshot Evidence Gate

*For any* screen entry assigned status `WORKING` in `audit/AUDIT.md`, the corresponding PNG
file `audit/screens/<screen>_<condition>.png` must exist on disk and have a byte size
strictly greater than zero.

**Validates: Requirements 9.8, 6.1**

---

### Property 7: Write Isolation

*For any* file path written by any script in `scripts/` during an audit run, the resolved
absolute path must begin with either `/home/kornella/Dha-Anywaa-application/audit/` or
`/home/kornella/Dha-Anywaa-application/scripts/`. Any write attempt to a path outside these
two directories must be blocked by `check_write_path` before the write occurs.

**Validates: Requirements 11.1, 11.2**
