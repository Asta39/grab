import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grab/core/utils/audio_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('uses every illustration before repeating', () async {
    final art = AudioArt(
      await SharedPreferences.getInstance(),
      random: Random(1),
    );
    final first = {
      for (var i = 0; i < AudioArt.count; i++) art.indexFor('a$i'),
    };
    expect(first, hasLength(AudioArt.count));
    final second = {
      for (var i = 0; i < AudioArt.count; i++) art.indexFor('b$i'),
    };
    expect(second, hasLength(AudioArt.count));
  });

  test('a download keeps its illustration, also after restart', () async {
    final prefs = await SharedPreferences.getInstance();
    final art = AudioArt(prefs, random: Random(2));
    final x = art.indexFor('job');
    expect(art.indexFor('job'), x);
    for (var i = 0; i < 10; i++) {
      art.indexFor('other$i');
    }
    final again = AudioArt(prefs, random: Random(3));
    expect(again.indexFor('job'), x);
    // The saved deck continues: the next 39 are all new pictures.
    final used = {x, for (var i = 0; i < 10; i++) again.indexFor('other$i')};
    final next = {for (var i = 0; i < 39; i++) again.indexFor('n$i')};
    expect(next.intersection(used), isEmpty);
  });

  test('no back-to-back repeat across a reshuffle', () async {
    for (var seed = 0; seed < 30; seed++) {
      SharedPreferences.setMockInitialValues({});
      final art = AudioArt(
        await SharedPreferences.getInstance(),
        random: Random(seed),
      );
      int? last;
      for (var i = 0; i < AudioArt.count * 3; i++) {
        final v = art.indexFor('k$i');
        expect(v, isNot(last));
        last = v;
      }
    }
  });

  test('choices from an older picture set are dropped', () async {
    SharedPreferences.setMockInitialValues({
      'audioArt.assigned': '{"job":3}',
      'audioArt.last': 3,
    });
    final prefs = await SharedPreferences.getInstance();
    AudioArt(prefs, random: Random(4)).indexFor('job');
    expect(
      prefs.getKeys().where((k) => !k.startsWith('audioArt.v2.')),
      isEmpty,
    );
  });

  test('asset names', () {
    expect(AudioArt.assetFor(0), 'assets/art/audio_01.png');
    expect(AudioArt.assetFor(49), 'assets/art/audio_50.png');
  });
}
