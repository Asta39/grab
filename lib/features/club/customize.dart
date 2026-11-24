import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cosmetics.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/utils/audio_art.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/sfx.dart';
import '../../core/widgets/dock_fill.dart';
import 'buddy.dart';
import 'celebration.dart';
import 'club_widgets.dart';
import 'fun.dart';
import 'game.dart';
import 'rewards.dart';

void openCustomize(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const CustomizeScreen()));

const _sky = Color(0xFF9FD8FF);
const _pink = Color(0xFFFFB2C8);

/// "Make it yours": dress the buddy, pick the confetti and sounds, and the
/// dock and cover looks. Things are earned with levels and badges; locked
/// ones can be tried on in the preview.
class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  final _confetti = ConfettiController(
    duration: const Duration(milliseconds: 600),
  );

  /// A locked hat being tried on in the preview.
  Hat? _tryOn;
  Celebration _party = Rewards.celebrations.first;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _celebrate(Celebration c) {
    setState(() => _party = c);
    if (Pop.reduceMotion(context)) return;
    // Play once the layer has the new style.
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  /// Explains how to earn something locked, while the preview shows it.
  Future<void> _locked({
    required String name,
    required Unlock unlock,
    required Widget art,
    Hat? hat,
  }) async {
    Haptics.warning();
    if (hat != null) setState(() => _tryOn = hat);
    Buddy.mood(BuddyMood.search);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _LockedSheet(name: name, unlock: unlock, art: art),
    );
    if (mounted) setState(() => _tryOn = null);
  }

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(funProvider);
    final g = ref.watch(gameProvider);
    final ctl = ref.read(funProvider.notifier);
    final level = g.level.n;

    final owned = [
      ...Rewards.hats.where((h) => h.unlock.ok(g)),
      ...Rewards.celebrations.where((c) => c.unlock.ok(g)),
      ...Rewards.sounds.where((s) => s.unlock.ok(g)),
      ...Cosmetics.docks.where((d) => dockUnlock(d).ok(g)),
      ...Cosmetics.covers.where((c) => c.level <= level),
    ].length;
    final total = Rewards.total(
      Cosmetics.docks.length,
      Cosmetics.covers.length,
    );
    final hat = _tryOn ?? Rewards.hatById(f.hat);

    return Scaffold(
      appBar: AppBar(title: const Text('Make it yours')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
            children: [
              _Hero(
                hat: hat,
                trying: _tryOn != null,
                game: g,
                owned: owned,
                total: total,
              ),
              const SizedBox(height: 28),
              const _Heading('Wardrobe', 'Hats go everywhere your buddy does.'),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
                children: [
                  for (final h in Rewards.hats)
                    _Tile(
                      name: h.name,
                      unlock: h.unlock,
                      open: h.unlock.ok(g),
                      selected: f.hat == h.id,
                      art: _hatArt(h),
                      onTap: () => h.unlock.ok(g)
                          ? ctl.update((x) => x.copyWith(hat: h.id))
                          : _locked(
                              name: h.name,
                              unlock: h.unlock,
                              art: _hatArt(h, size: 120),
                              hat: h,
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const _Heading(
                'Celebrations',
                'The confetti when a file saves. Tap to try it.',
              ),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: Rewards.celebrations.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final c = Rewards.celebrations[i];
                    final open = c.unlock.ok(g);
                    return SizedBox(
                      width: 104,
                      child: _Tile(
                        name: c.name,
                        unlock: c.unlock,
                        open: open,
                        selected: f.party == c.id,
                        art: _ConfettiArt(c),
                        onTap: () {
                          _celebrate(c);
                          if (open) {
                            ctl.update((x) => x.copyWith(party: c.id));
                          } else {
                            _locked(
                              name: c.name,
                              unlock: c.unlock,
                              art: SizedBox.square(
                                dimension: 110,
                                child: _ConfettiArt(c),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              const _Heading(
                'Sound packs',
                'What a save and an unlock sound like.',
              ),
              _Card(
                children: [
                  for (final p in Rewards.sounds)
                    _SoundRow(
                      pack: p,
                      open: p.unlock.ok(g),
                      selected: f.soundPack == p.id,
                      onTap: () {
                        Sfx.preview(p);
                        if (p.unlock.ok(g)) {
                          Haptics.selection();
                          ctl.update((x) => x.copyWith(soundPack: p.id));
                        } else {
                          _locked(
                            name: p.name,
                            unlock: p.unlock,
                            art: const Icon(Icons.graphic_eq_rounded, size: 72),
                          );
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const _Heading('Dock', 'The bubble behind your tabs. Some move.'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  for (final d in Cosmetics.docks)
                    _DockTile(
                      dock: d,
                      unlock: dockUnlock(d),
                      open: dockUnlock(d).ok(g),
                      selected: f.dock == d.id,
                      onTap: () => dockUnlock(d).ok(g)
                          ? ctl.update((x) => x.copyWith(dock: d.id))
                          : _locked(
                              name: '${d.name} dock',
                              unlock: dockUnlock(d),
                              art: SizedBox(
                                width: 200,
                                height: 64,
                                child: _DockPreview(d),
                              ),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const _Heading('Audio covers', 'Art for songs without a cover.'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in Cosmetics.covers)
                    _Swatch(
                      label: c.name,
                      open: c.level <= level,
                      selected: f.cover == c.id,
                      square: true,
                      onTap: () => c.level <= level
                          ? ctl.update((x) => x.copyWith(cover: c.id))
                          : _locked(
                              name: '${c.name} covers',
                              unlock: Unlock.level(c.level),
                              art: _coverArt(c, 96),
                            ),
                      child: _coverArt(c, 56),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const _Heading('Switches', null),
              _Card(
                children: [
                  _Toggle(
                    'Sounds',
                    'Play the pack above',
                    Icons.volume_up_rounded,
                    f.sounds,
                    (v) {
                      ctl.update((x) => x.copyWith(sounds: v));
                      if (v) Sfx.pop();
                    },
                  ),
                  _Toggle(
                    'Shake to grab',
                    'Shake to fetch the copied link',
                    Icons.vibration_rounded,
                    f.shake,
                    (v) => ctl.update((x) => x.copyWith(shake: v)),
                  ),
                  _Toggle(
                    'Grab buddy',
                    'Show the buddy on the dock',
                    Icons.emoji_emotions_rounded,
                    f.buddy,
                    (v) => ctl.update((x) => x.copyWith(buddy: v)),
                  ),
                ],
              ),
            ],
          ),
          Positioned.fill(
            child: CelebrationLayer(controller: _confetti, style: _party),
          ),
        ],
      ),
    );
  }

  Widget _hatArt(Hat h, {double size = 64}) =>
      DressedBuddy(mood: BuddyMood.happy, hat: h, size: size);

  Widget _coverArt(CoverStyle c, double size) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.1),
    decoration: BoxDecoration(
      color: c.bg,
      borderRadius: BorderRadius.circular(size * 0.25),
    ),
    child: Image.asset(AudioArt.assetFor(7), color: c.ink),
  );
}

/// The big preview: the buddy in its hat on a sunny stage, with your level.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.hat,
    required this.trying,
    required this.game,
    required this.owned,
    required this.total,
  });

  final Hat hat;
  final bool trying;
  final GameState game;
  final int owned, total;

  @override
  Widget build(BuildContext context) {
    final still = Pop.reduceMotion(context);
    final next = game.nextLevel;
    Widget buddy = DressedBuddy(
      key: ValueKey(hat.id),
      mood: trying ? BuddyMood.search : BuddyMood.happy,
      hat: hat,
      size: 140,
    );
    if (!still) {
      buddy = buddy
          .animate(key: ValueKey(hat.id))
          .scaleXY(begin: 0.8, curve: Curves.elasticOut, duration: 700.ms)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 1400.ms, curve: Curves.easeInOut);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Pop.yellow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: -150,
                  child: still
                      ? const _Rays()
                      : const _Rays()
                            .animate(onPlay: (c) => c.repeat())
                            .rotate(duration: 40.seconds),
                ),
                Positioned(
                  bottom: 26,
                  child: Container(
                    width: 150,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Pop.ink.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(75, 11),
                      ),
                    ),
                  ),
                ),
                Positioned(bottom: 30, child: buddy),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _Pill(
                    trying ? 'Trying on' : 'Wearing',
                    hat.name,
                    bg: trying ? _pink : Colors.white,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _Pill('Unlocked', '$owned of $total', bg: _sky),
                ),
              ],
            ),
          ),
          Container(
            color: Pop.ink,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                Image.asset(game.level.asset, width: 40, height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${game.level.n} · ${game.level.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(
                          value: game.levelProgress,
                          minHeight: 7,
                          color: Pop.yellow,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next == null
                            ? 'Top level. Everything levels can give is yours.'
                            : '${next.xp - game.xp} XP to ${next.name}'
                                  ' · ${_nextPrize(next.n)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// What the next level hands out, to give a reason to keep going.
  static String _nextPrize(int n) {
    final names = [
      ...Rewards.hats.where((h) => h.unlock.level == n).map((h) => h.name),
      ...Rewards.celebrations
          .where((c) => c.unlock.level == n)
          .map((c) => '${c.name} confetti'),
      ...Rewards.sounds
          .where((s) => s.unlock.level == n)
          .map((s) => '${s.name} sounds'),
    ];
    return names.isEmpty ? 'new looks' : 'unlocks ${names.take(2).join(', ')}';
  }
}

/// Soft sun rays behind the buddy.
class _Rays extends StatelessWidget {
  const _Rays();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size.square(520), painter: _RaysPainter());
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n;
      final b = a + math.pi / n;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r)
          ..lineTo(c.dx + math.cos(b) * r, c.dy + math.sin(b) * r)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.value, {required this.bg});

  final String label, value;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Pop.ink, width: 2),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
      style: const TextStyle(color: Pop.ink, fontSize: 13),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.sub);

  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        if (sub != null)
          Text(
            sub!,
            style: TextStyle(
              color: context.pop.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    ),
  );
}

/// Greys out locked art.
const _greyscale = ColorFilter.matrix([
  0.33, 0.33, 0.33, 0, 0, //
  0.33, 0.33, 0.33, 0, 0, //
  0.33, 0.33, 0.33, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// A wardrobe or celebration tile.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.name,
    required this.unlock,
    required this.open,
    required this.selected,
    required this.art,
    required this.onTap,
  });

  final String name;
  final Unlock unlock;
  final bool open, selected;
  final Widget art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: open ? name : '$name, locked: ${unlock.short}',
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: Pop.fast,
          decoration: BoxDecoration(
            color: selected ? Pop.yellow : context.pop.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Pop.ink : Colors.transparent,
              width: 2.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: open
                      ? art
                      : Opacity(
                          opacity: 0.45,
                          child: ColorFiltered(
                            colorFilter: _greyscale,
                            child: art,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              if (open)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Pop.ink : null,
                  ),
                )
              else
                _LockChip(unlock),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockChip extends StatelessWidget {
  const _LockChip(this.unlock);

  final Unlock unlock;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: context.pop.strong,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, size: 11, color: context.pop.onStrong),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            unlock.short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: context.pop.onStrong,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A little scatter of a celebration's bits.
class _ConfettiArt extends StatelessWidget {
  const _ConfettiArt(this.c);

  final Celebration c;

  static const _spots = [
    (-0.7, -0.55, -0.3, 30.0),
    (0.55, -0.7, 0.35, 26.0),
    (0.0, 0.05, 0.0, 38.0),
    (-0.75, 0.7, 0.2, 24.0),
    (0.7, 0.6, -0.25, 28.0),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    height: 70,
    child: Stack(
      children: [
        for (final (i, (x, y, turn, size)) in _spots.indexed)
          Align(
            alignment: Alignment(x, y),
            child: Transform.rotate(
              angle: turn,
              child: c.sprites.isEmpty
                  ? Container(
                      width: size * 0.6,
                      height: size * 0.36,
                      color: c.colors[i % c.colors.length],
                    )
                  : Image.asset(
                      c.sprites[(i * 2) % c.sprites.length],
                      width: size,
                      height: size,
                    ),
            ),
          ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: context.pop.card,
    borderRadius: Pop.cardRadius,
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({
    required this.pack,
    required this.open,
    required this.selected,
    required this.onTap,
  });

  final SoundPack pack;
  final bool open, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.fromLTRB(14, 4, 16, 4),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? Pop.yellow : context.pop.soft,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Pop.ink),
    ),
    title: Text(
      pack.name,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    ),
    subtitle: Text(pack.blurb),
    trailing: !open
        ? _LockChip(pack.unlock)
        : selected
        ? const Icon(Icons.check_circle_rounded, size: 26)
        : null,
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.title, this.sub, this.icon, this.value, this.onChanged);

  final String title, sub;
  final IconData icon;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon),
    title: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(sub),
    value: value,
    activeTrackColor: Pop.yellow,
    activeThumbColor: Pop.ink,
    onChanged: (x) {
      Haptics.selection();
      onChanged(x);
    },
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.open,
    required this.selected,
    required this.child,
    required this.onTap,
    this.square = false,
  });

  final String label;
  final bool open, selected, square;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(square ? 20 : 99);
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Pop.fast,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected ? context.pop.strong : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  open
                      ? child
                      : Opacity(
                          opacity: 0.4,
                          child: ColorFiltered(
                            colorFilter: _greyscale,
                            child: child,
                          ),
                        ),
                  if (!open) const Icon(Icons.lock_rounded, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: open ? null : context.pop.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How to earn a locked thing.
class _LockedSheet extends StatelessWidget {
  const _LockedSheet({
    required this.name,
    required this.unlock,
    required this.art,
  });

  final String name;
  final Unlock unlock;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    final badge = unlock.badgeAsset;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 120, child: Center(child: art)),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.pop.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  if (badge != null)
                    BadgeImage(badge, locked: true)
                        .animate()
                        .shimmer(duration: 1200.ms, delay: 300.ms)
                        .apply((w) => SizedBox.square(dimension: 52, child: w))
                  else
                    const Icon(Icons.lock_rounded, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      unlock.how,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Pop.yellow,
                  foregroundColor: Pop.ink,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  openTrophies(context);
                },
                child: const Text(
                  'See my trophies',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  Widget apply(Widget Function(Widget) f) => f(this);
}

/// A mini tab bar wearing a dock style, with the home tab selected.
class _DockPreview extends StatelessWidget {
  const _DockPreview(this.d);

  final DockColor d;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Pop.ink,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DockFill(d),
              Center(child: Icon(Icons.home_rounded, color: d.onColor)),
            ],
          ),
        ),
        for (final icon in const [
          Icons.download_rounded,
          Icons.video_library_rounded,
        ])
          Expanded(flex: 2, child: Icon(icon, color: Colors.white54, size: 20)),
      ],
    ),
  );
}

class _DockTile extends StatelessWidget {
  const _DockTile({
    required this.dock,
    required this.unlock,
    required this.open,
    required this.selected,
    required this.onTap,
  });

  final DockColor dock;
  final Unlock unlock;
  final bool open, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: open ? '${dock.name} dock' : '${dock.name} dock, locked',
    child: GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: Pop.fast,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: selected ? Pop.yellow : context.pop.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Pop.ink : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: open
                  ? _DockPreview(dock)
                  : Opacity(
                      opacity: 0.45,
                      child: ColorFiltered(
                        colorFilter: _greyscale,
                        child: _DockPreview(dock),
                      ),
                    ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dock.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: selected ? Pop.ink : null,
                        ),
                      ),
                      if (open)
                        Text(
                          dock.blurb,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Pop.ink.withValues(alpha: 0.7)
                                : context.pop.muted,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: _LockChip(unlock),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
