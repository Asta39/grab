import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/pop_theme.dart';

/// Metaballs ("gooey") effect: blurs its child, then cuts the alpha at a threshold,
/// so nearby shapes melt into each other with soft, liquid necks between them.
/// Shapes inside should be solid and a single color.
class Gooey extends StatelessWidget {
  const Gooey({
    super.key,
    required this.child,
    this.blur = 10,
    this.sharpness = 18,
  });

  final Widget child;

  /// How far shapes reach toward each other (logical px).
  final double blur;

  /// Edge hardness after the threshold. Higher = crisper edge.
  final double sharpness;

  @override
  Widget build(BuildContext context) {
    // alpha' = alpha * sharpness - offset: everything under ~50% alpha disappears,
    // everything above becomes solid. RGB is left alone.
    final offset = -255.0 * (sharpness / 2 - 0.5);
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        0, 0, 0, sharpness, offset,
      ]),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: child,
      ),
    );
  }
}

/// Slowly drifting yellow metaballs, used as a quiet background accent.
/// Freezes in place when the system "remove animations" setting is on.
class MetaballsBackground extends StatefulWidget {
  const MetaballsBackground({
    super.key,
    this.count = 5,
    this.color = Pop.yellow,
    this.opacity = 1,
  });

  final int count;
  final Color color;
  final double opacity;

  @override
  State<MetaballsBackground> createState() => _MetaballsBackgroundState();
}

class _MetaballsBackgroundState extends State<MetaballsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Pop.reduceMotion(context)) {
      _t.stop();
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: RepaintBoundary(
          child: Gooey(
            blur: 14,
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, _) => CustomPaint(
                size: Size.infinite,
                painter: _BallsPainter(
                  t: _t.value,
                  count: widget.count,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BallsPainter extends CustomPainter {
  _BallsPainter({required this.t, required this.count, required this.color});

  final double t;
  final int count;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final base = math.min(size.width, size.height);
    for (var i = 0; i < count; i++) {
      // Each ball follows its own slow Lissajous path, so they meet and part.
      final phase = i * 1.7;
      final a = 2 * math.pi * t;
      final x = 0.5 + 0.34 * math.sin(a * (1 + i % 2) + phase);
      final y =
          0.5 + 0.30 * math.cos(a * (1 + (i + 1) % 3) * 0.5 + phase * 1.3);
      final r = base * (0.16 + 0.07 * math.sin(a * 2 + i));
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BallsPainter old) =>
      old.t != t || old.color != color || old.count != count;
}
