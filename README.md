# Learn Dha Anywaa

A Flutter app for learning the Dha Anywaa (Anuak) language.
Alphabet, vocabulary, reading and a quiz. Works fully offline.

**Current Version**: 1.2.22 (build 122)  
Developed by **Kornella Otf** (Kornellaotf@gmail.com)

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
| Fish | 10 fish (Dha Anywaa names, English labels pending) |
| Numbers | 1 to 10 |
| Quiz | 31 questions, live score, confirm before quitting |
| Settings | Sound toggle, name change, update check, Privacy Policy, Terms |
| Anywaa AI | Offline translation and learning assistant |

---

## Project structure

```
lib/
  main.dart               App entry point
  wraper.dart             Startup: loads name, shows spinner
  home_page.dart          Home screen, drawer, bottom nav
  nameEntry.dart          First-run name entry
  pages/
    page1.dart            Alphabet
    page2.dart            Words
    page3.dart            Reading
    page4.dart            Quiz
  components/
    detail_screen.dart    Reusable grid and detail screen
    number.dart           Numbers screen
    savedData.dart        SharedPreferences helpers
    audio_helper.dart     Safe audio playback helper
  widgets/
    body.dart             Body parts screen with SVG illustration
  services/
    ota_service.dart      GitHub Releases update checker
    notification_service.dart  FCM push notifications
    anywaa_ai_service.dart     Offline AI translation
  theme/
    app_theme.dart        Color tokens and ThemeData
  privacy_policy_page.dart
  terms_page.dart
  about.dart
  help.dart
  anywaa_ai_page.dart     AI chat interface
assets/
  sound/                  Alphabet audio (29 files)
  word_sound/             Word audio (30 files)
  sentence_sound/         Reading audio (29 files, Voice6.mp3 missing)
  word_images/            Word and category images (including body_clean.svg)
  category_image/         Home grid images
  animals/                Animal images
  birds/                  Bird images
  fish/                   Fish images
  body_part/              Body part images
  cloth/                  Clothing images
  data/                   AI dictionary and model files
android/
  app/build.gradle        Package: com.kornellaotf.learn_dha_anywaa
  app/src/main/
    AndroidManifest.xml
    res/xml/network_security_config.xml
```

---

## Latest Updates (v1.2.22)

### 🎨 UI Improvements
- **Body Parts Screen**: Replaced watermarked stock image with clean custom SVG illustration
- Removed baked-in text labels that were blurry on mobile screens
- Eliminated excessive whitespace and improved layout
- Added proper Anywaa title: "Nying thäk dëër dhaanhø"

### 📦 Technical
- Added `flutter_svg` package for vector graphics support
- Improved container design without nested boxes
- Better visual hierarchy and professional appearance

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
| INTERNET | Update check via GitHub Releases API |
| ACCESS_NETWORK_STATE | Skip update check when offline |
| REQUEST_INSTALL_PACKAGES | Install downloaded update APK |

---

## Privacy summary

All user data (name, progress, preferences) is stored only on the device.
The only outbound request is one HTTPS call to api.github.com to check for
updates. No analytics, no advertising, no account required.

Full policy: see PRIVACY.md or Settings in the app.

---

## Content gaps (for the developer)

These are known issues in the content, listed here and left untouched in code:

- `sentence_sound/Voice6.mp3` is missing. The "Dh / Dhieng" reading item plays silently.
- All 10 fish entries have no English label.
- "Öök" in Words has no English label.
- Suspected typos to review: "Crocdile", "Hayna", "Quitar", "Three Angle".
- Orphan file: `word_sound/Ec.mp3` (not referenced by any word entry).
- Stray file: `assets/body_part/lion.png` (not a body part image).

---

## Credits

Developed by Kornella Otf
Contact: Kornellaotf@gmail.com

---

## License

All rights reserved. The Dha Anywaa language content, audio recordings
and illustrations are the property of their respective creators and are
provided for educational use only.
