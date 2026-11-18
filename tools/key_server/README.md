# Asset key endpoint (Cloudflare Worker)

Tiny stateless endpoint that delivers the encrypted-asset AES key,
wrapped to each device's own RSA public key.

## Deploy (one time, free)

```bash
cd tools/key_server
npm i -g wrangler   # or use npx wrangler
wrangler login
wrangler secret put ASSET_PASSPHRASE   # paste the DHA_ASSET_KEY passphrase
wrangler deploy
```

The worker URL will be `https://dna-asset-key.<account>.workers.dev`.
Update `ENDPOINT` in
`android/app/src/main/kotlin/com/kornellaotf/learn_dha_anywaa/AssetKeyStore.kt`.

## Key rotation

1. Generate a new passphrase, re-run `tools/encrypt_assets.py` with it.
2. `wrangler secret put ASSET_PASSPHRASE` with the new value.
3. Bump `minSupportedVersionCode` so old builds (native-embedded old
   key) are forced to update — they can't decrypt the new assets.

## Honest limits

- The endpoint has no attestation: anyone who finds the URL can request
  a wrapped key for their own device keypair. This is obfuscation-grade,
  same as the rest of the asset system — it raises cost, it is not a
  hard wall. Play Integrity attestation can be added later inside the
  worker if needed.
- The native-embedded key remains as an offline fallback until rotation.
