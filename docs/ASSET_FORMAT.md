# Encrypted Asset Format — Dha Anywaa

Custom encrypted container for bundled learning content. Goal: APK
contents are opaque — no plaintext lesson/dictionary/Bible text or
obvious filenames visible to `unzip -l` or `strings`.

This spec covers **JSON/text content assets**. Images and audio use the
same container but are wired separately (see "Scope" below).

## File layout

```
offset  size  field
0       8     magic header (see below)
8       1     version (uint8, currently 0x01)
9       12    AES-GCM nonce
21      n     AES-GCM ciphertext || 16-byte auth tag
```

- Cipher: **AES-256-GCM** (authenticated encryption; tampering fails).
- The auth tag is appended by the AES-GCM implementation
  (`cryptography`'s `AESGCM.encrypt` output already includes it).
- Total file size = 21 + plaintext_size + 16.

## Magic header

8 bytes, hex `A7 4E 43 52 59 50 54 21`
(ASCII-ish "…NCRYPT!" — chosen for this app, not copied from any
public format).

## Key

- 32-byte AES key = `SHA-256(DHA_ASSET_KEY)`.
- `DHA_ASSET_KEY` is a high-entropy passphrase. It is **not in Dart**:
  the passphrase lives XOR-split across two constant arrays inside
  `android/app/src/main/cpp/key_guard.c` (native `keyguard` library),
  reassembled and hashed only in native code per call.
- The Python encryptor gets the same passphrase via the
  `DHA_ASSET_KEY` environment variable. Never committed.
- Rationale: assets are obfuscation, not DRM — a determined attacker
  can still extract the key from the native library. The goal is
  raising the bar against casual `unzip`/`strings` inspection and
  Dart-source analysis.

## Nonce (deterministic)

`nonce = HMAC-SHA256(key, "nonce:" + logical_id)[:12]`

Deterministic so re-running the encryptor on unchanged sources yields
byte-identical output (idempotent builds, reproducible APKs).
HMAC is keyed, so nonces are not predictable without the key.

## Obfuscated filename

`name = lowercase_hex(HMAC-SHA256(key, "name:" + logical_id)[:8])`
i.e. 16 lowercase hex chars, e.g. `assets/encrypted/3fa9c1d2e8b47a60`.

- No extension — extension would leak content type.
- Same logical ID always maps to the same filename.

## Logical IDs

Logical ID = path relative to `assets_src/` without extension mangling,
using `/` separators, e.g.:

| logical_id                  | plaintext source                    |
|-----------------------------|-------------------------------------|
| `data/dictionary_full`      | `assets_src/data/dictionary_full.json` |
| `data/cultural_facts`       | `assets_src/data/cultural_facts.json`  |
| `bible`                     | `assets_src/bible.json`             |

(Convention: strip the final extension, keep directories.)

## Index

**No plaintext index ships.** The loader recomputes the obfuscated
filename from the logical ID at runtime using the same keyed hash.

## Scope

- `assets_src/` holds plaintext sources and is **gitignored** — never
  committed, never shipped.
- `tools/asset_manifest.log` (source → obfuscated name) is for the
  developer only, also gitignored.
- `assets/encrypted/` holds ciphertext and IS committed (it's what the
  APK bundles via `pubspec.yaml`).
- Images/audio are out of scope for v1 of this format.

## Usage

```bash
# Encrypt (requires DHA_ASSET_KEY env var + python cryptography pkg)
DHA_ASSET_KEY=... python3 tools/encrypt_assets.py --verify
```

## Release build (required flags)

Never ship an unobfuscated build. The release command is:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols/$(date +%Y%m%d)
```

`android/app/build.gradle` already sets `minifyEnabled true` and
`shrinkResources true` for release; keep them.

## Native layer (`keyguard`)

`android/app/src/main/cpp/key_guard.c` (CMake, all ABIs) exposes JNI
methods bridged to Dart via `MethodChannel('dna/asset_guard')` in
`MainActivity.kt`:

| Channel method | Returns |
|---|---|
| `getAssetKey` | derived 32-byte AES key (transient, per call) |
| `getAssetName` | HMAC-derived obfuscated filename for a logical ID |
| `getMagicBytes` | container magic bytes |
| `isTrusted` | false on emulator/root/debug builds signals |
| `checkIntegrity` | APK signing-cert SHA-256 vs baked constant; wipes key cache on failure |
| `antiTamperOk` | re-checked before EVERY decrypt: JDWP, ptrace/TracerPid, Frida/Xposed maps + port scan |

- Filename derivation and magic bytes are **not** in Dart source.
- `checkIntegrity` compares the running APK's signing cert against the
  release cert hash baked into native code; debug builds are exempt.
  On failure it also wipes the on-disk key cache.
- `antiTamperOk` re-runs before every decrypt (hooking can attach
  after launch). ptrace self-attach, /proc/self/status TracerPid,
  /proc/self/maps scan for frida/xposed/lsposed/substrate/dobby etc.,
  frida-server port 27042, xposed installer dir, plus
  `Debug.isDebuggerConnected()` on the Kotlin side. All failures return
  the same generic refusal — nothing reveals which check tripped.

## Server-delivered key (AssetKeyStore.kt)

The 32-byte key can also be fetched from a tiny Cloudflare Worker
(`tools/key_server/`):

1. Device generates an RSA-2048 keypair inside AndroidKeyStore
   (private key non-exportable).
2. App POSTs the public key; worker returns the asset key wrapped with
   RSA-OAEP-SHA256 — only that device can unwrap it.
3. The unwrapped key is cached on disk AES-GCM-wrapped by a second
   Keystore key, so raw key bytes never touch storage.
4. Offline fallback: the native-embedded key is used when the fetch
   fails, so first-launch-offline still works.

**Device binding:** a dumped wrapped blob or cache file is useless on
any other device or reinstall — unwrapping requires the on-device
Keystore keys. The raw key exists in memory only transiently.

**Backend down / key rotation:** the worker is stateless. Rotate by
updating the `ASSET_PASSPHRASE` secret and re-running
`tools/encrypt_assets.py`; bump `minSupportedVersionCode` so older
builds update. If the worker is deleted entirely, devices that already
cached the key keep working; new installs fall back to the native key
until a new endpoint ships.
- Decoy files: `tools/encrypt_assets.py` also writes 8 deterministic
  fake containers (valid headers, garbage ciphertext) into
  `assets/encrypted/` so bulk-extraction scripts produce broken output.

Dart side: `EncryptedAssetLoader.instance.loadBytes('data/dictionary_full')`
returns decrypted `Uint8List`; `loadString` decodes UTF-8.
Decrypts on an isolate; caches per logical ID in memory only.

## Threat model (honest)

- Stops: casual APK browsing, `strings`, `unzip -l`, asset ripping.
- Does NOT stop: a motivated attacker decompiling the Dart code,
  extracting `secrets.dart`'s key, and decrypting. True protection
  would need a server-side proxy — tracked as future work.
- Encrypted assets are slightly larger (+21 bytes overhead per file)
  and decrypt once per session per asset (cached in memory).
- Deterministic nonces are safe here because each plaintext is encrypted
  exactly once with a fixed key; nonce reuse would only matter if the
  same (key, nonce) pair encrypted two different plaintexts, which
  cannot happen since nonce derives from the unique logical ID.
- Decryption happens on first use, in an isolate — UI thread never
  blocks, low-RAM devices unaffected.

## Versioning

`version` byte allows future format changes. Loader rejects versions
!= 0x01 with `AssetDecryptException`.

---

*Last updated: initial spec (v2.0.8 development).*
