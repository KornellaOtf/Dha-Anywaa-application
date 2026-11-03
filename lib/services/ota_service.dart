import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  static const String _owner    = 'KornellaOtf';
  static const String _repo     = 'Dha-Anywaa-application';
  static const String _cacheKey = 'ota_last_check_ms';
  static const int _cacheTtlMs  = 1000 * 60 * 60 * 6; // 6 hours

  static const String _latestUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // ── Check ──────────────────────────────────────────────────────────────────
  Future<OtaCheckResult?> checkForUpdate({bool forceCheck = false}) async {
    if (!forceCheck) {
      final prefs     = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_cacheKey) ?? 0;
      final now       = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCheck < _cacheTtlMs) return null;
    }

    try {
      final releaseRes = await http
          .get(Uri.parse(_latestUrl),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));

      if (releaseRes.statusCode != 200) return null;

      final release = json.decode(releaseRes.body) as Map<String, dynamic>;
      final assets  = (release['assets'] as List<dynamic>);

      final manifestAsset = assets.firstWhere(
        (a) => (a['name'] as String) == 'manifest.json',
        orElse: () => null,
      );
      if (manifestAsset == null) return null;

      final manifestRes = await http
          .get(Uri.parse(manifestAsset['browser_download_url'] as String))
          .timeout(const Duration(seconds: 10));

      if (manifestRes.statusCode != 200) return null;

      final manifest = json.decode(manifestRes.body) as Map<String, dynamic>;
      final remoteCode = (manifest['versionCode'] as num).toInt();
      final info       = await PackageInfo.fromPlatform();
      final localCode  = int.tryParse(info.buildNumber) ?? 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheKey, DateTime.now().millisecondsSinceEpoch);

      if (remoteCode <= localCode) return null;

      return OtaCheckResult(
        updateAvailable:   true,
        mandatory:         manifest['mandatory'] as bool? ?? false,
        latestVersion:     manifest['version'] as String? ?? '',
        latestVersionCode: remoteCode,
        apkUrl:            manifest['apkUrl'] as String? ?? '',
        sha256:            manifest['sha256'] as String? ?? '',
        sizeBytes:         (manifest['sizeBytes'] as num?)?.toInt() ?? 0,
        releaseNotes:      manifest['releaseNotes'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  // ── Download APK to local storage ─────────────────────────────────────────
  /// Downloads the APK and returns its local [File] path.
  /// [onProgress] is called with 0.0–1.0 as bytes arrive.
  Future<File?> downloadApk(
    OtaCheckResult result, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir  = await getExternalStorageDirectory() ??
                   await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/dha_anywaa_update.apk');

      final request  = http.Request('GET', Uri.parse(result.apkUrl));
      final response = await request.send().timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) return null;

      final total     = response.contentLength ?? 0;
      int   received  = 0;
      final sink      = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
      return file;
    } catch (_) {
      return null;
    }
  }
}
