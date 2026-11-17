import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/pop_theme.dart';

/// "You copied a link" card that floats above the dock, with a big yellow
/// Grab button. Ink in both themes so it stands out from any page behind it.
class ClipboardOffer extends StatelessWidget {
  const ClipboardOffer({
    super.key,
    required this.platform,
    required this.link,
    required this.onGrab,
    required this.onDismiss,
  });

  final String platform;
  final String link;
  final VoidCallback onGrab;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final still = Pop.reduceMotion(context);
    final button = Material(
      color: Pop.yellow,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onGrab,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded, color: Pop.ink, size: 20),
              SizedBox(width: 6),
              Text(
                'Grab it',
                style: TextStyle(
                  fontFamily: Pop.font,
                  color: Pop.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      liveRegion: true,
      child: Dismissible(
        key: ValueKey('offer-$link'),
        direction: DismissDirection.down,
        onDismissed: (_) => onDismiss(),
        child: Material(
          color: Pop.ink,
          elevation: 10,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: dark
                ? const BorderSide(color: Pop.yellow, width: 1.5)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$platform link copied',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: Pop.font,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: Pop.font,
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: onDismiss,
                  color: Colors.white60,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
                still
                    ? button
                    : button
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 1,
                            end: 1.06,
                            duration: 700.ms,
                            curve: Curves.easeInOut,
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
