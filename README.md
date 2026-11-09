# Dha Anywaa

An offline-first Flutter app that helps absolute beginners learn to read **Dha Anywaa (Anuak)** — a Nilo-Saharan language spoken in Ethiopia and South Sudan — using illustrated lessons, native audio, and a quiz.

> 🌐 Landing page: https://dha-anywaa-app.netlify.app/
> 📱 Latest release: https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest
> 🐞 Report a bug: https://github.com/KornellaOtf/Dha-Anywaa-application/issues

---

## ✨ What the app does

- **Alphabet** — 29 letters with audio and progress tracking
- **Words** — 29 illustrated words with audio
- **Reading** — 29 sentences built from the words
- **Quiz** — 31 multiple-choice questions, shuffled, live score, result screen
- **Themed vocabulary** — Colors (8), Shapes (4), Body parts (18), Clothes (10), Birds (12), Animals (14), Fish (10), Numbers (1–10)
- **Progress tracking** — per-category “learned” counter on the home screen
- **Light / Dark / System theme** with instant, persisted switching
- **Fully offline** — no account, no ads, no tracking
- **OTA updates** — the app itself checks GitHub Releases and lets you install new versions without an app store

The app is designed so learners can proceed without a teacher: every letter, word, and sentence can be played aloud by tapping a single button.

---

## 🛠️ Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter / Dart (`>=3.2.1 <4.0.0`) |
| CI Flutter version | `3.47.7` (stable) |
| State | `provider` + `InheritedNotifier` (`AppSettings`) |
| Storage | `shared_preferences` |
| Audio | `audioplayers` |
| Networking | `http` |
| Integrity | `crypto` (SHA-256 of downloaded APK) |
| App info | `package_info_plus` |
| File paths | `path_provider` |
| APK install | `open_file` |
| External links | `url_launcher` |
| Scaling | `flutter_screenutil` |
| Fonts | `google_fonts` (Nunito + Playfair Display) |
| Theming | Material 3 + `ThemeExtension<AppColors>` (light + dark) |

---

## 📦 Project structure (short)
