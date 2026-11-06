import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the on-demand download of the Qwen2.5-0.5B GGUF model file.
///
/// CURRENT STATUS:
/// - Download infrastructure: ✅ Complete and working
/// - Model file storage: ✅ Working (saves to app documents)
/// - LLM inference: ⏳ Planned (requires llama.cpp FFI integration)
/// - Active AI: Dictionary-based AnywaaAiService (fully functional)
///
/// The app currently uses the dictionary-based AI for all responses.
/// The Qwen2.5 download prepares for future LLM inference that will
/// provide more conversational responses while maintaining accuracy.
///
/// Usage:
///   final svc = ModelDownloadService.instance;
///   svc.statusStream.listen((s) => ...);
///   await svc.download();
///   if (svc.isReady) { /* model file downloaded and ready */ }
class ModelDownloadService {
  ModelDownloadService._();
  static final ModelDownloadService instance = ModelDownloadService._();

  // ── Constants ─────────────────────────────────────────────────────────────
  static const _modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF'
      '/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf';
  static const _expectedBytes = 491400032; // 491,400,032 bytes (~469 MB)
  static const _fileName = 'qwen2.5-0.5b-instruct-q4_k_m.gguf';
  static const _prefKey = 'model_download_complete_qwen25';

  // ── State ─────────────────────────────────────────────────────────────────
  final _statusCtrl = StreamController<ModelStatus>.broadcast();

  /// Stream of download status updates. Listen to this to drive UI.
  Stream<ModelStatus> get statusStream => _statusCtrl.stream;

  ModelStatus _status = const ModelStatus.idle();
  ModelStatus get status => _status;

  bool get isReady => _status is ModelReady;
  bool get isDownloading => _status is ModelDownloading;

  // ── File path ─────────────────────────────────────────────────────────────
  Future<File> _modelFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call once at app startup to check if the model is already on disk.
  Future<void> checkExisting() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) != true) {
      _emit(const ModelStatus.idle());
      return;
    }
    final f = await _modelFile();
    if (await f.exists() && await f.length() == _expectedBytes) {
      _emit(ModelStatus.ready(f.path));
    } else {
      // Prefs says done but file is missing/corrupt — reset.
      await prefs.remove(_prefKey);
      _emit(const ModelStatus.idle());
    }
  }

  /// Starts the download. Safe to call when already downloading (no-op).
  Future<void> download() async {
    if (isDownloading || isReady) return;
    final file = await _modelFile();

    // Resume from partial download if file already exists.
    final existing = await file.exists() ? await file.length() : 0;
    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(_modelUrl));
      if (existing > 0) {
        request.headers['Range'] = 'bytes=$existing-';
      }

      _emit(ModelStatus.downloading(
          received: existing, total: _expectedBytes, path: file.path));

      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final sink = file.openWrite(
          mode: existing > 0 ? FileMode.append : FileMode.write);
      int received = existing;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        _emit(ModelStatus.downloading(
            received: received,
            total: _expectedBytes,
            path: file.path));
      }
      await sink.close();

      // Size check.
      final finalSize = await file.length();
      if (finalSize != _expectedBytes) {
        await file.delete();
        _emit(ModelStatus.error(
            'Download incomplete: got $finalSize bytes, '
            'expected $_expectedBytes. Please try again.'));
        return;
      }

      // Mark as complete.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      _emit(ModelStatus.ready(file.path));
    } catch (e) {
      _emit(ModelStatus.error('Download failed: $e'));
    } finally {
      client.close();
    }
  }

  /// Deletes the downloaded model and resets state.
  Future<void> deleteModel() async {
    final f = await _modelFile();
    if (await f.exists()) await f.delete();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _emit(const ModelStatus.idle());
  }

  void _emit(ModelStatus s) {
    _status = s;
    _statusCtrl.add(s);
  }
}

// ── Status types ─────────────────────────────────────────────────────────────

sealed class ModelStatus {
  const ModelStatus();
  const factory ModelStatus.idle() = ModelIdle;
  const factory ModelStatus.downloading(
      {required int received,
      required int total,
      required String path}) = ModelDownloading;
  const factory ModelStatus.ready(String path) = ModelReady;
  const factory ModelStatus.error(String message) = ModelError;
}

class ModelIdle extends ModelStatus {
  const ModelIdle();
}

class ModelDownloading extends ModelStatus {
  final int received;
  final int total;
  final String path;
  const ModelDownloading(
      {required this.received, required this.total, required this.path});

  /// 0.0 to 1.0
  double get progress => total > 0 ? received / total : 0;

  String get progressLabel {
    final mb = (received / 1024 / 1024).toStringAsFixed(1);
    final totalMb = (total / 1024 / 1024).toStringAsFixed(0);
    return '$mb / $totalMb MB';
  }
}

class ModelReady extends ModelStatus {
  final String path;
  const ModelReady(this.path);
}

class ModelError extends ModelStatus {
  final String message;
  const ModelError(this.message);
}
