package com.kornellaotf.learn_dha_anywaa

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Server-delivered asset key with device-bound caching.
 *
 * Flow:
 *  1. Keystore RSA-2048 keypair (private key non-exportable) identifies
 *     this install. Public key is sent to the key endpoint.
 *  2. Endpoint returns the asset AES key wrapped with RSA-OAEP-SHA256 —
 *     only this device's private key can unwrap it.
 *  3. The unwrapped key is cached on disk wrapped by a Keystore AES/GCM
 *     key, so the raw key never touches storage unprotected.
 *  4. Offline fallback: the native-embedded key (MainActivity.getAssetKey).
 */
object AssetKeyStore {

    private const val KEYSTORE = "AndroidKeyStore"
    private const val RSA_ALIAS = "dna_asset_rsa"
    private const val AES_ALIAS = "dna_asset_aes"
    private const val ENDPOINT = "https://dna-asset-key.kornellaotf.workers.dev/v1/key"
    private const val TIMEOUT_MS = 10_000

    @Volatile private var cached: ByteArray? = null
    @Volatile private var lastFailAt = 0L
    private val FAIL_BACKOFF_MS = 5 * 60 * 1000L

    /** Returns the 32-byte asset key, or null if unavailable. */
    fun get(context: Context): ByteArray? {
        cached?.let { return it }
        // Don't hammer a dead/undeployed endpoint on every decrypt call.
        if (System.currentTimeMillis() - lastFailAt < FAIL_BACKOFF_MS) {
            return null
        }
        return try {
            val key = loadCached(context) ?: fetchAndCache(context)
            if (key == null) lastFailAt = System.currentTimeMillis()
            cached = key
            key
        } catch (e: Exception) {
            lastFailAt = System.currentTimeMillis()
            null
        }
    }

    /** Delete all cached key material (tamper response / integrity fail). */
    fun wipe(context: Context) {
        cached = null
        try {
            File(context.filesDir, "asset_key.enc").delete()
            File(context.filesDir, "asset_key.iv").delete()
        } catch (_: Exception) {}
        // Keystore aliases are left in place — deleting them would force
        // re-pairing on legit reinstalls of the same APK signature anyway.
    }

    // ── RSA device keypair ────────────────────────────────────────────────

    private fun rsaKeyPair(): java.security.KeyPair {
        val ks = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        if (ks.containsAlias(RSA_ALIAS)) {
            val priv = ks.getKey(RSA_ALIAS, null) as java.security.PrivateKey
            val pub = ks.getCertificate(RSA_ALIAS).publicKey
            return java.security.KeyPair(pub, priv)
        }
        val kpg = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_RSA, KEYSTORE)
        kpg.initialize(
            KeyGenParameterSpec.Builder(
                RSA_ALIAS,
                KeyProperties.PURPOSE_DECRYPT or KeyProperties.PURPOSE_SIGN)
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
                .setKeySize(2048)
                .build())
        return kpg.generateKeyPair()
    }

    // ── Keystore AES wrap for the cached key ──────────────────────────────

    private fun aesKey(): SecretKey {
        val ks = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        if (ks.containsAlias(AES_ALIAS)) {
            return ks.getKey(AES_ALIAS, null) as SecretKey
        }
        val kg = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        kg.init(
            KeyGenParameterSpec.Builder(
                AES_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build())
        return kg.generateKey()
    }

    private fun loadCached(context: Context): ByteArray? {
        val dir = context.filesDir
        val ct = File(dir, "asset_key.enc")
        val iv = File(dir, "asset_key.iv")
        if (!ct.exists() || !iv.exists()) return null
        return try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, aesKey(),
                GCMParameterSpec(128, iv.readBytes()))
            cipher.doFinal(ct.readBytes())
        } catch (e: Exception) {
            wipe(context); null
        }
    }

    private fun saveCached(context: Context, key: ByteArray) {
        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val iv = ByteArray(12).also { SecureRandom().nextBytes(it) }
            cipher.init(Cipher.ENCRYPT_MODE, aesKey(), GCMParameterSpec(128, iv))
            File(context.filesDir, "asset_key.enc").writeBytes(cipher.doFinal(key))
            File(context.filesDir, "asset_key.iv").writeBytes(iv)
        } catch (_: Exception) {}
    }

    // ── Fetch + unwrap ────────────────────────────────────────────────────

    private fun fetchAndCache(context: Context): ByteArray? {
        val pair = rsaKeyPair()
        val pubB64 = Base64.encodeToString(
            pair.public.encoded, Base64.NO_WRAP)

        val body = JSONObject().put("pubkey", pubB64).toString()
        val conn = URL(ENDPOINT).openConnection() as HttpURLConnection
        conn.connectTimeout = TIMEOUT_MS
        conn.readTimeout = TIMEOUT_MS
        conn.requestMethod = "POST"
        conn.doOutput = true
        conn.setRequestProperty("Content-Type", "application/json")
        conn.outputStream.use { it.write(body.toByteArray()) }

        if (conn.responseCode != 200) return null
        val resp = conn.inputStream.bufferedReader().readText()
        conn.disconnect()
        val wrappedB64 = JSONObject(resp).optString("wrapped")
        if (wrappedB64.isEmpty()) return null

        val cipher = Cipher.getInstance("RSA/ECB/OAEPwithSHA-256andMGF1Padding")
        cipher.init(Cipher.DECRYPT_MODE, pair.private)
        val key = cipher.doFinal(Base64.decode(wrappedB64, Base64.NO_WRAP))
        if (key.size != 32) return null

        saveCached(context, key)
        return key
    }
}
