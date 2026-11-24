import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../theme/pop_theme.dart';
import '../utils/haptics.dart';

/// The app's one way to open a page from something on screen: the tapped card,
/// row or bar grows into the page (and shrinks back into it on close), instead
/// of a plain screen swap. Uses Material's container transform.
///
/// [builder] draws the closed state and gets an `open` callback to call on tap.
class Morph extends StatelessWidget {
  const Morph({
    super.key,
    required this.builder,
    required this.page,
    this.shape = const RoundedRectangleBorder(borderRadius: Pop.cardRadius),
    this.color,
    this.pageColor,
  });

  final Widget Function(BuildContext context, VoidCallback open) builder;
  final WidgetBuilder page;
  final ShapeBorder shape;

  /// Background of the closed widget; it fades into [pageColor] while growing.
  final Color? color;
  final Color? pageColor;

  static const duration = Duration(milliseconds: 380);

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return OpenContainer<void>(
      // A single cross-fade is cheaper than fade-through and reads as one motion.
      transitionType: ContainerTransitionType.fade,
      transitionDuration: still ? Duration.zero : duration,
      closedElevation: 0,
      openElevation: 0,
      closedShape: shape,
      closedColor: color ?? bg,
      openColor: pageColor ?? bg,
      middleColor: pageColor ?? bg,
      tappable: false,
      useRootNavigator: true,
      // OpenContainer's Material doesn't pick up the theme's text colour, so
      // titles went dark-on-dark in dark mode. Hand it the right one.
      closedBuilder: (context, open) => DefaultTextStyle.merge(
        style: TextStyle(color: context.pop.text, fontFamily: Pop.font),
        child: IconTheme.merge(
          data: IconThemeData(color: context.pop.text),
          child: builder(context, () {
            Haptics.light();
            open();
          }),
        ),
      ),
      // Its own layer, so the page is drawn once and then just moved and scaled.
      openBuilder: (context, _) => RepaintBoundary(child: page(context)),
    );
  }
}
