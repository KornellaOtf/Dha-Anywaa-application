# Audit 00 — Consolidated Summary

Date: 2026-11-15 · Version audited: v2.0.2 (build 2202) · Scope: full codebase, data files, release pipeline.

Reports: `01-architecture.md` `02-bugs.md` `03-security-privacy.md` `04-ota-release.md` `05-ui-ux.md` `06-content-data.md` `07-ai-chat.md` `08-performance.md`

## Findings by severity

| Severity | Count | Highlights |
|----------|-------|------------|
| Critical | 0 | — |
| High | 6 | SEC-01 Groq key in APK; SEC-02 privacy policy false claim; AI-01 language-rule/verified-data conflict; DATA-01 18 duplicate Bible verses; A11y-1 zero Semantics; A11y-2 color-only indicators |
| Medium | ~20 | BUG-01/02 OTA edges; BUG-04 streak freeze; BUG-05 no prefs migration; SEC-03 note injection; AI-02/04/06; DATA-02/03/04; PERF-01..05; ARCH-01/04/05; UX gaps |
| Low | ~25 | naming/style/deprecation debt, edge cases |
| Info | several | verified-good areas (OTA crypto, secrets hygiene, disposal, analyzer clean) |

## Top 15 to fix first

1. **SEC-02** — privacy policy must disclose Groq chat (5 min, compliance).
2. **AI-01** — decide word-lookup routing: dictionary queries → offline engine before Groq, or allow verified entries in rule 5. Biggest UX bug.
3. **DATA-01** — dedupe 18 Bible verse refs (users see verses twice).
4. **SEC-01** — plan Groq proxy (Cloudflare Worker); acceptable interim since free-tier key.
5. **BUG-04** — verify & fix streak-freeze math.
6. **PERF-05** — `cacheWidth` on all Image.asset (memory on low-end phones).
7. **PERF-01** — move OTA/retention/quick-actions init post-frame.
8. **DATA-04** — WebP + downscale oversized PNGs (~8 MB APK win).
9. **ARCH-01/02/03** — wire or delete Quick Challenge + unused deps/assets.
10. **SEC-03** — sanitize `[[SAVE]]` contributions (length cap, strip instruction-like text).
11. **AI-04** — surface 429/quota state instead of silent offline fallback.
12. **A11y-1** — Semantics pass on interactive elements.
13. **DATA-02** — fill or hide 42 empty-English verses.
14. **BUG-01/02** — OTA null-dir + sha256 try/catch (tiny).
15. **ARCH-04** — split practice_learn_page.dart (1,636 lines).

## Quick wins (<10 min each)

- Privacy policy Groq disclosure (SEC-02)
- OTA null-check + sha256 guard (BUG-01/02)
- `choices.isNotEmpty` guard (AI-03)
- Name trim/min-length (BUG-06)
- Chat message length cap (BUG-07)
- `dart fix --apply` const constructors (PERF-07)
- Remove unused packages provider/flutter_svg/screenutil + dead files (ARCH-01/02)
- Delete dead anywaa_dictionary.json (ARCH-03) — confirm unused first
- `cacheWidth` additions (PERF-05)

## Test status

- `flutter analyze`: 53 info-level issues, 0 errors/warnings.
- `flutter test`: 19 passed, 1 failed/hung — `test/dictionary_page_test.dart` times out (>120s, "did not complete"). Likely test-env issue (font fetch or unguarded async in page init), not confirmed app bug — investigate separately.
- Coverage: exists for settings/theme persistence, dictionary page, anywaa_ai, widget smoke + goldens. Untested: FSRS scoring, streak logic, OTA version compare, Groq parsing, Daily-5 once/day.

## Fixes applied (commit 2abb754, 2026-11-15)

**Fixed:** SEC-02 privacy policy now discloses Groq + GitHub downloads · BUG-02 `_sha256OfFile` guarded (BUG-01 resolved — API is non-nullable) · AI-03 empty-choices guard · AI-05/SEC-03 all SAVE tags stripped + 300-char cap · BUG-04 streak freezes now cover every missed day · BUG-06 name min 2 chars · BUG-07 chat 1000-char cap · DATA-01 bible.json deduped (31,057→31,039) · DATA-02 already handled (reader hides empty English) · PERF-03 dictionary JSON cached · PERF-04 WordAggregator memoized · PERF-05 cacheWidth on 7 image sites · PERF-01 OTA/retention/shortcuts init post-frame · ARCH-01 Quick Challenge wired into Practice (+removed broken screenutil scaling, dead audio button hidden) · ARCH-02 removed provider/flutter_svg/cupertino_icons/flutter_screenutil · ARCH-03 deleted dead anywaa_dictionary.json

**Deferred (need decision/effort):** SEC-01 Groq proxy (infra), AI-01 word-lookup routing (user chose leave-as-is), AI-02/04 prompt+429 polish, BUG-05 prefs schema versioning, DATA-03 bible.json slimming/isolate, DATA-04 WebP image compression, A11y Semantics pass, PERF-02 bible isolate parse, PERF-06/07 search+const cleanup, UX empty states/onboarding.

## Recommended order for next release (v2.0.3)

1. Privacy policy + AI-01 word-lookup decision + BUG-04 streak check (correctness/compliance).
2. DATA-01 bible dedupe (visible bug).
3. Quick wins batch (SEC-03 sanitize, BUG-01/02, AI-03, PERF-05, ARCH deps).
4. PERF-01 startup + PERF-03 caching.
5. Image compression pass (separate build, big APK win).
6. Accessibility Semantics pass (larger effort, schedule separately).
