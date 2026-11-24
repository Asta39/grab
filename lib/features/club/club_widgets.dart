import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../core/utils/sfx.dart';
import 'customize.dart';
import 'game.dart';
import 'wrapped.dart';

/// Home header pill: the streak flame and the level ring. Tap for Trophies.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    if (!g.enabled) return const SizedBox.shrink();
    final days = g.liveStreak();
    final risk = g.atRisk();
    return Semantics(
      button: true,
      label:
          '$days day streak, level ${g.level.n} ${g.level.name}. Open trophies',
      child: GestureDetector(
        onTap: () {
          Haptics.light();
          openTrophies(context);
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
          decoration: BoxDecoration(
            color: context.pop.field,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LevelRing(state: g, size: 34),
              const SizedBox(width: 8),
              Opacity(
                opacity: days == 0 || risk ? 0.5 : 1,
                child: Image.asset(
                  'assets/badges/streak.png',
                  width: 30,
                  height: 30,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$days',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelRing extends StatelessWidget {
  const _LevelRing({required this.state, required this.size});

  final GameState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: state.levelProgress),
              duration: Pop.medium,
              builder: (_, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: size / 10,
                strokeCap: StrokeCap.round,
                backgroundColor: context.pop.track,
                color: Pop.yellow,
              ),
            ),
          ),
          Text(
            '${state.level.n}',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

void openTrophies(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const TrophiesScreen()));

/// Level, streak and the badge shelf.
class TrophiesScreen extends ConsumerWidget {
  const TrophiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final next = g.nextLevel;
    final got = badges.where((b) => g.unlocked.containsKey(b.id)).length;
    final days = g.liveStreak();
    final still = Pop.reduceMotion(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trophies'),
        actions: [
          IconButton(
            tooltip: 'Grab Wrapped',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => openWrapped(context),
          ),
          IconButton(
            tooltip: 'Make it yours',
            icon: const Icon(Icons.palette_rounded),
            onPressed: () => openCustomize(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          // Level card.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Pop.yellow,
              borderRadius: Pop.cardRadius,
            ),
            child: Row(
              children: [
                Image.asset(g.level.asset, width: 88, height: 88),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL ${g.level.n}',
                        style: const TextStyle(
                          color: Pop.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        g.level.name,
                        style: const TextStyle(
                          color: Pop.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: g.levelProgress,
                          minHeight: 8,
                          color: Pop.ink,
                          backgroundColor: Pop.ink.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next == null
                            ? '${g.xp} XP · top level'
                            : '${g.xp} / ${next.xp} XP to ${next.name}',
                        style: const TextStyle(
                          color: Pop.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Streak card.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.pop.card,
              borderRadius: Pop.cardRadius,
            ),
            child: Row(
              children: [
                Image.asset(
                  days > 0
                      ? 'assets/badges/streak.png'
                      : 'assets/badges/streak_frozen.png',
                  width: 64,
                  height: 64,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$days day${days == 1 ? '' : 's'} in a row',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        g.atRisk()
                            ? 'Grab something today to keep it going.'
                            : days > 0
                            ? 'Done for today. See you tomorrow!'
                            : 'Grab something to start a streak.',
                        style: TextStyle(color: context.pop.muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Best ${g.best} · ${g.freezesNow()} freeze left this week',
                        style: TextStyle(
                          color: context.pop.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PopSection('Badges · $got of ${badges.length}'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, i) {
              final b = badges[i];
              final on = g.unlocked.containsKey(b.id);
              final tile = _BadgeTile(badge: b, unlocked: on);
              return still
                  ? tile
                  : tile
                        .animate(delay: (30 * i).ms)
                        .fadeIn(duration: 240.ms)
                        .scaleXY(begin: 0.85, curve: Curves.easeOutBack);
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.unlocked});

  final GameBadge badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => _BadgeSheet(badge: badge, unlocked: unlocked),
        );
      },
      child: Column(
        children: [
          Expanded(child: BadgeImage(badge.asset, locked: !unlocked)),
          const SizedBox(height: 6),
          Text(
            unlocked ? badge.title : '???',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: unlocked ? null : context.pop.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSheet extends StatelessWidget {
  const _BadgeSheet({required this.badge, required this.unlocked});

  final GameBadge badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 140,
              child: BadgeImage(badge.asset, locked: !unlocked),
            ),
            const SizedBox(height: 12),
            Text(
              badge.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              unlocked ? 'Unlocked · ${badge.how}' : badge.how,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.pop.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// A badge picture; locked ones are grey and faint.
class BadgeImage extends StatelessWidget {
  const BadgeImage(this.asset, {super.key, this.locked = false});

  final String asset;
  final bool locked;

  static const _grey = ColorFilter.matrix([
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0, //
    0, 0, 0, 0.3, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(asset, fit: BoxFit.contain);
    return locked ? ColorFiltered(colorFilter: _grey, child: img) : img;
  }
}

/// Shows one celebration: a badge, a level, or a streak milestone.
void showMoment(BuildContext context, GameMoment m) {
  final (String asset, String title, String detail) = switch (m) {
    BadgeUnlocked(:final badge) => (badge.asset, 'Badge unlocked', badge.title),
    LevelUp(:final level) => (
      level.asset,
      'Level ${level.n}!',
      'You are now a ${level.name}',
    ),
    StreakUp(:final days) => (
      'assets/badges/streak.png',
      '$days-day streak',
      'Keep grabbing every day',
    ),
    Milestone(:final files) => (
      'assets/buddy/cheer.png',
      'Milestone!',
      'Your ${files}th file',
    ),
  };
  Haptics.success();
  Sfx.ding();
  toastification.showCustom(
    alignment: Alignment.topCenter,
    autoCloseDuration: const Duration(milliseconds: 3200),
    builder: (context, item) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => toastification.dismiss(item),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
          decoration: BoxDecoration(
            color: Pop.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(asset, width: 52, height: 52)
                  .animate()
                  .scaleXY(
                    begin: 0.3,
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .rotate(begin: -0.08, duration: 500.ms),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Pop.yellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
