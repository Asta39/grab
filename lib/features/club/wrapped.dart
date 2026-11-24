import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';
import '../library/library_items.dart';
import 'game.dart';

/// Grab Wrapped: the year in downloads, as a short story of cards.
@immutable
class WrappedStats {
  const WrappedStats({
    required this.year,
    required this.files,
    required this.bytes,
    required this.videos,
    required this.audios,
    required this.topSite,
    required this.topSiteCount,
    required this.sites,
    required this.busiestMonth,
    required this.busiestMonthCount,
    required this.peakHour,
    required this.trims,
    required this.bestStreak,
    required this.firstTitle,
    this.ranks = const [],
    this.months = const [],
    this.thumbs = const [],
    this.days = 0,
  });

  final int year, files, bytes, videos, audios, sites, trims, bestStreak;
  final String? topSite, firstTitle;
  final int topSiteCount;
  final int? busiestMonth;
  final int busiestMonthCount;
  final int? peakHour;

  /// Top sites, most grabs first (up to five).
  final List<(String, int)> ranks;

  /// Grabs per month, January first.
  final List<int> months;

  /// (job id, thumbnail URL) of recent video grabs, for the polaroids.
  final List<(String, String)> thumbs;

  /// Days on which you grabbed anything.
  final int days;

  bool get nightOwl => peakHour != null && (peakHour! >= 22 || peakHour! < 5);

  /// A fun label from when and what you grab.
  String get personality {
    final morning = peakHour != null && peakHour! >= 5 && peakHour! < 10;
    final who = audios > videos
        ? 'Audiophile'
        : sites >= 5
        ? 'Explorer'
        : files >= 200
        ? 'Archivist'
        : 'Collector';
    final when = nightOwl
        ? 'Night Owl'
        : morning
        ? 'Early Bird'
        : 'Daytime';
    return 'The $when $who';
  }

  static WrappedStats of(List<DownloadJob> jobs, GameState g, int year) {
    final done =
        jobs
            .where(
              (j) =>
                  j.status == JobStatus.done &&
                  (j.finishedAt ?? j.createdAt).toLocal().year == year,
            )
            .toList()
          ..sort(
            (a, b) => (a.finishedAt ?? a.createdAt).compareTo(
              b.finishedAt ?? b.createdAt,
            ),
          );
    final bySite = <String, int>{};
    final byMonth = <int, int>{};
    final byHour = <int, int>{};
    final days = <int>{};
    var bytes = 0, videos = 0, audios = 0, trims = 0;
    for (final j in done) {
      final at = (j.finishedAt ?? j.createdAt).toLocal();
      final site = siteName(j.site);
      bySite[site] = (bySite[site] ?? 0) + 1;
      byMonth[at.month] = (byMonth[at.month] ?? 0) + 1;
      byHour[at.hour] = (byHour[at.hour] ?? 0) + 1;
      days.add(at.month * 40 + at.day);
      bytes += j.estimatedBytes ?? 0;
      if (j.mode == DownloadMode.audioOnly.name) {
        audios++;
      } else {
        videos++;
      }
      if (j.trimStart != null || j.trimEnd != null) trims++;
    }
    MapEntry<K, int>? top<K>(Map<K, int> m) => m.entries.isEmpty
        ? null
        : m.entries.reduce((a, b) => b.value > a.value ? b : a);
    final site = top(bySite), month = top(byMonth), hour = top(byHour);
    final ranks = [for (final e in bySite.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final thumbs = <(String, String)>[];
    for (final j in done.reversed) {
      final t = j.thumbnail;
      if (t == null || t.isEmpty || j.mode == DownloadMode.audioOnly.name) {
        continue;
      }
      thumbs.add((j.id, t));
      if (thumbs.length == 4) break;
    }
    return WrappedStats(
      year: year,
      files: done.length,
      bytes: bytes,
      videos: videos,
      audios: audios,
      topSite: site?.key,
      topSiteCount: site?.value ?? 0,
      sites: bySite.length,
      busiestMonth: month?.key,
      busiestMonthCount: month?.value ?? 0,
      peakHour: hour?.key,
      trims: trims,
      bestStreak: g.best,
      firstTitle: done.firstOrNull?.title,
      ranks: ranks.take(5).toList(),
      months: [for (var m = 1; m <= 12; m++) byMonth[m] ?? 0],
      thumbs: thumbs,
      days: days.length,
    );
  }
}

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

// Grab's pastels, shared with the dock colours.
const _sky = Color(0xFF9FD8FF);
const _pink = Color(0xFFFFB2C8);
const _mint = Color(0xFF7BE0B5);

String _size(int b) => b >= 1 << 30
    ? '${(b / (1 << 30)).toStringAsFixed(1)} GB'
    : '${(b / (1 << 20)).round()} MB';

String _hour(int h) => h == 0
    ? 'midnight'
    : h < 12
    ? '$h am'
    : h == 12
    ? 'noon'
    : '${h - 12} pm';

String _num(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

void openWrapped(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => const WrappedScreen(),
  ),
);

/// December 1st to January 10th: Wrapped season.
bool isWrappedSeason([DateTime? now]) {
  final d = now ?? DateTime.now();
  return d.month == 12 || (d.month == 1 && d.day <= 10);
}

class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  final _shot = GlobalKey();
  var _page = 0;
  var _count = 1;

  /// Fills the current story bar, then moves on, like a story.
  late final _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed && _page < _count - 1) _next();
        })
        ..forward();

  @override
  void dispose() {
    _clock.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _next() =>
      _pages.nextPage(duration: Pop.medium, curve: Curves.easeOutCubic);
  void _back() =>
      _pages.previousPage(duration: Pop.medium, curve: Curves.easeOutCubic);

  Future<void> _share(int year) async {
    Haptics.medium();
    final boundary =
        _shot.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    // The poster is laid out at 360 x 640: this makes a 1080 x 1920 story.
    final image = await boundary.toImage(
      pixelRatio: 1080 / boundary.size.width,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/grab-wrapped-$year.png');
    await f.writeAsBytes(data.buffer.asUint8List());
    final r = await SharePlus.instance.share(
      ShareParams(files: [XFile(f.path)], text: 'My $year on Grab 💛'),
    );
    if (r.status != ShareResultStatus.dismissed) {
      ref.read(gameProvider.notifier).shared();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // In early January, look back at the year that just ended.
    final year = now.month == 1 && now.day <= 10 ? now.year - 1 : now.year;
    final s = WrappedStats.of(
      ref.watch(jobsProvider).value ?? const [],
      ref.watch(gameProvider),
      year,
    );
    final soFar = now.year == year && now.month < 12;
    final cards = _cards(s, soFar);
    _count = cards.length;
    final last = _page == cards.length - 1;
    return Scaffold(
      backgroundColor: Pop.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(
                children: [
                  for (var i = 0; i < cards.length; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.centerLeft,
                        child: AnimatedBuilder(
                          animation: _clock,
                          builder: (_, _) => FractionallySizedBox(
                            widthFactor: i < _page || last
                                ? (i <= _page ? 1 : 0)
                                : i > _page
                                ? 0
                                : _clock.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Pop.yellow,
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                // Hold to pause, tap the left third to go back.
                onLongPressStart: (_) => _clock.stop(),
                onLongPressEnd: (_) => _clock.forward(),
                onTapUp: (d) {
                  Haptics.selection();
                  final w = MediaQuery.sizeOf(context).width;
                  d.localPosition.dx < w / 3 ? _back() : _next();
                },
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    _clock.forward(from: 0);
                  },
                  children: [
                    for (final (i, c) in cards.indexed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        // Rebuilt when it becomes the current card, so its
                        // entrance plays as you arrive rather than off-screen.
                        child: KeyedSubtree(
                          key: ValueKey('$i-${i == _page}'),
                          child: c,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Pop.yellow,
                    foregroundColor: Pop.ink,
                    textStyle: const TextStyle(
                      fontFamily: Pop.font,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: last ? () => _share(year) : _next,
                  icon: Icon(
                    last
                        ? Icons.ios_share_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(last ? 'Share my year' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cards(WrappedStats s, bool soFar) {
    if (s.files == 0) return [_IntroCard(s, soFar: soFar, empty: true)];
    return [
      _IntroCard(s, soFar: soFar),
      _FilesCard(s),
      if (s.ranks.isNotEmpty) _SitesCard(s),
      if (s.busiestMonth != null) _RhythmCard(s),
      _StreakCard(s),
      _PersonaCard(s),
      Center(
        child: FittedBox(
          child: RepaintBoundary(
            key: _shot,
            child: _Poster(s, soFar: soFar),
          ),
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Building blocks

TextStyle _display(Color c, double size) => TextStyle(
  color: c,
  fontSize: size,
  fontWeight: FontWeight.w900,
  letterSpacing: -size * 0.04,
  height: 0.92,
);

TextStyle _kicker(Color c) => TextStyle(
  color: c,
  fontSize: 13,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.8,
);

/// Entrance for the [i]th piece of a card; nothing when motion is reduced.
Widget _rise(BuildContext context, Widget w, int i) => Pop.reduceMotion(context)
    ? w
    : w
          .animate(delay: (140 * i + 80).ms)
          .fadeIn(duration: 320.ms)
          .moveY(begin: 28, curve: Curves.easeOutCubic, duration: 520.ms);

/// A sticker slapped onto the card.
Widget _pop(BuildContext context, Widget w, int i) => Pop.reduceMotion(context)
    ? w
    : w
          .animate(delay: (140 * i).ms)
          .scaleXY(begin: 0, end: 1, curve: Curves.elasticOut, duration: 900.ms)
          .fadeIn(duration: 120.ms);

/// Slow, endless motion for background shapes.
Widget _loop(BuildContext context, Widget w, Effect<dynamic> effect) =>
    Pop.reduceMotion(context)
    ? w
    : w.animate(onPlay: (c) => c.repeat()).addEffect(effect);

/// Like [_loop], but swings back and forth.
Widget _sway(BuildContext context, Widget w, Effect<dynamic> effect) =>
    Pop.reduceMotion(context)
    ? w
    : w.animate(onPlay: (c) => c.repeat(reverse: true)).addEffect(effect);

/// A full-bleed coloured card with motion shapes behind its content.
class _Stage extends StatelessWidget {
  const _Stage({
    required this.color,
    required this.back,
    required this.child,
    this.front = const [],
  });

  final Color color;
  final List<Widget> back;
  final Widget child;

  /// Stickers on top of the content, placed in its empty space.
  final List<Widget> front;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(32),
    child: ColoredBox(
      color: color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ...back,
          Padding(padding: const EdgeInsets.all(24), child: child),
          ...front,
        ],
      ),
    ),
  );
}

/// A spiky sunburst, the Grab "sticker" shape.
class _Burst extends StatelessWidget {
  const _Burst(this.size, this.color, {this.points = 14});

  final double size;
  final Color color;
  final int points;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _BurstPainter(color, points)),
  );
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.color, this.points);

  final Color color;
  final int points;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = math.pi * i / points - math.pi / 2;
      final d = i.isEven ? r : r * 0.8;
      final p = c + Offset(math.cos(a) * d, math.sin(a) * d);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.color != color || old.points != points;
}

/// A tilted band of endlessly scrolling words.
class _Ticker extends StatelessWidget {
  const _Ticker(this.text, {required this.bg, required this.fg, this.turn = 0});

  final String text;
  final Color bg, fg;
  final double turn;

  @override
  Widget build(BuildContext context) {
    final line = Text(
      List.filled(8, text).join(),
      maxLines: 1,
      softWrap: false,
      style: _kicker(fg).copyWith(fontSize: 18, letterSpacing: 1.2),
    );
    final row = Row(mainAxisSize: MainAxisSize.min, children: [line, line]);
    return Transform.rotate(
      angle: turn,
      child: Container(
        color: bg,
        height: 44,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: _loop(
              context,
              row,
              const SlideEffect(
                begin: Offset.zero,
                end: Offset(-0.5, 0),
                duration: Duration(seconds: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The buddy as a cut-out sticker: a thick white edge and a soft shadow.
class _Cutout extends StatelessWidget {
  const _Cutout(this.mood, this.size, {this.turn = 0});

  final String mood;
  final double size;
  final double turn;

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/buddy/$mood.png';
    const edge = 5.0;
    Widget img(Color? tint) =>
        Image.asset(asset, width: size, height: size, color: tint);
    return Transform.rotate(
      angle: turn,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(0, 8),
            child: img(Colors.black26),
          ),
          for (var i = 0; i < 12; i++)
            Transform.translate(
              offset: Offset(
                math.cos(i * math.pi / 6) * edge,
                math.sin(i * math.pi / 6) * edge,
              ),
              child: img(Colors.white),
            ),
          img(null),
        ],
      ),
    );
  }
}

/// One of the Magnific-made Wrapped stickers: slapped on, then wobbling.
class _Sticker extends StatelessWidget {
  const _Sticker(this.name, this.size, {this.turn = 0, this.delay = 0});

  final String name;
  final double size;
  final double turn;

  /// Order it lands in, after the card's own entrance.
  final int delay;

  @override
  Widget build(BuildContext context) {
    Widget img(Color? tint) => Image.asset(
      'assets/wrapped/$name.png',
      width: size,
      height: size,
      color: tint,
    );
    final w = Transform.rotate(
      angle: turn,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(0, 6),
            child: img(Colors.black26),
          ),
          img(null),
        ],
      ),
    );
    if (Pop.reduceMotion(context)) return w;
    return w
        .animate(delay: (400 + 160 * delay).ms)
        .scaleXY(begin: 0, end: 1, curve: Curves.elasticOut, duration: 900.ms)
        .fadeIn(duration: 120.ms)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .rotate(begin: -0.012, end: 0.012, duration: 1800.ms);
  }
}

/// A sticker pinned at a spot on the card.
Widget _at({
  double? top,
  double? left,
  double? right,
  double? bottom,
  required _Sticker sticker,
}) => Positioned(
  top: top,
  left: left,
  right: right,
  bottom: bottom,
  child: IgnorePointer(child: sticker),
);

/// A grabbed video's thumbnail as a tilted polaroid.
class _Polaroid extends StatelessWidget {
  const _Polaroid(this.seed, this.url, this.size, {this.turn = 0});

  final String seed, url;
  final double size;
  final double turn;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: turn,
    child: Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: PopThumb(
        seed: seed,
        url: url,
        size: size,
        radius: BorderRadius.circular(6),
      ),
    ),
  );
}

/// A number that counts up as the card arrives.
class _Count extends StatelessWidget {
  const _Count(this.to, this.style);

  final int to;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (Pop.reduceMotion(context)) return Text(_num(to), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: to.toDouble()),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutExpo,
      builder: (_, v, _) => Text(_num(v.round()), style: style),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
    this.icon,
    this.label, {
    this.bg = Pop.ink,
    this.fg = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: fg),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// The story

class _IntroCard extends StatelessWidget {
  const _IntroCard(this.s, {required this.soFar, this.empty = false});

  final WrappedStats s;
  final bool soFar, empty;

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    return _Stage(
      front: [
        if (!empty) ...[
          _at(
            top: 28,
            left: 18,
            sticker: const _Sticker('popper', 112, turn: -0.18),
          ),
          _at(
            bottom: 120,
            left: 34,
            sticker: const _Sticker('gift', 124, turn: -0.08, delay: 1),
          ),
          _at(
            bottom: 140,
            right: 46,
            sticker: const _Sticker('sparkles', 88, turn: 0.1, delay: 2),
          ),
        ],
      ],
      color: Pop.ink,
      back: [
        Positioned(
          top: -70,
          right: -80,
          child: _loop(
            context,
            const _Burst(280, Pop.yellow, points: 18),
            const RotateEffect(
              begin: 0,
              end: 1,
              duration: Duration(seconds: 24),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -50,
          child: _sway(
            context,
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: _sky,
                shape: BoxShape.circle,
              ),
            ),
            const ScaleEffect(
              begin: Offset(1, 1),
              end: Offset(1.12, 1.12),
              duration: Duration(seconds: 3),
              curve: Curves.easeInOut,
            ),
          ),
        ),
        const Positioned(
          left: -40,
          right: -40,
          top: 160,
          child: _Ticker(
            'GRAB WRAPPED  ✦  ',
            bg: _pink,
            fg: Pop.ink,
            turn: -0.12,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 5),
          FittedBox(
            child: Row(
              children: [
                for (final (i, ch) in '${s.year}'.split('').indexed)
                  still
                      ? Text(ch, style: _display(Pop.yellow, 170))
                      : Text(ch, style: _display(Pop.yellow, 170))
                            .animate(delay: (300 + 110 * i).ms)
                            .fadeIn(duration: 200.ms)
                            .moveY(
                              begin: -140,
                              curve: Curves.bounceOut,
                              duration: 800.ms,
                            ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _rise(
            context,
            Text(
              empty
                  ? 'Nothing grabbed yet. Your year starts with the first link.'
                  : soFar
                  ? 'Your year in grabs, so far. Ready?'
                  : 'Your whole year in grabs. Ready?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            6,
          ),
          const Spacer(flex: 2),
          Align(
            alignment: Alignment.bottomRight,
            child: _pop(context, const _Cutout('wave', 130, turn: 0.14), 7),
          ),
        ],
      ),
    );
  }
}

class _FilesCard extends StatelessWidget {
  const _FilesCard(this.s);

  final WrappedStats s;

  @override
  Widget build(BuildContext context) {
    const turns = [-0.2, 0.12, -0.06, 0.22];
    const spots = [
      Alignment(-0.95, -0.6),
      Alignment(0.95, -0.85),
      Alignment(-0.4, 0.9),
      Alignment(0.75, 0.75),
    ];
    final still = Pop.reduceMotion(context);
    return _Stage(
      front: [
        _at(
          top: 34,
          right: 18,
          sticker: const _Sticker('tapes', 140, turn: 0.14),
        ),
        _at(
          top: 178,
          right: 132,
          sticker: const _Sticker('bolt', 64, turn: -0.2, delay: 1),
        ),
      ],
      color: Pop.yellow,
      back: [
        Positioned(
          bottom: -120,
          right: -120,
          child: _loop(
            context,
            const _Burst(340, Colors.white38, points: 22),
            const RotateEffect(
              begin: 0,
              end: -1,
              duration: Duration(seconds: 30),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rise(
            context,
            Text('THIS YEAR YOU GRABBED', style: _kicker(Pop.ink)),
            0,
          ),
          const SizedBox(height: 6),
          _rise(
            context,
            FittedBox(
              alignment: Alignment.centerLeft,
              child: _Count(s.files, _display(Pop.ink, 150)),
            ),
            1,
          ),
          _rise(
            context,
            Text(s.files == 1 ? 'file' : 'files', style: _display(Pop.ink, 40)),
            2,
          ),
          Expanded(
            child: Stack(
              children: [
                for (final (i, t) in s.thumbs.indexed)
                  Align(
                    alignment: spots[i],
                    child: still
                        ? _Polaroid(t.$1, t.$2, 104, turn: turns[i])
                        : _Polaroid(t.$1, t.$2, 104, turn: turns[i])
                              .animate(delay: (500 + 160 * i).ms)
                              .moveY(
                                begin: 500,
                                curve: Curves.easeOutBack,
                                duration: 700.ms,
                              ),
                  ),
                if (s.thumbs.isEmpty)
                  Center(child: _pop(context, const _Cutout('cheer', 150), 4)),
              ],
            ),
          ),
          _rise(
            context,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(Icons.play_arrow_rounded, '${_num(s.videos)} videos'),
                _Chip(Icons.music_note_rounded, '${_num(s.audios)} audio'),
                if (s.bytes > 0) _Chip(Icons.save_rounded, _size(s.bytes)),
              ],
            ),
            5,
          ),
        ],
      ),
    );
  }
}

class _SitesCard extends StatelessWidget {
  const _SitesCard(this.s);

  final WrappedStats s;

  @override
  Widget build(BuildContext context) {
    final first = s.ranks.first;
    final rest = s.ranks.skip(1).toList();
    return _Stage(
      front: [
        _at(
          top: 22,
          right: 24,
          sticker: const _Sticker('globe', 124, turn: 0.1),
        ),
        _at(
          bottom: 70,
          left: 20,
          sticker: const _Sticker('trophy', 124, turn: -0.1, delay: 2),
        ),
      ],
      color: _sky,
      back: [
        Positioned(
          top: 70,
          right: -100,
          child: _sway(
            context,
            Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                color: Pop.yellow,
                shape: BoxShape.circle,
              ),
            ),
            const MoveEffect(
              begin: Offset(0, -20),
              end: Offset(0, 20),
              duration: Duration(seconds: 3),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rise(context, Text('YOUR TOP SITES', style: _kicker(Pop.ink)), 0),
          const Spacer(),
          _rise(
            context,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#1', style: _display(Pop.ink, 34)),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(first.$1, style: _display(Pop.ink, 76)),
                  ),
                ),
              ],
            ),
            1,
          ),
          _rise(
            context,
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 6),
              child: Text(
                '${_num(first.$2)} grabs',
                style: const TextStyle(
                  color: Pop.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            2,
          ),
          const SizedBox(height: 26),
          for (final (i, r) in rest.indexed)
            _rise(context, _RankRow(i + 2, r.$1, r.$2, first.$2), 3 + i),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _rise(
                  context,
                  Text(
                    s.sites == 1
                        ? 'Loyal to one site.'
                        : '${s.sites} sites in all.',
                    style: const TextStyle(
                      color: Pop.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  7,
                ),
              ),
              _pop(context, const _Cutout('happy', 100, turn: -0.12), 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow(this.n, this.name, this.count, this.most);

  final int n, count, most;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('$n', style: _display(Pop.ink, 24))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Pop.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _num(count),
                      style: const TextStyle(
                        color: Pop.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LayoutBuilder(
                  builder: (context, box) {
                    final bar = Container(
                      height: 7,
                      width: math.max(8, box.maxWidth * count / most),
                      decoration: BoxDecoration(
                        color: Pop.ink,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    );
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Pop.reduceMotion(context)
                          ? bar
                          : bar
                                .animate(delay: 400.ms)
                                .scaleX(
                                  begin: 0,
                                  alignment: Alignment.centerLeft,
                                  curve: Curves.easeOutCubic,
                                  duration: 800.ms,
                                ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmCard extends StatelessWidget {
  const _RhythmCard(this.s);

  final WrappedStats s;

  @override
  Widget build(BuildContext context) {
    final peak = s.busiestMonth!;
    final most = s.months.fold(1, math.max);
    return _Stage(
      front: [
        _at(
          top: 52,
          left: 28,
          sticker: const _Sticker('calendar', 124, turn: -0.12),
        ),
        _at(
          top: 70,
          right: 34,
          sticker: _Sticker(
            s.nightOwl ? 'moon' : 'sparkles',
            112,
            turn: 0.14,
            delay: 1,
          ),
        ),
      ],
      color: Pop.ink,
      back: [
        Positioned(
          top: -40,
          right: -40,
          child: _loop(
            context,
            const _Burst(170, _mint, points: 10),
            const RotateEffect(
              begin: 0,
              end: 1,
              duration: Duration(seconds: 18),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rise(
            context,
            Text('YOUR BUSIEST MONTH', style: _kicker(Pop.yellow)),
            0,
          ),
          const Spacer(),
          _rise(
            context,
            FittedBox(
              child: Text(_months[peak - 1], style: _display(Colors.white, 84)),
            ),
            1,
          ),
          const SizedBox(height: 8),
          _rise(
            context,
            Text(
              '${_num(s.busiestMonthCount)} grabs in one month.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            2,
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var m = 0; m < 12; m++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: math.max(
                                  0.04,
                                  s.months[m] / most,
                                ),
                                child: _bar(context, m, m + 1 == peak),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _months[m][0],
                            style: TextStyle(
                              color: m + 1 == peak
                                  ? Pop.yellow
                                  : Colors.white54,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _rise(
            context,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (s.peakHour != null)
                  _Chip(
                    s.nightOwl
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    'Peak hour ${_hour(s.peakHour!)}',
                    bg: _pink,
                    fg: Pop.ink,
                  ),
                _Chip(
                  Icons.calendar_month_rounded,
                  'Active ${s.days} day${s.days == 1 ? '' : 's'}',
                  bg: _sky,
                  fg: Pop.ink,
                ),
              ],
            ),
            4,
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, int m, bool peak) {
    final bar = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: peak ? Pop.yellow : Colors.white24,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Pop.reduceMotion(context)
        ? bar
        : bar
              .animate(delay: (350 + 50 * m).ms)
              .scaleY(
                begin: 0,
                alignment: Alignment.bottomCenter,
                curve: Curves.easeOutBack,
                duration: 700.ms,
              );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard(this.s);

  final WrappedStats s;

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    final goal = s.bestStreak >= 30 ? 100 : 30;
    final fill = (s.bestStreak / goal).clamp(0.0, 1.0);
    return _Stage(
      front: [
        _at(
          top: 56,
          right: 22,
          sticker: const _Sticker('flame', 128, turn: 0.12),
        ),
        _at(
          top: 150,
          left: 14,
          sticker: const _Sticker('sparkles', 68, turn: -0.1, delay: 1),
        ),
        if (s.trims > 0)
          _at(
            bottom: 18,
            right: 20,
            sticker: const _Sticker('scissors', 96, turn: 0.1, delay: 2),
          ),
      ],
      color: _pink,
      back: const [
        Positioned(
          left: -40,
          right: -40,
          bottom: 90,
          child: _Ticker(
            'KEEP IT GOING  🔥  ',
            bg: Pop.ink,
            fg: Pop.yellow,
            turn: 0.08,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rise(
            context,
            Text('YOUR LONGEST STREAK', style: _kicker(Pop.ink)),
            0,
          ),
          const Spacer(),
          Center(
            child: _pop(
              context,
              SizedBox.square(
                dimension: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: still ? fill : 0, end: fill),
                      duration: const Duration(milliseconds: 1600),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 18,
                        strokeCap: StrokeCap.round,
                        color: Pop.ink,
                        backgroundColor: Colors.white54,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Count(s.bestStreak, _display(Pop.ink, 96)),
                          Text(
                            s.bestStreak == 1 ? 'day' : 'days in a row',
                            style: const TextStyle(
                              color: Pop.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              1,
            ),
          ),
          const Spacer(flex: 2),
          if (s.trims > 0)
            _rise(
              context,
              _Chip(
                Icons.content_cut_rounded,
                '${_num(s.trims)} clips trimmed',
              ),
              3,
            ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard(this.s);

  final WrappedStats s;

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    final flood = Container(
      decoration: const BoxDecoration(
        color: Pop.yellow,
        shape: BoxShape.circle,
      ),
    );
    final name = Text(
      s.personality.replaceFirst('The ', 'The\n'),
      textAlign: TextAlign.center,
      style: _display(Pop.ink, 50),
    );
    return _Stage(
      front: [
        _at(
          top: 40,
          left: 18,
          sticker: const _Sticker('heart', 104, turn: -0.16, delay: 8),
        ),
        _at(
          top: 26,
          right: 24,
          sticker: const _Sticker('popper', 104, turn: 0.18, delay: 9),
        ),
        _at(
          bottom: 90,
          left: 26,
          sticker: const _Sticker('sparkles', 88, turn: 0.1, delay: 10),
        ),
        _at(
          bottom: 70,
          right: 30,
          sticker: const _Sticker('bolt', 78, turn: 0.2, delay: 11),
        ),
      ],
      color: Pop.ink,
      back: [
        // The yellow floods out from the middle like a reveal.
        Center(
          child: OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: 1400,
            maxHeight: 1400,
            child: SizedBox.square(
              dimension: 1400,
              child: still
                  ? flood
                  : flood
                        .animate(delay: 900.ms)
                        .scaleXY(
                          begin: 0,
                          end: 1,
                          duration: 700.ms,
                          curve: Curves.easeInCubic,
                        ),
            ),
          ),
        ),
      ],
      child: Column(
        children: [
          const Spacer(),
          _rise(
            context,
            Text(
              'YOUR GRAB PERSONALITY IS…',
              textAlign: TextAlign.center,
              style: _kicker(Pop.ink).copyWith(fontSize: 15),
            ),
            0,
          ),
          const SizedBox(height: 20),
          _pop(context, const _Cutout('cheer', 170, turn: -0.06), 10),
          const SizedBox(height: 24),
          still
              ? name
              : name
                    .animate(delay: 1500.ms)
                    .scaleXY(
                      begin: 0.4,
                      curve: Curves.elasticOut,
                      duration: 1000.ms,
                    )
                    .fadeIn(duration: 200.ms),
          const Spacer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The share poster: laid out at 360 x 640 and exported at 1080 x 1920.

class _Poster extends StatelessWidget {
  const _Poster(this.s, {required this.soFar});

  final WrappedStats s;
  final bool soFar;

  @override
  Widget build(BuildContext context) {
    const turns = [-0.12, 0.06, -0.03];
    return SizedBox(
      width: 360,
      height: 640,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: Pop.yellow,
          child: Stack(
            children: [
              const Positioned(
                top: -90,
                right: -90,
                child: _Burst(260, Colors.white38, points: 20),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Pop.ink,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        soFar
                            ? 'MY ${s.year} ON GRAB · SO FAR'
                            : 'MY ${s.year} ON GRAB',
                        style: _kicker(Pop.yellow).copyWith(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          s.personality.replaceFirst('The ', 'The\n'),
                          style: _display(Pop.ink, 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 140,
                      child: s.thumbs.isEmpty
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_num(s.files)}\nfiles grabbed',
                                style: _display(Pop.ink, 34),
                              ),
                            )
                          : Row(
                              children: [
                                for (final (i, t) in s.thumbs.take(3).indexed)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: _Polaroid(
                                      t.$1,
                                      t.$2,
                                      96,
                                      turn: turns[i],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Pop.ink,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _topSites(),
                                  const Spacer(),
                                  if (s.peakHour != null)
                                    _stat('PEAK HOUR', _hour(s.peakHour!)),
                                  _stat('ACTIVE', '${s.days} days'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _stat('FILES', _num(s.files)),
                                  if (s.bytes > 0)
                                    _stat('SAVED', _size(s.bytes)),
                                  _stat(
                                    'BEST STREAK',
                                    '${s.bestStreak} day${s.bestStreak == 1 ? '' : 's'}',
                                  ),
                                  const Spacer(),
                                  if (s.busiestMonth != null)
                                    _stat(
                                      'TOP MONTH',
                                      _months[s.busiestMonth! - 1],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Text(
                          'Grab',
                          style: TextStyle(
                            color: Pop.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'asta39.github.io/grab',
                          style: TextStyle(
                            color: Pop.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 14,
                right: 14,
                child: _Cutout('cheer', 96, turn: 0.16),
              ),
              Positioned(
                top: 300,
                right: 8,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Image.asset('assets/wrapped/flame.png', width: 60),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 64,
                child: Transform.rotate(
                  angle: -0.15,
                  child: Image.asset('assets/wrapped/trophy.png', width: 42),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topSites() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('TOP SITES', style: _kicker(Pop.yellow).copyWith(fontSize: 10)),
      const SizedBox(height: 10),
      for (final (i, r) in s.ranks.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '${i + 1}',
                  style: _display(i == 0 ? Pop.yellow : Colors.white54, 15),
                ),
              ),
              Expanded(
                child: Text(
                  r.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: i == 0 ? Pop.yellow : Colors.white,
                    fontSize: i == 0 ? 18 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _stat(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _kicker(Colors.white54).copyWith(fontSize: 9)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: _display(Colors.white, 24)),
        ),
      ],
    ),
  );
}
