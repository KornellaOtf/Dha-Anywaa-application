# Dha Anywaa

<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" alt="Dha Anywaa app icon" width="120">
</p>

A Flutter app for learning the Dha Anywaa (Anuak) language — alphabet,
vocabulary, reading, quizzes, spaced repetition, the Bible, and an offline
AI assistant. Works fully offline.

**Current version:** 1.9.2 (build 2188)
**Developer:** Kornella Otf (oriemiobango@gmail.com)

Download: [Latest Release](https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest)

---

## What it is

Dha Anywaa (also written Anuak) is a Nilo-Saharan language spoken in
Ethiopia and South Sudan. This app is designed for absolute beginners and
fluent speakers alike.

No account or internet connection is required for core features. The app
checks for updates via GitHub Releases (see [RELEASE.md](RELEASE.md)).

---

## Features

### Learning

| Screen | What it does |
|---|---|
| Alphabet | 29 letters, large card view, audio playback, mark as learned |
| Words | Illustrated vocabulary with audio |
| Reading | Sentences with audio; learned sentences tracked for progress |
| Practice + Learn | Unified hub: Overview and Progress tabs, due-for-review counts, streaks |
| Daily 5 | Spaced-repetition session: 5 words mixing due, weak, and new |
| Quick Challenge | 30-second micro-loop |
| Quiz | Multiple-choice quiz with live score and celebrations |
| Dictionary | 3,472-word offline dictionary with pronunciation and examples |
| Anywaa AI | Offline chat assistant — translate, meanings, pronunciation, examples, numbers, cultural facts |
| Bible | Full Bible (66 books, OT + NT) in Anywaa with English, search, night mode, text size |

### Anywaa AI

Fully on-device — no network, no model download. Answers are grounded in
the bundled dictionary and cultural facts; it never invents translations.

- English ↔ Dha Anywaa translation, both directions
- "How do you pronounce/say X", example sentences, part of speech
- Numbers 1–9999 spoken with the taught counting rules
- Cultural facts, time/date, greetings, follow-up questions
  ("and the plural?", "say it again", "what about X")

### Retention and Gamification

| Feature | What it does |
|---|---|
| Daily reminders | Smart notifications at a user-selected time, fires in Doze mode |
| Streaks | Consecutive-day streaks with milestones |
| XP and levels | XP for lessons, quizzes, Daily 5; level-up celebrations |
| Comeback bonus | Bonus XP when returning after days away |
| Celebrations | Confetti on quiz completion, trophy on level up |

### Home Screen Shortcuts

Long-press the app icon: Take a Quiz, Ask Anywaa AI, Share App.

### Share

Share the app or quiz scores from the drawer or Settings. Share messages
include the GitHub APK download link.

---

## Project structure

```
lib/
  main.dart                     App entry, init, quick actions, routes
  wraper.dart                   Startup: loads name, shows spinner
  home_page.dart                Home screen, drawer, category grid, stats
  nameEntry.dart                Welcome / onboarding screen
  anywaa_ai_page.dart           Anywaa AI chat interface
  bible_page.dart               Bible reader (library, chapters, search, night mode)
  dictionary_page.dart          Offline dictionary browser
  settings_page.dart            Settings: theme, sound, reminders, share, OTA
  pages/
    page1.dart                  Alphabet
    page2.dart                  Words
    page3.dart                  Reading (tracks learned sentences)
    page4.dart                  Quiz
    daily_five_page.dart        Daily 5 spaced repetition
    practice_learn_page.dart    Practice + Learn hub (Overview/Progress)
    quick_challenge_page.dart   30-second challenge
    result_page.dart            Quiz results
    bible_page.dart             (see lib/bible_page.dart)
  components/
    detail_screen.dart          Reusable grid/detail screen
    savedData.dart              SharedPreferences helpers
    ...                         Per-category word lists (animals, birds, fish, ...)
  services/
    analytics_service.dart      Firebase Analytics wrapper
    anywaa_ai_service.dart      Offline AI: dictionary lookup, intents, numbers
    gamification_service.dart   XP, streaks, levels, celebrations
    learning_engine.dart        FSRS-6 spaced repetition
    leaderboard_service.dart    Personal best / weekly leaderboard
    notification_service.dart   Local notifications
    ota_service.dart            GitHub Releases update checker/downloader
    retention_engine.dart       Notification scheduling, comeback bonus
    share_helper.dart           Native share sheet
    word_aggregator.dart        Unified vocabulary model
  theme/
    app_theme.dart              Color tokens and ThemeData
  widgets/
    celebration_widget.dart     Confetti overlay
    brand_leaf.dart             Brand logo
assets/
  sound/  word_sound/  sentence_sound/   Audio
  word_images/  category_image/  animals/ birds/ fish/ body_part/ cloth/
  data/
    dictionary_full.json        Main dictionary (3,472 words)
    cultural_facts.json         Anywaa cultural knowledge base
    anywaa_dictionary.json      Additional dictionary data
    bible.json                  Full Bible text (~31k verses)
docs/
  ARCHITECTURE.md                System architecture
  FIREBASE_ANALYTICS_GUIDE.md    Analytics guide
  INTEGRATION_GUIDE.md           Integration notes
RELEASE.md                       Build/release/OTA process
CHANGELOG.md                     Version history
```

---

## Build and run

Requirements: Flutter 3.47+, Android SDK, a connected device or emulator.

```bash
flutter pub get
flutter run                 # debug
flutter build apk --release # release APK
flutter analyze             # static analysis
flutter test test/anywaa_ai_test.dart
```

Release keystore: `android/key.properties` (not committed).

---

## Permissions

| Permission | Why |
|---|---|
| INTERNET | Update check via GitHub, Firebase Analytics |
| ACCESS_NETWORK_STATE | Skip update check when offline |
| REQUEST_INSTALL_PACKAGES | Install downloaded update APK |
| POST_NOTIFICATIONS | Daily reminder + OTA notifications (Android 13+) |
| SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM | On-time reminders in Doze (Android 12+) |
| FOREGROUND_SERVICE(_DATA_SYNC) | Keep OTA download alive in background |

---

## Privacy summary

User data (name, progress, preferences, streak, XP) is stored only on the
device via SharedPreferences. Firebase Analytics collects anonymous usage
events with privacy-preserving hashed IDs. No advertising, no account
required. No personal data is sent to any server.

Full policy: see [PRIVACY.md](PRIVACY.md) or Settings in the app.

---

## Release process

See **[RELEASE.md](RELEASE.md)** — covers versioning (versionCode must stay
above 2188), the OTA `manifest.json` contract, tagging, and `gh release`.

Short version:

1. Bump `version:` in `pubspec.yaml`
2. `flutter build apk --release`
3. Update `manifest.json` (version, versionCode, apkUrl, sha256, sizeBytes)
4. Commit, tag `vX.Y.Z`, push
5. `gh release create` with **both** the APK and `manifest.json` as assets

---

## Content notes

Known content gaps (documented, not code bugs):

- `sentence_sound/Voice6.mp3` missing — one reading item plays silently
- Some fish/word entries lack English labels
- Suspected typos to review: "Crocdile", "Hayna", "Quitar", "Three Angle"
- Orphan audio: `word_sound/Ec.mp3`; stray image: `assets/body_part/lion.png`
- Bible source data has verse-number gaps/duplicates in a few chapters
  (translation-source issue; the reader handles it)

---

## Credits

Developed by Kornella Otf
Contact: oriemiobango@gmail.com

## License

All rights reserved. The Dha Anywaa language content, audio recordings and
illustrations are the property of their respective creators and are provided
for educational use only.
