# Audit 08 — Performance & Size

Subagent code-level review + tool output.

## Tool results

- `flutter analyze`: **53 issues — all info-level** (withOpacity deprecations, super-parameters, one unnecessary import). 0 errors/warnings.
- `flutter test`: see test report section below (run in progress at write time — see 09-tests section of summary).
- APK size: ~91.7 MB release. Biggest contributors: assets/bible.json 11.2 MB raw, ~223 PNGs (~8 MB over-500KB outliers), dictionary_full.json 0.5 MB, Charis SIL fonts 1.5 MB, Dart AOT + plugins remainder.

## Findings

### PERF-01 — Blocking startup chain before first frame
- **Severity:** High-ish/Medium | `main.dart:41-123`
- Sequential awaits: timezone init, Firebase init, analytics storage init + logAppOpen, OTA init, RetentionEngine init, quick actions, SharedPreferences — all before runApp.
- **Fix:** Post-frame init for OTA/retention/quick-actions; Firebase must init early but analytics logging can defer.

### PERF-02 — Full Bible (31k verses) parsed + 3 lowercase lists in memory
- **Severity:** Medium | `bible_page.dart:_loadData`
- JSON decode of 11 MB on UI isolate; `_lcAnywaa`/`_lcEnglish` duplicate all text lowercase (~5-10 MB).
- **Fix:** `compute()` for parse; build search index lazily or per-book.

### PERF-03 — Dictionary 3,472 entries parsed on page open
- **Severity:** Medium | `dictionary_page.dart:_load`, `anyaawa_ai_service.dart`
- Full JSON decode per page visit (dictionary_page reloads every open — no cache).
- **Fix:** Cache parsed result in service; parse once.

### PERF-04 — `WordAggregator.getAllWords()` rebuilds 140+ objects per call
- **Severity:** Medium | `word_aggregator.dart:163`
- Called by multiple pages per build/session.
- **Fix:** Memoize.

### PERF-05 — Images decoded at full resolution
- **Severity:** Medium | daily_five_page, home_page, practice_learn_page, detail_screen
- `Image.asset` without `cacheWidth` — 1080px PNGs shown at ~180px.
- **Fix:** `cacheWidth: ~360` (2× display size) everywhere.

### PERF-06 — O(n) searches per keystroke
- **Severity:** Low-Medium | bible search (31k, debounced 300ms), dictionary `_searchResults` in build() every keystroke (3.4k)
- **Fix:** Debounce dictionary search; inverted index for Bible (long-term).

### PERF-07 — Missing const constructors (~100+ instances)
- **Severity:** Low | pervasive
- **Fix:** `dart fix --apply` prefer_const_constructors.

### PERF-08 — Disposal hygiene: GOOD
- **Severity:** Info — all AnimationControllers, AudioPlayers, TextEditingControllers, Timers checked dispose properly. Community notes capped 200; review log capped 10k.

### PERF-09 — APK size recommendations
- **Severity:** Medium
- WebP conversion for word images (~80% smaller), downscale to 512px.
- Split-per-ABI APKs or App Bundle for store; direct-APK users get fat binary regardless.
- Remove dead code/assets (ARCH-01/02/03) — small win.
- bible.json: strip whitespace → maybe -30%.

## Summary table

| ID | Severity | Issue |
|----|----------|-------|
| PERF-01 | Medium-High | Blocking startup init |
| PERF-02/03 | Medium | Big JSON parses on UI isolate, no caching |
| PERF-05 | Medium | Full-res image decode |
| PERF-04/06/07 | Low-Med | Rebuilds, O(n) search, missing const |
| PERF-08 | Info | Disposal clean |
| PERF-09 | Medium | ~91MB APK; WebP/split-ABI wins available |

## Top fixes
1. `cacheWidth` on all Image.asset (quick, big memory win).
2. Post-frame non-critical init.
3. Memoize WordAggregator + cache dictionary parse.
4. WebP/resize images before next release.
