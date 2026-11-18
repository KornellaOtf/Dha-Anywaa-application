import 'dart:convert';

import 'package:cryptography/cryptography.dart' hide Hmac;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
/// The key, filename derivation, magic bytes, signing-cert check, and
/// environment trust check all live in the native `keyguard` library —
/// Dart only ever sees the derived AES key transiently, right before a
/// decrypt job runs on an isolate. Nothing sensitive is recoverable
/// from Dart source alone.
class EncryptedAssetLoader {
  EncryptedAssetLoader._();
  static final EncryptedAssetLoader instance = EncryptedAssetLoader._();

  static const _channel = MethodChannel('dna/asset_guard');
  static const _dir = 'assets/encrypted/';

  final Map<String, Uint8List> _cache = {};
  final Map<String, String> _nameCache = {};
  Uint8List? _magic;
  bool? _guardOk;

  /// One-time environment + integrity gate. Returns false (and caches it)
  /// when the device is untrusted or the APK signature doesn't match —
  /// callers surface a generic "content unavailable" message.
  Future<bool> _guard() async {
    if (_guardOk != null) return _guardOk!;
    try {
      final trusted = await _channel.invokeMethod<bool>('isTrusted') ?? false;
      final intact = await _channel.invokeMethod<bool>('checkIntegrity') ?? false;
      _guardOk = trusted && intact;
    } catch (_) {
      _guardOk = false; // no native lib (tests/desktop) → refuse
    }
    return _guardOk!;
  }

  Future<String> _assetName(String logicalId) async {
    final cached = _nameCache[logicalId];
    if (cached != null) return cached;
    final name = await _channel.invokeMethod<String>('getAssetName', logicalId);
    if (name == null) {
      throw const AssetDecryptException('', 'native name derivation failed');
    }
    return _nameCache[logicalId] = name;
  }

  Future<List<int>> _magicBytes() async {
    if (_magic != null) return _magic!;
    final m = await _channel.invokeMethod<Uint8List>('getMagicBytes');
    if (m == null) throw const AssetDecryptException('', 'no magic bytes');
    return _magic = m;
  }

  /// Decrypted bytes for [logicalId] (e.g. 'data/dictionary_full').
  Future<Uint8List> loadBytes(String logicalId) async {
    final cached = _cache[logicalId];
    if (cached != null) return cached;

    if (!await _guard()) {
      throw AssetDecryptException(
          logicalId, 'content unavailable on this device');
    }

    final name = await _assetName(logicalId);
    final magic = await _magicBytes();

    final ByteData data;
    try {
      data = await rootBundle.load('$_dir$name');
    } catch (e) {
      throw AssetDecryptException(logicalId, 'asset not found: $name ($e)');
    }
    final blob = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Quick header pre-check before paying for an isolate hop.
    if (blob.length < magic.length + 1 + 12 + 16 ||
        !_startsWith(blob, magic)) {
      throw AssetDecryptException(logicalId, 'bad container header');
    }

    // Key is fetched transiently and only lives inside the job.
    final key = await _channel.invokeMethod<Uint8List>('getAssetKey');
    if (key == null) {
      throw AssetDecryptException(logicalId, 'key unavailable');
    }

    final plain =
        await compute(_decryptIsolate, _DecryptJob(blob, key, logicalId, magic));
    _cache[logicalId] = plain;
    return plain;
  }

  /// UTF-8 decoded text for [logicalId].
  Future<String> loadString(String logicalId) async =>
      utf8.decode(await loadBytes(logicalId));

  /// Drop cached plaintext (e.g. on logout / memory pressure).
  void evict(String logicalId) => _cache.remove(logicalId);
  void clear() => _cache.clear();

  /// Test hook: decrypt a raw container blob without touching rootBundle
  /// or the native channel.
  @visibleForTesting
  static Future<Uint8List> debugDecrypt(Uint8List blob, Uint8List key,
          {List<int>? magic}) =>
      _decryptIsolate(
          _DecryptJob(blob, key, 'test-fixture', magic ?? _defaultMagic));

  static const _defaultMagic = [0xA7, 0x4E, 0x43, 0x52, 0x59, 0x50, 0x54, 0x21];

  static bool _startsWith(Uint8List blob, List<int> prefix) {
    if (blob.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (blob[i] != prefix[i]) return false;
    }
    return true;
  }
}

class _DecryptJob {
  final Uint8List blob;
  final Uint8List key;
  final String logicalId;
  final List<int> magic;
  const _DecryptJob(this.blob, this.key, this.logicalId, this.magic);
}

/// Runs on a worker isolate — never blocks the UI thread.
Future<Uint8List> _decryptIsolate(_DecryptJob job) async {
  final blob = job.blob;
  final magic = job.magic;
  if (blob.length < magic.length + 1 + 12 + 16) {
    throw AssetDecryptException(job.logicalId, 'file too small');
  }
  for (var i = 0; i < magic.length; i++) {
    if (blob[i] != magic[i]) {
      throw AssetDecryptException(job.logicalId, 'bad magic header');
    }
  }
  if (blob[magic.length] != 0x01) {
    throw AssetDecryptException(
        job.logicalId, 'unsupported version ${blob[magic.length]}');
  }
  final nonce = blob.sublist(magic.length + 1, magic.length + 13);
  final ciphertext = blob.sublist(magic.length + 13);

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
