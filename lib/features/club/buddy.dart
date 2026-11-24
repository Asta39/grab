import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/pop_theme.dart';
import 'rewards.dart';

enum BuddyMood { happy, cheer, sad, sleep, search, wave }

/// The Grab buddy: a yellow blob who reacts to what happens in the app.
abstract final class Buddy {
  static final current = ValueNotifier<BuddyMood>(_resting());
  static Timer? _timer;

  /// A short line in a speech bubble over the dock buddy.
  static final bubble = ValueNotifier<String?>(null);

  /// A hat worn for a moment (headphones for a song, a crown for a milestone).
  static final costume = ValueNotifier<Hat?>(null);
  static Timer? _sayTimer;

  /// Says [line] (and briefly wears [hat]) for a few seconds.
  static void say(
    String line, {
    String? hat,
    Duration hold = const Duration(seconds: 4),
  }) {
    _sayTimer?.cancel();
    bubble.value = line;
    costume.value = hat == null ? null : Rewards.hatById(hat);
    _sayTimer = Timer(hold, () {
      bubble.value = null;
      costume.value = null;
    });
  }

  /// Late at night the buddy naps; otherwise it's happy.
  static BuddyMood _resting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    return h >= 23 || h < 6 ? BuddyMood.sleep : BuddyMood.happy;
  }

  /// Shows [m] for a while, then goes back to resting.
  static void mood(BuddyMood m, {Duration hold = const Duration(seconds: 3)}) {
    _timer?.cancel();
    current.value = m;
    _timer = Timer(hold, () => current.value = _resting());
  }

  /// The drawing of the buddy in mood [m], wearing [hat] if any.
  static String asset(BuddyMood m, [Hat? hat]) =>
      hat == null || hat.id == 'none'
      ? 'assets/buddy/${m.name}.png'
      : 'assets/buddy/${hat.id}/${m.name}.png';
}

/// The buddy in a given mood, wearing [hat]: each pairing is its own drawing.
class DressedBuddy extends StatelessWidget {
  const DressedBuddy({
    super.key,
    required this.mood,
    required this.hat,
    this.size = 56,
  });

  final BuddyMood mood;
  final Hat hat;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    Buddy.asset(mood, hat),
    width: size,
    height: size,
    semanticLabel: hat.id == 'none'
        ? 'Grab buddy, ${mood.name}'
        : 'Grab buddy in a ${hat.name.toLowerCase()}, ${mood.name}',
  );
}

/// Just the face, following the current mood and the chosen hat.
class BuddyFace extends StatelessWidget {
  const BuddyFace({super.key, this.size = 56});

  final double size;

  Hat get _hat => Buddy.costume.value ?? Rewards.hat.value;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Rewards.hat, Buddy.costume]),
      builder: (context, _) => ValueListenableBuilder(
        valueListenable: Buddy.current,
        builder: (context, mood, _) => AnimatedSwitcher(
          duration: Pop.medium,
          transitionBuilder: (child, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
            child: child,
          ),
          child: DressedBuddy(
            key: ValueKey((mood, _hat.id)),
            mood: mood,
            hat: _hat,
            size: size,
          ),
        ),
      ),
    );
  }
}

/// The buddy sitting on the dock, gently breathing. Tap to open Grab Pal.
class DockBuddy extends StatefulWidget {
  const DockBuddy({super.key, required this.onTap, this.size = 54});

  final VoidCallback onTap;
  final double size;

  @override
  State<DockBuddy> createState() => _DockBuddyState();
}

class _DockBuddyState extends State<DockBuddy>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    if (still) _breath.stop();
    return Semantics(
      button: true,
      label: 'Grab Pal: find something in your library',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, child) {
            final t = _breath.value * 2 * math.pi;
            final mood = Buddy.current.value;
            final bounce = mood == BuddyMood.cheer ? 6.0 : 2.0;
            return Transform.translate(
              offset: Offset(
                0,
                still ? 0 : -bounce * (0.5 + 0.5 * math.sin(t)),
              ),
              child: Transform.scale(
                scaleY: still ? 1 : 1 + 0.03 * math.sin(t),
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
          },
          child: BuddyFace(size: widget.size),
        ),
      ),
    ).withBubble(still);
  }
}

extension on Widget {
  /// Puts the buddy's speech bubble above and to the left of it.
  Widget withBubble(bool still) => Stack(
    clipBehavior: Clip.none,
    children: [
      this,
      Positioned(
        right: 30,
        bottom: 46,
        child: IgnorePointer(
          child: ValueListenableBuilder(
            valueListenable: Buddy.bubble,
            builder: (context, line, _) => AnimatedSwitcher(
              duration: still ? Duration.zero : Pop.medium,
              transitionBuilder: (child, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                alignment: Alignment.bottomRight,
                child: FadeTransition(opacity: a, child: child),
              ),
              child: line == null
                  ? const SizedBox.shrink()
                  : _Bubble(line, key: ValueKey(line)),
            ),
          ),
        ),
      ),
    ],
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 190),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Pop.ink, width: 2),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(4),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Pop.ink,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    ),
  );
}
