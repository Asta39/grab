import 'package:audioplayers/audioplayers.dart';

import '../../features/club/rewards.dart';

/// Short UI sounds: a pop when a file is saved, a ding when something unlocks.
/// Kept apart from the media player, and mixed with whatever else is playing.
abstract final class Sfx {
  static var enabled = true;

  /// The chosen sound pack.
  static SoundPack pack = Rewards.sounds.first;

  static final _pool = <String, AudioPlayer>{};

  static Future<void> pop() => _play(pack.pop, 0.6);
  static Future<void> ding() => _play(pack.ding, 0.7);

  /// Plays a pack's unlock sound once, to try it out.
  static Future<void> preview(SoundPack p) => _play(p.ding, 0.7, force: true);

  static Future<void> _play(
    String file,
    double volume, {
    bool force = false,
  }) async {
    if (!enabled && !force) return;
    try {
      final p = _pool[file] ??= AudioPlayer(playerId: 'sfx-$file')
        ..setReleaseMode(ReleaseMode.stop)
        ..setAudioContext(
          AudioContextConfig(
            focus: AudioContextConfigFocus.mixWithOthers,
            respectSilence: true,
          ).build(),
        );
      await p.stop();
      await p.play(AssetSource('sounds/$file'), volume: volume);
    } catch (_) {
      // Sounds are a nicety; never let them break anything.
    }
  }
}
