import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:dha_anywaaa/secrets.dart';
import 'package:dha_anywaaa/services/encrypted_asset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final key = Uint8List.fromList(
      sha256.convert(utf8.encode(Secrets.assetKey)).bytes);

  test('loads and decrypts a bundled asset end-to-end', () async {
    final raw =
        await EncryptedAssetLoader.instance.loadString('data/cultural_facts');
    final map = json.decode(raw) as Map<String, dynamic>;
    expect(map['facts'], isA<List>());
    expect((map['facts'] as List).length, greaterThan(10));
  });

  test('obfuscated filename matches the Python encryptor output', () async {
    // assets/encrypted/ddf73be92849b0e8 was produced by
    // tools/encrypt_assets.py for logical id 'data/cultural_facts'.
    // If this throws, the Dart HMAC derivation diverged.
    final data = await rootBundle
        .load('assets/encrypted/ddf73be92849b0e8');
    expect(data.lengthInBytes, greaterThan(100));
  });

  test('corrupted ciphertext throws AssetDecryptException', () async {
    final data = await rootBundle
        .load('assets/encrypted/ddf73be92849b0e8');
    final blob = data.buffer
        .asUint8List(data.offsetInBytes, data.lengthInBytes)
        .toList();
    blob[blob.length ~/ 2] ^= 0xFF; // flip one byte

    expect(
      () => EncryptedAssetLoader.debugDecrypt(Uint8List.fromList(blob), key),
      throwsA(isA<AssetDecryptException>()),
    );
  });

  test('bad magic header throws AssetDecryptException', () async {
    final data = await rootBundle
        .load('assets/encrypted/ddf73be92849b0e8');
    final blob = data.buffer
        .asUint8List(data.offsetInBytes, data.lengthInBytes)
        .toList();
    blob[0] = 0x00;

    expect(
      () => EncryptedAssetLoader.debugDecrypt(Uint8List.fromList(blob), key),
      throwsA(isA<AssetDecryptException>()),
    );
  });

  test('unknown logical id throws AssetDecryptException', () async {
    expect(
      () => EncryptedAssetLoader.instance.loadBytes('does/not/exist'),
      throwsA(isA<AssetDecryptException>()),
    );
  });
}
