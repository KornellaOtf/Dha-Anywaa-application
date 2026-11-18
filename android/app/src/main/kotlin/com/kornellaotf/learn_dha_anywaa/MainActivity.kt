package com.kornellaotf.learn_dha_anywaa

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity: FlutterActivity() {

    companion object {
        init { System.loadLibrary("keyguard") }

        @JvmStatic external fun getAssetKey(): ByteArray
        @JvmStatic external fun getAssetName(logicalId: String): String
        @JvmStatic external fun getMagicBytes(): ByteArray
        @JvmStatic external fun expectedCertHash(): String
        @JvmStatic external fun isTrustedEnvironment(): Boolean
        @JvmStatic external fun antiTamperOk(): Boolean
        @JvmStatic external fun guardReport(): String
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dna/asset_guard")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAssetKey" -> {
                        // AssetKeyStore may do a network fetch — never on
                        // the platform thread.
                        Thread {
                            val key = AssetKeyStore.get(applicationContext) ?: getAssetKey()
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(key)
                            }
                        }.start()
                    }
                    "getAssetName" -> result.success(getAssetName(call.arguments as String))
                    "getMagicBytes" -> result.success(getMagicBytes())
                    "isTrusted" -> result.success(isTrustedEnvironment())
                    "antiTamperOk" -> result.success(
                        !android.os.Debug.isDebuggerConnected() && antiTamperOk())
                    // Diagnostic only — never expose check detail in release.
                    "guardReport" -> result.success(
                        if (BuildConfig.DEBUG)
                            "trusted=${isTrustedEnvironment()} intact=${checkIntegrity()} " +
                            "tamper=${antiTamperOk()} native=[${guardReport()}]"
                        else "unavailable")
                    "checkIntegrity" -> result.success(checkIntegrity())
                    else -> result.notImplemented()
                }
            }
    }

    /** SHA-256 of the APK signing cert, compared against the native-baked hash. */
    private fun checkIntegrity(): Boolean {
        // Debug builds are signed with the debug cert — skip the check.
        if (BuildConfig.DEBUG) return true
        val ok = runCatching { verifySignature() }.getOrDefault(false)
        if (!ok) AssetKeyStore.wipe(applicationContext) // tamper response
        return ok
    }

    private fun verifySignature(): Boolean {
        return try {
            val pm = packageManager
            val sig = if (Build.VERSION.SDK_INT >= 28) {
                pm.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                    .signingInfo?.apkContentsSigners?.firstOrNull()
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                    .signatures?.firstOrNull()
            } ?: return false
            val md = MessageDigest.getInstance("SHA-256").digest(sig.toByteArray())
            val actual = md.joinToString("") { "%02X".format(it) }
            actual == expectedCertHash()
        } catch (e: Exception) {
            false
        }
    }
}
