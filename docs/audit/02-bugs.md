# Audit 02 — Bugs, Crashes & Logic

Subagent deep-read + manual verification of flagged items. Items I could not verify are marked Unverified.

## Verified / high-confidence

### BUG-01 — `dir.path` null-deref edge in OTA enqueue
- **Severity:** Medium | `lib/services/ota_service.dart:~239`
- `getExternalStorageDirectory() ?? getApplicationDocumentsDirectory()` — both nullable; result used as `dir.path` unchecked. Rare on Android (app docs dir ~always exists) but a null → throw inside try → `_fail` (graceful). **How to reproduce:** pathological device with no accessible storage dirs.
- **Fix:** `if (dir == null) { _fail('No storage available'); return; }`

### BUG-02 — `_sha256OfFile` unguarded async throw
- **Severity:** Medium | `ota_service.dart:~392`
- File deleted/permission-changed mid-read → exception inside `onStatus` async callback → unhandled async error (crash reporting noise / possible crash).
- **Fix:** try/catch around the stream, return '' on failure → verification fails safely.

### BUG-03 — `choices.first` on possibly-empty array
- **Severity:** Low | `groq_service.dart:~100`
- `([] as List?)?.first` throws StateError; caught by surrounding try → returns null → offline fallback. Safe but sloppy.
- **Fix:** check `isNotEmpty` first.

### BUG-04 — Streak freeze logic consumes only one freeze regardless of days missed
- **Severity:** Medium | `lib/services/gamification_service.dart:~148-189`
- Subagent claim: auto-freeze uses 1 freeze even if user missed 2+ days. **Unverified** — needs line-level re-check of `_daysBetween`/freeze accounting before fixing.
- **How to reproduce (if true):** miss 3 days, return → streak resets despite having 3 freezes.

### BUG-05 — No SharedPreferences schema versioning/migration
- **Severity:** Medium | all services
- Keys like `fsrs_word_states_v1` are versioned by name (good), but cross-key schema changes (e.g. name→learner_name compat exists) have no central migration. Future breaking change = silent data issues.
- **Fix:** Add `prefs_schema_version` + migration hook.

### BUG-06 — Name entry accepts whitespace-only / 1-char names
- **Severity:** Low | `nameEntry.dart` validator checks `isEmpty` only — `' '` passes, `'A'` passes, emoji names pass.
- **Fix:** trim + min length 2.

### BUG-07 — AI chat has no message-length cap
- **Severity:** Low | `anyaawa_ai_page.dart:_send`
- Huge paste → big API payload (cost/latency). Groq handles gracefully; app-side cap ~1000 chars is cheap insurance.

### BUG-08 — Daily 5 combo XP uses `_combo` not `_maxCombo` (subagent claim)
- **Severity:** Low | `daily_five_page.dart:~266`
- **Unverified** — flagged by subagent; combo XP may under-award if final answer wrong. Verify before fix.

## Subagent-reported items needing verification before fixing
- BUG-002 (dictionary JSON structure validation) — JSON is bundled & valid today; defensive parsing still worthwhile → Low.
- BUG-005 (retention_engine getInt null) — `?? 0` pattern likely already safe → verify.
- BUG-009/010 duplicates of BUG-04.
- BUG-013 covered by BUG-06. BUG-014 timezone — `_todayStr` uses local date; travel edge case, Low. BUG-015 = BUG-07. BUG-016 accent search — handled OK. BUG-017 = BUG-05. BUG-018 backup checksum — Low. BUG-019/020 — handled acceptably. BUG-021 font-scale clamp — verify on device. BUG-022 — correct behavior.

## Navigation/state
- Double-tap pushing Daily 5/Practice screens: possible (no navigation guard) — Low, cosmetic.
- `mounted` checks present in reviewed async paths (daily_five, page3, quick_challenge, anywaa_ai) — prior audit fixes hold.

## Persistence
- FSRS states: `fsrs_word_states_v1` + backup key + corruption recovery (v1.9.9 fixes) — good.
- Daily-5-once-per-day, streak, XP, name — SharedPreferences, survive updates.
- Community notes: `groq_community_notes` capped 200.

## Summary table

| ID | Severity | Issue |
|----|----------|-------|
| BUG-01/02 | Medium | OTA storage-dir + sha256 read edges |
| BUG-04 | Medium | Streak freeze math (verify) |
| BUG-05 | Medium | No prefs schema migration |
| BUG-03/06/07 | Low | Groq empty-choices, name validation, msg cap |
| BUG-08 | Low | Combo XP (verify) |

## Top fixes
1. BUG-01/02 OTA guards (tiny).
2. BUG-04 streak freeze verification + fix.
3. BUG-05 schema version hook.
