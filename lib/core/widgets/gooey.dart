import 'dart:ui';

import 'package:flutter/material.dart';

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
