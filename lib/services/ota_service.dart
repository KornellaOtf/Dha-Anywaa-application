import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of an OTA check.
class OtaCheckResult {
  final bool updateAvailable;
  final bool mandatory;
  final String latestVersion;
  final int latestVersionCode;
  final String apkUrl;
  final String sha256;
  final int sizeBytes;
  final String releaseNotes;

  const OtaCheckResult({
    required this.updateAvailable,
    required this.mandatory,
    required this.latestVersion,
    required this.latestVersionCode,
    required this.apkUrl,
    required this.sha256,
    required this.sizeBytes,
    required this.releaseNotes,
  });
}

class OtaService {
  static const String _owner     = 'oriemiobang';
  static const String _repo      = 'Dha-Anywaa-application';
  static const String _cacheKey  = 'ota_last_check_ms';
  static const int    _cacheTtlMs = 1000 * 60 * 60 * 6; // 6 hours

  // Stable channel: /releases/latest ignores prereleases automatically.
  static const String _latestUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Check for an update. Returns null if no update is available or if the
  /// cache TTL has not expired (prevents hammering the GitHub API).
  Future<OtaCheckResult?> checkForUpdate({bool forceCheck = false}) async {
    // ── Cache guard ─────────────────────────────────────────────────────────
    if (!forceCheck) {
      final prefs     = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_cacheKey) ?? 0;
      final now       = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCheck < _cacheTtlMs) return null;
    }

    try {
      // ── 1. Fetch latest release metadata ──────────────────────────────────
      final releaseRes = await http
          .get(Uri.parse(_latestUrl),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));

      if (releaseRes.statusCode != 200) return null;

      final release = json.decode(releaseRes.body) as Map<String, dynamic>;
      final assets  = release['assets'] as List<dynamic>;

      // ── 2. Find manifest.json asset ───────────────────────────────────────
      final manifestAsset = assets.firstWhere(
        (a) => (a['name'] as String) == 'manifest.json',
        orElse: () => null,
      );
      if (manifestAsset == null) return null;

      final manifestUrl = manifestAsset['browser_download_url'] as String;
      final manifestRes = await http
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 10));

      if (manifestRes.statusCode != 200) return null;

      final manifest =
          json.decode(manifestRes.body) as Map<String, dynamic>;

      // ── 3. Compare version codes ──────────────────────────────────────────
      final remoteCode = (manifest['versionCode'] as num).toInt();
      final info       = await PackageInfo.fromPlatform();
      final localCode  = int.tryParse(info.buildNumber) ?? 0;

      // Update cache timestamp regardless of result
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _cacheKey, DateTime.now().millisecondsSinceEpoch);

      if (remoteCode <= localCode) return null; // already up to date

      // ── 4. Build result ───────────────────────────────────────────────────
      return OtaCheckResult(
        updateAvailable:    true,
        mandatory:          manifest['mandatory'] as bool? ?? false,
        latestVersion:      manifest['version'] as String? ?? '',
        latestVersionCode:  remoteCode,
        apkUrl:             manifest['apkUrl'] as String? ?? '',
        sha256:             manifest['sha256'] as String? ?? '',
        sizeBytes:          (manifest['sizeBytes'] as num?)?.toInt() ?? 0,
        releaseNotes:       manifest['releaseNotes'] as String? ?? '',
      );
    } catch (_) {
      return null; // network error — fail silently
    }
  }
}
