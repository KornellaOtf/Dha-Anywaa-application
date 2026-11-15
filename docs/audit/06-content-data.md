# Audit 06 — Content & Data Integrity

## Validation results (scripted)

| File | Size | Entries | Status |
|------|------|---------|--------|
| assets/data/dictionary_full.json | 533 KB | 3,472 words / 69 categories | ✅ valid JSON, 0 missing en/dha, 0 duplicate English terms |
| assets/data/cultural_facts.json | 4 KB | 15 facts | ✅ valid; keyword arrays present |
| assets/data/anyaawa_dictionary.json | 170 KB | 1,353 words | ⚠️ valid but **dead asset** (no code references it) |
| assets/bible.json | **11.2 MB** | 31,057 verses | ❌ **18 duplicate verse refs + 42 empty-English verses** |

## Findings

### DATA-01 — Bible JSON has 18 duplicated verse references
- **Severity:** High
- **Evidence:** `(book, chapter, verse)` keys appearing twice with DIFFERENT content — e.g. `('Genesis',35,23)` ×2 where one entry has `english:''` and the other has a translation; `('Judges',20,10)`, `('1 Samuel',25,1)`, `('2 Samuel',12,16)`, `('2 Samuel',19,9)` etc. — 18 refs total. The reader will show the same verse twice and verse-number navigation/counts are off.
- **Fix:** Dedupe by (book,chapter,verse) preferring the entry with non-empty english; regenerate bible.json.

### DATA-02 — 42 Bible verses have empty `english`
- **Severity:** Medium
- **Evidence:** e.g. Genesis 35:23, Numbers 31:22, 1 Chronicles 1:1 — `english: ''`. Reader shows an empty English block (the Anywaa side exists).
- **Fix:** Fill translations or hide the English section when empty (check bible_page rendering — likely shows blank card).

### DATA-03 — bible.json is 11 MB uncompressed
- **Severity:** Medium
- **Evidence:** 31k verses as pretty/raw JSON → loaded fully into memory + 3 lowercase string lists for search (`bible_page.dart`). APK size contributor.
- **Fix:** Compact JSON (no whitespace), consider per-book files or sqlite; parse in isolate.

### DATA-04 — Oversized word images (>500 KB)
- **Severity:** Medium
- **Evidence:** elephant.png 990KB, shoe.png 986KB, lion.png 931KB, butterfly.png 807KB, croc.png 773KB, hen.png 747KB, thoom.png 728KB, lizard.png 644KB, side_bar_bg.png 603KB — displayed at ≤200px. ~8MB+ of decode-heavy PNGs.
- **Fix:** Downscale to ~512px + convert to WebP (Flutter supports webp) — expect ~80% size cut.

### DATA-05 — Quiz/question content spot-check
- **Severity:** Info (partial)
- **Evidence:** Questions are generated at runtime from WordAggregator/FSRS data (no static quiz JSON to validate). Options built from word pool — duplicates possible only if pool has dup English (none found in dictionary_full). Daily 5/quiz correctness derives from word data, which is clean.
- **Unverified:** runtime distractor quality needs device testing.

### DATA-06 — Coverage gaps
- **Severity:** Low
- **Evidence:** cultural_facts.json has only 15 facts — thin for the AI's "verified data" (Groq falls back to its own knowledge for most culture questions). Dictionary categories: 69 cats / 3,472 words is solid for a starter app.
- **Fix:** Grow cultural_facts via the community-notes pipeline (already built).

### DATA-07 — Attribution
- **Severity:** Low / needs owner input
- **Evidence:** dictionary_full.json includes "merged entries from external News scrape" (per docs) — provenance/permission for scraped dictionary content should be confirmed before wide release.
- **Fix:** Owner to confirm source licensing.

## Summary table

| ID | Severity | Issue |
|----|----------|-------|
| DATA-01 | High | 18 duplicate Bible verse refs |
| DATA-02 | Medium | 42 verses missing English |
| DATA-03 | Medium | 11MB bible.json + full-memory load |
| DATA-04 | Medium | ~8MB oversized PNGs |
| DATA-06/07 | Low | Thin facts; attribution check |

## Top fixes
1. Fix bible.json duplicates + empty English (data bug users will see).
2. Compress images to WebP @512px.
3. Slim bible.json / lazy-load.
