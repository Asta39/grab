import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/audio/audio_playback.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/morph.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../data/engine/media_info.dart';
import 'library_items.dart';

/// Full-screen audio player. Playback lives in [AudioPlayback], so leaving this
/// screen (or the app) keeps the music going.
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key, required this.item});

  final LibraryItem item;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  Object? _error;

  AudioPlayer get _p => AudioPlayback.player;

  @override
  void initState() {
    super.initState();
    AudioPlayback.play(
      widget.item,
    ).catchError((Object e) => mounted ? setState(() => _error = e) : null);
  }

  void _seekBy(int s) {
    final d = _p.duration ?? Duration.zero;
    var to = _p.position + Duration(seconds: s);
    if (to < Duration.zero) to = Duration.zero;
    if (to > d) to = d;
    _p.seek(to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pop.ink,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close player, keep playing',
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Stop',
                  color: Colors.white70,
                  onPressed: () {
                    AudioPlayback.stop();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.stop_rounded),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 12, 36, 24),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PopThumb(
                      seed: widget.item.jobId,
                      url: widget.item.thumbnail,
                      audio: true,
                      size: double.infinity,
                      radius: Pop.cardRadius,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _error != null
                        ? "Can't play this file."
                        : widget.item.site ?? widget.item.ext,
                    style: TextStyle(
                      color: _error != null ? Pop.error : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<Duration>(
              stream: _p.positionStream,
              builder: (context, _) {
                final total = _p.duration ?? Duration.zero;
                final pos = _p.position > total ? total : _p.position;
                final ms = total.inMilliseconds;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Pop.yellow,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Pop.yellow,
                          overlayColor: Pop.yellow.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: ms == 0 ? 0 : pos.inMilliseconds / ms,
                          onChanged: (x) =>
                              _p.seek(Duration(milliseconds: (x * ms).round())),
                          semanticFormatterCallback: (_) =>
                              '${_t(pos)} of ${_t(total)}',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              _t(pos),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _t(total),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<PlayerState>(
              stream: _p.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                final done =
                    snap.data?.processingState == ProcessingState.completed;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Back 10 seconds',
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () => _seekBy(-10),
                      icon: const Icon(Icons.replay_10_rounded),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      tooltip: playing && !done ? 'Pause' : 'Play',
                      onPressed: () {
                        Haptics.selection();
                        if (done) {
                          _p.seek(Duration.zero);
                          _p.play();
                        } else {
                          AudioPlayback.toggle();
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Pop.yellow,
                        foregroundColor: Pop.ink,
                        fixedSize: const Size(76, 76),
                      ),
                      icon: Icon(
                        playing && !done
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      tooltip: 'Forward 10 seconds',
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () => _seekBy(10),
                      icon: const Icon(Icons.forward_10_rounded),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  static String _t(Duration d) => clockLabel(d.inMilliseconds / 1000);
}

/// Small "now playing" bar shown above the dock while audio is loaded.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LibraryItem?>(
      valueListenable: AudioPlayback.current,
      builder: (context, item, _) {
        if (item == null) return const SizedBox.shrink();
        return Morph(
          shape: const StadiumBorder(),
          color: Pop.ink,
          pageColor: Pop.ink,
          page: (_) => AudioPlayerScreen(item: item),
          builder: (context, open) => InkWell(
            customBorder: const StadiumBorder(),
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Row(
                children: [
                  PopThumb(
                    seed: item.jobId,
                    url: item.thumbnail,
                    audio: true,
                    size: 40,
                    radius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: AudioPlayback.player.playingStream,
                    builder: (context, snap) {
                      final playing = snap.data ?? false;
                      return IconButton(
                        tooltip: playing ? 'Pause' : 'Play',
                        onPressed: () {
                          Haptics.selection();
                          AudioPlayback.toggle();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Pop.yellow,
                          foregroundColor: Pop.ink,
                        ),
                        icon: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Stop',
                    color: Colors.white60,
                    onPressed: AudioPlayback.stop,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
