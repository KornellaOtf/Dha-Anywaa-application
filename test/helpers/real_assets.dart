import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:dha_anywaaa/services/encrypted_asset_loader.dart';

/// Lets widget/unit tests decrypt the real bundled assets.
/// flutter_test has no native keyguard lib, so we derive the same
/// AES key the native code produces and bypass the device guard.
/// Call in setUp() of any test that loads dictionary/Bible content.
void enableRealEncryptedAssets() {
  // Same passphrase as android/app/src/main/cpp/key_guard.c.
  const passphrase =
      'ba3b2e7b830f7ab7fc0170b1dba9ecaeaac8a2eb6919f5173041692bef18d822';
  EncryptedAssetLoader.debugKeyOverride = Uint8List.fromList(
      sha256.convert(utf8.encode(passphrase)).bytes);
  EncryptedAssetLoader.debugBypassGuard = true;
  EncryptedAssetLoader.debugInlineDecrypt = true;
}
