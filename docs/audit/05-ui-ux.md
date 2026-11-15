# Audit 05 — UI, UX & Design Quality

Subagent product-design review + spot verification.

## Consistency deviations

| Screen | Deviation | Severity |
|--------|-----------|----------|
| bible_page.dart:12-19 | Own `_kDark/_kGold*` palette instead of `context.c` | Medium |
| bible_page.dart | radius 16 vs theme 18 | Low |
| practice_learn_page.dart | radius 22 vs 18; local `kSoftShadow` vs `kShadowSoft` | Low |
| daily_five_page.dart:321+ | hardcoded `0xFF1B2E1A` background; radius 24 | Medium |
| quick_challenge_page.dart | flutter_screenutil `.sp/.w` — only file using it (and it's dead code) | Medium |
| settings/result/about | legacy `kText`/`kTextMuted` vs `context.c.*` | Low |

## "AI-generated" look — cultural alternatives (subagent proposals, need owner taste check)
- Generic green gradient hero → awal pot / beadwork motif
- Generic confetti → cowrie shells / beads
- Fire streak icon → cattle icon; XP star → grain/harvest
- Generic progress bar → river-flow motif
- Identical card grid → varied cultural layouts
- **Caution:** these are subjective; current earth-tone palette is already on-brand. Recommend small accents, not a reskin.

## Content rules
- ✅ Zero em/en dashes or emojis in user-facing strings (verified by grep — only code comments contain them; Groq output is sanitized in code).

## Accessibility (biggest gap)
- **Zero `Semantics` widgets in the entire codebase** — screen readers get almost nothing. High.
- Color-only indicators: progress dots, answer correctness (green/red only), "Reading" badge — High.
- Touch targets <48dp: home menu button (~36px), settings icon chips (38px) — Medium.
- No `MediaQuery.disableAnimations` checks anywhere — celebration/nav animations ignore reduced-motion — Medium.
- Contrast: several `withOpacity`/alpha text colors likely below AA — Unverified (needs contrast pass).
- 200% font scale: unverified — likely overflow in fixed-height cards.

## UX flow
- First launch: wrapper loading → name entry (no skip) → home with 12 categories, no guidance. Friction: no "start here" path for new learners — Medium.
- Empty states exist for Bible/Dictionary/Daily5; missing for Practice/Learn, Settings partial — Medium.
- Error states minimal; offline state invisible (app is offline-first by design — mostly fine).

## Summary table (top items)

| ID | Severity | Issue |
|----|----------|-------|
| A11y-1 | High | No Semantics anywhere |
| A11y-2 | High | Color-only correctness/progress indicators |
| UX-1 | Medium | No first-run guidance / recommended path |
| UX-2 | Medium | Missing empty/error states on several screens |
| TOK-1 | Medium | Token inconsistencies (bible palette, hardcoded colors, screenutil) |
| A11y-3 | Medium | No reduced-motion support; small touch targets |

## Top fixes
1. Add Semantics to interactive elements (batched, per screen).
2. Pair color indicators with icons/text.
3. Add "Start here" recommended path on home for new users.
4. Consolidate tokens (bible_page palette → context.c).
