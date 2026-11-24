import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grab/core/widgets/release_notes.dart';

void main() {
  test('release notes drop tables, downloads and credits', () {
    final md = File('docs/releases/v1.1.0.md').readAsStringSync();
    final blocks = parseReleaseNotes(md);
    final text = blocks.map((b) => b.text).join('\n');
    expect(text, isNot(contains('|')));
    expect(text, isNot(contains('##')));
    expect(text, isNot(contains('`')));
    expect(text, isNot(contains('grab-v1.1.0')));
    expect(text, isNot(contains('Kenney')));
    expect(blocks.whereType<NoteHeading>().map((b) => b.text),
        containsAll(["What's new", 'Grab Club', 'Fixes']));
    expect(blocks.whereType<NoteBullet>(), isNotEmpty);
    expect(blocks.first, isA<NoteParagraph>());
  });

  test('links keep their text', () {
    final b = parseReleaseNotes('- Uses [yt-dlp](https://x.y) and `ffmpeg`');
    expect(b.single.text, 'Uses yt-dlp and ffmpeg');
  });
}
