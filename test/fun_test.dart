import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grab/features/club/game.dart';
import 'package:grab/features/club/pal.dart';
import 'package:grab/features/club/wrapped.dart';
import 'package:grab/features/library/library_items.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'game_test.dart' show job;

LibraryItem item(
  String id,
  String title, {
  LibraryKind kind = LibraryKind.video,
  String site = 'youtube',
}) => LibraryItem(
  jobId: id,
  path: '/x/$id.mp4',
  title: title,
  kind: kind,
  site: site,
  finishedAt: DateTime(2026, 11, 1),
);

void main() {
  final lib = [
    item('a', 'JONTE CHAPTER 1 || The Origin Story'),
    item('b', 'Luxury studio apartment tour', site: 'tiktok'),
    item('c', 'Lofi beats to relax', kind: LibraryKind.audio),
  ];

  group('local search', () {
    test('matches words in titles', () {
      expect(localSearch(lib, 'jonte origin').first.item.jobId, 'a');
    });
    test('forgives typos', () {
      expect(localSearch(lib, 'apartmnt').first.item.jobId, 'b');
    });
    test('matches site and kind', () {
      expect(localSearch(lib, 'tiktok').single.item.jobId, 'b');
      expect(localSearch(lib, 'audio').single.item.jobId, 'c');
    });
    test('nothing for nonsense', () {
      expect(localSearch(lib, 'zzqx'), isEmpty);
    });
  });

  test('groq search parses picks and ignores bad indexes', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      expect(req.headers['Authorization'], 'Bearer k');
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'matches': [
                    {'i': 2, 'why': 'chill music'},
                    {'i': 99, 'why': 'bad'},
                  ],
                  'say': 'Here you go!',
                }),
              },
            },
          ],
        }),
        200,
      );
    });
    final r = await groqSearch('k', lib, 'something calm', client: client);
    expect(r.single.item.jobId, 'c');
    expect(r.single.why, 'chill music');
    expect(lastSay, 'Here you go!');
    // Only metadata goes out: no file paths.
    expect(jsonEncode(sent), isNot(contains('/x/')));
  });

  test('groq search reports a refused key', () async {
    final client = MockClient((_) async => http.Response('no', 401));
    expect(
      groqSearch('bad', lib, 'x', client: client),
      throwsA(isA<PalError>()),
    );
  });

  test('cheer words follow progress', () {
    expect(cheerFor(0), 'Warming up…');
    expect(cheerFor(45), 'Halfway-ish…');
    expect(cheerFor(95), 'Wrapping it up…');
  });

  test('wrapped stats for the year', () {
    final jobs = [
      job('1', DateTime(2026, 3, 2, 23)),
      job('2', DateTime(2026, 3, 9, 23), site: 'tiktok'),
      job('3', DateTime(2026, 3, 10, 23), site: 'tiktok', mode: 'audioOnly'),
      job('old', DateTime(2025, 6, 1)),
    ];
    final s = WrappedStats.of(jobs, const GameState(best: 4), 2026);
    expect(s.files, 3);
    expect(s.topSite, isNotNull);
    expect(s.busiestMonth, 3);
    expect(s.peakHour, 23);
    expect(s.audios, 1);
    expect(s.personality, contains('Night Owl'));
    expect(s.bestStreak, 4);
  });

  test('wrapped season is December to Jan 10', () {
    expect(isWrappedSeason(DateTime(2026, 12, 5)), isTrue);
    expect(isWrappedSeason(DateTime(2027, 1, 9)), isTrue);
    expect(isWrappedSeason(DateTime(2026, 11, 23)), isFalse);
  });
}
