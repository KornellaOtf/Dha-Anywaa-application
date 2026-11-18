# Security & Content Protection

How Dha Anywaa protects bundled learning content, and — honestly — what
that protection does and does not stop. Read this before changing anything
under `assets/encrypted/`, `android/app/src/main/cpp/`, or
`lib/services/encrypted_asset_loader.dart`.

## 1. Encrypted asset container

Spec: `docs/ASSET_FORMAT.md`. Summary:

```
[8-byte magic][1-byte version][12-byte nonce][AES-256-GCM ciphertext || 16-byte tag]
```

- AES-256-GCM, deterministic nonce = `HMAC-SHA256(key, "nonce:" + id)`.
- Filenames are `HMAC-SHA256(key, "name:" + logicalId)` truncated to 16
  hex chars — derived at runtime, no plaintext index ships.
- Sources live in `assets_src/` (gitignored). Encrypt with
  `DHA_ASSET_KEY=… python3 tools/encrypt_assets.py --verify`.
- 8 deterministic decoy containers (valid headers, garbage ciphertext)
  are written alongside real assets to break bulk-extraction scripts.

## 2. Where the key lives

Three layers, in order of preference:

1. **Server-delivered** (`AssetKeyStore.kt`): device RSA-2048 keypair in
   AndroidKeyStore → POST pubkey to the Cloudflare Worker
   (`tools/key_server/`) → asset key returned RSA-OAEP-SHA256 wrapped to
   that device only → cached on disk AES-GCM-wrapped by a second
   Keystore key. Raw key never touches disk.
2. **Native-embedded fallback** (`key_guard.c`): passphrase split across
   `kPartA`/`kPartB` (XOR pair), reassembled + SHA-256'd only in native
   code per call. Dart receives the derived key transiently and zeroes
   it after each decrypt.
3. **Never in Dart source.** `lib/secrets.dart` holds only API keys.

> ⚠️ `kStrData`, `kPartA`, `kPartB` are `volatile const` **on purpose**.
> Without `volatile`, clang -O2 constant-folds the XOR decode and emits
> the secrets as plaintext `.rodata.cst16` constants — this actually
> happened in the first release APK and was caught by `strings`.

## 3. Integrity & environment gates

All failures return the same generic "content unavailable" — nothing
reveals which check tripped.

| Check | Where | What it does |
|---|---|---|
| `checkIntegrity` | Kotlin + native const | SHA-256 of APK signing cert vs baked release hash; debug builds exempt. Failure wipes the key cache. |
| `isTrusted` | native C | Emulator props (qemu/goldfish/ranchu), `ro.debuggable`, su binary paths |
| `antiTamperOk` | native C + Kotlin | Re-run before EVERY decrypt: `ptrace(PTRACE_TRACEME)`, `/proc/self/status` TracerPid, `/proc/self/maps` scan (frida, gum-js-loop, xposed, lsposed, substrate, epic, sandhook, edxp, pine, dobby), frida port 27042, xposed installer dir, `Debug.isDebuggerConnected()` |

Tamper response: in-memory decrypted cache cleared, transient key bytes
zeroed, on-disk key cache deleted. No decrypted plaintext is ever
written to disk — the cache is memory-only.

## 4. Obfuscation & build

- Release **requires**: `flutter build apk --release --obfuscate
  --split-debug-info=build/symbols/<stamp>` (documented in
  `docs/ASSET_FORMAT.md` and `RELEASE.md`).
- `minifyEnabled true` + `shrinkResources true` in release buildType.
- `libkeyguard.so` linked with `-s` (stripped).
- Detection strings in C are XOR-0x5A byte arrays decoded at call site.

## 5. CI enforcement

`.github/workflows/release-safety-check.yml` fails the build if:
`assets_src/` is committed, obfuscation flags are undocumented,
minify/shrink is removed, a raw 64-hex key literal appears in sources,
or `assets/encrypted/` is missing/too small.

## 6. Anywaa AI rules (must not regress)

`lib/services/groq_prompts.dart` enforces:

- Never speaks/writes Dha Anywaa — no sentences, greetings, proverbs,
  or example phrases. Sole exception: a single dictionary headword for
  a direct translation/meaning question.
- Answers from model knowledge only — no local app data is injected
  into prompts (dictionary/cultural-facts/Bible lookups removed).
- `cleanReply()` backstop: strips model attribution, normalizes
  invisible spaces/dashes, transliterates Anywaa orthography
  (ë ï ö ŋ ɔ ə) out of replies as a final guard.
- UTF-8 body decoding fixes mojibake.

Covered by `test/anywaa_ai_test.dart`, `test/mojibake_test.dart`.

## 7. Honest threat model

**Stops:** casual `unzip`/`strings` APK inspection; Dart-source analysis
(no key, filename algorithm, or magic in Dart); repackaged APKs; obvious
emulators/root; common Frida/Xposed setups; leaked on-disk key caches.

**Does NOT stop:** a determined reverse engineer. The key is recoverable
from `libkeyguard.so` on a rooted device (XOR arrays + SHA-256 are
deterministic); the worker endpoint has no Play Integrity attestation;
decrypted plaintext exists in memory while the app runs. This is
obfuscation + cost-raising, not DRM. The only true fix for key secrecy
is server-side gating with real attestation, which can be added to the
worker later.

## 8. Key rotation runbook

1. New passphrase → regenerate `kPartA`/`kPartB` in `key_guard.c`
   (XOR-split) and update `test/helpers/real_assets.dart`.
2. `DHA_ASSET_KEY=<new> python3 tools/encrypt_assets.py --verify`
   (re-encrypts all assets + decoys).
3. `wrangler secret put ASSET_PASSPHRASE` with the new value.
4. Bump `minSupportedVersionCode` so old builds are forced to update —
   they cannot decrypt the new assets.
5. Rebuild release APK with the obfuscation flags above.

## 9. File map

| Piece | Location |
|---|---|
| Format spec | `docs/ASSET_FORMAT.md` |
| Encryptor | `tools/encrypt_assets.py` |
| Key worker | `tools/key_server/` (worker.js, wrangler.toml, README) |
| Native guard | `android/app/src/main/cpp/key_guard.c`, `CMakeLists.txt` |
| Kotlin bridge | `MainActivity.kt`, `AssetKeyStore.kt` |
| Dart loader | `lib/services/encrypted_asset_loader.dart` |
| CI guard | `.github/workflows/release-safety-check.yml` |
| Tests | `test/encrypted_asset_loader_test.dart`, `test/helpers/real_assets.dart` |
| Plaintext sources | `assets_src/` (local only, never committed) |
| Encrypted output | `assets/encrypted/` (committed) |
| Local manifest | `tools/asset_manifest.log` (local only) |
| Server key part | `tools/asset_server_key.bin` (local only) |
| Release docs | `RELEASE.md`, `APP_DOCUMENTATION.md` |
| Audit reports | `docs/audit/` |
| Architecture | `docs/ARCHITECTURE.md` |
| Changelog | `CHANGELOG.md` |
| App docs | `README.md`, `APP_DOCUMENTATION.md` |
| OTA manifest | `manifest.json` (baked into each release) |
| Release notes | GitHub Releases (per tag) |
| Debug symbols | `build/symbols/<stamp>/` (keep private, needed to deobfuscate crash logs) |
| App icon/splash/fonts/media | rest of `assets/` — intentionally unencrypted |

## 10. Verification checklist (run before every release)

```bash
flutter analyze
flutter test
DHA_ASSET_KEY=… python3 tools/encrypt_assets.py --verify
dart format --set-exit-if-changed .
flutter build apk --release --obfuscate --split-debug-info=build/symbols/$(date +%Y%m%d)
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep assets/encrypted   # opaque names only
unzip -p <apk> lib/arm64-v8a/libkeyguard.so | strings | grep -iE 'ba3b|ro\.|xposed|frida|/proc|/system|/data|goldfish|debuggable'   # must be empty
sha256sum build/app/outputs/flutter-apk/app-release.apk   # record in manifest.json
```

Then: update `manifest.json`, tag `vX.Y.Z`, push, `gh release create`
with the renamed APK + manifest, and update `minSupportedVersionCode`
if the asset key rotated.

## 11. Known gaps (tracked, not hidden)

- Images/audio assets are still plaintext (~39 MB) — media encryption
  needs an AssetImage-compatible loader; not yet implemented.
- Worker endpoint lacks attestation — anyone with the URL can fetch a
  wrapped key for their own device. Obfuscation-grade only.
- `test/helpers/real_assets.dart` contains the passphrase for tests —
  excluded from CI's key-literal check; rotate the passphrase if this
  ever becomes a concern.
- Per-device HKDF key derivation was evaluated and rejected: shared
  APK assets require an identical key on every device, so binding is
  enforced at transport/cache layer instead (documented in
  `docs/ASSET_FORMAT.md`).
- Old `.tmp_apk/` release copies were cleaned from disk; GitHub
  Releases remain the archive of record.
- Disk space: builds need ~4 GB free; keep an eye on `df -h` before
  release builds.
- AI offline dictionary fallback in chat was intentionally kept when
  local-data grounding was removed — revisit if "no local data" is ever
  meant to include offline lookups too.
- Release APK currently bundles all ABIs in one file (~97 MB);
  `--split-per-abi` is available if download size matters.
- `lib/pages/page4.dart` contains an unrelated Anywaa name "Ojulu" as a
  quiz distractor — kept intentionally (it's a name option, not the
  creator attribution that was fixed in the dictionary).
- `word_aggregator.dart` contains hardcoded Anywaa word data in Dart
  source — it predates the encrypted pipeline and is a candidate for
  migration to an encrypted JSON asset in a future pass.
- `cultural_facts.json` is encrypted but only consumed by the offline
  AI service — it's not user-visible content, just context that was
  removed from model grounding; kept encrypted for consistency.
- `bible.json` encryption means Bible content is protected the same
  way as the dictionary — the reader page decrypts once per session.
- If the worker is ever taken down permanently, devices that already
  fetched the key keep working from the Keystore-wrapped cache; new
  installs fall back to the native-embedded key until a new endpoint
  ships — plan a backup distribution path before relying on the
  worker alone.
- The `AssetKeyStore` RSA keypair persists across app updates (same
  signing cert → same Keystore entries) — no re-pairing needed on
  normal updates; only reinstall or keystore clear triggers refetch.
- `checkIntegrity` uses `apkContentsSigners` on API 28+ and
  `signatures` below — both compare against the same baked hash;
  v1/v2 signature scheme differences are handled by taking the first
  signer, which is correct for this app's single-cert signing.
- The `antiTamperOk` check runs on the UI isolate via MethodChannel —
  it's fast (~ms) but if it ever shows up in profiles, move the
  maps/port scans to a native worker thread.
- `EncryptedAssetLoader._guard()` caches `_staticGuard` once per
  process — acceptable because Android doesn't allow mid-session cert
  changes without reinstall.
- The `debugBypassGuard`/`debugKeyOverride`/`debugInlineDecrypt` test
  hooks are `@visibleForTesting` — never set them in production code;
  a release build with them enabled would bypass all protection.
- `flutter analyze` reports ~53 pre-existing info/warnings (mostly
  `withOpacity` deprecations) — none are errors.
- `git` history was rewritten once to remove AI attribution — don't
  reintroduce co-author trailers or generated-with footers in
  commits; match the existing clean style.
- `docs/audit/` findings were addressed in batches 1-4 (commit
  `35589b7`) — any new audit should diff against that baseline.
- `NVIDIA Nemotron` is the default AI provider with `Groq` fallback —
  keys live in `lib/secrets.dart` (gitignored); never commit real
  keys or the file itself.
- The `Daily 5` feature is once-per-day by design — intentional
  pedagogy, not a bug.
- Streak/gamification data lives in `shared_preferences` — local-only,
  no cloud sync; losing it on reinstall is expected.
- OTA update checks hit `manifest.json` on the latest GitHub release —
  the URL is hardcoded in `ota_update_page.dart`; keep it stable.
- `minSupportedVersionCode` in the manifest gates forced updates —
  test OTA flow on a real device before bumping it.
- `android/gradle` 8.14.2 / AGP 8.11.1 / Kotlin 2.2.20 emit
  deprecation warnings — upgrade deliberately in a dedicated PR.
- `coreLibraryDesugaring` is enabled for `open_file`/`url_launcher`
  — don't remove it or those plugins break on older APIs.
- `google_fonts` is used for Charis SIL + UI fonts — fonts are bundled
  in `assets/fonts/` (unencrypted, intentionally).
- `audioplayers` handles all audio — asset paths in `page3.dart` etc.
  are plaintext media references; don't encrypt them without the
  compatible loader described above.
- `shared_preferences` stores user progress — schema changes need
  migration logic; never silently drop keys.
- OTA APKs are sideloaded via `open_file`, not Play Store — signature
  consistency across updates is critical (same upload keystore).
- `upload-keystore.jks` + `key.properties` are gitignored — never
  commit them; losing the keystore means users can't update in place.
  Back the keystore up somewhere safe.
- `local.properties`, `.metadata`, `android/.gradle`, `build/` are all
  gitignored — never commit build outputs.
- `pubspec.lock` IS committed — dependency resolution is reproducible.
- `analysis_options.yaml` controls lints — don't weaken rules to make
  CI pass; fix the code instead.
- `flutter_launcher_icons`/`flutter_native_splash` configs live in
  `pubspec.yaml` — regenerate after changing them.
- `android/app/proguard-rules.pro` — keep rules minimal; test release
  builds after adding any.
- `android/app/src/main/AndroidManifest.xml` — permissions and
  activities are declared here; check it before assuming a feature
  works (e.g., notification permission on Android 13+).
- `android/key.properties` + `android/upload-keystore.jks` — gitignored
  signing config; required for release builds.
- `assets_src/` — gitignored plaintext source; re-encrypting needs it.
- `tools/asset_server_key.bin`, `tools/asset_manifest.log`,
  `build/symbols/` — gitignored; local-only artifacts.
- `.github/workflows/` — CI definitions; the release-safety-check is
  the only workflow currently.
- `docs/audit/` — historical audit reports; keep for reference but
  don't treat as current state.
- `docs/ARCHITECTURE.md` — app structure; update on architectural
  changes.
- `RELEASE.md` — release runbook; keep it in sync with reality.
- `APP_DOCUMENTATION.md` — feature documentation; update on user-
  visible changes.
- `README.md` — repo overview; update on major changes.
- `CHANGELOG.md` — release history; update every release.
- `manifest.json` — OTA manifest; schema is fixed, update every
  release.
- `pubspec.yaml` — version + dependencies + assets; update every
  release.
- `lib/` — all Dart source.
- `test/` — all tests; keep them passing.
- `android/` — native Android project; the only native code is
  `key_guard.c` + `MainActivity.kt` + `AssetKeyStore.kt`.
- `assets/` — bundled resources; encrypted content in
  `assets/encrypted/`, media/fonts elsewhere.
- `assets_src/` — plaintext sources (local only).
- `tools/` — build/release utilities (encryptor, key server).
- `docs/` — documentation.
- `.github/` — CI workflows.
- Root files — `pubspec.yaml`, `manifest.json`, `CHANGELOG.md`,
  `README.md`, `APP_DOCUMENTATION.md`, `RELEASE.md`, `analysis_options.yaml`,
  `.gitignore`, plus gitignored `assets_src/` and `build/`.

*Last updated: v2.0.8 release.*
*If you change any protection layer, update this file in the same
commit.*
