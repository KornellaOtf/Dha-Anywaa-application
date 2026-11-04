# Requirements Document

## Introduction

This spec defines the Android QA Audit workflow for the **Learn Dha Anywaa** Flutter app at
`/home/kornella/Dha-Anywaa-application` (package `com.kornellaotf.learn_dha_anywaa`, version 1.0.2+3).

The app is a Flutter-based Dha Anywaa language learning application. The `android/` folder is
the Flutter host shell — all UI is Flutter widgets using Material 2 (MaterialApp + ThemeData).
There is no Jetpack Compose, no XML layouts, and no dark theme configured. The only native
Kotlin file is `MainActivity.kt`, which extends `FlutterActivity`.

The audit produces structured, evidence-based findings across four dimensions: build/configuration
correctness, runtime screen coverage (screenshots), feature status classification, and security
posture. Every finding must cite a source (file:line or raw command output); claims without a
citation are dropped.

Output artefacts:
- `audit/AUDIT.md` — primary findings report
- `audit/build_output.txt` — last 80 lines of `flutter build apk --debug` output
- `audit/screens/*.png` — per-screen screenshots (standard, dark, font_1_3 variants)
- `audit/gallery.html` — scrollable HTML gallery of all captured screenshots

No script produced by this audit may write to any file outside the `audit/` and `scripts/`
directories. Source files under `/home/kornella/Dha-Anywaa-application` are read-only.

---

## Glossary

- **App**: The Flutter application `com.kornellaotf.learn_dha_anywaa` at
  `/home/kornella/Dha-Anywaa-application`.
- **Auditor**: The automated QA workflow that performs static analysis, adb commands, and
  generates output artefacts.
- **ADB**: Android Debug Bridge; the command-line tool used for device/emulator interaction.
- **Finding**: A documented defect or risk assigned a priority tier (P0 / P1 / P2) and backed
  by at least one source citation (file:line or raw command output).
- **Route**: One named destination registered in `lib/main.dart` or reachable via Drawer push.
- **Static Analysis**: Reading source files and build scripts without executing the App.
- **Evidence Rule**: Each claim in a finding requires a file:line reference or verbatim command
  output; findings without evidence are omitted from the report.
- **P0**: Crash / data-loss / security blocker — must be fixed before release.
- **P1**: Significant functional defect that degrades the core user journey.
- **P2**: Polish / accessibility / non-blocking issue.
- **WORKING**: Feature verified via build success (flutter build apk --debug exit 0) AND
  runtime evidence (screenshot). Static analysis alone cannot produce this status.
- **PARTIAL**: Feature code exists but is incomplete, or verified only by static analysis
  without runtime confirmation.
- **BROKEN**: Feature intended to work but demonstrably non-functional (with citation).
- **UNVERIFIED**: Feature not found in the codebase or not testable; must record the search
  evidence (command + zero-match output or missing file).

### Routes (15 named routes in lib/main.dart:32–47)

| Route | Widget | File |
|---|---|---|
| `/` | `Wrapper()` | `wraper.dart` — checks name, routes to `HomePage` or `NameEntry` |
| `number` | `Number()` | `components/number.dart` |
| `alphabet` | `Page1()` | `pages/page1.dart` — alphabet grid + audio |
| `word` | `Page2()` | `pages/page2.dart` |
| `shape` | `Shpae()` | `components/shape.dart` (note: class name typo) |
| `reading` | `Page3()` | `pages/page3.dart` |
| `quiz` | `Page4()` | `pages/page4.dart` |
| `home_page` | `HomePage()` | `home_page.dart` — main grid + drawer |
| `name_entry` | `NameEntry()` | `nameEntry.dart` — first-run name form |
| `colors` | `Kit()` | `components/colors.dart` |
| `body` | `BodyPart()` | `components/body_part.dart` |
| `fish` | `Fish()` | `components/fish.dart` |
| `animal` | `Animal()` | `components/animal.dart` |
| `bird` | `Bird()` | `components/bird.dart` |
| `clothes` | `Cloth()` | `components/cloth.dart` |

### Drawer-Only Screens (reachable via Navigator.push, not named routes)

| Screen | Widget | File |
|---|---|---|
| Göörë moo cïp dwøl | `VowelLetter()` | `vowelLetter.dart` |
| Jap dëël | `Body()` | `widgets/body.dart` |
| About | `About()` | `about.dart` |
| Help | `Help()` | `help.dart` |

---

## Requirements

### Requirement 1 — Evidence-Gated Finding Classification

**User Story:** As a QA engineer, I want every finding in the audit report to be backed by a
source citation, so that I can reproduce and verify each issue without guessing.

#### Acceptance Criteria

1. THE Auditor SHALL omit any finding from `audit/AUDIT.md` that does not include at least one
   citation in the form `file:line` or a verbatim excerpt of adb / build-tool output.
2. WHEN the Auditor cannot locate a feature's implementation in the codebase, THE Auditor SHALL
   classify that feature as UNVERIFIED and record the search command and its output as evidence.
3. IF a finding references a Dart, Kotlin, or Gradle source file, THEN THE Auditor SHALL
   include the exact line number alongside the quoted excerpt.
4. THE Auditor SHALL include a "What I could NOT verify and why" section in `audit/AUDIT.md`
   listing each UNVERIFIED item with the reason (e.g., "grep returned 0 matches for
   'darkTheme' in lib/").
5. THE Auditor SHALL classify feature status using only these four states: WORKING, PARTIAL,
   BROKEN, or UNVERIFIED, as defined in the Glossary.

---

### Requirement 2 — Build Execution (Evidence Gate)

**User Story:** As a developer, I want the audit to actually compile the project and record the
result, so that build-time errors are captured as evidence rather than inferred from config files.

#### Acceptance Criteria

1. THE Auditor SHALL execute `flutter build apk --debug` in the directory
   `/home/kornella/Dha-Anywaa-application` and capture the last 80 lines of combined
   stdout+stderr as raw output evidence, saving them to `audit/build_output.txt`.
2. THE Auditor SHALL record the build exit code (0 = success, non-zero = failure) in
   `audit/AUDIT.md` under a "Build Result" heading.
3. IF the build exits with a non-zero code, THEN THE Auditor SHALL include the first error line
   from the captured output as a P0 finding citing the raw output in `audit/build_output.txt`.
4. WHEN the build succeeds (exit code 0), THE Auditor SHALL record the generated APK path
   and size from the build output as evidence.
5. THE Auditor SHALL record the build result before proceeding to any runtime evidence
   collection; screenshot capture MAY only proceed after a confirmed build success.
6. THE Auditor SHALL perform this build step by executing `scripts/build_check.sh`, which
   runs the above Flutter command and writes the raw output to `audit/build_output.txt`.

---

### Requirement 3 — Build Configuration Audit

**User Story:** As a developer, I want the audit to surface build-script inconsistencies and
manifest settings, so that I can fix them before publishing to the Play Store.

#### Acceptance Criteria

1. THE Auditor SHALL record finding BUILD-001 (P1): `android/build.gradle` line 2 declares
   `ext.kotlin_version = '1.8.0'`, but a later classpath line hardcodes
   `org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22`, and `resolutionStrategy` forces
   `kotlin-stdlib:1.8.0` and `kotlin-reflect:1.8.0`, creating a version conflict; recommended
   fix: remove the `1.9.22` classpath line and rely solely on `$kotlin_version`.
2. THE Auditor SHALL record finding BUILD-002 (P2): `android/build.gradle` contains two
   identical `classpath 'com.android.tools.build:gradle:8.2.2'` declarations; recommended fix:
   remove one.
3. THE Auditor SHALL record finding BUILD-003 (P1): `android/app/build.gradle` contains two
   `defaultConfig` blocks — the first (around line 36) declares `targetSdk 34`; the second
   (around line 49) declares `minSdkVersion 21`, `targetSdkVersion 33`, `applicationId`, and
   `targetSdkVersion flutter.targetSdkVersion`; Gradle uses the last parsed value; recommended
   fix: merge into a single `defaultConfig` block.
4. THE Auditor SHALL record finding BUILD-004 (P1): `android/app/build.gradle` contains two
   `compileSdk` declarations — `compileSdkVersion flutter.compileSdkVersion` and the
   hardcoded `compileSdk 34`; recommended fix: remove the hardcoded `compileSdk 34`.
5. THE Auditor SHALL record finding BUILD-005 (P1): `android/app/build.gradle` contains
   conflicting `targetSdk` values: `targetSdk 34` in the first `defaultConfig` block and
   `targetSdkVersion 33` then `targetSdkVersion flutter.targetSdkVersion` in the second;
   the resolved value is ambiguous; recommended fix: keep only `targetSdkVersion flutter.targetSdkVersion`
   in a single `defaultConfig` block.
6. THE Auditor SHALL verify that `android/app/build.gradle` declares
   `namespace "com.kornellaotf.learn_dha_anywaa"` and `applicationId "com.kornellaotf.learn_dha_anywaa"`
   and record these as consistent.
7. THE Auditor SHALL verify that `MainActivity` in `AndroidManifest.xml` extends
   `FlutterActivity` (confirmed by `MainActivity.kt`) and is the sole Activity declared with
   `android:exported="true"` and a MAIN/LAUNCHER intent-filter, and record this as CORRECT.

---

### Requirement 4 — Known Static Analysis Findings (Dart)

**User Story:** As a QA engineer, I want all statically confirmed Dart defects pre-recorded in
the audit report with their exact citations, so that I can validate them without re-running analysis.

#### Acceptance Criteria

1. THE Auditor SHALL record finding DART-001 (P1): `lib/pages/page1.dart` lines 100 and 115
   cast the return value of `player.getDuration()` to `int` using `as int`; in
   `audioplayers ^5.2.1` (declared in `pubspec.yaml`), `getDuration()` returns `Duration?`,
   not `int`, so this cast throws a `TypeError` at runtime on every letter tap; recommended
   fix: replace `(await player.getDuration()) as int` with
   `(await player.getDuration())?.inMilliseconds ?? 0`.
2. THE Auditor SHALL record finding DART-002 (P1): `lib/home_page.dart` declares
   `bool themeValue = false` (approximately line 93) that is never written to
   `SharedPreferences` and never used to alter the app theme; `lib/main.dart` lines 29–31
   declare only `theme: ThemeData(...)` with no `darkTheme:` property, confirming dark mode
   is unsupported; this is a dead variable with no effect; recommended fix: either remove
   `themeValue` or wire it to `SharedPreferences` and apply via `ThemeMode`.

---

### Requirement 5 — Known Static Analysis Findings (Security)

**User Story:** As a security reviewer, I want dedicated security findings with exact remediation
steps, so that I can evaluate the app's attack surface before Play Store submission.

#### Acceptance Criteria

1. THE Auditor SHALL record finding SEC-001 (P1): `android/app/src/main/AndroidManifest.xml`
   does not explicitly set `android:allowBackup`; Android defaults this to `true`, enabling
   unencrypted ADB backup of `SharedPreferences` (including the persisted user name);
   recommended fix: add `android:allowBackup="false"` to the `<application>` element.
2. THE Auditor SHALL record finding SEC-002 (P2): `android/app/src/main/AndroidManifest.xml`
   line 3 declares `<uses-permission android:name="android.permission.INTERNET"/>` but no
   `res/xml/network_security_config.xml` exists in the project; recommended fix: create
   `res/xml/network_security_config.xml` and reference it via
   `android:networkSecurityConfig="@xml/network_security_config"` in the `<application>`
   element, defining explicit cleartext-traffic rules.
3. THE Auditor SHALL record finding SEC-003 (P2): `lib/home_page.dart` calls
   `launchUrl(webUrl, ...)` directly on tap of the 'More' drawer item, opening
   `https://dha-anywaa-app.netlify.app/` in an external browser without a user confirmation
   dialog; recommended fix: show an `AlertDialog` before calling `launchUrl` and handle the
   `PlatformException` if the URL cannot be launched.
4. THE Auditor SHALL produce a "Security Findings" section in `audit/AUDIT.md` listing
   SEC-001 through SEC-003 in priority order, each with a recommended fix.
5. THE Auditor SHALL verify that `MainActivity` has `android:exported="true"` with an
   explicit `<intent-filter>` for MAIN/LAUNCHER, and record this as EXPECTED (not a finding).

---

### Requirement 6 — Feature Status Table

**User Story:** As a product owner, I want a clear table showing which app features are
WORKING, PARTIAL, BROKEN, or UNVERIFIED, so that I can track release readiness.

#### Acceptance Criteria

1. THE Auditor SHALL produce a Feature Status table in `audit/AUDIT.md` covering every feature
   listed below with columns: Feature | Status | Evidence | Citation.
2. THE Auditor SHALL classify name persistence as PARTIAL: `SavedData.setName()` and
   `SavedData.getName()` are fully wired via `SharedPreferences` in
   `lib/components/savedData.dart:7–15`; WORKING requires build success and runtime screenshot
   of the `name_entry` screen rendering the saved name.
3. THE Auditor SHALL classify the home page category grid as PARTIAL: `lib/home_page.dart`
   renders a `GridView` of 12 categories on phone and a `ListView` + detail panel on tablet;
   WORKING requires a screenshot.
4. THE Auditor SHALL classify alphabet page audio as BROKEN: `lib/pages/page1.dart` lines 100
   and 115 cast `getDuration()` to `int`, which throws a `TypeError` at runtime (DART-001).
5. THE Auditor SHALL classify the drawer navigation as PARTIAL: drawer items for
   `VowelLetter`, `Body`, `About`, `Help`, and `More` are wired via `Navigator.push` or
   `launchUrl`; WORKING requires screenshots.
6. THE Auditor SHALL classify the quiz screen as PARTIAL: `Page4()` is registered at route
   `quiz`; no functional defects found by static analysis; WORKING requires a screenshot.
7. THE Auditor SHALL classify dark mode as UNVERIFIED: `lib/main.dart` declares no
   `darkTheme:` property; `themeValue` in `lib/home_page.dart` is a dead variable (DART-002);
   evidence: grep for `darkTheme` in `lib/` returns 0 matches.
8. THE Auditor SHALL classify the `themeValue` dark-mode toggle as BROKEN: declared in
   `lib/home_page.dart` but never persisted and never applied (DART-002).
9. THE Auditor SHALL classify notification support as UNVERIFIED: `pubspec.yaml` declares no
   FCM or notification dependency; evidence: full dependency list from `pubspec.yaml`.
10. THE Auditor SHALL classify offline mode as UNVERIFIED: no connectivity checks or
    local-database fallback found in the codebase; evidence: grep for `Connectivity` and
    `sqflite` returns 0 matches.

---

### Requirement 7 — Settings Audit Table

**User Story:** As a QA engineer, I want a settings audit table that traces each configurable
value in the app to its persistence layer, so that I can verify the full write → persist → reload chain.

#### Acceptance Criteria

1. THE Auditor SHALL produce a Settings Audit table in `audit/AUDIT.md` with columns:
   Setting | Persistence mechanism | Write location (file:line) | Read location (file:line) |
   Expected behaviour | Status.
2. THE Auditor SHALL populate the User Name row as: Setting = User Name; Persistence =
   SharedPreferences (key `name`); Write = `lib/components/savedData.dart:11`;
   Read = `lib/components/savedData.dart:7`; Expected = persists across restarts; Status = PARTIAL
   (wired but WORKING requires runtime confirmation); Citation = `savedData.dart:7–15`.
3. THE Auditor SHALL populate the Theme / Dark Mode row as: Setting = Theme toggle
   (`themeValue`); Persistence = none; Write = none; Read = none; Expected = applies dark mode
   across restarts; Status = BROKEN (DART-002); Citation = `lib/home_page.dart:~93`.
4. THE Auditor SHALL note in the Settings Audit section that no other persisted settings exist
   in the codebase (no language toggle, no audio volume preference, no notification setting)
   and record the evidence as grep commands returning 0 matches.

---

### Requirement 8 — Top-5 Fix Priority List

**User Story:** As a developer, I want the audit report to lead with the five most important
fixes in priority order, so that I can begin remediation without reading the full report first.

#### Acceptance Criteria

1. THE Auditor SHALL open `audit/AUDIT.md` with a "Top 5 Fixes First" section appearing before
   all other findings tables.
2. THE top-5 list SHALL rank findings by tier (P0 first, then P1, then P2) and SHALL include
   for each: tier label, finding ID, one-line description, file:line citation, and the exact
   code or configuration change required.
3. IF the build fails (Requirement 2, exit code non-zero), THEN THE Auditor SHALL include the
   build failure as a P0 entry in the top-5 list.
4. THE Auditor SHALL include DART-001 (audioplayers `getDuration()` cast crash,
   `lib/pages/page1.dart:100`) as a P1 entry in the top-5 list.
5. THE Auditor SHALL include BUILD-003 (duplicate `defaultConfig` blocks in
   `android/app/build.gradle`) as a P1 entry in the top-5 list.
6. THE Auditor SHALL include BUILD-001 (Kotlin version conflict in `android/build.gradle:2`)
   as a P1 entry in the top-5 list.
7. IF fewer than 5 P0/P1 findings exist, THE Auditor SHALL fill remaining slots with the
   highest-ranked P2 findings.

---

### Requirement 9 — Screen Capture Workflow

**User Story:** As a QA engineer, I want a screenshot of each screen in three rendering
conditions (standard, dark, font scale 1.3), so that I can visually verify layout correctness
and accessibility.

#### Acceptance Criteria

1. WHEN `scripts/screen_capture.sh` is executed, THE Auditor SHALL run `adb devices` first
   and, IF no device or emulator is listed as connected, THE Auditor SHALL print
   "ERROR: No ADB device connected. Connect your phone and re-run." to stderr and EXIT 1.
   THE Auditor SHALL NOT silently continue or mark screenshots as UNVERIFIED.
2. THE Auditor SHALL capture screenshots for the 15 named routes and 4 drawer-only screens
   (19 screens total) × 3 conditions = 57 PNG slots, saved to
   `audit/screens/<screen>_<condition>.png` where condition is one of `standard`, `dark`,
   or `font_1_3`.
3. THE 15 named-route screens to capture are: `root` (Wrapper), `number`, `alphabet`, `word`,
   `shape`, `reading`, `quiz`, `home_page`, `name_entry`, `colors`, `body`, `fish`, `animal`,
   `bird`, `clothes`.
4. THE 4 drawer-only screens to capture are: `vowel_letter`, `body_widget`, `about`, `help`.
5. WHEN capturing a screen in dark mode, THE Auditor SHALL execute
   `adb shell cmd uimode night yes` before capture and `adb shell cmd uimode night no` after.
6. WHEN capturing a screen at font scale 1.3, THE Auditor SHALL execute
   `adb shell settings put system font_scale 1.3` before capture and
   `adb shell settings put system font_scale 1.0` after to restore the default.
7. WHEN a screenshot is successfully captured, THE Auditor SHALL record the filename, capture
   timestamp, and adb device serial in `audit/AUDIT.md` alongside the screen entry.
8. THE Auditor SHALL record a WORKING classification for a screen only after its screenshot
   file exists and is a non-zero-byte PNG; a missing or zero-byte file SHALL produce a
   PARTIAL classification with a note that runtime evidence is absent.
9. THE Auditor SHALL gate all screenshot capture on a successful build (Requirement 2,
   exit code 0); IF the build has not succeeded, THE Auditor SHALL skip screenshot capture
   and mark all screens as PARTIAL.

---

### Requirement 10 — HTML Screenshot Gallery

**User Story:** As a reviewer, I want a single scrollable HTML page showing all captured
screenshots, so that I can browse the full visual audit without opening individual files.

#### Acceptance Criteria

1. THE Auditor SHALL generate `audit/gallery.html` listing every PNG file found under
   `audit/screens/`.
2. THE gallery SHALL display each image with its filename as a caption and SHALL group images
   by screen name using HTML section headings.
3. WHEN no screenshots were captured (adb unavailable or hard-stop triggered), THE gallery
   SHALL render a placeholder message per image slot:
   "Screenshot not available — adb device not connected."
4. THE gallery SHALL be valid HTML5 and SHALL NOT depend on any external CDN or network
   resource; all styles SHALL be inline or in a `<style>` block in the document `<head>`.

---

### Requirement 11 — Audit Isolation (Read-Only Source)

**User Story:** As a developer, I want the audit scripts to be strictly non-destructive, so
that running the audit never modifies the project source.

#### Acceptance Criteria

1. THE Auditor SHALL NOT write any file to any path outside `audit/` and `scripts/` directories
   (relative to `/home/kornella/Dha-Anywaa-application`).
2. IF a script attempts to write a file outside `audit/` or `scripts/`, THEN the script SHALL
   abort with an error message before writing.
3. THE Auditor SHALL only read source files under `/home/kornella/Dha-Anywaa-application`
   using read-only operations (cat, grep, head, wc — no editors or redirects targeting those
   paths).
4. WHEN adb shell commands are used, THE Auditor SHALL NOT push or install any APK or file to
   the device except the temporary screencap pull (which writes only to `audit/screens/`).
