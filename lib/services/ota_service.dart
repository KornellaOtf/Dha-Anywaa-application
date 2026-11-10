import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
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
  final double progress; // 0.0 .. 1.0
  final String message;
  final String? filePath; // set once the APK is fully downloaded & verified

  const OtaDownloadState(this.phase, this.progress, this.message,
      [this.filePath]);

  bool get isRunning => phase == OtaPhase.running;
}

class OtaService {
  OtaService._internal();

  static final OtaService _instance = OtaService._internal();

  /// Singleton: every caller shares one instance so an in-flight download keeps
  /// running even when the Settings screen that started it is disposed.
  factory OtaService() => _instance;

  static const String _owner = 'KornellaOtf';
  static const String _repo = 'Dha-Anywaa-application';
  static const String _cacheKey = 'ota_last_check_ms';
  static const int _cacheTtlMs = 1000 * 60 * 60 * 6; // 6 hours
  static const String _taskId = 'ota_apk_download';

  static const String _latestUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // ── Download state (survives navigation) ─────────────────────────────────
  final ValueNotifier<OtaDownloadState> download =
      ValueNotifier(const OtaDownloadState(OtaPhase.idle, 0, ''));

  bool _active = false;
  bool get isDownloading => _active;

  // ── One-time initializer — call from main() ───────────────────────────────
  /// Initializes background_downloader and re-attaches to any in-progress
  /// download that survived the app being killed. Call once at app startup.
  static Future<void> initialize() async {
    await FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(minutes: 10)),
      ],
      androidConfig: [
        // Show a persistent "Downloading update…" notification so Android
        // keeps the download alive even if the user switches to another app.
        (Config.useCacheDir, false),
      ],
    );

    // Re-attach listener in case the app was relaunched mid-download.
    FileDownloader().updates.listen((update) {
      _instance._handleUpdate(update);
    });
  }

  // ── Check ─────────────────────────────────────────────────────────────────
  /// Check for updates from GitHub releases.
  ///
  /// [forceCheck] - If true, bypasses the 6-hour cache
  /// [silent] - If true, shows notification instead of returning result
  Future<OtaCheckResult?> checkForUpdate({
    bool forceCheck = false,
    bool silent = false,
  }) async {
    AnalyticsService.instance.logCheckUpdate(forced: forceCheck);

    if (!forceCheck) {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_cacheKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCheck < _cacheTtlMs) return null;
    }

    try {
      final releaseRes = await http
          .get(Uri.parse(_latestUrl),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));

      if (releaseRes.statusCode != 200) return null;

      final release = json.decode(releaseRes.body) as Map<String, dynamic>;
      final assets = (release['assets'] as List<dynamic>);

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
      final info = await PackageInfo.fromPlatform();
      final localCode = int.tryParse(info.buildNumber) ?? 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheKey, DateTime.now().millisecondsSinceEpoch);

      if (remoteCode <= localCode) return null;

      final result = OtaCheckResult(
        updateAvailable: true,
        mandatory: manifest['mandatory'] as bool? ?? false,
        latestVersion: manifest['version'] as String? ?? '',
        latestVersionCode: remoteCode,
        apkUrl: manifest['apkUrl'] as String? ?? '',
        sha256: manifest['sha256'] as String? ?? '',
        sizeBytes: (manifest['sizeBytes'] as num?)?.toInt() ?? 0,
        releaseNotes: manifest['releaseNotes'] as String? ?? '',
      );

      if (silent) {
        await NotificationService().showUpdateNotification(
          version: result.latestVersion,
          sizeBytes: result.sizeBytes,
          mandatory: result.mandatory,
        );
        return null;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────
  /// Starts the APK download as a background foreground-service task.
  /// The download will continue even if the user switches to another app,
  /// locks their phone, or minimises Dha Anywaa.
  void startDownload(OtaCheckResult result, {bool showNotifications = true}) {
    if (_active) return;
    _active = true;
    // Store result details for use in the update handler
    _pendingResult = result;
    download.value =
        const OtaDownloadState(OtaPhase.running, 0, 'Preparing download…');
    unawaited(_enqueue(result, showNotifications: showNotifications));
  }

  OtaCheckResult? _pendingResult;

  Future<void> _enqueue(OtaCheckResult result,
      {bool showNotifications = true}) async {
    try {
      // Cancel any stale task with the same ID
      await FileDownloader().cancelTaskWithId(_taskId);

      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final fileName = 'dha_anywaa_update.apk';

      // Check if a completed verified file already exists
      final existing = File('${dir.path}/$fileName');
      if (await existing.exists() &&
          result.sizeBytes > 0 &&
          await existing.length() == result.sizeBytes) {
        final digest = await _sha256OfFile(existing);
        if (digest.toLowerCase() == result.sha256.toLowerCase()) {
          download.value = OtaDownloadState(
              OtaPhase.success, 1, 'Download complete. Tap to install.',
              existing.path);
          _active = false;
          return;
        }
        await _deleteQuietly(existing);
      }

      final task = DownloadTask(
        taskId: _taskId,
        url: result.apkUrl,
        filename: fileName,
        directory: dir.path,
        baseDirectory: BaseDirectory.root,
        updates: Updates.statusAndProgress,
        requiresWiFi: false,
        retries: 3,
        allowPause: true,
        // This notification keeps Android from killing the download
        // when the user switches apps.
        displayName: 'Downloading update ${result.latestVersion}…',
      );

      await FileDownloader().download(
        task,
        onProgress: (progress) {
          final pct = progress.clamp(0.0, 1.0);
          final recvMb =
              ((pct * result.sizeBytes) / 1048576).toStringAsFixed(1);
          final totalMb = (result.sizeBytes / 1048576).toStringAsFixed(1);
          download.value = OtaDownloadState(
            OtaPhase.running,
            pct,
            'Downloading… ${(pct * 100).toStringAsFixed(0)}%'
            ' ($recvMb of $totalMb MB)',
          );

          if (showNotifications) {
            NotificationService().showDownloadProgress(
              progress: pct,
              bytesDownloaded: (pct * result.sizeBytes).round(),
              totalBytes: result.sizeBytes,
            );
          }
        },
        onStatus: (status) async {
          if (status == TaskStatus.complete) {
            await _onComplete(result,
                filePath: '${dir.path}/$fileName',
                showNotifications: showNotifications);
          } else if (status == TaskStatus.failed ||
              status == TaskStatus.notFound) {
            _fail('Download failed. Tap to retry.');
            if (showNotifications) {
              await NotificationService().cancelDownloadProgress();
            }
            _active = false;
          } else if (status == TaskStatus.canceled) {
            download.value =
                const OtaDownloadState(OtaPhase.idle, 0, '');
            _active = false;
          }
        },
      );
    } catch (e) {
      _fail('Download failed. Try again.');
      _active = false;
    }
  }

  void _handleUpdate(TaskUpdate update) {
    // Re-attach progress from background updates (e.g. after app reopen)
    if (update.task.taskId != _taskId) return;
    if (update is TaskProgressUpdate) {
      final pct = update.progress.clamp(0.0, 1.0);
      final result = _pendingResult;
      if (result != null) {
        final recvMb =
            ((pct * result.sizeBytes) / 1048576).toStringAsFixed(1);
        final totalMb = (result.sizeBytes / 1048576).toStringAsFixed(1);
        download.value = OtaDownloadState(
          OtaPhase.running,
          pct,
          'Downloading… ${(pct * 100).toStringAsFixed(0)}%'
          ' ($recvMb of $totalMb MB)',
        );
      }
    }
  }

  Future<void> _onComplete(
    OtaCheckResult result, {
    required String filePath,
    required bool showNotifications,
  }) async {
    final file = File(filePath);

    // Size check
    if (result.sizeBytes > 0 && await file.length() != result.sizeBytes) {
      await _deleteQuietly(file);
      _fail('Download incomplete. Tap to retry.');
      _active = false;
      return;
    }

    // SHA-256 check
    if (result.sha256.isNotEmpty) {
      final digest = await _sha256OfFile(file);
      if (digest.toLowerCase() != result.sha256.toLowerCase()) {
        await _deleteQuietly(file);
        _fail('Download failed verification. Tap to retry.');
        _active = false;
        return;
      }
    }

    // Log analytics
    final info = await PackageInfo.fromPlatform();
    AnalyticsService.instance
        .logDownloadUpdate(info.version, result.latestVersion);

    download.value = OtaDownloadState(
        OtaPhase.success, 1, 'Download complete. Tap to install.', filePath);

    if (showNotifications) {
      await NotificationService().cancelDownloadProgress();
      await NotificationService().showDownloadComplete();
    }
    _active = false;
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
