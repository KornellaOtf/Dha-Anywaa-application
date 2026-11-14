# Dha Anywaa App Architecture

> Canonical documentation now lives in `APP_DOCUMENTATION.md` (repo root).
> This file is kept for historical reference.

Last updated: v1.9.8 (build 2194)

## Overview

Learn Dha Anywaa is a Flutter Android app for learning the Anywaa language.
281 users, ~50% 7-day retention.
Distributed via GitHub Releases (no Play Store).

## Project Structure

```
lib/
  main.dart                    # App entry point, initialization, quick actions
  home_page.dart               # Main home screen, drawer, category grid
  nameEntry.dart               # Welcome / onboarding screen
  settings_page.dart           # Settings: theme, sound, reminders, share, OTA
  wraper.dart                  # Auth wrapper (name entry vs home)
  about.dart                   # About page
  help.dart                    # Help page
  dictionary_coming_soon_page.dart
  dictionary_page.dart
  anywaa_ai_page.dart          # Offline AI word helper (3,346 words)
  vowelLetter.dart
  words.dart                   # Legacy word model
  app_settings.dart            # Theme/sound settings notifier
  
  pages/
    page1.dart                 # Alphabet
    page2.dart                 # Words
    page3.dart                 # Reading
    page4.dart                 # Quiz
    daily_five_page.dart       # Daily 5 learning session
    quick_challenge_page.dart  # 30-second micro-loop
    result_page.dart           # Quiz results
    
  components/
    animal.dart                # Animals vocabulary (14 words)
    bird.dart                  # Birds vocabulary (12 words)
    body_part.dart             # Body parts vocabulary
    cloth.dart                 # Clothes vocabulary
    colors.dart                # Colors vocabulary (8 words)
    fish.dart                  # Fish vocabulary
    number.dart                # Numbers vocabulary
    shape.dart                 # Shapes vocabulary (4 words)
    detail_screen.dart         # Shared word card screen
    savedData.dart             # SharedPreferences helpers
    
  services/
    analytics_service.dart     # Firebase Analytics wrapper
    gamification_service.dart  # XP, streaks, levels, celebrations
    learning_engine.dart       # Spaced repetition (Leitner box model)
    leaderboard_service.dart   # Personal best / weekly leaderboard
    ota_service.dart           # OTA update check and download
    retention_engine.dart      # Notification scheduling and comeback bonus
    share_helper.dart          # Native share sheet helper
    word_aggregator.dart       # Unified word data model and vocabulary list
    
  theme/
    app_theme.dart             # Light and dark theme definitions
    
  widgets/
    body.dart                  # Body parts widget
    brand_leaf.dart            # Brand logo widget
    celebration_widget.dart    # Confetti / celebration overlay
```

## Core Systems

### 1. Retention Engine (lib/services/retention_engine.dart)

Handles all notification scheduling and comeback tracking.

Initialization (main.dart):
```
RetentionEngine.instance.initialize()
RetentionEngine.instance.requestPermission()
```

Called on every app open (home_page.dart initState):
```
RetentionEngine.instance.onAppOpen()
```

What onAppOpen() does:
1. Records last open timestamp in SharedPreferences
2. Cancels pending notifications (user is in app)
3. Re-schedules next notification if enabled

Notification scheduling:
- Uses flutter_local_notifications with tz timezone scheduling
- AndroidScheduleMode.exactAllowWhileIdle (fires even in Doze mode)
- Default time: 7pm, user-adjustable
- 10 rotating message templates (no emoji)

Comeback bonus:
- If last open was 3+ days ago: +50 XP on next open
- Tracked via isComebackEligible() / claimComebackBonus()

Permissions required (AndroidManifest.xml):
- POST_NOTIFICATIONS (Android 13+)
- SCHEDULE_EXACT_ALARM (Android 12+)
- USE_EXACT_ALARM (Android 12+)

Settings integration (settings_page.dart):
- Toggle calls requestPermission() first
- Only updates UI if permission granted
- Toast feedback on every state change
- Time picker re-requests permission before applying

### 2. Gamification Service (lib/services/gamification_service.dart)

XP system:
- Correct answer: 10 XP
- Combo (3+ in a row): +5 XP
- Lesson complete: 5 XP
- Quiz complete: 20 XP
- Streak bonus: varies by streak length

Streak tracking:
- Increments if user opens on consecutive calendar days
- Resets to 1 if a day is missed
- Stored in SharedPreferences

Levels:
- XP thresholds define levels
- Level-up triggers celebration animation

### 3. Learning Engine (lib/services/learning_engine.dart)

Leitner box spaced repetition (5 boxes):
- Box 0 (new): review next session
- Box 1: review in 1 day
- Box 2: review in 3 days
- Box 3: review in 7 days
- Box 4: review in 14 days
- Box 5 (mastered): review in 30 days

Correct answer: advances one box, ease factor increases
Wrong answer: drops one box (not to zero), ease factor decreases

Daily 5 session mix:
- 60% due words (overdue for review)
- 30% weak words (low ease factor)
- 10% new words (never seen)

Word state stored per word ID in SharedPreferences as JSON.

### 4. Word Aggregator (lib/services/word_aggregator.dart)

Provides a unified list of WordData for use in Daily 5 and Learning Engine.

Current vocabulary (38 words):
- Animals: 14 words (cat, dog, lion, giraffe, etc.)
- Birds: 12 words (hen, duck, owl, dove, etc.)
- Colors: 8 words (red, yellow, blue, etc.)
- Shapes: 4 words (circle, triangle, rectangle, oval)

WordData model:
```dart
class WordData {
  final String id;        // e.g. "animal_cat"
  final String english;   // e.g. "Cat"
  final String anywaa;    // e.g. "Adhurrï"
  final String imageUrl;  // e.g. "assets/animals/cat.png"
  final String category;  // e.g. "Animals"
  final String? audioPath; // optional audio file
}
```

To add more words: add entries to _allWordsData in word_aggregator.dart.
To add more categories (e.g. body parts, clothes, fish): add their entries following the same map structure.

### 5. OTA Update System (lib/services/ota_service.dart)

Flow:
1. App checks manifest.json from GitHub on startup (cached 6 hours)
2. Compares versionCode to current build number
3. If update available: navigates to OtaUpdatePage
4. User taps download: background_downloader fetches APK
5. Download survives backgrounding (foreground service)
6. On completion: launches install intent

manifest.json fields:
- version: semantic version string
- versionCode: integer build number
- downloadUrl: direct APK link
- sha256: APK checksum
- size: bytes
- releaseNotes: what's new text
- minSdkVersion: minimum Android version

### 6. Analytics (lib/services/analytics_service.dart)

Firebase Analytics wrapper. All events are emoji-free.

Events logged:
- play_lesson_audio (category, word_id, song_name)
- complete_lesson (category, word_id)
- finish_quiz (score, total, percent)
- notification_shown
- notification_opened
- streak_milestone (days)
- comeback_bonus_claimed (days_away, xp_awarded)
- check_for_update (current_version)
- app_update (from_version, to_version, method)
- change_theme (theme_name)
- toggle_sound (enabled)

User properties set at startup:
- app_version
- build_number
- distribution = "github"

### 7. Share Helper (lib/services/share_helper.dart)

Uses share_plus package. All messages are emoji-free.

Methods:
- shareApp() - generic share from menu/settings
- shareStreak(days) - share streak milestone
- shareQuizResult(score, total) - share quiz score
- shareWord(anywaa, english) - share a learned word
- sharePersonalBest(count) - share weekly record

APK URL points to latest GitHub release download.
No netlify or website links included.

### 8. Home Screen Shortcuts (lib/main.dart)

Implemented via quick_actions package.

Three shortcuts defined:
- action_quiz -> navigates to 'quiz' route
- action_ai -> navigates to 'anywaa_ai' route
- action_share -> calls ShareHelper.instance.shareApp()

Static shortcuts also defined in android/app/src/main/res/xml/shortcuts.xml
so they appear immediately on install without opening the app first.

Required for navigation: GlobalKey<NavigatorState> in _MyAppState,
passed to MaterialApp as navigatorKey.

## Android Manifest Permissions

```xml
INTERNET                      - OTA downloads, Firebase
REQUEST_INSTALL_PACKAGES      - Install APK after OTA download
ACCESS_NETWORK_STATE          - Network check before OTA
POST_NOTIFICATIONS            - Reminder notifications (Android 13+)
SCHEDULE_EXACT_ALARM          - Exact alarm scheduling (Android 12+)
USE_EXACT_ALARM               - Exact alarm scheduling (Android 12+)
FOREGROUND_SERVICE            - Background OTA download
FOREGROUND_SERVICE_DATA_SYNC  - Background OTA download type
```

## Named Routes (main.dart)

```
/              -> Wrapper (checks if name is set, routes to home or name entry)
number         -> Number vocabulary
alphabet       -> Alphabet (Page1)
word           -> Word vocabulary (Page2)
shape          -> Shapes
reading        -> Reading (Page3)
quiz           -> Quiz (Page4)
anywaa_ai      -> Anywaa AI page
home_page      -> Home
name_entry     -> Welcome / onboarding
colors         -> Colors (Kit)
body           -> Body parts
fish           -> Fish
animal         -> Animals
bird           -> Birds
clothes        -> Clothes (Cloth)
```

## Release Process

1. Update version in pubspec.yaml (version: X.Y.Z+BUILD)
2. Build: `flutter build apk --release`
3. Copy APK to .tmp_apk/dha-anywaa-vX.Y.Z.apk
4. Get SHA: `sha256sum dha-anywaa-vX.Y.Z.apk`
5. Update manifest.json with new version, SHA, size, notes
6. Update share_helper.dart APK URL
7. Update CHANGELOG.md
8. Create docs/RELEASE_NOTES_vX.Y.Z.md
9. `git add` changed files, `git commit`, `git tag vX.Y.Z`
10. `git push origin ui-cleanup-startup && git push origin vX.Y.Z`
11. `gh release create vX.Y.Z apk manifest.json --title "..." --notes "..."`

## SharedPreferences Keys

| Key | Type | Purpose |
|-----|------|---------|
| user_name | String | User's display name |
| theme_mode | int | 0=system, 1=light, 2=dark |
| sound_enabled | bool | Audio on/off |
| notifications_enabled | bool | Daily reminders on/off |
| preferred_notification_time | int | Hour of day (0-23) |
| last_open_time | int | Milliseconds since epoch |
| notifications_sent | int | Total notifications shown |
| comeback_bonus_eligible | int | Timestamp of comeback eligibility |
| daily_five_completed | String | ISO date string of last completion |
| daily_completed_date | String | ISO date for LearningEngine daily lock |
| word_state_{id} | String | JSON WordState for spaced repetition |
| xp_total | int | Total XP earned |
| streak_days | int | Current streak count |
| last_streak_date | String | ISO date of last streak update |
| level | int | Current level |
| weekly_word_count | int | Words this week for leaderboard |
| personal_best_weekly | int | All-time best weekly word count |

## Known Issues / Future Work

- Body parts, clothes, fish not yet in WordAggregator (need to add to word_aggregator.dart)
- Audio paths not set in WordData (audioPath is null for all words, Daily 5 is silent)
- Quick Challenge page exists but not wired to real data (same issue as Daily 5 was)
- Cloth._items is private: cannot reference from outside file without exposing getter
- Alphabet and reading categories have no WordData equivalent (different content format)
- 522 existing users need manual GitHub APK download (OTA was broken in earlier versions)
