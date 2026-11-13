# Learn Dha Anywaa

A Flutter app for learning the Dha Anywaa (Anuak) language.
Alphabet, vocabulary, reading, quizzes, spaced repetition, daily reminders,
and an offline AI assistant. Works fully offline.

**Current Version**: 1.4.9 (build 169)
Developed by **Kornella Otf** (Kornellaotf@gmail.com)

Download: [Latest Release](https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest)

---

## What it is

Dha Anywaa (also written Anuak) is a Nilo-Saharan language spoken in
Ethiopia and South Sudan. This app is designed for absolute beginners.
It teaches the alphabet with audio, vocabulary with pictures and audio,
reading sentences, and tests knowledge with a multiple-choice quiz.

No account or internet connection is required to use the core features.
The app checks for updates once every 6 hours when online.

---

## Features

### Learning

| Screen | What it does |
|---|---|
| Alphabet | 29 letters, large card view, audio playback, mark as learned |
| Words | 29 illustrated words with audio |
| Reading | 29 sentences with audio |
| Colors | 8 color cards with pictures |
| Shapes | 4 shape cards |
| Body | 18 body parts with clean SVG illustration |
| Clothes | 10 clothing items |
| Birds | 12 birds |
| Animals | 14 animals |
| Fish | 10 fish |
| Numbers | 1 to 10 |
| Quiz | 31 questions, live score, confirm before quitting |
| Anywaa AI | Offline translation and learning assistant (3,346 words) |
| Daily 5 | Spaced repetition session: 5 words mixing due, weak, and new |

### Retention and Gamification

| Feature | What it does |
|---|---|
| Daily reminders | Smart notifications at user-selected time, fires even in Doze mode |
| Streak tracking | Consecutive day streak with milestones at 3, 7, 14, 30 days |
| XP and levels | Earn XP for audio, lessons, quizzes; level up with celebrations |
| Comeback bonus | +50 XP when returning after 3+ days away |
| Combo bonus | Bonus XP for 3+ correct answers in a row |
| Personal best | Weekly word count tracked against personal record |
| Celebrations | Confetti on quiz completion, trophy on level up, streak milestone pops |

### Home Screen Shortcuts

Long-press the app icon on your home screen for quick access:
- Take a Quiz
- Ask Anywaa AI
- Share App

### Share

Share the app directly from the drawer or Settings. Share quiz scores,
streak milestones, learned words, and personal bests. All share messages
include a direct GitHub APK download link.

---

## Project structure

```
lib/
  main.dart                    App entry, initialization, quick actions
  wraper.dart                  Startup: loads name, shows spinner
  home_page.dart               Home screen, drawer, category grid, stats
  nameEntry.dart               Welcome / onboarding screen
  settings_page.dart           Settings: theme, sound, reminders, share, OTA
  anywaa_ai_page.dart          AI chat interface
  pages/
    page1.dart                 Alphabet
    page2.dart                 Words
    page3.dart                 Reading
    page4.dart                 Quiz
    daily_five_page.dart       Daily 5 spaced repetition session
    quick_challenge_page.dart  30-second micro-loop
    result_page.dart           Quiz results with celebrations
  components/
    detail_screen.dart         Reusable grid and detail screen
    animal.dart                Animals (14 words)
    bird.dart                  Birds (12 words)
    body_part.dart             Body parts
    cloth.dart                 Clothes
    colors.dart                Colors (8 words)
    fish.dart                  Fish
    number.dart                Numbers
    shape.dart                 Shapes (4 words)
    savedData.dart             SharedPreferences helpers
  services/
    analytics_service.dart     Firebase Analytics wrapper
    gamification_service.dart   XP, streaks, levels, celebrations
    learning_engine.dart       Spaced repetition (Leitner box model)
    leaderboard_service.dart   Personal best / weekly leaderboard
    ota_service.dart            GitHub Releases update checker and downloader
    retention_engine.dart      Notification scheduling and comeback bonus
    share_helper.dart          Native share sheet helper
    word_aggregator.dart       Unified word data model and vocabulary list
  theme/
    app_theme.dart             Color tokens and ThemeData
  widgets/
    body.dart                  Body parts screen with SVG illustration
    brand_leaf.dart            Brand logo widget
    celebration_widget.dart    Confetti / celebration overlay
assets/
  sound/                       Alphabet audio (29 files)
  word_sound/                  Word audio (30 files)
  sentence_sound/              Reading audio (29 files)
  word_images/                 Word and category images
  category_image/              Home grid images
  animals/                     Animal images
  birds/                       Bird images
  fish/                        Fish images
  body_part/                   Body part images
  cloth/                       Clothing images
  data/                        AI dictionary and model files
android/
  app/build.gradle             Package: com.kornellaotf.learn_dha_anywaa
  app/src/main/
    AndroidManifest.xml
    res/xml/shortcuts.xml       Home screen shortcut definitions
    res/xml/network_security_config.xml
docs/
  ARCHITECTURE.md               Full system architecture
  RELEASE_NOTES_v1.4.9.md       Latest release notes
  FIREBASE_ANALYTICS_GUIDE.md   Analytics guide
  RELEASE_WORKFLOW.md           Release process guide
```

---

## Latest Updates (v1.4.9)

### Redesigned Welcome Screen
- Gradient hero with brand logo glow
- 3 feature pills: Audio, Offline, Quizzes
- Cleaner single-column form layout

### Redesigned Quit Quiz Dialog
- Side-by-side Quit and Keep going buttons
- Pause icon instead of running person
- Calmer "Take a break?" tone

### Daily 5 Now Works
- Connected to 38 real vocabulary words (Animals, Birds, Colors, Shapes)
- Spaced repetition with Leitner box model
- XP rewards and combo tracking
- Session summary with stats

### Home Screen Shortcuts
- Long-press app icon for Take a Quiz, Ask Anywaa AI, Share App
- Static shortcuts XML for instant native display

### Reminder System Fixes
- Fixed date calculation crash at month boundaries
- Added Android 12+ exact alarm permissions
- Fixed toggle ON/OFF state sync (switch no longer shows ON when permission denied)
- Added user feedback toasts for all toggle actions
- Re-request permission when changing reminder time

### Share
- APK URL updated to v1.4.9
- Netlify link removed entirely (GitHub APK only)

See [full changelog](CHANGELOG.md) and [release notes](docs/RELEASE_NOTES_v1.4.9.md).

---

## Build and run

Requirements: Flutter 3.47+, Android SDK, a connected device or emulator.

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

The release keystore is configured in `android/key.properties` (not committed).
For CI, the keystore is stored as a GitHub Actions secret.

---

## Permissions

| Permission | Why |
|---|---|
| INTERNET | Update check via GitHub, Firebase Analytics |
| ACCESS_NETWORK_STATE | Skip update check when offline |
| REQUEST_INSTALL_PACKAGES | Install downloaded update APK |
| POST_NOTIFICATIONS | Daily reminder notifications (Android 13+) |
| SCHEDULE_EXACT_ALARM | Fire notifications on time even in Doze mode (Android 12+) |
| USE_EXACT_ALARM | Exact alarm scheduling (Android 12+) |
| FOREGROUND_SERVICE | Keep OTA download alive when app is backgrounded |
| FOREGROUND_SERVICE_DATA_SYNC | Foreground service type for download |

---

## Privacy summary

User data (name, progress, preferences, streak, XP) is stored only on the
device via SharedPreferences. Firebase Analytics collects anonymous usage
events (screen views, audio plays, quiz scores, lesson completions, update
checks) with privacy-preserving SHA-256 hashed user IDs. No advertising, no
account required. No personal data is sent to any server.

Full policy: see PRIVACY.md or Settings in the app.

---

## Analytics events

| Event | When |
|---|---|
| play_lesson_audio | User plays audio for a letter or word |
| complete_lesson | User marks a lesson as learned |
| finish_quiz | User completes a quiz (score, total) |
| notification_shown | A scheduled reminder notification appears |
| notification_opened | User taps a reminder notification |
| streak_milestone | User hits 3, 7, 14, or 30 day streak |
| comeback_bonus_claimed | User returns after 3+ days and claims bonus |
| check_for_update | App checks GitHub for new version |
| app_update | User downloads and installs an update |
| change_theme | User switches theme |
| toggle_sound | User toggles sound on/off |

---

## Release process

1. Update version in `pubspec.yaml`
2. `flutter build apk --release`
3. Copy APK to `.tmp_apk/dha-anywaa-vX.Y.Z.apk`
4. Get SHA256 checksum
5. Update `manifest.json` with version, SHA, size, release notes
6. Update `share_helper.dart` APK URL
7. Update `CHANGELOG.md` and create `docs/RELEASE_NOTES_vX.Y.Z.md`
8. Commit, tag, push
9. `gh release create` with APK and manifest.json as assets

See [RELEASE_WORKFLOW.md](docs/RELEASE_WORKFLOW.md) for details.

---

## Content gaps (for the developer)

These are known issues in the content, listed here and left untouched in code:

- `sentence_sound/Voice6.mp3` is missing. The "Dh / Dhieng" reading item plays silently.
- All 10 fish entries have no English label.
- "Ook" in Words has no English label.
- Suspected typos to review: "Crocdile", "Hayna", "Quitar", "Three Angle".
- Orphan file: `word_sound/Ec.mp3` (not referenced by any word entry).
- Stray file: `assets/body_part/lion.png` (not a body part image).
- Body parts, clothes, and fish not yet in WordAggregator (need adding for Daily 5).
- Audio paths not set in WordData (Daily 5 is currently silent).

---

## Credits

Developed by Kornella Otf
Contact: Kornellaotf@gmail.com

---

## License

All rights reserved. The Dha Anywaa language content, audio recordings
and illustrations are the property of their respective creators and are
provided for educational use only.
