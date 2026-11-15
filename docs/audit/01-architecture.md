# Audit 01 — Architecture & Project Map

## Project map

**Stack:** Flutter/Dart, Material 3, SharedPreferences persistence, FSRS-6 spaced repetition, firebase_analytics, flutter_local_notifications, background_downloader OTA, Groq chat (http), google_fonts (Nunito/Playfair), Charis SIL bundled fallback font, flutter_screenutil (single file only).

**Entry:** `lib/main.dart` → `wraper.dart` (name gate) → `nameEntry.dart` → `home_page.dart` (sidebar + pages via SlideRoute/MaterialPageRoute; no named-route table except 'home_page').

**Screens (lib/):** home_page, anywaa_ai_page, dictionary_page, settings_page, nameEntry, ota_update_page, result_page, privacy_policy_page, about.dart, help.dart, terms_page.dart; pages/: page1 (alphabet/lessons), page3 (reading/audio), page4 (quiz), daily_five_page, practice_learn_page (1,636 lines — largest), quick_challenge_page (**dead file**), bible_page (1,562), page2?, plus components/ (detail_screen, audio_helper — dead), widgets/ (floating_nav, celebration_widget, progress_ring, brand_leaf).

**Services (lib/services/):** learning_engine (FSRS-6), gamification_service, retention_engine (streaks/notifications), analytics_service, notification_service, ota_service, anywaa_ai_service (offline dictionary brain), groq_service + groq_prompts, word_aggregator, share_helper.

**Data:** assets/data/{dictionary_full.json (69 cats/3,472 words), anywaa_dictionary.json (1,353 words — **dead asset**), cultural_facts.json (15 facts)}; assets/bible.json (31,057 verses, 11 MB); ~223 images in assets/{animals,birds,word_images,…}; fonts CharisSIL.

**State:** plain StatefulWidget + Singletons + ValueNotifier (OTA download) + AppSettings InheritedWidget-ish notifier. No Provider/Riverpod/BLoC despite `provider` dep.

## Findings

### ARCH-01 — Dead files (unreachable code)
- **Severity:** Medium
- **Evidence:** `lib/pages/quick_challenge_page.dart`, `lib/words.dart`, `lib/components/audio_helper.dart` have ZERO importers (grep-verified). `quick_challenge_page.dart` is a full quiz screen (~360 lines) never launched — "Challenges" feature promised in prompts/docs is unreachable.
- **Impact:** Dead weight, confusion about whether Quick Challenge exists.
- **Fix:** Wire it into Practice navigation or delete; same decision for words.dart/audio_helper.dart.

### ARCH-02 — Unused packages
- **Severity:** Low
- **Evidence:** `provider` (0 imports), `flutter_svg` (0 imports), `cupertino_icons` (template leftover) in pubspec.yaml. `flutter_screenutil` used ONLY in quick_challenge_page.dart (the dead file!) — removing dead file removes last usage.
- **Fix:** Remove provider, flutter_svg, cupertino_icons, and flutter_screenutil (+ the dead page) — APK size win.

### ARCH-03 — Dead asset: anywaa_dictionary.json
- **Severity:** Low
- **Evidence:** 170 KB / 1,353 words; zero references in lib/ (grep-verified). Only dictionary_full.json + cultural_facts.json are loaded.
- **Fix:** Delete or wire into a feature.

### ARCH-04 — Giant files
- **Severity:** Medium
- **Evidence:** practice_learn_page.dart 1,636 lines; bible_page.dart 1,562; home_page.dart 1,311; daily_five_page.dart 1,150; anywaa_ai_service.dart 1,105. Total lib ≈ 19k lines.
- **Fix:** Split practice_learn_page into per-screen files; extract bible search/index logic into a service.

### ARCH-05 — Startup does heavy sequential awaits before first frame
- **Severity:** Medium (see PERF report)
- **Evidence:** `main.dart` awaits timezone init, Firebase, analytics storage init, OTA init, retention init, quick actions, SharedPreferences — all before runApp.
- **Fix:** Post-frame init for non-critical services.

### ARCH-06 — Inconsistent design-token usage
- **Severity:** Low (detail in 05-ui-ux)
- **Evidence:** bible_page defines own `_kDark/_kGold*` palette; daily_five hardcodes `0xFF1B2E1A`; quick_challenge uses `.sp/.w` units nowhere else used; several files use legacy `kText/kTextMuted` constants vs `context.c.*`.
- **Fix:** Consolidate on AppColors + text theme.

### ARCH-07 — No route table / deep-link structure
- **Severity:** Low
- **Evidence:** Only 'home_page' named route; everything else via SlideRoute/MaterialPageRoute constructors. Fine at this size; makes deep links impossible.
- **Fix:** Optional — onGenerateRoute table if deep links ever needed.

### ARCH-08 — Secrets pattern is good
- **Severity:** Info
- **Evidence:** `lib/secrets.dart` gitignored + `secrets.example.dart` committed template; key never in git history (verified `git log -S "gsk_"`).

## Dart quality scan (analyzer-backed)

`flutter analyze`: **53 issues, all info-level** — `withOpacity` deprecations (~40, daily_five/progress_ring/etc.), `use_super_parameters`, `unnecessary_import` (result_page), dead_code hints. **0 errors, 0 warnings.** Force-unwrap/`late` audit: services use `late` for initialized-once fields (dictionary, prefs) — acceptable; `_DigestSink._digest` `late` could throw if sink closed empty (OTA edge, covered in 04). Async-gap `context` use: one lint found & fixed in ota_update_page (`context.mounted`→`mounted`); remaining `mounted` checks present in page async paths reviewed.

## Summary table

| ID | Severity | Issue |
|----|----------|-------|
| ARCH-01 | Medium | 3 dead Dart files incl. full Quick Challenge screen |
| ARCH-04 | Medium | 4 files >1,100 lines |
| ARCH-05 | Medium | Blocking startup init |
| ARCH-02/03 | Low | Unused packages + dead 170KB asset |
| ARCH-06 | Low | Token inconsistency |
| ARCH-07/08 | Info | Routes OK; secrets pattern good |

## Top fixes
1. Decide Quick Challenge: wire or delete (user-facing promise vs dead code).
2. Remove unused deps/assets (quick win, shrinks APK).
3. Split practice_learn_page.dart.
