import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/platform.dart';
import '../../data/engine/media_info.dart';

/// How the preview frames the clip.
enum ClipLook { video, square, audio }

/// Picks a short part of a long file, Apple-style: a live preview that loops
/// the part, a full-length overview to jump around, and a zoomed trim bar
/// for fine control in tenths of a second.
class ClipEditor extends StatefulWidget {
  const ClipEditor({
    super.key,
    required this.path,
    required this.duration,
    required this.maxLength,
    required this.look,
    required this.onChanged,
    this.minLength = 0.5,
    this.lengths = const [],
    this.initialLength = 3,
    this.poster,
  });

  /// A thumbnail to show until the video is ready.
  final String? poster;

  final String path;
  final double duration;
  final double maxLength;
  final double minLength;
  final double initialLength;
  final ClipLook look;

  /// Quick lengths to offer as chips.
  final List<double> lengths;
  final void Function(double start, double end) onChanged;

  @override
  State<ClipEditor> createState() => _ClipEditorState();
}

class _ClipEditorState extends State<ClipEditor> {
  late double _start = 0;
  late double _end = math.min(widget.initialLength, widget.duration);
  late double _view = 0;
  VideoPlayerController? _player;
  var _ready = false;
  var _playing = false;
  double _pos = 0;
  Timer? _seekLater;

  /// Seconds shown by the zoomed trim bar.
  double get _span =>
      math.min(widget.duration, math.max(widget.maxLength * 2.5, 12));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(_start, _end);
    });
    final c = VideoPlayerController.file(
      File(widget.path),
      viewType: videoViewType,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _player = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setLooping(false);
      c.addListener(_tick);
      setState(() => _ready = true);
    }, onError: (_) {});
  }

  @override
  void didUpdateWidget(ClipEditor old) {
    super.didUpdateWidget(old);
    // A shorter limit (GIF → sticker) trims the part to fit.
    if (_end - _start > widget.maxLength) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _set(_start, _start + widget.maxLength);
      });
    }
  }

  @override
  void dispose() {
    _seekLater?.cancel();
    _player?.removeListener(_tick);
    _player?.dispose();
    super.dispose();
  }

  /// Keeps playback inside the chosen part, looping it.
  void _tick() {
    final c = _player;
    if (c == null) return;
    final p = c.value.position.inMilliseconds / 1000;
    if (_playing && (p >= _end || p < _start - 0.3)) {
      c.seekTo(_ms(_start));
    }
    if ((p - _pos).abs() > 0.05) setState(() => _pos = p);
  }

  Duration _ms(double s) => Duration(milliseconds: (s * 1000).round());

  void _toggle() {
    final c = _player;
    if (c == null || !_ready) return;
    Haptics.selection();
    if (_playing) {
      c.pause();
    } else {
      c.seekTo(_ms(_start));
      c.play();
    }
    setState(() => _playing = !_playing);
  }

  /// Applies a new part, keeps the zoom window around it, and replays it.
  void _set(double s, double e, {bool recenter = false}) {
    final d = widget.duration;
    e = e.clamp(widget.minLength, d);
    s = s.clamp(0.0, e - widget.minLength);
    if (e - s > widget.maxLength) e = s + widget.maxLength;
    s = (s * 10).round() / 10;
    e = (e * 10).round() / 10;
    if (s.floor() != _start.floor() || e.floor() != _end.floor()) {
      Haptics.selection();
    }
    var v = _view;
    if (recenter || s < v || e > v + _span) {
      v = ((s + e) / 2 - _span / 2).clamp(0.0, math.max(0, d - _span));
    }
    setState(() {
      _start = s;
      _end = e;
      _view = v;
    });
    widget.onChanged(s, e);
    _seekLater?.cancel();
    _seekLater = Timer(const Duration(milliseconds: 150), () {
      _player?.seekTo(_ms(s));
    });
  }

  @override
  Widget build(BuildContext context) {
    final len = _end - _start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _preview(context),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              clockLabel(_start),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Pop.yellow,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${len.toStringAsFixed(1)} s',
                style: const TextStyle(
                  color: Pop.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            Text(
              clockLabel(_end),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ZoomBar(
          view: _view,
          span: _span,
          start: _start,
          end: _end,
          position: _playing ? _pos : null,
          onChanged: (s, e) => _set(s, e),
        ),
        const SizedBox(height: 12),
        _Overview(
          duration: widget.duration,
          view: _view,
          span: _span,
          start: _start,
          end: _end,
          onMove: (center) {
            final l = _end - _start;
            _set(center - l / 2, center + l / 2, recenter: true);
          },
        ),
        if (widget.lengths.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final l in widget.lengths)
                if (l <= widget.duration)
                  ChoiceChip(
                    label: Text('${l % 1 == 0 ? l.toInt() : l} s'),
                    selected: (len - l).abs() < 0.05,
                    showCheckmark: false,
                    selectedColor: Pop.yellow,
                    backgroundColor: context.pop.card,
                    side: BorderSide(color: context.pop.track),
                    labelStyle: TextStyle(
                      fontFamily: Pop.font,
                      fontWeight: FontWeight.w800,
                      color: (len - l).abs() < 0.05
                          ? Pop.ink
                          : context.pop.text,
                    ),
                    onSelected: (_) => _set(_start, _start + l),
                  ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _preview(BuildContext context) {
    final c = _player;
    final play = Material(
      color: Pop.yellow,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Pop.ink,
            size: 30,
          ),
        ),
      ),
    );
    if (widget.look == ClipLook.audio) {
      return Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Pop.ink,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            play,
            const SizedBox(width: 16),
            Expanded(child: _Bars(playing: _playing)),
            const SizedBox(width: 12),
            Text(
              _playing ? 'Playing this part' : 'Tap to hear it',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    final video = c != null && _ready
        ? FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          )
        : widget.poster != null
        ? Image.network(
            widget.poster!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : const Center(child: CircularProgressIndicator(color: Pop.yellow));
    final square = widget.look == ClipLook.square;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: square ? 1.6 : 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (square)
                // A 512 × 512 sticker: the clip inside a square, transparent around it.
                AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(painter: _Checker(), child: video),
                )
              else
                Positioned.fill(child: video),
              if (!_playing) play,
              if (_playing)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The zoomed trim bar: a window of [span] seconds with a yellow frame.
/// Drag an end to trim, drag the middle to move, tap to jump there.
class _ZoomBar extends StatefulWidget {
  const _ZoomBar({
    required this.view,
    required this.span,
    required this.start,
    required this.end,
    required this.onChanged,
    this.position,
  });

  final double view, span, start, end;
  final double? position;
  final void Function(double start, double end) onChanged;

  @override
  State<_ZoomBar> createState() => _ZoomBarState();
}

enum _Grab { start, end, both }

class _ZoomBarState extends State<_ZoomBar> {
  static const _h = 64.0;
  static const _handle = 18.0;
  _Grab? _grab;
  double _from = 0, _s0 = 0, _e0 = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Room on both sides for the yellow handles at the very ends.
        const pad = _handle;
        final w = box.maxWidth - pad * 2;
        double x(double t) => pad + (t - widget.view) / widget.span * w;
        double t(double dx) => widget.view + (dx - pad) / w * widget.span;
        final sx = x(widget.start), ex = x(widget.end);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (u) {
            final l = widget.end - widget.start;
            final at = t(u.localPosition.dx);
            widget.onChanged(at - l / 2, at + l / 2);
          },
          onHorizontalDragStart: (g) {
            final dx = g.localPosition.dx;
            _from = dx;
            _s0 = widget.start;
            _e0 = widget.end;
            _grab = (dx - sx).abs() < 28
                ? _Grab.start
                : (dx - ex).abs() < 28
                ? _Grab.end
                : _Grab.both;
            Haptics.light();
          },
          onHorizontalDragUpdate: (g) {
            final dt = (g.localPosition.dx - _from) / w * widget.span;
            switch (_grab) {
              case _Grab.start:
                widget.onChanged(_s0 + dt, _e0);
              case _Grab.end:
                widget.onChanged(_s0, _e0 + dt);
              case _Grab.both:
                widget.onChanged(_s0 + dt, _e0 + dt);
              case null:
            }
          },
          onHorizontalDragEnd: (_) => _grab = null,
          child: SizedBox(
            height: _h,
            child: CustomPaint(
              painter: _ZoomPainter(
                view: widget.view,
                span: widget.span,
                pad: _handle,
                sx: sx,
                ex: ex,
                position: widget.position == null ? null : x(widget.position!),
                handle: _handle,
                track: context.pop.track,
                tick: context.pop.muted,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ZoomPainter extends CustomPainter {
  _ZoomPainter({
    required this.view,
    required this.pad,
    required this.span,
    required this.sx,
    required this.ex,
    required this.position,
    required this.handle,
    required this.track,
    required this.tick,
  });

  final double view, span, sx, ex, handle, pad;
  final double? position;
  final Color track, tick;

  @override
  void paint(Canvas canvas, Size size) {
    final trackW = size.width - pad * 2;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, 0, trackW, size.height),
      const Radius.circular(14),
    );
    canvas.drawRRect(r, Paint()..color = track);
    // Second ticks; taller every 5 s with a label.
    final step = span > 60 ? 5 : 1;
    final tickPaint = Paint()
      ..color = tick.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    for (var s = (view / step).ceil() * step; s <= view + span; s += step) {
      final x = pad + (s - view) / span * trackW;
      final big = s % (step * 5) == 0;
      canvas.drawLine(
        Offset(x, size.height - (big ? 18 : 10)),
        Offset(x, size.height - 4),
        tickPaint,
      );
      if (big) {
        final tp = TextPainter(
          text: TextSpan(
            text: clockLabel(s.toDouble()),
            style: TextStyle(
              color: tick,
              fontFamily: Pop.font,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 3, 5));
      }
    }
    // Selected part: soft yellow fill with a thick frame and grips.
    final sel = Rect.fromLTRB(sx, 0, ex, size.height);
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(sel, Paint()..color = Pop.yellow.withValues(alpha: 0.35));
    canvas.restore();
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTRB(sx - handle, -2, ex + handle, size.height + 2),
      const Radius.circular(12),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTRB(sx, 3, ex, size.height - 3),
      const Radius.circular(4),
    );
    canvas.drawDRRect(frame, inner, Paint()..color = Pop.yellow);
    final grip = Paint()
      ..color = Pop.ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final cx in [sx - handle / 2, ex + handle / 2]) {
      canvas.drawLine(
        Offset(cx, size.height / 2 - 10),
        Offset(cx, size.height / 2 + 10),
        grip,
      );
    }
    final p = position;
    if (p != null && p >= sx && p <= ex) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p - 1.5, 2, 3, size.height - 4),
          const Radius.circular(2),
        ),
        Paint()..color = Pop.ink,
      );
    }
  }

  @override
  bool shouldRepaint(_ZoomPainter o) =>
      o.view != view ||
      o.sx != sx ||
      o.ex != ex ||
      o.position != position ||
      o.track != track;
}

/// The whole file at a glance: the zoom window and the chosen part. Drag
/// or tap anywhere to move the part there.
class _Overview extends StatelessWidget {
  const _Overview({
    required this.duration,
    required this.view,
    required this.span,
    required this.start,
    required this.end,
    required this.onMove,
  });

  final double duration, view, span, start, end;
  final ValueChanged<double> onMove;

  @override
  Widget build(BuildContext context) {
    if (duration <= span + 0.5) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHOLE ${clockLabel(duration)} · DRAG TO JUMP',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: context.pop.muted,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            double at(double dx) => (dx / w * duration).clamp(0.0, duration);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (u) => onMove(at(u.localPosition.dx)),
              onHorizontalDragUpdate: (g) => onMove(at(g.localPosition.dx)),
              child: SizedBox(
                height: 34,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.pop.track,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    // The zoom window.
                    Positioned(
                      left: view / duration * w,
                      width: math.max(14, span / duration * w),
                      top: 2,
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: context.pop.text, width: 2),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    // The chosen part.
                    Positioned(
                      left: start / duration * w,
                      width: math.max(4, (end - start) / duration * w),
                      top: 10,
                      bottom: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Pop.yellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bouncing sound bars for the audio preview.
class _Bars extends StatefulWidget {
  const _Bars({required this.playing});

  final bool playing;

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(_Bars old) {
    super.didUpdateWidget(old);
    widget.playing && !Pop.reduceMotion(context) ? _c.repeat() : _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 14; i++)
          Container(
            width: 4,
            height:
                8 +
                (widget.playing
                    ? 30 *
                          (0.5 +
                                  0.5 *
                                      math.sin(
                                        _c.value * 2 * math.pi + i * 0.9,
                                      ))
                              .abs()
                    : 6 + (i * 7 % 13).toDouble()),
            decoration: BoxDecoration(
              color: i.isEven ? Pop.yellow : Colors.white54,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    ),
  );
}

/// Checkerboard behind the sticker, so the transparent padding shows.
class _Checker extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 12.0;
    final a = Paint()..color = const Color(0xFF3A3A3C);
    final b = Paint()..color = const Color(0xFF2C2C2E);
    for (var y = 0.0; y < size.height; y += s) {
      for (var x = 0.0; x < size.width; x += s) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, s, s),
          ((x + y) / s).round().isEven ? a : b,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Checker o) => false;
}
