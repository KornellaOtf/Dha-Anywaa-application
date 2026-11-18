import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dha_anywaaa/services/encrypted_asset_loader.dart';

/// Test-only AES key — NOT the production key (that lives in native code).
final _testKey = Uint8List.fromList(List.generate(32, (i) => i * 7 + 3));
const _magic = [0xA7, 0x4E, 0x43, 0x52, 0x59, 0x50, 0x54, 0x21];

/// Builds a valid container blob exactly like tools/encrypt_assets.py output.
Future<Uint8List> _makeBlob(String plaintext) async {
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(plaintext),
    secretKey: SecretKey(_testKey),
    nonce: List<int>.generate(12, (i) => i + 1),
  );
  final ctAndTag = [...box.cipherText, ...box.mac.bytes];
  return Uint8List.fromList([
    ..._magic,
    0x01,
    ...box.nonce,
    ...ctAndTag,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock the native asset_guard channel: trusted, intact, known name.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dna/asset_guard'),
      (call) async {
        switch (call.method) {
          case 'isTrusted':
          case 'checkIntegrity':
          case 'antiTamperOk':
            return true;
          case 'getAssetName':
            return 'testasset';
          case 'getMagicBytes':
            return Uint8List.fromList(_magic);
          case 'getAssetKey':
            return _testKey;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dna/asset_guard'), null);
  });

  test('debugDecrypt round-trips a valid container', () async {
    final blob = await _makeBlob('{"hello":"world"}');
    final plain = await EncryptedAssetLoader.debugDecrypt(blob, _testKey);
    expect(utf8.decode(plain), '{"hello":"world"}');
  });

  test('corrupted ciphertext throws AssetDecryptException', () async {
    final blob = (await _makeBlob('secret data')).toList();
    blob[blob.length ~/ 2] ^= 0xFF;
    expect(
      () => EncryptedAssetLoader.debugDecrypt(Uint8List.fromList(blob), _testKey),
      throwsA(isA<AssetDecryptException>()),
    );
  });

  test('bad magic header throws AssetDecryptException', () async {
    final blob = (await _makeBlob('x')).toList();
    blob[0] = 0x00;
    expect(
      () => EncryptedAssetLoader.debugDecrypt(Uint8List.fromList(blob), _testKey),
      throwsA(isA<AssetDecryptException>()),
    );
  });

  test('unsupported version throws AssetDecryptException', () async {
    final blob = (await _makeBlob('x')).toList();
    blob[8] = 0x02;
    expect(
      () => EncryptedAssetLoader.debugDecrypt(Uint8List.fromList(blob), _testKey),
      throwsA(isA<AssetDecryptException>()),
    );
  });

  test('missing bundled asset throws AssetDecryptException', () async {
    // 'testasset' isn't in the real bundle → rootBundle.load fails.
    expect(
      () => EncryptedAssetLoader.instance.loadBytes('data/cultural_facts'),
      throwsA(isA<AssetDecryptException>()),
    );
  });
}
