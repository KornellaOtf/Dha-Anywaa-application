import 'package:audioplayers/audioplayers.dart';

/// Play an asset audio file and wait for it to finish.
/// Returns immediately if [soundEnabled] is false.
/// Never throws: all errors are silently swallowed so a missing audio
/// file can never crash the UI.
Future<void> playAsset(
  AudioPlayer player,
  String assetPath, {
  bool soundEnabled = true,
}) async {
  if (!soundEnabled) return;
  if (assetPath.isEmpty) return;
  try {
    await player.play(AssetSource(assetPath));
    final Duration? dur = await player.getDuration();
    if (dur != null && dur.inMilliseconds > 0) {
      await Future.delayed(dur);
    }
    await player.stop();
  } catch (_) {
    // Missing file or platform error: fail silently.
  }
}
