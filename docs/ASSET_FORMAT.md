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
- `DHA_ASSET_KEY` is a high-entropy passphrase stored **only** in
  `lib/secrets.dart` (compiled into the app, same protection level as
  the API keys) and in the `DHA_ASSET_KEY` environment variable for the
  Python encryptor. Never committed.
- Rationale: assets are obfuscation, not DRM — a determined attacker
  with the APK can extract the key. The goal is raising the bar against
  casual `unzip`/`strings` inspection.

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
DHA_ASSET_KEY=... python3 tools/encrypt_assets.py

# Verify round-trip
DHA_ASSET_KEY=... python3 tools/encrypt_assets.py --verify
```

Dart side: `EncryptedAssetLoader.instance.loadBytes('data/dictionary_full')`
returns decrypted `Uint8List`; `loadString` decodes UTF-8.
Decrypts on an isolate; caches per logical ID.

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
