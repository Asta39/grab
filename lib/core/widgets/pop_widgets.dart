import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/cosmetics.dart';
import '../theme/pop_theme.dart';
import '../utils/audio_art.dart';
import 'dock_fill.dart';
import 'gooey.dart';
import '../../core/utils/haptics.dart';

/// Black pill button that squishes when pressed. The signature "Fetch" / "Download" button.
class PopButton extends StatefulWidget {
  const PopButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.height = 56,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final double height;
  final bool expand;
  final IconData? icon;

  @override
  State<PopButton> createState() => _PopButtonState();
}

class _PopButtonState extends State<PopButton> {
  var _down = false;

  bool get _enabled => widget.onPressed != null && !widget.busy;

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    final c = context.pop;
    final fg = _enabled ? c.onStrong : Pop.navIdle;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: _enabled
            ? () {
                Haptics.light();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down && !still ? 0.94 : 1,
          duration: Pop.fast,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: Pop.fast,
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: _enabled ? c.strong : c.disabled,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: Pop.fast,
              child: widget.busy
                  ? SizedBox(
                      key: const ValueKey('busy'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: fg,
                      ),
                    )
                  : Row(
                      key: ValueKey(widget.label),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fg, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round icon button on a soft surface.
class PopIconButton extends StatelessWidget {
  const PopIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.selection();
              onPressed!();
            },
      style: IconButton.styleFrom(
        backgroundColor: background ?? context.pop.field,
        foregroundColor: foreground ?? context.pop.text,
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}

/// Pill segmented control with a sliding black indicator.
class PopSegmented<T> extends StatelessWidget {
  const PopSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected).clamp(0, values.length - 1);
    final n = values.length;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: context.pop.field,
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: Pop.reduceMotion(context) ? Duration.zero : Pop.medium,
            curve: Curves.easeOutBack,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: context.pop.strong,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () {
                        Haptics.selection();
                        onChanged(values[i]);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Pop.fast,
                          style: TextStyle(
                            fontFamily: Pop.font,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: i == index
                                ? context.pop.onStrong
                                : context.pop.muted,
                          ),
                          child: Text(labels[i]),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chunky rounded progress bar that eases to each new value.
class PopProgressBar extends StatelessWidget {
  const PopProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
    this.track,
  });

  /// 0..1, or null for "waiting".
  final double? value;
  final double height;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final target = (value ?? 0).clamp(0.0, 1.0);
    return Semantics(
      value: value == null ? 'waiting' : '${(target * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: track ?? context.pop.track,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: target),
              duration: Pop.reduceMotion(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? context.pop.strong,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded thumbnail with a tinted fallback and a play / music glyph.
class PopThumb extends StatelessWidget {
  const PopThumb({
    super.key,
    required this.seed,
    this.url,
    this.size = 56,
    this.audio = false,
    this.radius = Pop.thumbRadius,
  });

  final String seed;
  final String? url;
  final double size;
  final bool audio;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    if (audio && AudioArt.instance != null) return _art(context);
    final glyph = Icon(
      audio ? Icons.music_note_rounded : Icons.play_arrow_rounded,
      color: Pop.ink,
      // Fill-the-space thumbs pass an infinite size; give the glyph a real one.
      size: size.isFinite ? size * 0.42 : 56,
    );
    final fallback = ColoredBox(
      color: Pop.tintFor(seed),
      child: Center(child: glyph),
    );
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || audio
            ? fallback
            // Decode at the size it is shown, not the full 1280px source:
            // much less memory and no decode hitches while scrolling or morphing.
            : LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth.isFinite ? box.maxWidth : 400.0;
                  return Image.network(
                    url!,
                    fit: BoxFit.cover,
                    cacheWidth: (w * MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(64, 1280),
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => fallback,
                    frameBuilder: (_, child, frame, sync) =>
                        sync || frame != null ? child : fallback,
                  );
                },
              ),
      ),
    );
  }

  /// Audio: a line-drawn illustration from the shuffled deck, ink on soft
  /// yellow (yellow on dark brown in dark mode).
  Widget _art(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final i = AudioArt.instance!.indexFor(seed);
    return ValueListenableBuilder(
      valueListenable: Cosmetics.cover,
      builder: (context, c, _) => ClipRRect(
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          color: dark ? c.bgDark : c.bg,
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            AudioArt.assetFor(i),
            fit: BoxFit.contain,
            color: dark ? c.inkDark : c.ink,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'Audio',
          ),
        ),
      ),
    );
  }
}

/// Small pill label, e.g. "MP4 · 1080p".
class PopTag extends StatelessWidget {
  const PopTag(this.text, {super.key, this.color});

  final String text;

  /// Background; defaults to soft yellow. Pass another on yellow cards.
  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      shape: const StadiumBorder(),
      color: color ?? context.pop.soft,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.pop.text,
        ),
      ),
    ),
  );
}

/// Small uppercase section label.
class PopSection extends StatelessWidget {
  const PopSection(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.pop.muted,
      ),
    ),
  );
}

/// One tab in [PopTabBar].
class PopTab {
  const PopTab(this.icon, this.label, {this.badge = 0});

  final IconData icon;
  final String label;
  final int badge;
}

/// Floating liquid-glass dock. The page shows through the glass; the active tab
/// is a yellow blob that stretches like a metaball when it moves between tabs.
class PopTabBar extends StatefulWidget {
  const PopTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<PopTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  State<PopTabBar> createState() => _PopTabBarState();
}

class _PopTabBarState extends State<PopTabBar> {
  late int _from = widget.index;

  @override
  void didUpdateWidget(PopTabBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _from = old.index;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final still = Pop.reduceMotion(context);
    final n = widget.tabs.length;
    final movingRight = widget.index > _from;
    // The leading edge races ahead and the trailing edge catches up:
    // the gap between them is what stretches into a liquid neck.
    const fast = Duration(milliseconds: 260);
    const slow = Duration(milliseconds: 520);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 68,
        // Frosted glass: the page blurs through, with a tint, a top highlight
        // and a hairline edge, clipped to the dock's soft superellipse.
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? const [Color(0xB32A2A2A), Color(0x99161616)]
                      : const [Color(0xCCFFFFFF), Color(0x99F4F4F4)],
                ),
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(34),
                  side: BorderSide(
                    color: dark ? Colors.white24 : Colors.black12,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  const pad = 6.0;
                  // The active tab is wider so its label fits: 16 parts vs 10.
                  final unit = (box.maxWidth - pad * 2) / (10 * (n - 1) + 16);
                  final w = unit * 16;
                  double left(int i) => pad + unit * 10 * i;
                  // The active bubble, sliding to the selected tab.
                  Widget blob(Widget Function(DockColor) fill) =>
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: left(widget.index)),
                        duration: still
                            ? Duration.zero
                            : (movingRight ? slow : fast),
                        curve: Curves.easeOutCubic,
                        builder: (_, l, _) => TweenAnimationBuilder<double>(
                          tween: Tween(end: left(widget.index) + w),
                          duration: still
                              ? Duration.zero
                              : (movingRight ? fast : slow),
                          curve: Curves.easeOutBack,
                          builder: (_, r, _) => Positioned(
                            left: math.min(l, r - 40),
                            width: math.max(r - l, 40),
                            top: pad,
                            bottom: pad,
                            child: ValueListenableBuilder(
                              valueListenable: Cosmetics.dock,
                              builder: (_, d, _) => fill(d),
                            ),
                          ),
                        ),
                      );
                  return Stack(
                    children: [
                      // Gooey active blob: the blur gives it the stretchy
                      // shape, so only a flat colour goes through it.
                      Positioned.fill(
                        child: Gooey(
                          blur: 7,
                          child: Stack(
                            children: [
                              blob(
                                (d) => d.style == DockStyle.solid
                                    ? DockFill(d)
                                    : ColoredBox(color: d.color),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Patterned docks are drawn crisp on top, outside the blur.
                      ValueListenableBuilder(
                        valueListenable: Cosmetics.dock,
                        builder: (_, d, _) => d.style == DockStyle.solid
                            ? const SizedBox.shrink()
                            : Positioned.fill(
                                child: Stack(children: [blob(DockFill.new)]),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(pad),
                        child: ValueListenableBuilder(
                          // Icons follow the dock's colour (light on dark docks).
                          valueListenable: Cosmetics.dock,
                          builder: (context, _, _) => Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < n; i++)
                                _tab(context, i, dark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i, bool dark) {
    final tab = widget.tabs[i];
    final on = i == widget.index;
    final idle = dark ? const Color(0xFFBDBDBD) : const Color(0xFF3A3A3A);
    return Expanded(
      flex: on ? 16 : 10,
      child: Semantics(
        selected: on,
        button: true,
        label: tab.badge > 0 ? '${tab.label}, ${tab.badge} active' : tab.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!on) Haptics.selection();
            widget.onChanged(i);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: tab.badge > 0,
                backgroundColor: Pop.ink,
                textColor: Pop.yellow,
                label: Text('${tab.badge}'),
                child: AnimatedScale(
                  scale: on ? 1.08 : 1,
                  duration: Pop.medium,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    tab.icon,
                    color: on ? Cosmetics.dock.value.onColor : idle,
                  ),
                ),
              ),
              AnimatedSize(
                duration: Pop.medium,
                curve: Curves.easeOutCubic,
                child: on
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Cosmetics.dock.value.onColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable option card: soft yellow with an outline when selected.
class PopOptionTile extends StatelessWidget {
  const PopOptionTile({
    super.key,
    required this.label,
    this.size,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: Pop.cardRadius,
          onTap: () {
            Haptics.selection();
            onTap();
          },
          child: AnimatedContainer(
            duration: Pop.fast,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: selected ? context.pop.soft : context.pop.card,
              borderRadius: Pop.cardRadius,
              border: Border.all(
                color: selected ? context.pop.text : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: Pop.fast,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    key: ValueKey(selected),
                    color: context.pop.text,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (size != null)
                  Text(
                    size!,
                    style: TextStyle(
                      color: context.pop.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
