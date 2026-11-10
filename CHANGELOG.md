# Changelog

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
