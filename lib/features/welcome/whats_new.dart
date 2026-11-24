import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';

/// The release the current "What's new" pages describe.
const whatsNewRelease = '1.1';
const _seenKey = 'whatsNew.seen';

/// Whether to show "What's new": only to people who used an older Grab.
/// A fresh install (still on the welcome screen) just marks it seen.
bool takeWhatsNew(SharedPreferences prefs, {required bool returning}) {
  if (prefs.getString(_seenKey) == whatsNewRelease) return false;
  prefs.setString(_seenKey, whatsNewRelease);
  return returning;
}

class _Page {
  const _Page(
    this.art,
    this.kicker,
    this.title,
    this.body,
    this.bg, {
    this.dark = false,
  });
  final String art, kicker, title, body;
  final Color bg;
  final bool dark;
}

const _pages = [
  _Page(
    'assets/whatsnew/club.png',
    'Grab Club',
    'Every grab\ncounts.',
    'Earn XP, level up from Clipper to Legend, keep a daily streak and collect 24 badges in Trophies.',
    Pop.yellow,
  ),
  _Page(
    'assets/whatsnew/hats.png',
    'Meet your buddy',
    'Dress it up.',
    'Your buddy lives on the dock and cheers you on. Earn hats, confetti, sound packs and animated docks in Make it yours.',
    Color(0xFFFFB2C8),
  ),
  _Page(
    'assets/whatsnew/pal.png',
    'Grab Pal',
    'Describe it.\nFind it.',
    'Tap the buddy and say what you\'re looking for, typos and all. Grab Pal finds it in your library.',
    Color(0xFF9FD8FF),
  ),
  _Page(
    'assets/whatsnew/clip.png',
    'GIFs and stickers',
    'The best\nthree seconds.',
    'Open a saved video and tap the GIF button to make a looping GIF or a WhatsApp sticker.',
    Color(0xFF7BE0B5),
  ),
  _Page(
    'assets/whatsnew/gift.png',
    'And more',
    'Little extras.',
    'Grab Wrapped for your year, a weekly recap, a home screen widget and shake to grab. Find it all in Settings.',
    Pop.ink,
    dark: true,
  ),
];

Future<void> openWhatsNew(BuildContext context) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    fullscreenDialog: true,
    transitionDuration: Pop.medium,
    pageBuilder: (_, _, _) => const WhatsNewScreen(),
    transitionsBuilder: (_, a, _, child) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  ),
);

/// "What's new in Grab 1.1": a short story of colourful pages.
class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  final _ctl = PageController();
  var _page = 0;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _next() {
    Haptics.selection();
    if (_page == _pages.length - 1) {
      Navigator.pop(context);
    } else {
      _ctl.nextPage(duration: Pop.medium, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    final fg = p.dark ? Colors.white : Pop.ink;
    final last = _page == _pages.length - 1;
    return AnimatedContainer(
      duration: Pop.medium,
      color: p.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: p.dark ? Pop.yellow : Pop.ink,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        "WHAT'S NEW IN $whatsNewRelease",
                        style: TextStyle(
                          color: p.dark ? Pop.ink : Pop.yellow,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: fg),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctl,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) =>
                      _PageView(_pages[i], active: i == _page),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: Pop.fast,
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? fg : fg.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: p.dark ? Pop.yellow : Pop.ink,
                        foregroundColor: p.dark ? Pop.ink : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: Pop.font,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      child: Text(last ? "Let's go" : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView(this.p, {required this.active});

  final _Page p;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    final fg = p.dark ? Colors.white : Pop.ink;
    Widget art = Image.asset(p.art, fit: BoxFit.contain);
    if (!still) {
      art = art
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: -10,
            duration: 1800.ms,
            curve: Curves.easeInOut,
          );
    }
    Widget rise(Widget w, int i) => still || !active
        ? w
        : w
              .animate(delay: (120 * i + 100).ms)
              .fadeIn(duration: 300.ms)
              .moveY(begin: 20, curve: Curves.easeOutCubic, duration: 500.ms);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: still || !active
                  ? art
                  : art
                        .animate()
                        .scaleXY(
                          begin: 0.7,
                          curve: Curves.elasticOut,
                          duration: 900.ms,
                        )
                        .fadeIn(duration: 200.ms),
            ),
          ),
          const SizedBox(height: 12),
          rise(
            Text(
              p.kicker.toUpperCase(),
              style: TextStyle(
                color: fg.withValues(alpha: 0.65),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.6,
              ),
            ),
            0,
          ),
          const SizedBox(height: 6),
          rise(
            Text(
              p.title,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                fontSize: 44,
                height: 0.98,
                letterSpacing: -1.6,
              ),
            ),
            1,
          ),
          const SizedBox(height: 14),
          rise(
            Text(
              p.body,
              style: TextStyle(
                color: fg.withValues(alpha: 0.78),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            2,
          ),
        ],
      ),
    );
  }
}
