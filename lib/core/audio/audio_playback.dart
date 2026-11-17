import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../features/library/library_items.dart';

/// The one audio player in the app. It keeps playing with the screen off or the
/// app in the background, with controls in the notification and on the lock screen.
abstract final class AudioPlayback {
  static final player = AudioPlayer();

  /// What is loaded (playing or paused); null when stopped.
  static final current = ValueNotifier<LibraryItem?>(null);

  /// Call once in main(), before runApp.
  static Future<void> init() => JustAudioBackground.init(
    androidNotificationChannelId: 'app.grab.grab.playback',
    androidNotificationChannelName: 'Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_stat_grab',
  );

  /// Loads [item] (unless it is already loaded) and plays it.
  static Future<void> play(LibraryItem item) async {
    if (current.value?.path != item.path) {
      await player.setAudioSource(
        AudioSource.file(
          item.path,
          tag: MediaItem(
            id: item.path,
            title: item.title,
            album: item.site ?? 'Grab',
            artUri: item.thumbnail == null
                ? null
                : Uri.tryParse(item.thumbnail!),
          ),
        ),
      );
      current.value = item;
    }
    await player.play();
  }

  static Future<void> toggle() =>
      player.playing ? player.pause() : player.play();

  /// Call before deleting a file, so the player never holds a missing file.
  static Future<void> forget(String path) async {
    if (current.value?.path == path) await stop();
  }

  static Future<void> stop() async {
    await player.stop();
    current.value = null;
  }
}
