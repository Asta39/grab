import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Hands out line-drawn illustrations for audio thumbnails.
///
/// Works like a shuffled deck: each new audio download draws the next card, so
/// all [count] illustrations are used before any repeats. When the deck runs
/// out it is reshuffled (never starting with the one just drawn). Each download
/// keeps its illustration for good: the choice is saved in preferences.
class AudioArt {
  AudioArt(this._prefs, {Random? random}) : _random = random ?? Random() {
    // Choices saved against an older picture set no longer mean anything.
    for (final k in _prefs.getKeys().where(
      (k) => k.startsWith('audioArt.') && !k.startsWith(_prefix),
    )) {
      _prefs.remove(k);
    }
    try {
      final m = jsonDecode(_prefs.getString(_mapKey) ?? '{}') as Map;
      _assigned.addAll(m.map((k, v) => MapEntry('$k', v as int)));
    } catch (_) {}
    _deck.addAll(
      (_prefs.getStringList(_deckKey) ?? const [])
          .map(int.tryParse)
          .nonNulls
          .where((i) => i >= 0 && i < count),
    );
    _last = _prefs.getInt(_lastKey);
  }

  /// Number of illustrations in assets/art.
  static const count = 50;

  /// Bump when the pictures in assets/art change, so everything is redrawn.
  static const _prefix = 'audioArt.v2.';
  static const _mapKey = '${_prefix}assigned';
  static const _deckKey = '${_prefix}deck';
  static const _lastKey = '${_prefix}last';

  /// App-wide deck, set up in main().
  static AudioArt? instance;

  final SharedPreferences _prefs;
  final Random _random;
  final _assigned = <String, int>{};
  final _deck = <int>[];
  int? _last;

  /// The illustration index for [key] (a download id), drawing a new one if needed.
  int indexFor(String key) {
    final known = _assigned[key];
    if (known != null) return known;
    if (_deck.isEmpty) _reshuffle();
    final i = _deck.removeAt(0);
    _assigned[key] = i;
    _last = i;
    _save();
    return i;
  }

  void _reshuffle() {
    _deck
      ..addAll(List.generate(count, (i) => i))
      ..shuffle(_random);
    // Don't show the same picture twice in a row across a reshuffle.
    if (_deck.first == _last) _deck.add(_deck.removeAt(0));
  }

  void _save() {
    _prefs
      ..setString(_mapKey, jsonEncode(_assigned))
      ..setStringList(_deckKey, [for (final i in _deck) '$i'])
      ..setInt(_lastKey, _last!);
  }

  static String assetFor(int index) =>
      'assets/art/audio_${'${index + 1}'.padLeft(2, '0')}.png';
}
