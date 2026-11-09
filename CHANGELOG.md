# Changelog

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
