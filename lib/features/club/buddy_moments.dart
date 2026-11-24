import 'dart:math' as math;

import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';

/// What the buddy says (and briefly wears) after something happens.
typedef BuddyLine = ({String text, String? hat});

String _pick(List<String> lines, math.Random rng) =>
    lines[rng.nextInt(lines.length)];

/// A reaction to a finished download, picked by what was grabbed and when.
BuddyLine lineForGrab(DownloadJob j, {DateTime? now, math.Random? rng}) {
  final r = rng ?? math.Random();
  final t = (now ?? DateTime.now()).hour;
  final site = (j.site ?? '').toLowerCase();
  if (j.mode == DownloadMode.audioOnly.name) {
    return (
      text: _pick([
        'Ooh, a banger 🎧',
        'Adding this to the mixtape',
        'My ears are ready',
        'Volume up!',
      ], r),
      hat: 'headphones',
    );
  }
  if (j.mode == DownloadMode.subtitlesOnly.name) {
    return (text: 'Words, words, words 📝', hat: null);
  }
  if (t >= 23 || t < 5) {
    return (
      text: _pick([
        'Late-night grab 🌙',
        'One more, then bed?',
        'Shh… saved',
      ], r),
      hat: 'nightcap',
    );
  }
  if (j.trimStart != null || j.trimEnd != null) {
    return (text: _pick(['Snip snip ✂️', 'Just the good part'], r), hat: null);
  }
  if ((j.estimatedBytes ?? 0) > 500 * 1024 * 1024) {
    return (text: "That's a big one! 🍿", hat: null);
  }
  if (j.attempts > 0) {
    return (text: 'Got it on the retry 💪', hat: null);
  }
  if (site.contains('tiktok')) {
    return (
      text: _pick(['Straight from TikTok ✨', 'For the scroll'], r),
      hat: 'party',
    );
  }
  if (site.contains('instagram')) {
    return (text: 'Saved from the gram 📸', hat: null);
  }
  return (
    text: _pick([
      'Got it!',
      'Into the library it goes',
      'Another one 🎉',
      'Nice find',
      'Grabbed!',
    ], r),
    hat: null,
  );
}

/// When a download fails.
BuddyLine lineForFailure({math.Random? rng}) => (
  text: _pick([
    'Oops, that one slipped 😢',
    "Couldn't grab that one",
    'Try again in a bit?',
  ], rng ?? math.Random()),
  hat: null,
);

/// For a file-count milestone.
BuddyLine lineForMilestone(int n) => (text: '$n grabs! 👑', hat: 'crown');

/// For a new day on the streak.
BuddyLine lineForStreak(int days) => (
  text: days == 1 ? 'Streak started 🔥' : '$days days in a row 🔥',
  hat: null,
);
