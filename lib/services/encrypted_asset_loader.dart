import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' hide Hmac;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:dha_anywaaa/secrets.dart';

/// Thrown when a bundled encrypted asset fails validation or decryption.
class AssetDecryptException implements Exception {
  final String logicalId;
  final String reason;
  const AssetDecryptException(this.logicalId, this.reason);

  @override
  String toString() => 'AssetDecryptException($logicalId): $reason';
}

/// Loads bundled content assets encrypted per docs/ASSET_FORMAT.md.
///
/// Filenames are derived at runtime via keyed HMAC — no plaintext index
/// ships in the app. Decryption runs on an isolate; results are cached
/// per logical ID for the session.
class EncryptedAssetLoader {
  EncryptedAssetLoader._();
  static final EncryptedAssetLoader instance = EncryptedAssetLoader._();

  static const _magic = [0xA7, 0x4E, 0x43, 0x52, 0x59, 0x50, 0x54, 0x21];
  static const _version = 0x01;
  static const _dir = 'assets/encrypted/';

  final Map<String, Uint8List> _cache = {};
  Uint8List? _key;

  Uint8List get _keyBytes =>
      _key ??= Uint8List.fromList(
          sha256.convert(utf8.encode(Secrets.assetKey)).bytes);

  /// HMAC-SHA256(key, "label:logicalId") truncated — must match
  /// tools/encrypt_assets.py byte for byte.
  List<int> _derive(String label, String logicalId, int n) {
    final mac = Hmac(sha256, _keyBytes);
    return mac
        .convert(utf8.encode('$label:$logicalId'))
        .bytes
        .sublist(0, n);
  }

  String _obfuscatedName(String logicalId) =>
      _derive('name', logicalId, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Decrypted bytes for [logicalId] (e.g. 'data/dictionary_full').
  Future<Uint8List> loadBytes(String logicalId) async {
    final cached = _cache[logicalId];
    if (cached != null) return cached;

    final name = _obfuscatedName(logicalId);
    final ByteData data;
    try {
      data = await rootBundle.load('$_dir$name');
    } catch (e) {
      throw AssetDecryptException(logicalId, 'asset not found: $name ($e)');
    }
    final blob = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    final plain = await compute(_decryptIsolate, _DecryptJob(blob, _keyBytes, logicalId));
    _cache[logicalId] = plain;
    return plain;
  }

  /// UTF-8 decoded text for [logicalId].
  Future<String> loadString(String logicalId) async =>
      utf8.decode(await loadBytes(logicalId));

  /// Drop cached plaintext (e.g. on logout / memory pressure).
  void evict(String logicalId) => _cache.remove(logicalId);
  void clear() => _cache.clear();

  /// Test hook: decrypt a raw container blob without touching rootBundle.
  @visibleForTesting
  static Future<Uint8List> debugDecrypt(Uint8List blob, Uint8List key) =>
      _decryptIsolate(_DecryptJob(blob, key, 'test-fixture'));
}

class _DecryptJob {
  final Uint8List blob;
  final Uint8List key;
  final String logicalId;
  const _DecryptJob(this.blob, this.key, this.logicalId);
}

/// Runs on a worker isolate — never blocks the UI thread.
Future<Uint8List> _decryptIsolate(_DecryptJob job) async {
  final blob = job.blob;
  if (blob.length < 21 + 16) {
    throw AssetDecryptException(job.logicalId, 'file too small');
  }
  for (var i = 0; i < 8; i++) {
    if (blob[i] != EncryptedAssetLoader._magic[i]) {
      throw AssetDecryptException(job.logicalId, 'bad magic header');
    }
  }
  if (blob[8] != EncryptedAssetLoader._version) {
    throw AssetDecryptException(job.logicalId, 'unsupported version ${blob[8]}');
  }
  final nonce = blob.sublist(9, 21);
  final ciphertext = blob.sublist(21);

  try {
    final secretBox = SecretBox(
      ciphertext.sublist(0, ciphertext.length - 16),
      nonce: nonce,
      mac: Mac(ciphertext.sublist(ciphertext.length - 16)),
    );
    final plain = await AesGcm.with256bits().decrypt(
      secretBox,
      secretKey: SecretKey(job.key),
    );
    return Uint8List.fromList(plain);
  } catch (e) {
    throw AssetDecryptException(job.logicalId, 'decrypt failed: $e');
  }
}
