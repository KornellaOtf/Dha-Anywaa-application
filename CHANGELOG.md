# Changelog

## 1.9.5 (build 2191)

Released: 2026-11-14

### Fixed
- Notification engine initialization on desktop platforms (Linux/Windows settings added)
- Notification permission check no longer fails off-Android
- Scheduled notifications safely skipped on platforms that don't support them

## 1.9.4 (build 2190)

Released: 2026-11-14

### Added
- Sidebar/drawer redesign: rounded card tiles, section labels (Learn / Discover / App), press-scale animation matching the floating nav

### Fixed
- Desktop (Linux/Windows) startup crashes: quick-actions plugin and Firebase analytics now guarded when unavailable
- Analytics no longer crashes if Firebase fails to initialize

## 1.9.3 (build 2189)

Released: 2026-11-14

### Added
- Floating pill bottom navigation on Home, shared with Practice/Learn (`FloatingNav`)
- Nav animations: press bounce, selection pop, smooth highlight transitions
- Bible home redesign: 2-column book cover cards, letter avatars, "Reading" badge
- Bible: segmented Old/New Testament pill switcher, chapter-count hero stats
- Bible: redesigned chapter cells, reader top bar avatar, floating prev/next pill bar
- Bible: card-style search results, pill "audio coming soon" badge

### Changed
- Daily 5 can only be played once per day (completion screen on replay)
- Practice/Learn and Quick Challenge now follow the app light/dark theme
- Bible night mode defaults to the app theme until the user picks a mode

## 1.9.2 (build 2188)

Released: 2026-11-13

### Added
- Anywaa AI: pronunciation guides, example sentences, part-of-speech answers, synonyms/opposites
- Anywaa AI: time/date, greetings, thanks, goodbye, help, and identity intents
- Anywaa AI: field questions work without prior context ("example for X", "pronounce Y")
- Pronunciation guide shown under answer cards
- Dictionary expanded to 3,472 words with pronunciation and example data merged from curated source
- Bible: book-name matching in search, cross-book prev/next navigation, load error state with retry

### Fixed
- Practice/Learn compile errors (WordAggregator API, GamState.streakDays, CelebrationOverlay)
- Practice/Learn: real Overview/Progress tabs replacing duplicated HomePage
- Practice/Learn: learner name key, working notification bell, real Daily 5 streak
- Reading progress tracking in page3
- AI reply ranking: typo queries prefer the closest term ("waterr" → water, not hot water)
- Removed em-dashes from user-facing text

## 1.9.1 (build 2187)

Released: 2026-11-13

First build of the Practice+Learn, Bible, and Anywaa AI improvements listed above; superseded by 1.9.2 (punctuation cleanup only).

## 1.4.9 (build 169)

Released: 2026-11-11

### Added
- Home screen shortcuts: long-press app icon for Take a Quiz, Ask Anywaa AI, Share App
- Static shortcuts XML for instant native menu on all Android launchers
- WordAggregator service: aggregates 38 vocabulary words from Animals (14), Birds (12), Colors (8), Shapes (4) into a unified WordData model
- Daily 5 feature now fully functional: connected to real word data with spaced repetition, XP rewards, combo tracking, session summary
- Wrong answer generation: Daily 5 dynamically picks a random different word as the wrong choice
- Image error fallback: Daily 5 shows a placeholder icon if an image asset fails to load
- quick_actions ^1.0.8 package added

### Changed
- Redesigned welcome screen (NameEntry): gradient hero with brand logo glow, 3 feature pills (Audio/Offline/Quizzes), cleaner single-column form
- Redesigned quit quiz dialog: side-by-side Quit/Keep going buttons, pause icon instead of running person, calmer "Take a break?" tone
- Share helper: APK URL updated to v1.4.9, removed netlify website link entirely (GitHub only)
- main.dart: MyApp converted from StatelessWidget to StatefulWidget with GlobalKey<NavigatorState> for shortcut navigation
- daily_five_page.dart: removed duplicate WordData class, now imports unified WordData from word_aggregator.dart
- Settings page toggle: only updates UI state after permission is confirmed, re-requests permission on time change
- AndroidManifest.xml: added SCHEDULE_EXACT_ALARM and USE_EXACT_ALARM permissions, registered shortcuts meta-data

### Fixed
- Date calculation bug in retention_engine.dart: _timeUntilTomorrow() used DateTime(now.year, now.month, now.day + 1) which crashes at month boundaries (Jan 31 + 1 = invalid date). Now uses now.add(Duration(days: 1))
- Notification toggle state desync: switch showed ON even when permission was denied. Now only updates after successful permission grant
- Missing user feedback on notification toggle: added toast messages ("Daily reminders enabled", "Daily reminders disabled", "Please enable notifications in Settings", "Reminder set for X:00 PM")
- Time picker permission leak: user could change reminder time without notification permission. Now re-requests permission before scheduling
- requestPermission() only requested POST_NOTIFICATIONS, not SCHEDULE_EXACT_ALARM. Now requests both

### Technical
- APK size: 86.2MB
- SHA256: 05d755f43665fbfb6bee06077f138ee115bf065ba963a5fc105838647c9a747d
- Branch: ui-cleanup-startup
- 16 files changed, 804 insertions, 259 deletions

---

## 1.4.8 (build 168)

Released: 2026-11-11

### Added
- Share button in drawer: "Share Dha Anywaa" ListTile with share icon
- Share button in Settings: "Invite a Friend" section
- Share quiz result: appears on quiz results scoring 70% or higher
- Personal best leaderboard: weekly word count vs personal record with progress bar
- Streak milestone celebrations added to quiz results
- comeback_bonus_claimed analytics event
- streak_milestone analytics event

### Changed
- Redesigned home page: compact header with time-aware greeting (Good morning/afternoon/evening), stats strip (streak/XP/level), single hero continue card replacing 4 stacked cards, quick action pills (Daily 5/Quiz/Reading), cleaner 2-column category grid
- Comeback bonus XP fixed: awards 50 XP instead of 5
- Streak and level-up celebrations added to quiz result page
- Share helper: removed netlify website link, GitHub APK download only
- All emoji-free across notifications, celebrations, and share messages

### Fixed
- Removed dead NotificationService call that was never wired up
- Comeback bonus XP was awarding 5 instead of 50

### Technical
- APK size: 82MB
- SHA256: a76faec548e80176cdd7a707ef01c55bb74809d6a2f4a1542feac9b0a4bd1d10

---

## 1.4.7 (build 167)

Released: 2026-11-11

### Added
- Spaced repetition system (LearningEngine): Leitner box model with 5 boxes, ease factor adjustment, exponential review intervals
- Smart notification engine (RetentionEngine): daily reminders with AndroidScheduleMode.exactAllowWhileIdle, reschedules on app open, cancels on disable
- Celebration system (CelebrationHelper): confetti on quiz completion, correct answer feedback, level-up trophy animation, streak milestone celebrations
- Gamification service (GamificationService): XP for audio/lessons/quizzes, streak tracking with consecutive day increment, comeback bonus for 3+ day absence, combo bonus for 3+ correct in a row
- Daily 5 card on home page: shows daily practice status with completion indicator
- Personal best leaderboard: tracks weekly word count
- Comeback bonus: +50 XP when user returns after 3+ days away
- Streak milestones: celebrations at 3, 7, 14, and 30 days
- Firebase Analytics events: notification_shown, notification_opened, streak_milestone, comeback_bonus_claimed, finish_quiz, play_lesson_audio, complete_lesson
- Settings page: daily reminder toggle with showTimePicker, preferred notification time stored in SharedPreferences

### Technical
- Packages added: flutter_local_notifications ^17.0.0, timezone ^0.9.4
- RetentionEngine.instance.initialize() and requestPermission() called in main.dart
- RetentionEngine.instance.onAppOpen() called in HomePage.initState()
- Notifications use tz scheduling with exactAllowWhileIdle for Doze mode compatibility

---

## 1.3.4 (build 154)

Released: 2026-11-10

### Fixed
- OTA now uses browser download (no more "keep phone open")
- Dead Qwen/LLaMA stub code removed (llama_service.dart, model_download_service.dart)
- Removed "Download Anywaa-LM" banner from AI page (was never functional)
- AI subtitle updated to "on-device · 3,346 words"

### Changed
- App version: 1.3.3 → 1.3.4
- Build number: 153 → 154

## 1.3.3 (build 153)

Released: 2026-11-10

### Changed
- APK size reduced from 101.8MB to 78.5MB (saved 23MB, 23% smaller)
- Removed x86_64 native library (emulator-only, no real device uses it)
- Compressed all 140 images (strip metadata, optimized quality)
- Build now uses --target-platform android-arm,android-arm64 only
- Downloads ~23% faster on mobile data
- App version: 1.3.2 → 1.3.3
- Build number: 152 → 153

## 1.3.2 (build 152)

Released: 2026-11-10

### Changed
- Reverted to in-app download with progress bar (user request)
- Download happens inside the app with visual progress
- User should keep app open until download completes
- Browser download method kept as fallback (downloadInBrowser)
- App version: 1.3.1 → 1.3.2
- Build number: 151 → 152

## 1.3.1 (build 151)

Released: 2026-11-10

### Changed
- Dictionary "coming soon" is now a full page (not a popup snackbar)
- Clean, centered design showing verification status
- Removed emoji from dictionary message
- App version: 1.3.0 → 1.3.1
- Build number: 150 → 151

## 1.3.0 (build 150)

Released: 2026-11-10

### Added
- Anywaa AI now trained on 3,346 verified words (was 1,353)
- 2x smarter: knows more vocabulary, grammar, cultural context
- AI can now answer questions about words from all 69 categories

### Changed
- Dictionary temporarily hidden with "Coming next month" message
- Will be released publicly after final verification is complete
- Jumped build number to 150 to signal major AI improvement
- App version: 1.2.36 → 1.3.0

## 1.2.36 (build 136)

Released: 2026-11-10

### Fixed
- **OTA downloads now use browser instead of in-app download**
- No more "keep phone open" issue — browser downloads work in background
  on all Android versions (8, 9, 10, 11, 12, 13, 14)
- After download completes, tap the browser's download notification to install
- Fixes 51 failed update attempts reported in analytics (54 tried, only 3 succeeded)

### Changed
- FirebaseAnalyticsObserver already present in main.dart (screen tracking works)
- Added `app_update` analytics event to track browser vs in-app download method
- App version: 1.2.35 → 1.2.36
- Build number: 135 → 136

## 1.2.35 (build 135)

Released: 2026-11-10

### Fixed
- OTA update check completely reworked — no longer uses GitHub API
- Now fetches manifest.json directly via release download URL
  (no authentication required, no rate limit, works for all users)
- Root cause of "you're up to date" bug: GitHub API has 60 req/hour
  unauthenticated limit, hitting it silently returned null = "up to date"
- Also fixed: manifest.json SHA-256 mismatch in v1.2.34

### Changed
- App version: 1.2.34 → 1.2.35
- Build number: 134 → 135

## 1.2.34 (build 134)

Released: 2026-11-10

### Fixed
- Dictionary sources merged by trust priority:
  1. Hand-entered seed words (65, highest trust)
  2. Original in-app dictionary (1,313, natural/authentic)
  3. Additional words from master dictionary (1,968, fills gaps)
- Existing entries enriched with categories, POS, pronunciation and
  examples from master where those fields were missing
- 3,346 total words across 69 categories

### Changed
- App version: 1.2.33 → 1.2.34
- Build number: 133 → 134

## 1.2.33 (build 133)

Released: 2026-11-10

### Changed
- Dictionary: replaced all emoji icons with Flutter Material icons
- Every word card shows a clean, consistent Material icon matching the word
  (e.g. eye → visibility, cow → cruelty_free, water → water_drop, run → directions_run)
- 150+ word-to-icon mappings, falls back to category icon for unmatched words
- No more emoji rendering inconsistencies across Android devices
- App version: 1.2.32 → 1.2.33
- Build number: 132 → 133

## 1.2.32 (build 132)

Released: 2026-11-10

### Fixed
- Dictionary: removed 280 duplicate words (3304 → 3024 unique words)
- Duplicates were cross-category (same word appearing in multiple categories)

### Changed
- Every word card now shows an emoji icon matching the word meaning
  (e.g. eye → 👁️, cow → 🐄, water → 💧, run → 🏃)
- Word cards redesigned: emoji bubble on left, Anywaa word large and bold,
  English below in category colour, POS badge top right
- Cleaner layout, no vibe-coded artifacts from previous version
- App version: 1.2.31 → 1.2.32
- Build number: 131 → 132

## 1.2.31 (build 131)

Released: 2026-11-10

### Fixed
- OTA check was silently failing when GitHub API rate limit was hit (60 req/hour
  for unauthenticated IPs) — now detects 403/429 responses and does NOT cache
  the failed check, so the next open retries instead of waiting 6 hours
- Cache timestamp is now only saved after a successful manifest response,
  not on rate-limit or network failures
- "You're up to date" toast now shows current version number for clarity

### Changed
- App version: 1.2.30 → 1.2.31
- Build number: 130 → 131

## 1.2.30 (build 130)

Released: 2026-11-10

### Added
- Dictionary completely redesigned
- 3,304 verified words imported from Anywaa web database (was 1,353)
- Browse by category: 62 categories with icons, word counts, and colour coding
- Tap any word card to expand: pronunciation guide, example sentences (Anywaa + English), alternative meanings, cultural notes
- Global search across all 3,304 words from the app bar
- Category search to filter within any category
- Part-of-speech badges (noun, verb, adjective, etc.) with colour coding

### Changed
- App version: 1.2.29 → 1.2.30
- Build number: 129 → 130

## 1.2.29 (build 129)

Released: 2026-11-10

### Fixed
- OTA download now survives app backgrounding — users can switch to WhatsApp,
  lock their phone, or use other apps while the update downloads
- Android shows a persistent "Downloading update…" notification in the status
  bar; download continues until complete regardless of app state
- Download resumes automatically if interrupted (retries up to 3 times)

### Technical
- Added `background_downloader ^9.6.6` package
- Added `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_DATA_SYNC` permissions
- OtaService now uses `DownloadTask` with `foregroundServiceType=dataSync`
- `OtaService.initialize()` called at app startup to re-attach any in-progress download

### Changed
- App version: 1.2.28 → 1.2.29
- Build number: 128 → 129

## 1.2.28 (build 128)

Released: 2026-11-10

### Fixed
- Firebase Analytics: all screens now have named routes — no more `(not set)` in Firebase console
- `play_lesson_audio` now includes `song_name` parameter (e.g. `alphabet_A`, `animal_Cow`)
- Named routes added to: vowel_letters, body_parts, anywaa_ai, dictionary, settings,
  privacy_policy, terms_of_use, about, help, ota_update, quiz_result

### Changed
- App version: 1.2.27 → 1.2.28
- Build number: 127 → 128

## 1.2.27 (build 127)

Released: 2026-11-09

### Fixed
- Analytics events now firing across all key user actions
- Quiz completion (`finish_quiz`) logged with score and total
- Alphabet audio plays logged with letter ID
- Alphabet lesson completions logged when marked as learned
- Vocabulary category audio plays logged with category and word
- Vocabulary lesson completions logged when marked as learned
- OTA download completion logged with from/to version
- OTA install tap logged with target version

### Changed
- `Result` widget converted from `StatelessWidget` to `StatefulWidget` to support analytics in `initState`
- App version: 1.2.26 → 1.2.27
- Build number: 126 → 127

## 1.2.26 (build 126)

Released: 2026-11-09

### Important Notice
⚠️ **Package name changed** - Requires clean install (uninstall old app first)

### Fixed
- User tracking in Firebase Analytics now properly tracks users across sessions
- User IDs are privacy-preserving SHA-256 hashes
- Analytics persist across app restarts

### Added
- User ID initialization on app start
- Analytics user tracking on name entry and changes
- User ID clearing on logout for privacy

### Changed
- App version: 1.2.24 → 1.2.26
- Build number: 124 → 126
- Package name: com.bellaTech.dha_anywaaa → com.kornellaotf.learn_dha_anywaa

## 1.2.24 (build 124)

Released: 2026-11-09

### Fixed
- Jaap dëël screen: restored original body.jpg diagram
- Improved image fit with better constraints and centering
- Optimized container padding for balanced display

### Changed
- App version: 1.2.23 → 1.2.24
- Build number: 123 → 124

## 1.2.23 (build 123)

Released: 2026-11-09

### Fixed
- Dictionary data quality: removed double spaces in 18 entries
- Improved AI translation accuracy with cleaner dictionary data
- JSON formatting for better maintainability

### Changed
- App version: 1.2.22 → 1.2.23
- Build number: 122 → 123

## 1.2.22 (build 122)

Released: 2026-11-09

### Fixed
- Jaap dëël (Body Parts) screen: replaced low-quality image with baked-in text labels with clean custom SVG illustration
- Removed watermarked stock photo, eliminated excessive whitespace
- Improved container design: cleaner layout without nested boxes
- Added proper title "Nying thäk dëër dhaanhø" (Body part names)
- Professional attribution placement

### Added
- Custom SVG body diagram illustration (body_clean.svg) - no copyright issues, clean design
- flutter_svg package for vector graphics support

### Changed
- App version: 1.2.21 → 1.2.22
- Build number: 121 → 122

## 1.2.20 (build 120)

Released: 2026-11-08

### Added
- Firebase Analytics integration for anonymous usage tracking
- Analytics service: logPlayAudio, logCompleteLesson, logFinishQuiz, logCheckUpdate, logChangeTheme, logToggleSound
- Automatic screen tracking via FirebaseAnalyticsObserver
- OTA update notifications (local notifications on app open)
- Settings page: theme change logging, sound toggle logging

### Changed
- Privacy policy updated to mention Firebase Analytics
- App version: 1.2.18 → 1.2.20
- Build number: 118 → 120

## 1.2.19 (build 119)

Released: 2026-11-08

### Added
- Firebase Cloud Messaging (FCM) integration for push OTA notifications
- App subscribes to 'updates' topic automatically

### Changed
- App version: 1.2.18 → 1.2.19
- Build number: 118 → 119

## 1.2.18 (build 118)

Released: 2026-11-08

### Fixed
- Notification permissions fixed - request before initialization
- OTA update notifications now show when updates are available

Released: 2025

### Added
- In-app Privacy Policy screen (no website link needed)
- In-app Terms of Use screen
- Open-source licences screen via showLicensePage
- Privacy Policy and Terms of Use linked from Settings and the drawer
- network_security_config.xml: HTTPS only, no cleartext traffic

### Changed
- App version now read from package_info_plus in About and Settings
- Drawer: closes before navigating to any sub-screen
- Drawer: Website tile replaced with Privacy Policy and Terms of Use
- Home: _load() runs once only (removed double call from didChangeDependencies)
- Home: update check runs after first frame with offline guard
- About: external Privacy Policy and Read More links replaced with in-app screens
- About: version number now reads from pubspec.yaml via package_info_plus
- Help: removed "visit the website" instruction, updated quiz description
- Name entry: removed gradient header band
- Name entry: fixed extra space in "Get started" button text
- Package name updated to com.kornellaotf.learn_dha_anywaa
- Developer credit updated to Kornella Otf, Kornellaotf@gmail.com

### Fixed
- android:allowBackup set to false (was missing, defaulted to true)
- Audio helper: getDuration() result handled as Duration? throughout
- Home category tiles now show images

### Content gaps (not changed, listed for review)
- sentence_sound/Voice6.mp3 is missing. Reading item "Dh / Dhieng" plays silently.
- Fish screen: all 10 items have no English label.
- Words screen: "Öök" has no English label.
- Suspected typos: "Crocdile", "Hayna", "Quitar", "Three Angle".
- Orphan file: word_sound/Ec.mp3 (not referenced by any word entry).
- Stray file: assets/body_part/lion.png (not a body part).

---

## 1.0.2 (build 3)

- New UI design applied across all screens
- Progress tracking with SharedPreferences
- Settings screen: sound toggle, name change
- OTA update check via GitHub Releases API
- Quiz: live score, confirm-quit dialog, swipe disabled
- Result screen: percentage, share to clipboard
