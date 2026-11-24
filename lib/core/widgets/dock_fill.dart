import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

import '../theme/cosmetics.dart';
import '../theme/pop_theme.dart';

/// Fills the dock bubble (or a swatch) with a [DockColor]: flat colour,
/// rolling candy stripes, a twinkling night sky, a lava-lamp or aurora mesh,
/// holographic foil, or a sticker bomb. Still when motion is reduced.
class DockFill extends StatefulWidget {
  const DockFill(this.dock, {super.key, this.shape = const StadiumBorder()});

  final DockColor dock;
  final ShapeBorder shape;

  @override
  State<DockFill> createState() => _DockFillState();
}

class _DockFillState extends State<DockFill>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  bool get _moves => switch (widget.dock.style) {
    DockStyle.stripes ||
    DockStyle.stars ||
    DockStyle.holo ||
    DockStyle.stickers => true,
    _ => false,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DockFill old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final go = _moves && !Pop.reduceMotion(context);
    if (go && !_clock.isAnimating) _clock.repeat();
    if (!go) _clock.stop();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dock;
    final still = Pop.reduceMotion(context);
    final Widget fill = switch (d.style) {
      DockStyle.solid => ColoredBox(color: d.color),
      DockStyle.mesh =>
        still
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: d.gradient!),
                ),
              )
            : AnimatedMeshGradient(
                colors: d.gradient!,
                options: AnimatedMeshGradientOptions(
                  speed: 1.2,
                  frequency: 4,
                  amplitude: 24,
                ),
              ),
      DockStyle.stickers => AnimatedBuilder(
        animation: _clock,
        builder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: d.color,
            image: DecorationImage(
              image: const AssetImage('assets/docks/stickers.jpg'),
              repeat: ImageRepeat.repeat,
              // Without an explicit fit the tile shrinks to the dock height.
              fit: BoxFit.none,
              scale: 2.6,
              alignment: Alignment(-1 + 2 * _clock.value, 0),
              // A sunny wash so the tab label stays readable on top.
              colorFilter: ColorFilter.mode(
                Pop.yellow.withValues(alpha: 0.35),
                BlendMode.srcATop,
              ),
            ),
          ),
        ),
      ),
      _ => AnimatedBuilder(
        animation: _clock,
        builder: (_, _) => CustomPaint(
          painter: _DockPainter(d, _clock.value),
          child: const SizedBox.expand(),
        ),
      ),
    };
    return ClipPath(
      clipper: ShapeBorderClipper(shape: widget.shape),
      child: fill,
    );
  }
}

class _DockPainter extends CustomPainter {
  _DockPainter(this.d, this.t);

  final DockColor d;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (d.style) {
      case DockStyle.stripes:
        canvas.drawRect(rect, Paint()..color = d.gradient![1]);
        final p = Paint()..color = d.gradient![0];
        const w = 14.0;
        final shift = t * w * 2 * 6;
        canvas.save();
        canvas.clipRect(rect);
        for (
          var x = -size.height - w * 2 + shift % (w * 2);
          x < size.width + size.height;
          x += w * 2
        ) {
          canvas.drawPath(
            Path()
              ..moveTo(x, size.height)
              ..lineTo(x + w, size.height)
              ..lineTo(x + w + size.height, 0)
              ..lineTo(x + size.height, 0)
              ..close(),
            p,
          );
        }
        canvas.restore();
      case DockStyle.stars:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              colors: d.gradient!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(rect),
        );
        // Fixed stars that twinkle out of step with each other.
        final rng = math.Random(7);
        for (var i = 0; i < 26; i++) {
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          final r = 0.6 + rng.nextDouble() * 1.4;
          final phase = rng.nextDouble() * 2 * math.pi;
          final glow =
              0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 3 + phase));
          canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()..color = Colors.white.withValues(alpha: glow),
          );
        }
      case DockStyle.holo:
        canvas.drawRect(
          rect,
          Paint()
            ..shader =
                SweepGradient(
                  colors: d.gradient!,
                  transform: GradientRotation(t * 2 * math.pi),
                  center: Alignment.center,
                ).createShader(
                  Rect.fromCircle(center: rect.center, radius: size.width),
                ),
        );
        // A soft white sheen that slides across.
        final x = -size.width * 0.4 + (size.width * 1.8) * ((t * 2) % 1);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ).createShader(Rect.fromLTWH(x, 0, size.width * 0.35, size.height)),
        );
      default:
        canvas.drawRect(rect, Paint()..color = d.color);
    }
  }

  @override
  bool shouldRepaint(_DockPainter old) => old.t != t || old.d != d;
}
