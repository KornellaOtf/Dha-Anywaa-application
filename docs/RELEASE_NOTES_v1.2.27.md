# Release v1.2.27 - Analytics Fix & Firebase App Distribution

**Release Date:** November 9, 2026
**Version:** 1.2.27 (build 127)
**Package:** com.kornellaotf.learn_dha_anywaa
**Type:** Normal OTA update (no reinstall needed)

---

## Summary

This release fixes Firebase Analytics — events were defined but never actually called in the UI. It also sets up Firebase App Distribution so releases are tracked in the Firebase console.

---

## What Was Wrong

Firebase was showing:
- ✅ Active users (user IDs working from v1.2.26)
- ❌ Event count: 0
- ❌ Engagement time: 0s

**Root cause:** The analytics methods (`logPlayAudio`, `logCompleteLesson`, `logFinishQuiz`, etc.) existed in `AnalyticsService` but were never connected to actual user actions in the UI code.

---

## What Was Fixed

### Events Now Firing

| Event | Where | Trigger |
|---|---|---|
| `play_lesson_audio` | `detail_screen.dart` | User taps audio in any vocabulary category |
| `play_lesson_audio` | `pages/page1.dart` | User taps audio in Alphabet screen |
| `complete_lesson` | `detail_screen.dart` | User marks a word as learned |
| `complete_lesson` | `pages/page1.dart` | User marks a letter as learned |
| `finish_quiz` | `result_page.dart` | Quiz ends, logs score + total |
| `download_update` | `services/ota_service.dart` | OTA APK finishes downloading |
| `install_update` | `ota_update_page.dart` | User taps Install button |

### Already Working (Unchanged)
- `toggle_sound` — settings page
- `change_theme` — settings page
- `check_update` — OTA service
- `screen_view` — automatic via FirebaseAnalyticsObserver

---

## Files Modified

1. **lib/result_page.dart**
   - Converted from `StatelessWidget` to `StatefulWidget`
   - Added `initState()` that calls `logFinishQuiz(score, total)`
   - Fixed all field references to use `widget.finalResult` / `widget.total`

2. **lib/components/detail_screen.dart**
   - Added `analytics_service.dart` import
   - `_playAudio()`: logs `play_lesson_audio` with category + engName
   - `_toggleLearned()`: logs `complete_lesson` when marking as learned

3. **lib/pages/page1.dart**
   - Added `analytics_service.dart` import
   - `_playAudio()`: logs `play_lesson_audio` with `'alphabet'` + letter
   - `_toggleLearned()`: logs `complete_lesson` when marking as learned

4. **lib/services/ota_service.dart**
   - Logs `download_update(fromVersion, toVersion)` after APK verified and renamed

5. **lib/ota_update_page.dart**
   - Added `analytics_service.dart` import
   - Install button: logs `install_update(latestVersion)` before opening APK

6. **lib/main.dart**
   - Cleaned up `FirebaseAnalyticsObserver` declaration formatting

---

## Firebase App Distribution Setup

### What It Does
Firebase App Distribution is a free service for distributing APKs to users outside Google Play. Uploading releases here keeps the Firebase console "Latest app release overview" widget accurate and lets Firebase track version adoption.

### Configuration
- **Project:** learn-dha-anywaa
- **App ID:** 1:741893789084:android:c37941cbe756ed3f92a459
- **Console:** https://console.firebase.google.com/project/learn-dha-anywaa/appdistribution

### Files Added
- `.firebaserc` — links workspace to `learn-dha-anywaa` project
- `scripts/distribute.sh` — one-command release script (see below)

---

## Build Information

- **APK size:** 100,363,730 bytes (95.7 MB)
- **SHA-256:** `48a0521de72f16c74ab80b8d47b543e0b5e9cb362db1168d523632b5a5dd73e1`
- **Build time:** ~128 seconds

---

## GitHub Release

https://github.com/KornellaOtf/Dha-Anywaa-application/releases/tag/v1.2.27

---

**Document Version:** 1.0
**Last Updated:** November 9, 2026
