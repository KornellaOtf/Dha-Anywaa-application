/**
 * Dha Anywaa asset-key endpoint (Cloudflare Worker, free tier).
 *
 * POST /v1/key  { "pubkey": "<base64 SPKI RSA-2048>" }
 *   → { "wrapped": "<base64 RSA-OAEP-SHA256 wrapped 32-byte AES key>" }
 *
 * The AES key = SHA-256(ASSET_PASSPHRASE secret). It is wrapped to the
 * caller's device public key, so only that device's Keystore private
 * key can unwrap it. Stateless — nothing is stored server-side.
 *
 * Deploy:
 *   cd tools/key_server
 *   wrangler secret put ASSET_PASSPHRASE   # the DHA_ASSET_KEY passphrase
 *   wrangler deploy
 * Then update ENDPOINT in AssetKeyStore.kt to your workers.dev URL.
 */

function b64encode(buf) {
  const bytes = new Uint8Array(buf);
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s);
}

function b64decode(s) {
  const bin = atob(s);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/health') {
      return new Response('ok');
    }
    if (request.method !== 'POST' || url.pathname !== '/v1/key') {
      return new Response('not found', { status: 404 });
    }
    if (!env.ASSET_PASSPHRASE) {
      return new Response('misconfigured', { status: 500 });
    }

    let pubkeyB64;
    try {
      const body = await request.json();
      pubkeyB64 = body.pubkey;
      if (typeof pubkeyB64 !== 'string' || pubkeyB64.length > 2000) {
        return new Response('bad request', { status: 400 });
      }
    } catch {
      return new Response('bad request', { status: 400 });
    }

    try {
      // AES key = SHA-256(passphrase), matching the native derivation.
      const passBytes = new TextEncoder().encode(env.ASSET_PASSPHRASE);
      const keyBytes = await crypto.subtle.digest('SHA-256', passBytes);

      const pubKey = await crypto.subtle.importKey(
        'spki',
        b64decode(pubkeyB64),
        { name: 'RSA-OAEP', hash: 'SHA-256' },
        false,
        ['encrypt']
      );

      const wrapped = await crypto.subtle.encrypt(
        { name: 'RSA-OAEP' },
        pubKey,
        keyBytes
      );

      return new Response(
        JSON.stringify({ wrapped: b64encode(wrapped) }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    } catch (e) {
      return new Response('key error', { status: 500 });
    }
  },
};
