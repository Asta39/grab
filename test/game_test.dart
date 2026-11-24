import 'package:flutter_test/flutter_test.dart';
import 'package:grab/data/db/app_database.dart';
import 'package:grab/features/club/game.dart';

DownloadJob job(
  String id,
  DateTime at, {
  String mode = 'video',
  String? site = 'youtube',
  double? trimStart,
  double? trimEnd,
  int attempts = 0,
  int bytes = 1000,
  String subLangs = '',
}) => DownloadJob(
  id: id,
  url: 'https://x/$id',
  title: id,
  site: site,
  mode: mode,
  container: 'mp4',
  audioFormat: 'mp3',
  subLangs: subLangs,
  subAuto: false,
  subEmbed: false,
  estimatedBytes: bytes,
  trimStart: trimStart,
  trimEnd: trimEnd,
  attempts: attempts,
  status: JobStatus.done,
  progress: 1,
  paths: '',
  createdAt: at,
  finishedAt: at,
);

GameState run(List<DownloadJob> jobs) {
  var s = const GameState();
  for (final j in jobs) {
    s = GameRules.applyJob(s, j);
  }
  return GameRules.checkBadges(s).$1;
}

void main() {
  final mon = DateTime(2026, 11, 16, 12); // a Monday

  test('first grab earns XP and the First Grab badge', () {
    final s = run([job('a', mon)]);
    expect(s.files, 1);
    expect(s.unlocked.keys, contains('first_grab'));
    expect(s.xp, Xp.grab + Xp.badge);
    expect(s.streak, 1);
  });

  test('a job is only counted once', () {
    final j = job('a', mon);
    var s = GameRules.applyJob(const GameState(), j);
    s = GameRules.applyJob(s, j);
    expect(s.files, 1);
  });

  test('consecutive days build a streak; a gap resets it', () {
    var s = run([
      for (var d = 0; d < 7; d++) job('d$d', mon.add(Duration(days: d))),
    ]);
    expect(s.streak, 7);
    expect(s.unlocked.keys, contains('streak_7'));
    s = GameRules.applyJob(s, job('late', mon.add(const Duration(days: 12))));
    expect(s.streak, 1);
    expect(s.best, 7);
  });

  test('one missed day is covered by the weekly freeze, once', () {
    var s = run([job('a', mon), job('b', mon.add(const Duration(days: 2)))]);
    expect(s.streak, 2, reason: 'freeze used for Tuesday');
    s = GameRules.applyJob(s, job('c', mon.add(const Duration(days: 4))));
    expect(s.streak, 1, reason: 'no freeze left this week');
  });

  test('live streak lapses after a missed day with no freeze', () {
    final s = run([
      job('a', mon),
    ]).copyWith(freezes: 0, freezeWeek: weekNumber(mon));
    expect(s.liveStreak(mon.add(const Duration(days: 1))), 1);
    expect(s.atRisk(mon.add(const Duration(days: 1))), isTrue);
    expect(s.liveStreak(mon.add(const Duration(days: 2))), 0);
  });

  test('moment badges: night owl, surgeon, never give up, globetrotter', () {
    final s = run([
      job('n', DateTime(2026, 11, 16, 2)),
      job('t', mon, trimStart: 10, trimEnd: 13),
      job('r', mon, attempts: 2),
      for (final site in ['tiktok', 'instagram', 'x', 'pinterest'])
        job(site, mon, site: site),
    ]);
    expect(
      s.unlocked.keys,
      containsAll([
        'night_owl',
        'surgeon',
        'first_trim',
        'never_give_up',
        'globetrotter',
      ]),
    );
  });

  test('full spectrum needs video, audio and subtitles', () {
    final s = run([
      job('v', mon),
      job('a', mon, mode: 'audioOnly'),
      job('s', mon, mode: 'subtitlesOnly'),
    ]);
    expect(s.unlocked.keys, contains('full_spectrum'));
  });

  test('levels follow XP', () {
    expect(const GameState().level.name, 'Clipper');
    expect(const GameState(xp: 150).level.name, 'Collector');
    expect(const GameState(xp: 6000).nextLevel, isNull);
    expect(const GameState(xp: 375).levelProgress, closeTo(0.5, 0.001));
  });

  test('state survives JSON', () {
    final s = run([job('a', mon), job('b', mon, mode: 'audioOnly')]);
    final back = GameState.fromJson(s.toJson());
    expect(back.toJson(), s.toJson());
  });

  test('parseSpeed', () {
    expect(parseSpeed('12.5MiB/s'), 12.5 * 1024 * 1024);
    expect(parseSpeed('800 KB/s'), 800 * 1024);
    expect(parseSpeed('--'), isNull);
  });

  test('every badge and level has an asset name that exists', () {
    for (final b in badges) {
      expect(b.asset, startsWith('assets/badges/'));
    }
    expect(
      levels.map((l) => l.asset),
      contains('assets/badges/level_5_legend.png'),
    );
  });
}
