import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dha_anywaaa/services/notification_service.dart';
import 'package:dha_anywaaa/services/analytics_service.dart';

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

enum OtaPhase { idle, running, success, error }

/// Snapshot of the in-app APK download, exposed so any screen can show live
/// progress without owning (or accidentally cancelling) the download.
class OtaDownloadState {
  final OtaPhase phase;
  final double progress;   // 0.0 .. 1.0
  final String message;
  final String? filePath;  // set once the APK is fully downloaded & verified

  const OtaDownloadState(this.phase, this.progress, this.message, [this.filePath]);

  bool get isRunning => phase == OtaPhase.running;
}

class OtaService {
  OtaService._internal();

  static final OtaService _instance = OtaService._internal();

  /// Singleton: every caller shares one instance so an in-flight download keeps
  /// running even when the Settings screen that started it is disposed.
  factory OtaService() => _instance;

  static const String _owner    = 'KornellaOtf';
  static const String _repo     = 'Dha-Anywaa-application';
  static const String _cacheKey = 'ota_last_check_ms';
  static const int _cacheTtlMs  = 1000 * 60 * 60 * 6; // 6 hours

  static const String _latestUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // ── Download state (survives navigation) ──────────────────────────────────
  final ValueNotifier<OtaDownloadState> download =
      ValueNotifier(const OtaDownloadState(OtaPhase.idle, 0, ''));

  bool _active = false;
  bool get isDownloading => _active;

  // ── Check ──────────────────────────────────────────────────────────────────
  /// Check for updates from GitHub releases.
  /// 
  /// [forceCheck] - If true, bypasses the 6-hour cache
  /// [silent] - If true, shows notification instead of returning result
  /// 
  /// Returns null if no update available or if silent mode is enabled.
  Future<OtaCheckResult?> checkForUpdate({
    bool forceCheck = false,
    bool silent = false,
  }) async {
    AnalyticsService.instance.logCheckUpdate(forced: forceCheck);

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

      final result = OtaCheckResult(
        updateAvailable:   true,
        mandatory:         manifest['mandatory'] as bool? ?? false,
        latestVersion:     manifest['version'] as String? ?? '',
        latestVersionCode: remoteCode,
        apkUrl:            manifest['apkUrl'] as String? ?? '',
        sha256:            manifest['sha256'] as String? ?? '',
        sizeBytes:         (manifest['sizeBytes'] as num?)?.toInt() ?? 0,
        releaseNotes:      manifest['releaseNotes'] as String? ?? '',
      );

      // If silent mode, show notification instead of returning result
      if (silent) {
        await NotificationService().showUpdateNotification(
          version: result.latestVersion,
          sizeBytes: result.sizeBytes,
          mandatory: result.mandatory,
        );
        return null; // Don't return result in silent mode
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  // ── Download (idempotent, resumable) ──────────────────────────────────────
  /// Starts (or ignores a duplicate of) the APK download. Progress and result
  /// are published on [download]; leaving the current screen will not cancel it,
  /// and a later retry resumes from the bytes already on disk instead of
  /// starting over.
  /// 
  /// [showNotifications] - If true, shows system notifications for progress
  void startDownload(OtaCheckResult result, {bool showNotifications = true}) {
    if (_active) return; // already running – do not restart or duplicate
    _active = true;
    download.value = const OtaDownloadState(
        OtaPhase.running, 0, 'Preparing download…');
    unawaited(_run(result, showNotifications: showNotifications));
  }

  Future<void> _run(OtaCheckResult result, {bool showNotifications = true}) async {
    File? part;
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      part = File('${dir.path}/dha_anywaa_update.apk.part');
      final finalFile = File('${dir.path}/dha_anywaa_update.apk');
      final expected = result.sizeBytes;

      // Reset to a clean file if we already produced a verified APK.
      if (await finalFile.exists()) {
        if (expected > 0 && await finalFile.length() == expected) {
          download.value = OtaDownloadState(
              OtaPhase.success, 1, 'Download complete. Tap to install.',
              finalFile.path);
          return;
        }
        await _deleteQuietly(finalFile);
      }

      int existing = part.existsSync() ? part.lengthSync() : 0;
      if (expected > 0 && existing > expected) {
        part.deleteSync();
        existing = 0;
      }

      // Fetch whatever is missing (HTTP Range resume) unless we already have it.
      if (!(expected > 0 && existing == expected)) {
        final request = http.Request('GET', Uri.parse(result.apkUrl));
        if (existing > 0) request.headers['Range'] = 'bytes=$existing-';

        final response =
            await request.send().timeout(const Duration(seconds: 30));
        if (response.statusCode != 200 && response.statusCode != 206) {
          _fail('Download failed (server ${response.statusCode}). Try again.');
          return;
        }

        // 206 means the server honoured our Range request and we can append.
        final resumed = response.statusCode == 206 && existing > 0;
        if (!resumed) {
          existing = 0;
          if (part.existsSync()) part.deleteSync();
        }

        final sink = part.openWrite(
            mode: resumed ? FileMode.append : FileMode.write);
        final contentLen = response.contentLength ??
            (expected > 0 ? expected - existing : 0);
        final total = expected > 0 ? expected : existing + contentLen;
        int received = existing;
        try {
          await for (final chunk in
              response.stream.timeout(const Duration(seconds: 60))) {
            sink.add(chunk);
            received += chunk.length;
            final pct = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
            download.value = OtaDownloadState(
              OtaPhase.running,
              pct,
              'Downloading… ${(pct * 100).toStringAsFixed(0)}% '
              '(${(received / 1048576).toStringAsFixed(1)} MB)',
            );
            
            // Update notification progress
            if (showNotifications) {
              await NotificationService().showDownloadProgress(
                progress: pct,
                bytesDownloaded: received,
                totalBytes: total,
              );
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }
      }

      if (!part.existsSync()) {
        _fail('Download failed. Try again.');
        return;
      }

      // ── Integrity checks (over the finished file) ───────────────────────
      if (expected > 0 && part.lengthSync() != expected) {
        await _deleteQuietly(part);
        _fail('Download incomplete. Tap to retry.');
        return;
      }
      if (result.sha256.isNotEmpty) {
        final digest = await _sha256OfFile(part);
        if (digest.toLowerCase() != result.sha256.toLowerCase()) {
          await _deleteQuietly(part);
          _fail('Download failed verification. Tap to retry.');
          return;
        }
      }

      await part.rename(finalFile.path);
      download.value = OtaDownloadState(
          OtaPhase.success, 1, 'Download complete. Tap to install.',
          finalFile.path);
      
      // Show completion notification
      if (showNotifications) {
        await NotificationService().cancelDownloadProgress();
        await NotificationService().showDownloadComplete();
      }
    } catch (_) {
      if (part != null) await _deleteQuietly(part);
      _fail('Download failed. Try again.');
      if (showNotifications) {
        await NotificationService().cancelDownloadProgress();
      }
    } finally {
      _active = false;
    }
  }

  void _fail(String message) {
    download.value = OtaDownloadState(OtaPhase.error, 0, message);
  }

  /// Clears a terminal (success/error) state so the tile returns to idle.
  void clearDownload() {
    if (_active) return;
    download.value = const OtaDownloadState(OtaPhase.idle, 0, '');
  }

  Future<String> _sha256OfFile(File file) async {
    final digestSink = _DigestSink();
    final hasher = sha256.startChunkedConversion(digestSink);
    await for (final chunk in file.openRead()) {
      hasher.add(chunk);
    }
    hasher.close();
    return digestSink.digest.toString();
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Minimal [Sink] that captures the single [Digest] emitted when a chunked
/// SHA-256 conversion is closed.
class _DigestSink implements Sink<Digest> {
  late Digest _digest;
  Digest get digest => _digest;

  @override
  void add(Digest data) => _digest = data;

  @override
  void close() {}
}
