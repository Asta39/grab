import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/pop_theme.dart';

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
    final fg = _enabled ? Pop.yellow : Pop.navIdle;
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
                HapticFeedback.lightImpact();
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
            decoration: ShapeDecoration(shape: const StadiumBorder(), color: _enabled ? Pop.ink : const Color(0xFF3A3A3A)),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: Pop.fast,
              child: widget.busy
                  ? SizedBox(
                      key: const ValueKey('busy'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                    )
                  : Row(key: ValueKey(widget.label), mainAxisSize: MainAxisSize.min, children: [
                      if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: 20), const SizedBox(width: 8)],
                      Text(widget.label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round icon button on a soft surface.
class PopIconButton extends StatelessWidget {
  const PopIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.background = Pop.field});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      style: IconButton.styleFrom(backgroundColor: background, foregroundColor: Pop.ink, fixedSize: const Size(48, 48)),
      icon: Icon(icon),
    );
  }
}

/// Pill segmented control with a sliding black indicator.
class PopSegmented<T> extends StatelessWidget {
  const PopSegmented({super.key, required this.values, required this.labels, required this.selected, required this.onChanged});

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
      decoration: const ShapeDecoration(shape: StadiumBorder(), color: Pop.field),
      child: Stack(children: [
        AnimatedAlign(
          duration: Pop.reduceMotion(context) ? Duration.zero : Pop.medium,
          curve: Curves.easeOutBack,
          alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
          child: FractionallySizedBox(
            widthFactor: 1 / n,
            heightFactor: 1,
            child: const DecoratedBox(decoration: ShapeDecoration(shape: StadiumBorder(), color: Pop.ink)),
          ),
        ),
        Row(children: [
          for (var i = 0; i < n; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(values[i]);
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: Pop.fast,
                      style: TextStyle(
                        fontFamily: Pop.font,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: i == index ? Pop.yellow : Pop.muted,
                      ),
                      child: Text(labels[i]),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}

/// Chunky rounded progress bar that eases to each new value.
class PopProgressBar extends StatelessWidget {
  const PopProgressBar({super.key, required this.value, this.height = 10, this.color = Pop.ink, this.track = Pop.track});

  /// 0..1, or null for "waiting".
  final double? value;
  final double height;
  final Color color;
  final Color track;

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
            color: track,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: target),
              duration: Pop.reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height)),
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
  const PopThumb({super.key, required this.seed, this.url, this.size = 56, this.audio = false, this.radius = Pop.thumbRadius});

  final String seed;
  final String? url;
  final double size;
  final bool audio;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(audio ? Icons.music_note_rounded : Icons.play_arrow_rounded, color: Pop.ink, size: size * 0.42);
    final fallback = ColoredBox(color: Pop.tintFor(seed), child: Center(child: glyph));
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || audio
            ? fallback
            : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback,
                frameBuilder: (_, child, frame, sync) => sync || frame != null
                    ? child
                    : fallback),
      ),
    );
  }
}

/// Small uppercase section label.
class PopSection extends StatelessWidget {
  const PopSection(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Pop.muted)),
      );
}

/// One tab in [PopTabBar].
class PopTab {
  const PopTab(this.icon, this.label, {this.badge = 0});

  final IconData icon;
  final String label;
  final int badge;
}

/// Floating black pill tab bar; the active tab is a yellow pill.
class PopTabBar extends StatelessWidget {
  const PopTabBar({super.key, required this.tabs, required this.index, required this.onChanged});

  final List<PopTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(8),
        decoration: const ShapeDecoration(shape: StadiumBorder(), color: Pop.ink),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                label: tabs[i].badge > 0 ? '${tabs[i].label}, ${tabs[i].badge} active' : tabs[i].label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: Pop.reduceMotion(context) ? Duration.zero : Pop.medium,
                    curve: Curves.easeOutCubic,
                    decoration: ShapeDecoration(shape: const StadiumBorder(), color: i == index ? Pop.yellow : Colors.transparent),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Badge(
                        isLabelVisible: tabs[i].badge > 0,
                        backgroundColor: Pop.yellow,
                        textColor: Pop.ink,
                        label: Text('${tabs[i].badge}'),
                        child: Icon(tabs[i].icon, color: i == index ? Pop.ink : Pop.navIdle),
                      ),
                      if (i == index) ...[
                        const SizedBox(width: 8),
                        Text(tabs[i].label, style: const TextStyle(fontWeight: FontWeight.w700, color: Pop.ink)),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
