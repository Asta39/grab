import 'package:flutter/material.dart';

import '../../core/theme/cosmetics.dart';
import 'game.dart';

/// What it takes to unlock a reward: a Grab Club level, or a specific badge.
@immutable
class Unlock {
  const Unlock.level(int this.level) : badge = null;
  const Unlock.badge(String this.badge) : level = null;

  final int? level;
  final String? badge;

  static const free = Unlock.level(1);

  bool ok(GameState g) =>
      level != null ? g.level.n >= level! : g.unlocked.containsKey(badge);

  GameBadge? get _badge => badges.where((b) => b.id == badge).firstOrNull;

  /// Short label for a locked tile: "Level 3" or "Night Owl".
  String get short => level != null ? 'Level $level' : _badge?.title ?? badge!;

  /// One line on how to get it.
  String get how => level != null
      ? 'Reach level $level, ${levels[level! - 1].name}. You earn XP for '
            'every grab, trim, ringtone, playlist and share.'
      : 'Earn the ${_badge?.title} badge: ${_badge?.how.toLowerCase()}.';

  /// The badge picture, when it's a badge unlock.
  String? get badgeAsset => _badge?.asset;
}

/// What unlocks a dock: its badge, or its level.
Unlock dockUnlock(DockColor d) =>
    d.badge != null ? Unlock.badge(d.badge!) : Unlock.level(d.level);

/// A hat the buddy can wear. Each hat is drawn into every buddy mood.
@immutable
class Hat {
  const Hat(this.id, this.name, this.unlock);

  final String id, name;
  final Unlock unlock;
}

/// How a celebration's bits move.
enum CelebrationMotion { burst, floatUp, arcs, popUp, rain, drift }

/// What flies when a file saves or a milestone lands.
@immutable
class Celebration {
  const Celebration(
    this.id,
    this.name,
    this.unlock,
    this.blurb,
    this.motion, {
    this.colors = const [],
    this.sprites = const [],
  });

  final String id, name, blurb;
  final Unlock unlock;
  final CelebrationMotion motion;

  /// Paper colours, for plain confetti.
  final List<Color> colors;

  /// Pictures that fly instead of paper.
  final List<String> sprites;
}

List<String> _set(String name) => [
  for (var i = 0; i < 6; i++) 'assets/party/${name}_$i.png',
];

/// A pair of sounds: one for a save, one for an unlock.
@immutable
class SoundPack {
  const SoundPack(this.id, this.name, this.unlock, this.blurb);

  final String id, name, blurb;
  final Unlock unlock;

  String get pop => id == 'classic' ? 'pop.mp3' : '${id}_pop.mp3';
  String get ding => id == 'classic' ? 'ding.mp3' : '${id}_ding.mp3';
}

abstract final class Rewards {
  static const hats = [
    Hat('none', 'Just me', Unlock.free),
    Hat('party', 'Party hat', Unlock.level(2)),
    Hat('beanie', 'Cozy beanie', Unlock.level(3)),
    Hat('headphones', 'DJ cans', Unlock.badge('audiophile')),
    Hat('nightcap', 'Nightcap', Unlock.badge('night_owl')),
    Hat('flowers', 'Flower crown', Unlock.badge('streak_7')),
    Hat('explorer', 'Explorer hat', Unlock.badge('globetrotter')),
    Hat('crown', 'Crown', Unlock.level(5)),
  ];

  static final celebrations = [
    const Celebration(
      'classic',
      'Classic',
      Unlock.free,
      'Paper confetti',
      CelebrationMotion.burst,
      colors: [
        Color(0xFFFFD84D),
        Color(0xFF141414),
        Color(0xFF9FD8FF),
        Color(0xFFFFB2C8),
      ],
    ),
    Celebration(
      'hearts',
      'Love letters',
      const Unlock.level(2),
      'Hearts float up',
      CelebrationMotion.floatUp,
      sprites: _set('hearts'),
    ),
    Celebration(
      'mixtape',
      'Mixtape',
      const Unlock.level(3),
      'Notes bounce out',
      CelebrationMotion.arcs,
      sprites: _set('music'),
    ),
    Celebration(
      'movie',
      'Movie night',
      const Unlock.badge('cinephile'),
      'Popcorn pops',
      CelebrationMotion.popUp,
      sprites: _set('movie'),
    ),
    Celebration(
      'gold',
      'Gold rush',
      const Unlock.level(4),
      'Coins rain down',
      CelebrationMotion.rain,
      sprites: _set('gold'),
    ),
    Celebration(
      'buddies',
      'Buddy rain',
      const Unlock.level(5),
      'Buddies drift down',
      CelebrationMotion.drift,
      sprites: [
        for (final h in ['', 'party/', 'crown/', 'flowers/', 'nightcap/'])
          for (final m in ['happy', 'cheer', 'wave']) 'assets/buddy/$h$m.png',
      ],
    ),
  ];

  static const sounds = [
    SoundPack('classic', 'Classic', Unlock.free, 'Pop and ding'),
    SoundPack('bubble', 'Bubbles', Unlock.level(2), 'Soft and fizzy'),
    SoundPack('strings', 'Pizzicato', Unlock.level(3), 'Plucked strings'),
    SoundPack(
      'chime',
      'Chimes',
      Unlock.badge('first_ringtone'),
      'Kalimba and glass',
    ),
    SoundPack(
      'crystal',
      'Crystal',
      Unlock.badge('early_bird'),
      'Clinking glass',
    ),
    SoundPack(
      'island',
      'Island',
      Unlock.badge('weekend_warrior'),
      'Steel drums',
    ),
    SoundPack('arcade', 'Arcade', Unlock.badge('speed_demon'), '8-bit jingles'),
    SoundPack('lounge', 'Lounge', Unlock.level(4), 'Smooth sax'),
    SoundPack('showtime', 'Showtime', Unlock.level(5), 'Orchestra hits'),
  ];

  static final hat = ValueNotifier<Hat>(hats.first);
  static final celebration = ValueNotifier<Celebration>(celebrations.first);

  static Hat hatById(String? id) =>
      hats.where((h) => h.id == id).firstOrNull ?? hats.first;
  static Celebration celebrationById(String? id) =>
      celebrations.where((c) => c.id == id).firstOrNull ?? celebrations.first;
  static SoundPack soundById(String? id) =>
      sounds.where((s) => s.id == id).firstOrNull ?? sounds.first;

  /// Everything there is to unlock, for the "x of y" count.
  static int total(int docks, int covers) =>
      hats.length + celebrations.length + sounds.length + docks + covers;
}
