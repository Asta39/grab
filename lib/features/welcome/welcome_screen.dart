import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/permissions.dart';

/// Three short pages shown on first launch.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  static const seenKey = 'seenWelcome';

  static bool seen(SharedPreferences prefs) => prefs.getBool(seenKey) ?? false;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _Page {
  const _Page(this.icon, this.title, this.body, this.steps);

  final IconData icon;
  final String title;
  final String body;
  final List<String> steps;
}

const _pages = [
  _Page(
    Icons.download_rounded,
    'Paste a link.\nGet the file.',
    'Video, audio or subtitles from TikTok, YouTube, Instagram, Pinterest and 1,800+ more sites. Free, no account, no ads.',
    [],
  ),
  _Page(
    Icons.ios_share_rounded,
    'Share straight\nto Grab',
    'The fastest way in, from any app:',
    ['Tap Share on a video', 'Pick Grab', 'Choose a format, done'],
  ),
  _Page(
    Icons.bolt_rounded,
    'One tap from\nanywhere',
    'Copy a link, then tap the Grab tile in Quick Settings. Add it once:',
    [
      'Swipe down twice from the top',
      'Tap the pencil (Edit)',
      'Drag "Grab link" into your tiles',
    ],
  ),
  _Page(
    Icons.notifications_active_rounded,
    'Know when\nit\'s done',
    'Grab keeps downloading when you leave the app. Allow notifications to see progress and a "Saved" alert.',
    [
      'Only about your downloads',
      'No ads, no tracking, ever',
      'Change it any time in Settings',
    ],
  ),
];

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pager = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    Haptics.light();
    if (_page == _pages.length - 1) {
      // The last page explains notifications; ask now, then never again at first download.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('askedNotifications', true);
      await requestNotifications();
      widget.onDone();
    } else {
      _pager.nextPage(duration: Pop.medium, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    final still = Pop.reduceMotion(context);
    // Dark status bar icons on yellow.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Pop.yellow,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                // "Not now" on the notifications page: notifications stay off,
                // and Grab asks again (with its explanation) at the first download.
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text(
                    last ? 'Not now' : 'Skip',
                    style: const TextStyle(
                      color: Pop.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pager,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    Haptics.selection();
                    setState(() => _page = i);
                  },
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Same top on every page, so the icon doesn't jump.
                          const SizedBox(height: 56),
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: const ShapeDecoration(
                                    shape: CircleBorder(),
                                    color: Pop.ink,
                                  ),
                                  child: Icon(
                                    p.icon,
                                    color: Pop.yellow,
                                    size: 48,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                                p.title,
                                style: const TextStyle(
                                  color: Pop.ink,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.02,
                                  letterSpacing: -0.6,
                                ),
                              )
                              .animate(target: still ? null : 1)
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.15, end: 0),
                          const SizedBox(height: 14),
                          Text(
                            p.body,
                            style: const TextStyle(
                              color: Pop.ink,
                              fontSize: 16,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (final (n, step) in p.steps.indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: const ShapeDecoration(
                                      shape: CircleBorder(),
                                      color: Pop.ink,
                                    ),
                                    child: Text(
                                      '${n + 1}',
                                      style: const TextStyle(
                                        color: Pop.yellow,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: const TextStyle(
                                        color: Pop.ink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                child: Row(
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: Pop.medium,
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: i == _page
                              ? Pop.ink
                              : Pop.ink.withValues(alpha: 0.25),
                        ),
                      ),
                    const Spacer(),
                    Material(
                      color: Pop.ink,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: _next,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 16,
                          ),
                          child: Text(
                            last ? 'Allow & start' : 'Next',
                            style: const TextStyle(
                              color: Pop.yellow,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
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
