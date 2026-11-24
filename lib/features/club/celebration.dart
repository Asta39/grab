import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'rewards.dart';

/// A single bit of celebration: a sprite or a paper square in flight.
class _Bit {
  _Bit({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.look,
    required this.spin,
    required this.phase,
  });

  double x, y, vx, vy, turn = 0, age = 0;
  final double size, life, spin, phase;

  /// Sprite asset, or null for a paper square in [color].
  final Object look;
}

/// Plays the chosen [Celebration] whenever [controller] is played. Each style
/// moves its own way: hearts float up, popcorn pops, coins rain and flip,
/// buddies drift down, paper bursts.
class CelebrationLayer extends StatefulWidget {
  const CelebrationLayer({
    super.key,
    required this.controller,
    this.big = false,
    this.style,
  });

  final ConfettiController controller;

  /// Milestones get more, and paper bursts from the middle.
  final bool big;

  /// A fixed style to show (for previews); otherwise the chosen one.
  final Celebration? style;

  @override
  State<CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<CelebrationLayer>
    with SingleTickerProviderStateMixin {
  final _rng = math.Random();
  final _bits = <_Bit>[];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  late Celebration _style;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.controller.addListener(_onPlay);
  }

  @override
  void didUpdateWidget(CelebrationLayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onPlay);
      widget.controller.addListener(_onPlay);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlay);
    _ticker.dispose();
    super.dispose();
  }

  void _onPlay() {
    if (widget.controller.state != ConfettiControllerState.playing) return;
    widget.controller.stop();
    if (_size.isEmpty) return;
    _style = widget.style ?? Rewards.celebration.value;
    _spawn();
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  double _r(double a, double b) => a + _rng.nextDouble() * (b - a);

  void _spawn() {
    final s = _style;
    final w = _size.width, h = _size.height;
    final sprites = s.sprites;
    Object look(int i) => sprites.isEmpty
        ? s.colors[i % s.colors.length]
        : sprites[_rng.nextInt(sprites.length)];
    final n = switch (s.motion) {
      CelebrationMotion.burst => widget.big ? 90 : 46,
      CelebrationMotion.drift => widget.big ? 16 : 9,
      _ => widget.big ? 34 : 18,
    };
    for (var i = 0; i < n; i++) {
      final b = switch (s.motion) {
        CelebrationMotion.burst => () {
          final a = widget.big
              ? _r(0, 2 * math.pi)
              : _r(math.pi * 0.15, math.pi * 0.85);
          final v = _r(350, widget.big ? 1100 : 800);
          return _Bit(
            x: w / 2,
            y: widget.big ? h * 0.45 : 0,
            vx: math.cos(a) * v,
            vy: math.sin(a) * v,
            size: _r(9, 15),
            life: _r(1.8, 2.6),
            look: look(i),
            spin: _r(-9, 9),
            phase: _r(0, 6),
          );
        }(),
        CelebrationMotion.floatUp => _Bit(
          x: _r(w * 0.08, w * 0.92),
          y: h + _r(10, 160),
          vx: 0,
          vy: -_r(170, 300),
          size: _r(32, 54),
          life: _r(3, 4.2),
          look: look(i),
          spin: _r(-0.4, 0.4),
          phase: _r(0, 6),
        ),
        CelebrationMotion.arcs => _Bit(
          x: w / 2 + _r(-30, 30),
          y: h * 0.82,
          vx: _r(-420, 420),
          vy: -_r(700, 1150),
          size: _r(34, 52),
          life: _r(2.2, 2.8),
          look: look(i),
          spin: _r(-3, 3),
          phase: _r(0, 6),
        ),
        CelebrationMotion.popUp => _Bit(
          x: _r(w * 0.1, w * 0.9),
          y: h + 30,
          vx: _r(-90, 90),
          vy: -_r(900, 1400),
          size: _r(34, 54),
          life: _r(2, 2.6),
          look: look(i),
          spin: _r(-6, 6),
          phase: _r(0, 6),
        )..age = -_r(0, 0.7), // popcorn pops one after another
        CelebrationMotion.rain => _Bit(
          x: _r(0, w),
          y: -_r(40, 300),
          vx: _r(-30, 30),
          vy: _r(260, 460),
          size: _r(30, 50),
          life: _r(2.6, 3.2),
          look: look(i),
          spin: _r(6, 11),
          phase: _r(0, 6),
        ),
        CelebrationMotion.drift => _Bit(
          x: _r(w * 0.1, w * 0.9),
          y: -_r(60, 360),
          vx: 0,
          vy: _r(130, 200),
          size: _r(48, 70),
          life: _r(4, 5),
          look: look(i),
          spin: _r(-0.3, 0.3),
          phase: _r(0, 6),
        ),
      };
      _bits.add(b);
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final motion = _style.motion;
    for (final b in _bits) {
      b.age += dt;
      if (b.age < 0) continue;
      switch (motion) {
        case CelebrationMotion.burst:
          b.vy += 700 * dt;
          b.vx *= 1 - 1.6 * dt;
          b.vy *= 1 - 0.9 * dt;
        case CelebrationMotion.floatUp:
          b.vx = math.sin(b.age * 2.2 + b.phase) * 60;
        case CelebrationMotion.arcs:
        case CelebrationMotion.popUp:
          b.vy += 1700 * dt;
        case CelebrationMotion.rain:
          b.vy += 220 * dt;
        case CelebrationMotion.drift:
          b.vx = math.sin(b.age * 1.4 + b.phase) * 70;
      }
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.turn += b.spin * dt;
    }
    _bits.removeWhere((b) => b.age > b.life);
    if (_bits.isEmpty) _ticker.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          _size = box.biggest;
          if (_bits.isEmpty) return const SizedBox.expand();
          final coin = _style.motion == CelebrationMotion.rain;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final b in _bits)
                if (b.age >= 0)
                  Positioned(
                    left: b.x - b.size / 2,
                    top: b.y - b.size / 2,
                    width: b.size,
                    height: b.size,
                    child: Opacity(
                      opacity: (b.life - b.age).clamp(0.0, 0.6) / 0.6,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationZ(coin ? 0 : b.turn)
                          // Coins flip as they fall.
                          ..scaleByDouble(
                            coin ? math.cos(b.turn).abs() * 0.8 + 0.2 : 1,
                            1,
                            1,
                            1,
                          ),
                        child: switch (b.look) {
                          final String asset => Image.asset(
                            asset,
                            gaplessPlayback: true,
                          ),
                          final Color c => Center(
                            child: Container(
                              width: b.size,
                              height: b.size * 0.6,
                              color: c,
                            ),
                          ),
                          _ => const SizedBox(),
                        },
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
