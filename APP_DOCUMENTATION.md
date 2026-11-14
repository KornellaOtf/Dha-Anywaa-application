# Dha Anywaa — Complete App Documentation

> Everything about the app in one place: purpose, features, screens,
> architecture, services, data model, theme system, OTA updates, release
> pipeline, platform support, and known limitations.

- **App name:** Dha Anywaa
- **Dart package:** `dha_anywaaa`
- **Android application id:** `com.kornellaotf.learn_dha_anywaa`
- **Current version:** `1.9.8+2194` (see `pubspec.yaml` and `manifest.json`)
- **Developer:** Kornella Otf — kornellaotf@gmail.com
- **Repository:** https://github.com/KornellaOtf/Dha-Anywaa-application
- **Primary platform:** Android · also builds/runs on Linux desktop

---

## 1. What the app is

Dha Anywaa (also written Anuak) is a Nilo-Saharan language of the Eastern
Sudanic branch, closely related to Dinka and Nuer, spoken primarily in the
Gambella region of Ethiopia and along the rivers of South Sudan.

This is an **offline-first** learning app: alphabet, illustrated vocabulary,
reading sentences, quizzes, spaced-repetition practice, an offline Anywaa AI
assistant, and the full Bible in Anywaa with English translation. No account
required. The only network use is the optional OTA update check against
GitHub Releases and anonymous Firebase Analytics.

Target audience: children and beginner learners of the language.

---

## 2. Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter / Dart (`>=3.2.1 <4.0.0`) |
| State | `provider` (AppSettings), `setState`, singletons for services |
| Storage | `shared_preferences` (all progress, prefs, FSRS state) |
| Spaced repetition | Custom FSRS-6 implementation (`LearningEngine`) |
| Analytics | Firebase Analytics (guarded — no-ops when unavailable) |
| Audio | `audioplayers` |
| Updates | Custom OTA via GitHub Releases (`OtaService`) |
| Fonts | `google_fonts` (Playfair Display for display text) |

---

## 3. Feature map

### Home (`lib/home_page.dart`)
- Greeting header with learner name, streak/XP stat chips
- Quick-action cards: Daily 5, Quick Challenge, Continue reading
- Bottom navigation: **Learn · Quiz · Read · Practice · More**
- Drawer (sidebar): fixed panel (no scrolling), grouped sections —
  **Learn** (Göörë moo cïp dwöl / vowels, Jap dëël / body parts, Dictionary),
  **Discover** (Anywaa AI, Wëël Jwök / Bible, Share), **App** (Settings,
  About, Help), plus Log out. Rounded card tiles with press-scale animation.

### Practice / Learn shell (`lib/pages/practice_learn_page.dart`)
Four tabs sharing `FloatingNav` (`lib/widgets/floating_nav.dart`):
**Overview · Learn · Practice · Progress**

- **Overview** — stats cards (words learned, phrases done), Daily 5 hero,
  "More to explore" rows
- **Learn** — vocabulary categories grid (numbers, alphabet, words, animals,
  birds, fish, body parts, clothes, colors, shapes)
- **Practice** — working session launchers:
  - **Daily 5** — FSRS session, once per day
  - **Random Words** — 10 random words
  - **Long Session** — 20 words
  - **Mistakes Review** — words flagged by FSRS (lapses / low accuracy /
    high difficulty), worst first, up to 10
  - **Saved Words** — all words with FSRS history, most overdue first, up to 15
  - Notifications sheet (daily reminder toggle)
- **Progress** — stats, categories progress, gamification state

Custom practice sessions reuse the Daily Five session UI and **record every
answer into FSRS** and award XP, but do **not** consume the daily slot.

### Daily Five (`lib/pages/daily_five_page.dart`)
- FSRS-6 driven session: picture → pick the Anywaa word → instant feedback
- Combo tracking, per-card XP, progress dots, haptic feedback
- Once per day (`LearningEngine.isDailyCompleted` / `markDailyCompleted`)
- Branded exit-confirmation dialog (progress is not saved on exit)
- Summary screen: accuracy, XP earned, best combo, per-word results;
  shows a session label for custom modes (e.g. "RANDOM WORDS")
- Empty states for already-done-today and no-words-available

### Quiz / Quick Challenge (`lib/pages/page4.dart`, `quick_challenge_page.dart`)
- Multiple-choice quiz with live score, celebration overlays, take-a-break
  exit dialog

### Reading (`lib/pages/page1.dart`, `page2.dart`, `page3.dart`)
- Alphabet, words, and sentence reading with audio; learned-state tracked
  via `SavedData` (`learned_<category>_<index>` keys)

### Bible (`lib/pages/bible_page.dart`)
- Full Bible (66 books) in Anywaa with optional English translation
- Library: clean app bar, Old/New Testament segmented switcher, continue-
  reading banner, book list rows (letter avatar, chapter count, "Reading"
  badge on current book)
- Chapter grid with book header, highlighted current chapter
- Reader: Anywaa text + optional English, adjustable font size, night mode,
  cross-book previous/next chapter navigation, search with debounce
- Reading-settings bottom sheet (font size slider, English toggle, night
  toggle) — repaints instantly on night-mode change
- All preferences persisted (`bible_night`, `bible_show_eng`,
  `bible_font_size`, last position)

### Anywaa AI (`lib/anywaa_ai_page.dart`, `lib/services/anywaa_ai_service.dart`)
- Fully offline assistant: word lookup, English↔Anywaa, pronunciation,
  examples, numbers, cultural facts
- Backed by `assets/data/dictionary_full.json` (3,400+ entries, includes
  merged entries from external News scrape)

### Dictionary
- Currently a "Coming Soon" placeholder page (real dictionary data lives in
  the Anywaa AI and `dictionary_full.json`)

### Settings (`lib/settings_page.dart`)
- Theme picker (System / Light / Dark) — branded choice dialog
- Sound effects toggle
- Name editor — branded dialog, updates analytics user id
- Reminders — daily reminder toggle + reminder-time picker (Android
  notifications via `RetentionEngine`)
- Updates — version display + "Check for updates" (force-checks OTA)
- Invite Friends — share sheet
- Assistant — shortcut to Anywaa AI
- About — Privacy Policy, Terms of Use, Help, About, open-source licences

### Other pages
- `nameEntry.dart` — first-run name entry (wrapper routes here when no name)
- `about.dart`, `help.dart`, `terms_page.dart`, `privacy_policy_page.dart`
- `dictionary_coming_soon_page.dart`

---

## 4. Architecture

```
lib/
  main.dart                     # init: Firebase(guarded), RetentionEngine,
                                #   quick actions (mobile only), theme load,
                                #   routes, OTA auto-check
  wraper.dart                   # name-gate → NameEntry or HomePage (+ splash)
  home_page.dart                # home screen + drawer
  app_settings.dart             # ThemeMode + sound notifier (provider)
  theme/app_theme.dart          # brand tokens + light/dark ThemeData +
                                #   context.c semantic colors + shadows
  widgets/floating_nav.dart     # shared animated bottom nav (Home + Practice)
  widgets/celebration_widget.dart
  pages/                        # screens listed above
  services/
    learning_engine.dart        # FSRS-6 scheduler + word states
    gamification_service.dart   # XP, levels, streaks, daily goal
    retention_engine.dart       # local notifications + comeback bonus
    ota_service.dart            # GitHub Releases manifest + APK download
    analytics_service.dart      # Firebase Analytics wrapper (null-safe)
    word_aggregator.dart        # WordData model + full vocabulary (~129 words)
    anywaa_ai_service.dart      # offline dictionary/AI replies
    share_helper.dart
    audio_helper.dart (components/)
  components/savedData.dart     # name, last route, learned flags, sound, theme
```

### Key services

- **LearningEngine (FSRS-6)** — per-word stability `S`, difficulty `D`,
  due date, lapses, accuracy. APIs: `loadStates`, `buildDailyFive`,
  `recordReview`, `getDueCount`, `isDailyCompleted`, `markDailyCompleted`,
  `getDailyStreak`. Storage key `fsrs_word_states_v1`.
- **GamificationService** — XP, level thresholds, streaks, streak freezes,
  daily goal. `completeDailyFive(correct,total,comboXp)` is the single XP
  award path.
- **RetentionEngine** — schedules daily/streak-danger/comeback local
  notifications (Android `zonedSchedule`; Linux init works but scheduled
  delivery is Android-only). Keys: notifications enabled/preferred hour/
  last open/sent count.
- **OtaService** — fetches
  `releases/latest/download/manifest.json`, compares `versionCode` to
  `package_info.buildNumber`, 6-hour cache, SHA-256 + size verification,
  background download, `open_file` install.
- **AnalyticsService** — every analytics call null-guards on
  `Firebase.apps.isEmpty`; all methods no-op when Firebase is unavailable.
- **WordAggregator** — `WordData{id, english, anywaa, imageUrl, category}`
  for the full vocabulary used by Daily 5 and all practice modes.
- **SavedData** — SharedPreferences helpers: `name`, `last_route`,
  `learned_<category>_<index>`, `sound_enabled`, `theme_mode`.

### Theme system
- `AppTheme.data` / `AppTheme.dark` + `AppSettings` (system/light/dark)
- `context.c` exposes `bg`, `card`, `text`, `textSub`, `border`, `accent`
- Brand tokens: `kGreen #1F4D3A`, `kGreenMid #2D6A4F`, `kGold #C9993A`,
  `kRust #A8472A`; shadows `kShadowSoft`, `kShadowCard`
- Loaded before `runApp` to avoid theme flash
- Bible has its own independent night-mode palette (`_night` pref)

### Shared UI
- `FloatingNav` — floating pill bottom nav shared by Home and Practice
  shell: press bounce (scale 0.88), selection pop (easeOutBack), animated
  highlight, soft shadow.
- `_PressableCard` (home_page) — press-scale wrapper used by drawer tiles.
- `_BrandedDialog` / `_ChoiceTile` / `_NameDialog` (settings_page) —
  rounded icon-chip dialogs used by theme and name pickers.

---

## 5. Data & storage keys (SharedPreferences)

| Key | Purpose |
|---|---|
| `name` | learner name |
| `last_route` | continue-reading route |
| `learned_<cat>_<i>` | per-item learned flags |
| `sound_enabled`, `theme_mode` | app prefs |
| `fsrs_word_states_v1` | FSRS card states (JSON map) |
| `learn_daily_completed_date`, `learn_daily_streak` | Daily 5 lock + streak |
| `learn_review_log` | review history (legacy) |
| `gam_*` | XP, streak, freezes, daily goal, today XP |
| `analytics_user_id` | hashed analytics id |
| `ota_last_check_ms` | OTA cache timestamp |
| notification keys | enabled, preferred hour, last open, sent count, comeback |
| `bible_*` | night mode, English toggle, font size, last book/chapter |

---

## 6. OTA update system

- Manifest: `manifest.json` in repo root, uploaded as a release asset.
  Fields: `version`, `versionCode`, `apkUrl`, `sha256`, `sizeBytes`,
  `minSupportedVersionCode`, `mandatory`, `releaseNotes`, `developer`.
- App fetches `releases/latest/download/manifest.json`; skips if
  `remote versionCode <= local buildNumber`; caches result 6 h
  (`ota_last_check_ms`); Settings → Check for updates forces a fresh check.
- Download verifies SHA-256 + size before install; `OpenFile.open` hands
  the APK to the Android installer.
- **Rule:** `pubspec.yaml` version (`x.y.z+build`) and `manifest.json`
  `versionCode` must always match — bump both together.

---

## 7. Release pipeline

1. Bump `pubspec.yaml` → `version: X.Y.Z+BUILD`
2. `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
3. Copy to `.tmp_apk/dha-anywaa-vX.Y.Z.apk`
4. Update `manifest.json` (version, versionCode, apkUrl, sha256, sizeBytes)
5. Add `CHANGELOG.md` entry
6. `git commit` (as Kornella Otf) → `git tag vX.Y.Z` → push branch + tag
7. `gh release create vX.Y.Z <apk> manifest.json --title "vX.Y.Z" --notes …`
8. Verify: assets list, manifest on tag, `releases/latest` (CDN may lag
   a few minutes)

Docs: see `RELEASE.md` and `docs/RELEASE_WORKFLOW.md`.

---

## 8. Platform support

| Platform | Status |
|---|---|
| Android | Primary target; release APKs via GitHub Releases + OTA |
| Linux | Builds and runs (debug verified); Firebase/analytics and scheduled notifications gracefully disabled |
| Windows | Code-compatible; must be built on Windows + Visual Studio |
| Web / macOS / iOS | Scaffolded; untested |
| Android TV | Not supported — touch-first UI, no D-pad/leanback mode |

Mobile-only plugins (quick actions) are gated to Android/iOS;
Firebase init and analytics observer are guarded; notification init
includes Linux settings; `zonedSchedule` is Android-only.

---

## 9. Permissions

- `POST_NOTIFICATIONS` (Android 13+) — requested via reminder toggle
- `SCHEDULE_EXACT_ALARM` / exact alarms (Android 12+) — reminder scheduling
- `REQUEST_INSTALL_PACKAGES` — OTA APK install
- Internet — only for OTA manifest/APK and Firebase Analytics

---

## 10. Privacy

- No accounts; learner name stored locally only
- Analytics uses a SHA-256 hash of the name as user id (no raw PII)
- All learning progress is on-device (SharedPreferences)
- See `PRIVACY.md` and the in-app Privacy Policy page

---

## 11. Known limitations / tech debt

- Dictionary is a "Coming Soon" placeholder (data exists in Anywaa AI)
- Bible audio is a placeholder pill
- Scheduled local notifications are Android-only (Linux plugin lacks
  `zonedSchedule`)
- Windows builds require a Windows machine/CI
- Gradle 8.14.2 / AGP 8.11.1 / Kotlin 2.2.20 approaching Flutter support
  floors — upgrade before they are dropped
- Repo contains large historical APK/ZIP assets (>50 MB GitHub warnings)
- `.tmp_apk/` holds local APK copies (~900 MB) — clean periodically
- Analyzer: pre-existing warnings remain (deprecated `withOpacity`,
  unused elements in `home_page.dart`)

---

*Last updated for v1.9.8 (build 2194).*
