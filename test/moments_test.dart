import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:grab/features/club/buddy_moments.dart';
import 'package:grab/features/club/weekly.dart';

import 'game_test.dart' show job;

void main() {
  final noon = DateTime(2026, 11, 24, 12);

  group('buddy lines', () {
    test('songs get headphones', () {
      final l = lineForGrab(job('a', noon, mode: 'audioOnly'), now: noon);
      expect(l.hat, 'headphones');
    });
    test('late at night the nightcap comes out', () {
      final late = DateTime(2026, 11, 24, 23, 30);
      expect(lineForGrab(job('a', late), now: late).hat, 'nightcap');
    });
    test('trims, big files and retries get their own lines', () {
      expect(
        lineForGrab(job('a', noon, trimStart: 1, trimEnd: 4), now: noon).text,
        anyOf('Snip snip ✂️', 'Just the good part'),
      );
      expect(
        lineForGrab(job('a', noon, bytes: 900 << 20), now: noon).text,
        contains('big one'),
      );
      expect(
        lineForGrab(job('a', noon, attempts: 2), now: noon).text,
        contains('retry'),
      );
    });
    test('plain grabs pick a cheerful line', () {
      final l = lineForGrab(job('a', noon), now: noon, rng: math.Random(1));
      expect(l.text, isNotEmpty);
      expect(l.hat, isNull);
    });
    test('milestones wear the crown', () {
      expect(lineForMilestone(100), (text: '100 grabs! 👑', hat: 'crown'));
    });
  });

  group('weekly recap', () {
    test('counts the last seven days only', () {
      final s = WeeklyStats.of([
        job('today', noon),
        job('today2', noon, site: 'tiktok'),
        job('mon', DateTime(2026, 11, 23, 9), mode: 'audioOnly'),
        job('wk', DateTime(2026, 11, 18, 9)),
        job('old', DateTime(2026, 11, 17, 9)),
      ], noon);
      expect(s.files, 4);
      expect(s.days, 3);
      expect(s.audios, 1);
      expect(s.perDay.last, 2);
      expect(s.perDay.first, 1);
    });
    test('recap shows Saturday to Monday', () {
      expect(isRecapDay(DateTime(2026, 11, 22)), isTrue); // Sunday
      expect(isRecapDay(DateTime(2026, 11, 23)), isTrue); // Monday
      expect(isRecapDay(noon), isFalse); // Tuesday
    });
  });
}
