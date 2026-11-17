import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils/platform.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/widgets/pop_widgets.dart';
import 'audio_player_screen.dart';
import 'library_items.dart';
import '../../core/utils/haptics.dart';

/// Audio opens the background-capable audio player; video the video player.
void openPlayer(BuildContext context, LibraryItem item) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => item.kind == LibraryKind.audio
          ? AudioPlayerScreen(item: item)
          : PlayerScreen(item: item),
    ),
  );
}

/// Plays a saved video or audio file. Audio shows the artwork with the same controls.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.item});

  final LibraryItem item;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final VideoPlayerController _c = VideoPlayerController.file(
    File(widget.item.path),
    // A real Android view: the texture path shows no picture on some phones.
    viewType: videoViewType,
    // Play even while a call or other app holds the audio; otherwise Android
    // silently holds playback back and the preview just sits there.
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  Object? _error;
  var _controlsVisible = true;
  Timer? _hide;

  bool get _audio => widget.item.kind == LibraryKind.audio;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => mounted ? setState(() {}) : null);
    _c.initialize().then((_) {
      _c.play();
      _scheduleHide();
    }, onError: (Object e) => setState(() => _error = e));
  }

  @override
  void dispose() {
    _hide?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hide?.cancel();
    if (_audio) return;
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && _c.value.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggle() {
    Haptics.selection();
    _c.value.isPlaying ? _c.pause() : _c.play();
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _seekBy(int seconds) {
    _c.seekTo(_c.value.position + Duration(seconds: seconds));
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _controlsVisible = !_controlsVisible);
                  _scheduleHide();
                },
                child: Center(
                  child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            "Can't play this file.\n$_error",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : !v.isInitialized
                      ? const CircularProgressIndicator(color: Pop.yellow)
                      : _audio
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: PopThumb(
                              seed: widget.item.jobId,
                              url: widget.item.thumbnail,
                              size: double.infinity,
                              radius: Pop.cardRadius,
                            ),
                          ),
                        )
                      : AspectRatio(
                          aspectRatio: v.aspectRatio,
                          child: VideoPlayer(_c),
                        ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _controlsVisible || _audio ? 1 : 0,
              duration: Pop.medium,
              child: IgnorePointer(
                ignoring: !(_controlsVisible || _audio),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          color: Colors.white,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            widget.item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const Spacer(),
                    if (v.isInitialized) _controls(v),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(VideoPlayerValue v) {
    final total = v.duration.inMilliseconds;
    final pos = v.position.inMilliseconds.clamp(0, total);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xCC141414),
        borderRadius: Pop.cardRadius,
      ),
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
              value: total == 0 ? 0 : pos / total,
              onChanged: (x) =>
                  _c.seekTo(Duration(milliseconds: (x * total).round())),
              onChangeEnd: (_) => _scheduleHide(),
              semanticFormatterCallback: (_) =>
                  '${_fmt(v.position)} of ${_fmt(v.duration)}',
            ),
          ),
          Row(
            children: [
              Text(
                _fmt(v.position),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Back 10 seconds',
                color: Colors.white,
                onPressed: () => _seekBy(-10),
                icon: const Icon(Icons.replay_10_rounded),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: v.isPlaying ? 'Pause' : 'Play',
                onPressed: _toggle,
                style: IconButton.styleFrom(
                  backgroundColor: Pop.yellow,
                  foregroundColor: Pop.ink,
                  fixedSize: const Size(60, 60),
                ),
                icon: Icon(
                  v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Forward 10 seconds',
                color: Colors.white,
                onPressed: () => _seekBy(10),
                icon: const Icon(Icons.forward_10_rounded),
              ),
              const Spacer(),
              Text(
                _fmt(v.duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes
        .remainder(60)
        .toString()
        .padLeft(d.inHours > 0 ? 2 : 1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}
