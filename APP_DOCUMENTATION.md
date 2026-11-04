# Dha Anywaa, Complete App Documentation

> Everything about the app in one place: purpose, tech stack, architecture,
> screens, content, data model, theming, OTA update system, release pipeline,
> build steps, permissions, privacy, and known issues.

- **App name:** Dha Anywaa (MaterialApp title)
- **Dart package:** `dha_anywaaa`
- **Android application id:** `com.kornellaotf.learn_dha_anywaa`
- **Current version:** `1.1.5+100` (versionName `1.1.5`, versionCode `100`)
- **Developer:** Kornella Otf (Kornellaotf@gmail.com)
- **Repository:** https://github.com/KornellaOtf/Dha-Anywaa-application
- **Platform focus:** Android (also scaffolds for iOS, web, Linux, macOS, Windows)

---

## 1. What the app is

Dha Anywaa (also written Anuak) is a Nilo-Saharan language spoken in Ethiopia
and South Sudan. This is an offline-first mobile learning app for absolute
beginners. It teaches the alphabet with audio, illustrated vocabulary with
audio, reading sentences, themed word categories (animals, birds, fish, body
parts, clothes, colors, shapes, numbers), and tests knowledge with a
multiple-choice quiz.

No account is required. The core features work with no internet at all. The
only network use is an optional update check (GitHub Releases) once every six
hours when the device is online.

Target audience: children and beginner learners of the language.

---

## 2. Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter / Dart (SDK `>=3.2.1 <4.0.0`) |
| CI Flutter version | `3.47.7` (stable) |
| State management | `provider` package is present; the app itself uses an `InheritedNotifier` (`AppSettings`) plus `StatefulWidget` screens |
| Local storage | `shared_preferences` (via the `SavedData` helper) |
| Audio | `audioplayers` (wrapped by `audio_helper.dart`) |
| Networking | `http` (update check + APK download) |
| Integrity | `crypto` (SHA-256 of downloaded APK) |
| App info | `package_info_plus` (installed version/build number) |
| File paths | `path_provider` |
| Install APK | `open_file` |
| External links | `url_launcher` |
| Scaling | `flutter_screenutil` |
| Fonts | `google_fonts`: Nunito (body), Playfair Display (titles / big Anywaa words) |
| Icons/launcher | `flutter_launcher_icons` |
| Lints | `flutter_lints` (`analysis_options.yaml`) |

Key dependency versions (from `pubspec.yaml`):
`cupertino_icons ^1.0.2`, `flutter_screenutil ^5.9.0`, `audioplayers ^5.2.1`,
`url_launcher ^6.2.2`, `provider ^6.1.1`, `shared_preferences ^2.2.3`,
`http ^1.2.0`, `package_info_plus ^8.0.0`, `path_provider ^2.1.2`,
`open_file ^3.3.2`, `google_fonts ^6.2.1`, `crypto ^3.0.3`.

---

## 3. Architecture and startup flow

Entry point is `lib/main.dart`.

1. `main()` is `async`. It calls `WidgetsFlutterBinding.ensureInitialized()`,
   then preloads `SharedPreferences` before `runApp`.
2. It reads the saved `theme_mode` and `sound_enabled` and passes them into
   `AppSettingsNotifier(initialThemeMode: ..., initialSoundEnabled: ...)`.
   Preloading synchronously means the correct theme is applied on the very
   first frame (no flash of the system theme on relaunch).
3. `MaterialApp` is wrapped in the `AppSettings` `InheritedNotifier`, so any
   screen can read/write settings via `AppSettings.of(context)`.
4. `MyApp` sets `theme`, `darkTheme`, and `themeMode` from the notifier, and
   declares the named routes.

Routing / navigation:

- Route `/` -> `Wrapper` (`lib/wraper.dart`).
- `Wrapper` loads the saved name. While loading it shows a branded splash
  (logo, "Dha Anywaa", a small spinner with a fade-in animation).
- After load: if no name is set (`name == 'guess'`) it shows `NameEntry`
  (first-run name capture); otherwise it shows `HomePage`.
- `HomePage` (`lib/home_page.dart`) provides the drawer, bottom nav, category
  grid, progress, and links to Settings, Help, About, Privacy, Terms.

Named routes (from `main.dart`):

| Route | Screen |
|---|---|
| `/` | `Wrapper` (splash + gate) |
| `home_page` | `HomePage` |
| `name_entry` | `NameEntry` |
| `alphabet` | `Page1` (Alphabet) |
| `word` | `Page2` (Words) |
| `reading` | `Page3` (Reading sentences) |
| `quiz` | `Page4` (Quiz) |
| `number` | `Number` |
| `colors` | `Kit` |
| `shape` | `Shpae` (note: class name is misspelled in code) |
| `body` | `BodyPart` |
| `fish` | `Fish` |
| `animal` | `Animal` |
| `bird` | `Bird` |
| `clothes` | `Cloth` |

After finishing the quiz, `Page4` navigates (pushReplacement) to `Result`
(`lib/result_page.dart`) with the final score and total.

---

## 4. Screens and features

| Screen | File | What it does |
|---|---|---|
| Alphabet | `pages/page1.dart` | 29 letters, large card view, per-letter audio, mark as learned |
| Words | `pages/page2.dart` | 29 illustrated words with audio |
| Reading | `pages/page3.dart` | 29 sentences with audio |
| Quiz | `pages/page4.dart` | 31 multiple-choice questions, shuffled, live score, confirm before quitting, result screen |
| Colors | `components/colors.dart` | 8 color cards with pictures |
| Shapes | `components/shape.dart` | 4 shape cards |
| Body | `components/body_part.dart` | 18 body parts with pictures |
| Clothes | `components/cloth.dart` | 10 clothing items |
| Birds | `components/bird.dart` | 12 birds |
| Animals | `components/animal.dart` | 14 animals |
| Fish | `components/fish.dart` | 10 fish (Dha Anywaa names, English labels pending) |
| Numbers | `components/number.dart` | 1 to 10 |
| Settings | `settings_page.dart` | Sound toggle, name change, theme (System/Light/Dark), Check for update, Privacy, Terms |
| Help | `help.dart` | Usage help per feature |
| About | `about.dart` | App info |
| Privacy Policy | `privacy_policy_page.dart` | In-app privacy disclosure |
| Terms | `terms_page.dart` | Terms of use |

Extra content/data modules: `Questions.dart` (quiz model), `Sentence.dart`,
`words.dart`, `vowel.dart`, `vowelLetter.dart`, `letters_and_sound.dart`,
`body_part.dart` (top level), `widgets/body.dart`, and
`components/detail_screen.dart` (a reusable grid + detail screen used by the
category screens).

Progress tracking: each learned item is stored per category, and the home
screen shows progress as learned/total per category. Totals are defined in
`_categoryTotals` in `home_page.dart`:

```
alphabet 29, number 10, word 29, reading 29, colors 8, shape 4,
body 18, clothes 10, bird 12, animal 14, fish 10, quiz 31
```

### Quiz details (`pages/page4.dart`)

- A `PageView.builder` with `NeverScrollableScrollPhysics` (advance only via
  the Next button), a top bar with a close (X) button, "Question n of total",
  and a live score badge.
- Picture questions show the image (text-only questions using
  `blank_image.png` are handled without an empty placeholder).
- Answer state is tracked per page (`_pageSelectedIndex`, `_selectedIndex`,
  `_answeredIds`) so a question is only scored once and cannot be re-tapped.
- Feedback colors: green for correct, red for the wrong selection, and the
  correct answer is revealed. Uses `AnimatedScale` for press/pop micro-motion.
- A `PopScope(canPop: false)` intercepts the system back gesture and shows the
  "Quit the quiz?" confirmation dialog. Confirmed only by "Quit anyway".

---

## 5. Content and assets

Assets live under `assets/`:

| Folder | Purpose | Notes |
|---|---|---|
| `sound/` | Alphabet letter audio | ~29 files (A, B, ... including Dh, Ng, Nh, Ny, Th, and dotted vowels) |
| `word_sound/` | Word audio | ~30 files |
| `sentence_sound/` | Reading audio | ~29 files (`Voice6.mp3` is missing) |
| `word_images/` | Word + logo + blank placeholder | includes `app_logo.png`, `awal_icon.jpeg`, `blank_image.png` |
| `category_image/` | Home grid tiles | alphabets, numbers, colors, shapes, body, quiz, reading, book |
| `animals/` `birds/` `fish/` `body_part/` `cloth/` | Themed pictures | one PNG per item |

The launcher icon is generated from `assets/word_images/app_logo.png` via
`flutter_launcher_icons`.

---

## 6. Data model and persistence

All persistence goes through `lib/components/savedData.dart`, a thin wrapper
over `SharedPreferences`. Every getter fetches the cached instance, so the
data is local only.

| Key | Type | Meaning / default |
|---|---|---|
| `name` | String | Learner name, default `guess` (sentinel = no name yet) |
| `last_route` | String | Last visited category, used by the Continue card |
| `learned_<category>_<index>` | bool | Marks a single item as learned (e.g. `learned_alphabet_3`) |
| `sound_enabled` | bool | Sound effects on/off, default true |
| `theme_mode` | int | 0 system, 1 light, 2 dark (stored as `ThemeMode.index`) |
| `ota_last_check_ms` | int | Timestamp of last OTA check, powers the 6-hour cache |

Methods: `getName/setName`, `getLastRoute/setLastRoute`, `isLearned`,
`setLearned`, `learnedCount(category, total)`, `getSoundEnabled/setSoundEnabled`,
`getThemeMode/setThemeMode`, and `clearProgress()` which removes every
`learned_*` key and `last_route` (used to reset progress on logout).

### Settings store (`lib/app_settings.dart`)

- `AppSettings` is an `InheritedNotifier<AppSettingsNotifier>`; read anywhere
  with `AppSettings.of(context)`.
- `AppSettingsNotifier` is a `ChangeNotifier` holding `_themeMode` and
  `_soundEnabled`. It accepts `initialThemeMode` / `initialSoundEnabled` so
  values can be applied synchronously at startup, and still refreshes via
  `_load()`.
- `setThemeMode(ThemeMode)` and `setSoundEnabled(bool)` update state, call
  `notifyListeners()` (rebuilding `MaterialApp`), then persist.

---

## 7. Theming (`lib/theme/app_theme.dart`)

A single centralized theme with Material 3 and a semantic, theme-aware palette
exposed as a `ThemeExtension<AppColors>`.

Brand tokens: `kGreen #1F4D3A` (forest green, solid surfaces/buttons),
`kGreenMid #2D6A4F`, `kGold #C9993A`, `kRust #A8472A` (terracotta).

Semantic colors (`context.c.<name>`):

| Token | Light | Dark |
|---|---|---|
| `bg` | `#F6EFE3` (sand) | `#101512` |
| `card` | `#FFFFFF` | `#1B221D` |
| `text` | `#1B1F1C` | `#ECEAE4` |
| `textSub` | `#5B625D` | `#A7B0A8` |
| `border` | `#E4DACB` | `#2C352E` |
| `accent` | `#1F4D3A` | `#7FB896` |

Usage convention: new code should read `context.c.*` (via the `AppColorsX`
extension `context.c`) rather than hard-coded colors, so light/dark stay
correct. Shared shadows: `kShadowSoft` (blur 8), `kShadowCard` (blur 12),
`kShadowBtn`. Shared decoration helpers: `cardDeco`, `gridCellDeco`,
`detailCardDeco`. Text theme uses Nunito with Playfair Display for
display/headline sizes. `AppTheme.data` is the light theme and `AppTheme.dark`
the dark theme.

Visual polish conventions used across the app: rounded corners (radius 14-20
for cards/buttons), soft shadows (blur 8-12), and micro-animations
(`AnimatedScale` press feedback, `AnimatedSwitcher` / scale-in transitions).
Circular badges fit their text with `FittedBox` (scaleDown, maxLines 1) so
long words never overflow.

---

## 8. OTA update system (`lib/services/ota_service.dart`)

The app self-updates from GitHub Releases. No app store is involved.

Config: owner `KornellaOtf`, repo `Dha-Anywaa-application`, endpoint
`.../releases/latest`, cache TTL 6 hours (`ota_last_check_ms`).

### Check

`checkForUpdate({forceCheck})`:
1. If not forced, returns early when the last check was under 6 hours ago.
2. Fetches `releases/latest`, finds the `manifest.json` asset, downloads it.
3. Compares `manifest.versionCode` against the installed
   `PackageInfo.buildNumber`. If remote is greater, it returns an
   `OtaCheckResult` (version, versionCode, apkUrl, sha256, sizeBytes,
   mandatory, releaseNotes); otherwise null.

Triggers: `HomePage` auto-checks after the first frame (cached, non-forced);
`Settings -> Check for update` forces a fresh check (bypasses the cache). If
`mandatory` is true, the update dialog is not dismissible.

### Download (resumable, singleton)

`OtaService` is a **singleton** (`factory OtaService() => instance`) exposing a
`ValueNotifier<OtaDownloadState>` (`idle / running / success / error`,
`progress`, `message`, `filePath`). Because the download lives in the service
and not in a widget, it keeps running when you leave the Settings screen; the
UI just listens.

`startDownload(result)`:
- Idempotent: a second call while one is running is ignored (no duplicate).
- Streams bytes to `dha_anywaa_update.apk.part` in the external storage (or
  app documents) directory.
- Resumable: on (re)start it measures the existing `.part` bytes and sends
  `Range: bytes=<n>-`; if the server honors it (HTTP 206) it appends, else
  (HTTP 200) it truncates and starts over.
- Per-read idle timeout (60s) and a 30s header timeout, so a stalled transfer
  aborts cleanly.
- After download it verifies the byte size against the manifest, computes
  SHA-256 over the finished file, and compares it; on any mismatch it deletes
  the partial file and reports failure. On success it renames the `.part` to
  the final APK and sets the state to success.

On success the Settings tile flips to "Install update" and calls
`OpenFile.open(...)` so Android shows the installer. (Grant "install unknown
apps" when prompted.)

Note: this fixes navigation and accidental process restarts within the running
app. A guaranteed true background download that survives a full force-kill
would require a native downloader (e.g. WorkManager / flutter_downloader),
which is not currently used.

The home-screen update dialog instead opens the APK URL in the external
browser (`url_launcher`), which is a separate code path from the in-app
downloader.

---

## 9. Release pipeline (`.github/workflows/release.yml`)

Releases are built and published by GitHub Actions, not locally (local builds
can hit memory limits).

- **Trigger:** pushing a tag matching `v*` (e.g. `v1.1.5`), plus manual
  `workflow_dispatch`. Permissions: `contents: write`.
- **Steps:**
  1. Checkout.
  2. Set up Java 17 (Temurin).
  3. Set up Flutter `3.47.7` (cached).
  4. `flutter pub get`.
  4b. Restore the signing keystore from secrets (`KEYSTORE_BASE64`,
      `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`) into
      `android/upload-keystore.jks` + `android/key.properties`.
  5. **Build signed release APK.** The build number is taken from the pubspec
     `+N` suffix (e.g. `100`), not the CI run counter, so the APK versionCode
     always matches the manifest versionCode.
  6. Rename APK to `dha-anywaa-<TAG>.apk`.
  7. Compute SHA-256 and byte size of the APK.
  8. Write `manifest.json` with real `version`, `versionCode`, `apkUrl`,
     `sha256`, `sizeBytes` (version/versionCode come from pubspec; `apkUrl`
     points at the release download for that tag).
  9. Publish (idempotent): `gh release create <TAG> --generate-notes --latest`
     (ignore if it exists), then `gh release upload <TAG> <apk> manifest.json
     --clobber`.
- **Duration:** ~5-7 min on a warm cache, ~19-27 min on a cold cache.

### Versioning and tagging

- Tags follow `vX.Y.Z`.
- `pubspec.yaml` holds `version: X.Y.Z+NN`. **`NN` is the versionCode used for
  OTA detection** and must increase on every release. Both the manifest and the
  installed APK now derive it from `NN`, so OTA shows an update whenever the
  new `NN` is greater than what is already on the device.
- Example history: `1.1.1+14` ... `1.1.4+17`, then `1.1.5+100` (a high `NN`
  chosen to clearly exceed previously installed builds).

Standard release procedure:
1. Bump `version:` in `pubspec.yaml` (increment the `+NN`).
2. Commit, then create an annotated/lightweight tag `vX.Y.Z`.
3. Push the commit and the tag; the tag push triggers the CI build and the
   published GitHub Release.

Repo branch/commit conventions: work on feature branches (e.g.
`ui-cleanup-startup`), descriptive commit messages, and a security review gate
is offered before each push (see project SCM settings; the L3 scan prompt can
be disabled from Qoder Settings > Security).

---

## 10. Building and running locally

Requirements: Flutter 3.47+, Android SDK, a device or emulator.

```bash
flutter pub get          # install dependencies
flutter run              # debug on connected device
flutter build apk --release   # signed release APK (needs android/key.properties)
# output: build/app/outputs/flutter-apk/app-release.apk

dart analyze lib test    # static analysis
flutter test             # run the test suite
```

The release keystore is configured in `android/key.properties` (not committed);
in CI it comes from GitHub Actions secrets.

Tests: `test/widget_test.dart` currently contains deterministic regression tests
for theme persistence (index-to-`ThemeMode` mapping, SharedPreferences
round-trip, synchronous startup application, and `setThemeMode` persisting the
chosen mode). The old stock "counter" smoke test was replaced because it never
applied to this app and crashed without its `AppSettings` ancestor.

---

## 11. Permissions (Android)

| Permission | Reason |
|---|---|
| `INTERNET` | Update check via the GitHub Releases API and APK download |
| `ACCESS_NETWORK_STATE` | Skip the update check when offline |
| `REQUEST_INSTALL_PACKAGES` | Install the downloaded update APK |

A `network_security_config.xml` lives under `android/app/src/main/res/xml/`.

---

## 12. Privacy summary

All user data (name, learned progress, sound and theme preferences, last update
check time) is stored only on the device via SharedPreferences and never leaves
it. The only outbound network traffic is the update check to `api.github.com`
(which includes the device IP as part of normal HTTPS) and the optional APK
download from GitHub release assets. There is no analytics, no advertising, and
no account. The full text is shown in-app under Settings, Privacy Policy, and
Terms.

---

## 13. Known content gaps (tracked for the developer)

- `sentence_sound/Voice6.mp3` is missing; the "Dh / Dhieng" reading item plays
  silently.
- All 10 fish entries have no English label.
- "Öök" in Words has no English label.
- Suspected typos to review: "Crocdile", "Hayna", "Quitar", "Three Angle".
- Orphan file: `word_sound/Ec.mp3` (not referenced by any word).
- Stray file: `assets/body_part/lion.png` (not a body part image).
- Class name `Shpae` (Shapes) is misspelled in code.

---

## 14. Project structure (lib/)

```
lib/
  main.dart                 Entry point: preload prefs, AppSettings, MaterialApp, routes
  wraper.dart               Startup gate: splash, then NameEntry or HomePage
  home_page.dart            Home: drawer, bottom nav, category grid, progress, OTA auto-check
  nameEntry.dart            First-run name capture
  app_settings.dart         InheritedNotifier settings store (theme + sound)
  settings_page.dart        Sound, name, theme selector, Check for update (OTA UI)
  help.dart  about.dart     Help and about screens
  privacy_policy_page.dart  In-app privacy policy
  terms_page.dart           Terms of use
  result_page.dart          Quiz result screen
  letters_and_sound.dart    Alphabet/sound helper screen
  vowel.dart  vowelLetter.dart  Words.dart body_part.dart  Sentence.dart  Questions.dart
  pages/
    page1.dart  Alphabet
    page2.dart  Words
    page3.dart  Reading
    page4.dart  Quiz
  components/
    detail_screen.dart      Reusable grid + detail screen
    number.dart  colors.dart  shape.dart  body_part.dart
    cloth.dart  bird.dart  animal.dart  fish.dart
    savedData.dart          SharedPreferences helpers
    audio_helper.dart       Safe audio playback
  services/
    ota_service.dart        GitHub Releases update check + resumable singleton downloader
  theme/
    app_theme.dart          Color tokens, ThemeExtension, light/dark ThemeData
  widgets/
    body.dart               Shared widget(s)
```

---

## 15. Credits and license

Developed by **Kornella Otf**. Contact: Kornellaotf@gmail.com.

All rights reserved. The Dha Anywaa language content, audio recordings and
illustrations are the property of their respective creators and are provided
for educational use only.
