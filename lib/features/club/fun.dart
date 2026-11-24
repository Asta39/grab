import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/cosmetics.dart';
import '../../core/utils/sfx.dart';
import 'game.dart';
import 'rewards.dart';

/// Small "fun" preferences: sounds, shake to paste, the chosen dock colour and
/// cover style, and the user's own Groq key for Grab Pal.
@immutable
class FunPrefs {
  const FunPrefs({
    this.sounds = true,
    this.shake = true,
    this.buddy = true,
    this.dock = 'yellow',
    this.cover = 'classic',
    this.groqKey = '',
    this.hat = 'none',
    this.party = 'classic',
    this.soundPack = 'classic',
  });

  final bool sounds, shake, buddy;
  final String dock, cover;
  final String groqKey;

  /// Chosen buddy hat, celebration confetti and sound pack.
  final String hat, party, soundPack;

  FunPrefs copyWith({
    bool? sounds,
    bool? shake,
    bool? buddy,
    String? dock,
    String? cover,
    String? groqKey,
    String? hat,
    String? party,
    String? soundPack,
  }) => FunPrefs(
    sounds: sounds ?? this.sounds,
    shake: shake ?? this.shake,
    buddy: buddy ?? this.buddy,
    dock: dock ?? this.dock,
    cover: cover ?? this.cover,
    groqKey: groqKey ?? this.groqKey,
    hat: hat ?? this.hat,
    party: party ?? this.party,
    soundPack: soundPack ?? this.soundPack,
  );
}

class FunController extends Notifier<FunPrefs> {
  @override
  FunPrefs build() {
    final p = ref.read(sharedPrefsProvider);
    final f = FunPrefs(
      sounds: p.getBool('fun.sounds') ?? true,
      shake: p.getBool('fun.shake') ?? true,
      buddy: p.getBool('fun.buddy') ?? true,
      dock: p.getString('fun.dock') ?? 'yellow',
      cover: p.getString('fun.cover') ?? 'classic',
      groqKey: p.getString('fun.groqKey') ?? '',
      hat: p.getString('fun.hat') ?? 'none',
      party: p.getString('fun.party') ?? 'classic',
      soundPack: p.getString('fun.soundPack') ?? 'classic',
    );
    // Cosmetics only apply while playful mode is on and the level allows them.
    ref.listen(gameProvider, (_, _) => _apply(state), fireImmediately: false);
    _apply(f);
    return f;
  }

  void _apply(FunPrefs f) {
    final g = ref.read(gameProvider);
    final level = g.level.n;
    final dock = Cosmetics.dockById(f.dock);
    final cover = Cosmetics.coverById(f.cover);
    Cosmetics.dock.value = g.enabled && dockUnlock(dock).ok(g)
        ? dock
        : Cosmetics.docks.first;
    Cosmetics.cover.value = g.enabled && cover.level <= level
        ? cover
        : Cosmetics.covers.first;
    Sfx.enabled = g.enabled && f.sounds;
    // Rewards only show while playful mode is on and they're still earned.
    final hat = Rewards.hatById(f.hat);
    final party = Rewards.celebrationById(f.party);
    final pack = Rewards.soundById(f.soundPack);
    Rewards.hat.value = g.enabled && hat.unlock.ok(g)
        ? hat
        : Rewards.hats.first;
    Rewards.celebration.value = g.enabled && party.unlock.ok(g)
        ? party
        : Rewards.celebrations.first;
    Sfx.pack = pack.unlock.ok(g) ? pack : Rewards.sounds.first;
  }

  void update(FunPrefs Function(FunPrefs) change) {
    state = change(state);
    final p = ref.read(sharedPrefsProvider);
    p
      ..setBool('fun.sounds', state.sounds)
      ..setBool('fun.shake', state.shake)
      ..setBool('fun.buddy', state.buddy)
      ..setString('fun.dock', state.dock)
      ..setString('fun.cover', state.cover)
      ..setString('fun.groqKey', state.groqKey.trim())
      ..setString('fun.hat', state.hat)
      ..setString('fun.party', state.party)
      ..setString('fun.soundPack', state.soundPack);
    _apply(state);
  }
}

final funProvider = NotifierProvider<FunController, FunPrefs>(
  FunController.new,
);
