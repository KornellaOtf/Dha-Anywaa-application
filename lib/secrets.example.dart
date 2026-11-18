/// Groq API credentials. THIS FILE IS GITIGNORED — never commit it.
/// Copy secrets.example.dart to secrets.dart and fill in your key.
class Secrets {
  Secrets._();
  static const String groqApiKey =
      'gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  /// Passphrase for encrypted bundled assets (docs/ASSET_FORMAT.md).
  /// Must match DHA_ASSET_KEY used by tools/encrypt_assets.py.
  static const String assetKey =
      '<generate-a-random-passphrase>';
  static const String nvidiaApiKey =
      'nvapi-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
}
