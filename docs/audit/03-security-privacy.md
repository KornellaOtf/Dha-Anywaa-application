# Audit 03 — Security & Privacy

Scope: secrets, network, local data, AI chat, Android hardening, privacy policy, OTA.

## Findings

### SEC-01 — Groq API key ships inside the APK (extractable)
- **Severity:** High
- **Evidence:** `lib/secrets.dart:5` holds the real `gsk_…` key. The file is correctly gitignored (`git check-ignore` confirms; `git log --all -S "gsk_"` shows only the `gsk_xxx` placeholder in `secrets.example.dart` and the `startsWith` guard in `groq_service.dart:39` — the real key is NOT in git history). However the key is a Dart string constant compiled into `libapp.so`; anyone can extract it from the APK and burn the quota.
- **Impact:** Key abuse, quota exhaustion, unexpected Groq bills if the key is upgraded to paid tier.
- **Fix:** Move the key behind a backend proxy (e.g. a Cloudflare Worker holding `GROQ_API_KEY` as a secret). App calls the worker URL with an optional shared app token. Rate-limit per IP/device on the worker.

### SEC-02 — Privacy policy claims "No other third-party services are used" — false since v2.0.0
- **Severity:** High (compliance)
- **Evidence:** `lib/privacy_policy_page.dart:98` says `'No other third-party services are used.'` but `groq_service.dart` POSTs user chat text to `https://api.groq.com` on every message.
- **Impact:** Policy mismatch; users' messages leave the device without disclosure.
- **Fix:** Update privacy policy to disclose Groq (chat messages sent to Groq API for AI replies, no account needed) and what data is sent.

### SEC-03 — Community notes are stored and re-sent to the model without moderation
- **Severity:** Medium
- **Evidence:** `groq_service.dart` `saveContribution()` stores `[[SAVE:…]]` text in `groq_community_notes` pref (cap 200); `_communityNotes()` injects the last 10 into every request's system prompt. A user can socially-engineer the model into emitting a crafted SAVE tag containing prompt-injection text, which then persists and is sent to the model on every subsequent request.
- **Impact:** Stored prompt injection; also unverified user text reaches all users' prompts.
- **Fix:** Sanitize contributions on save (strip instruction-like patterns, cap length ~280 chars), and/or require review (the Community knowledge sheet exists — promote notes to verified only after approval).

### SEC-04 — OTA verification is solid; minor gaps
- **Severity:** Low
- **Evidence:** `ota_service.dart` fetches manifest over HTTPS only (`network_security_config.xml` sets `cleartextTrafficPermitted="false"`, system CAs only). `_onComplete()` verifies size AND SHA-256, deletes file on mismatch. `android:allowBackup="false"` set. REQUEST_INSTALL_PACKAGES present (justified for OTA).
- **Residual:** `dir` from `getExternalStorageDirectory() ?? getApplicationDocumentsDirectory()` is used as `dir.path` without a null check (`ota_service.dart:~239-244`) — both APIs are nullable; on a pathological device this throws inside `_enqueue`'s try (caught → `_fail`), so impact is a failed download, not a crash. Also `_sha256OfFile` has no try/catch — a file deleted mid-read propagates an unhandled async error through the `onStatus` callback.
- **Fix:** Null-check `dir`; wrap `_sha256OfFile` in try/catch returning ''.

### SEC-05 — Secrets hygiene otherwise good
- **Severity:** Info
- **Evidence:** `android/key.properties` and `android/upload-keystore.jks` are gitignored via `android/.gitignore` and NOT tracked (`git ls-files` confirms). `google-services.json` is committed — standard practice (Firebase API keys are app-identifiers, not secrets, restricted by package name + SHA-1). `minifyEnabled true`, `shrinkResources true`, ProGuard rules present. `android:debuggable` not set (release default false).
- **Fix:** None required; optionally add SHA-1/SHA-256 cert restrictions in Firebase console.

### SEC-06 — debugPrint logging
- **Severity:** Low
- **Evidence:** `ota_service.dart` logs manifest body and stack traces via `debugPrint` (debug-only, stripped in release? — debugPrint is NOT stripped in release builds; it prints to logcat). Manifest body contains no secrets. No key/token logging found in `groq_service.dart`.
- **Fix:** Optional — gate verbose OTA logging behind `kDebugMode`.

## Summary table

| ID | Severity | Area |
|----|----------|------|
| SEC-01 | High | Groq key in APK |
| SEC-02 | High | Privacy policy mismatch (Groq) |
| SEC-03 | Medium | Unmoderated community-note injection loop |
| SEC-04 | Low | OTA null-dir / sha256 read edge cases |
| SEC-05 | Info | Keystore/google-services hygiene OK |
| SEC-06 | Low | debugPrint in release |

## Top fixes
1. SEC-02 — update privacy policy before next release (5 min).
2. SEC-01 — plan worker proxy; acceptable short-term since key is free-tier.
3. SEC-03 — sanitize + length-cap saved contributions.
