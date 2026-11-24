import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';

/// Grab Club: streaks, XP, levels and badges. All local, never required, and
/// switched off entirely by "Playful mode" in Settings.

/// One badge: what it's called, how to earn it, and when it's earned.
class GameBadge {
  const GameBadge(this.id, this.title, this.how, this.earned);

  final String id;
  final String title;
  final String how;
  final bool Function(GameState s) earned;

  String get asset => 'assets/badges/$id.png';
}

const _gb = 1024 * 1024 * 1024;

final badges = <GameBadge>[
  GameBadge(
    'first_grab',
    'First Grab',
    'Save your first file',
    (s) => s.files >= 1,
  ),
  GameBadge(
    'first_trim',
    'Snip Snip',
    'Save a trimmed clip',
    (s) => s.trims >= 1,
  ),
  GameBadge(
    'surgeon',
    'Surgeon',
    'Trim a clip under 5 seconds',
    (s) => s.has('surgeon'),
  ),
  GameBadge(
    'first_ringtone',
    'Ring Ring',
    'Make a ringtone',
    (s) => s.ringtones >= 1,
  ),
  GameBadge(
    'first_playlist',
    'Binge Mode',
    'Grab from a playlist',
    (s) => s.playlists >= 1,
  ),
  GameBadge(
    'first_subtitle',
    'Read Along',
    'Save subtitles',
    (s) => s.subs >= 1,
  ),
  GameBadge(
    'full_spectrum',
    'Full Spectrum',
    'Save video, audio and subtitles',
    (s) => s.videos > 0 && s.audios > 0 && s.subs > 0,
  ),
  GameBadge(
    'globetrotter',
    'Globetrotter',
    'Grab from 5 different sites',
    (s) => s.sites.length >= 5,
  ),
  GameBadge('files_10', 'Starter Box', 'Save 10 files', (s) => s.files >= 10),
  GameBadge('files_100', 'Bookworm', 'Save 100 files', (s) => s.files >= 100),
  GameBadge(
    'files_1000',
    'Treasure Chest',
    'Save 1,000 files',
    (s) => s.files >= 1000,
  ),
  GameBadge('gb_1', 'Gigabyte', 'Save 1 GB', (s) => s.bytes >= _gb),
  GameBadge('gb_10', 'Server Room', 'Save 10 GB', (s) => s.bytes >= 10 * _gb),
  GameBadge(
    'audiophile',
    'Audiophile',
    'Save 50 songs or sounds',
    (s) => s.audios >= 50,
  ),
  GameBadge('cinephile', 'Cinephile', 'Save 50 videos', (s) => s.videos >= 50),
  GameBadge(
    'night_owl',
    'Night Owl',
    'Grab something after midnight',
    (s) => s.has('night_owl'),
  ),
  GameBadge(
    'early_bird',
    'Early Bird',
    'Grab something before 7 am',
    (s) => s.has('early_bird'),
  ),
  GameBadge(
    'weekend_warrior',
    'Weekend Warrior',
    'Save 10 files on weekends',
    (s) => s.weekend >= 10,
  ),
  GameBadge(
    'speed_demon',
    'Speed Demon',
    'Download faster than 10 MB/s',
    (s) => s.has('speed_demon'),
  ),
  GameBadge(
    'never_give_up',
    'Never Give Up',
    'Finish a download that had to retry',
    (s) => s.has('never_give_up'),
  ),
  GameBadge(
    'sharer',
    'Sharer',
    'Share a file you grabbed',
    (s) => s.shares >= 1,
  ),
  GameBadge('streak_7', 'On Fire', 'Keep a 7-day streak', (s) => s.best >= 7),
  GameBadge(
    'streak_30',
    'Unstoppable',
    'Keep a 30-day streak',
    (s) => s.best >= 30,
  ),
  GameBadge(
    'streak_100',
    'Legendary Flame',
    'Keep a 100-day streak',
    (s) => s.best >= 100,
  ),
];

/// Levels: XP needed to reach each, and its emblem.
class Level {
  const Level(this.n, this.name, this.xp);
  final int n;
  final String name;
  final int xp;

  String get asset => 'assets/badges/level_${n}_${name.toLowerCase()}.png';
}

const levels = [
  Level(1, 'Clipper', 0),
  Level(2, 'Collector', 150),
  Level(3, 'Archivist', 600),
  Level(4, 'Hoarder', 2000),
  Level(5, 'Legend', 6000),
];

/// Experience points per action.
abstract final class Xp {
  static const grab = 10;
  static const trim = 5;
  static const ringtone = 15;
  static const playlist = 10;
  static const share = 5;
  static const badge = 25;
}

int dayNumber(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ 86400000;

/// Monday-based week number, for the weekly streak freeze.
int weekNumber(DateTime t) => (dayNumber(t) + 3) ~/ 7;

@immutable
class GameState {
  const GameState({
    this.enabled = true,
    this.xp = 0,
    this.streak = 0,
    this.best = 0,
    this.lastDay = -1,
    this.freezes = 1,
    this.freezeWeek = -1,
    this.files = 0,
    this.videos = 0,
    this.audios = 0,
    this.subs = 0,
    this.trims = 0,
    this.ringtones = 0,
    this.playlists = 0,
    this.shares = 0,
    this.weekend = 0,
    this.bytes = 0,
    this.sites = const {},
    this.flags = const {},
    this.unlocked = const {},
    this.counted = const {},
  });

  final bool enabled;
  final int xp;

  /// Days in a row with a grab, as of [lastDay]; see [liveStreak].
  final int streak;
  final int best;
  final int lastDay;

  /// One freeze a week covers a single missed day.
  final int freezes;
  final int freezeWeek;

  final int files,
      videos,
      audios,
      subs,
      trims,
      ringtones,
      playlists,
      shares,
      weekend;
  final int bytes;
  final Set<String> sites;

  /// One-off moments (night_owl, surgeon...).
  final Set<String> flags;

  /// GameBadge id -> unlock time (ms).
  final Map<String, int> unlocked;

  /// Job ids already rewarded.
  final Set<String> counted;

  bool has(String flag) => flags.contains(flag);

  /// The streak as it stands today: 0 once it has lapsed.
  int liveStreak([DateTime? now]) {
    final gap = dayNumber(now ?? DateTime.now()) - lastDay;
    if (lastDay < 0) return 0;
    if (gap <= 1) return streak;
    if (gap == 2 && freezesNow(now) > 0) return streak;
    return 0;
  }

  /// Freezes available this week.
  int freezesNow([DateTime? now]) =>
      weekNumber(now ?? DateTime.now()) == freezeWeek ? freezes : 1;

  /// True when today's grab hasn't happened yet but the streak is still alive.
  bool atRisk([DateTime? now]) =>
      liveStreak(now) > 0 && dayNumber(now ?? DateTime.now()) != lastDay;

  Level get level => levels.lastWhere((l) => xp >= l.xp);
  Level? get nextLevel => level.n < levels.length ? levels[level.n] : null;

  /// 0..1 progress to the next level.
  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 1;
    return (xp - level.xp) / (next.xp - level.xp);
  }

  GameState copyWith({
    bool? enabled,
    int? xp,
    int? streak,
    int? best,
    int? lastDay,
    int? freezes,
    int? freezeWeek,
    int? files,
    int? videos,
    int? audios,
    int? subs,
    int? trims,
    int? ringtones,
    int? playlists,
    int? shares,
    int? weekend,
    int? bytes,
    Set<String>? sites,
    Set<String>? flags,
    Map<String, int>? unlocked,
    Set<String>? counted,
  }) => GameState(
    enabled: enabled ?? this.enabled,
    xp: xp ?? this.xp,
    streak: streak ?? this.streak,
    best: best ?? this.best,
    lastDay: lastDay ?? this.lastDay,
    freezes: freezes ?? this.freezes,
    freezeWeek: freezeWeek ?? this.freezeWeek,
    files: files ?? this.files,
    videos: videos ?? this.videos,
    audios: audios ?? this.audios,
    subs: subs ?? this.subs,
    trims: trims ?? this.trims,
    ringtones: ringtones ?? this.ringtones,
    playlists: playlists ?? this.playlists,
    shares: shares ?? this.shares,
    weekend: weekend ?? this.weekend,
    bytes: bytes ?? this.bytes,
    sites: sites ?? this.sites,
    flags: flags ?? this.flags,
    unlocked: unlocked ?? this.unlocked,
    counted: counted ?? this.counted,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'xp': xp,
    'streak': streak,
    'best': best,
    'lastDay': lastDay,
    'freezes': freezes,
    'freezeWeek': freezeWeek,
    'files': files,
    'videos': videos,
    'audios': audios,
    'subs': subs,
    'trims': trims,
    'ringtones': ringtones,
    'playlists': playlists,
    'shares': shares,
    'weekend': weekend,
    'bytes': bytes,
    'sites': sites.toList(),
    'flags': flags.toList(),
    'unlocked': unlocked,
    'counted': counted.toList(),
  };

  static GameState fromJson(Map<String, Object?> j) {
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    Set<String> set(String k) =>
        ((j[k] as List?) ?? const []).map((e) => '$e').toSet();
    return GameState(
      enabled: j['enabled'] as bool? ?? true,
      xp: i('xp'),
      streak: i('streak'),
      best: i('best'),
      lastDay: (j['lastDay'] as num?)?.toInt() ?? -1,
      freezes: (j['freezes'] as num?)?.toInt() ?? 1,
      freezeWeek: (j['freezeWeek'] as num?)?.toInt() ?? -1,
      files: i('files'),
      videos: i('videos'),
      audios: i('audios'),
      subs: i('subs'),
      trims: i('trims'),
      ringtones: i('ringtones'),
      playlists: i('playlists'),
      shares: i('shares'),
      weekend: i('weekend'),
      bytes: i('bytes'),
      sites: set('sites'),
      flags: set('flags'),
      unlocked: ((j['unlocked'] as Map?) ?? const {}).map(
        (k, v) => MapEntry('$k', (v as num).toInt()),
      ),
      counted: set('counted'),
    );
  }
}

/// Something worth celebrating, shown by the shell.
sealed class GameMoment {
  const GameMoment();
}

class BadgeUnlocked extends GameMoment {
  const BadgeUnlocked(this.badge);
  final GameBadge badge;
}

class LevelUp extends GameMoment {
  const LevelUp(this.level);
  final Level level;
}

/// The 10th, 100th, 1,000th... file.
class Milestone extends GameMoment {
  const Milestone(this.files);
  final int files;
}

const milestones = [10, 50, 100, 250, 500, 1000, 5000];

class StreakUp extends GameMoment {
  const StreakUp(this.days);
  final int days;
}

/// Pure rules, kept apart from storage so they're easy to test.
abstract final class GameRules {
  /// Credits one finished job. Returns the new state (unchanged if already counted).
  static GameState applyJob(GameState s, DownloadJob job) {
    if (job.status != JobStatus.done || s.counted.contains(job.id)) return s;
    final at = (job.finishedAt ?? DateTime.now()).toLocal();
    final mode = DownloadMode.values
        .where((m) => m.name == job.mode)
        .firstOrNull;
    final isSubs =
        mode == DownloadMode.subtitlesOnly || job.subLangs.isNotEmpty;
    final isAudio =
        mode == DownloadMode.audioOnly || mode == DownloadMode.videoAndAudio;
    final isVideo =
        mode == DownloadMode.video || mode == DownloadMode.videoAndAudio;
    final trimmed = job.trimStart != null || job.trimEnd != null;
    final flags = {...s.flags};
    if (at.hour < 5) flags.add('night_owl');
    if (at.hour >= 5 && at.hour < 7) flags.add('early_bird');
    if (job.attempts > 0) flags.add('never_give_up');
    if (trimmed &&
        job.trimStart != null &&
        job.trimEnd != null &&
        job.trimEnd! - job.trimStart! < 5) {
      flags.add('surgeon');
    }
    final weekend =
        at.weekday == DateTime.saturday || at.weekday == DateTime.sunday;
    s = s.copyWith(
      counted: {...s.counted, job.id},
      xp: s.xp + Xp.grab + (trimmed ? Xp.trim : 0),
      files: s.files + 1,
      videos: s.videos + (isVideo ? 1 : 0),
      audios: s.audios + (isAudio ? 1 : 0),
      subs: s.subs + (isSubs ? 1 : 0),
      trims: s.trims + (trimmed ? 1 : 0),
      weekend: s.weekend + (weekend ? 1 : 0),
      bytes: s.bytes + (job.estimatedBytes ?? 0),
      sites: job.site == null ? s.sites : {...s.sites, job.site!.toLowerCase()},
      flags: flags,
    );
    return touchStreak(s, at);
  }

  /// Marks [at]'s day as active and extends or restarts the streak.
  static GameState touchStreak(GameState s, DateTime at) {
    final day = dayNumber(at);
    if (day <= s.lastDay) return s;
    final week = weekNumber(at);
    var freezes = s.freezeWeek == week ? s.freezes : 1;
    final gap = s.lastDay < 0 ? 99 : day - s.lastDay;
    int streak;
    if (gap == 1) {
      streak = s.streak + 1;
    } else if (gap == 2 && freezes > 0) {
      freezes -= 1;
      streak = s.streak + 1;
    } else {
      streak = 1;
    }
    return s.copyWith(
      streak: streak,
      best: streak > s.best ? streak : s.best,
      lastDay: day,
      freezes: freezes,
      freezeWeek: week,
    );
  }

  /// Unlocks every newly earned badge; returns the state and what unlocked.
  static (GameState, List<GameBadge>) checkBadges(
    GameState s, [
    DateTime? now,
  ]) {
    final fresh = [
      for (final b in badges)
        if (!s.unlocked.containsKey(b.id) && b.earned(s)) b,
    ];
    if (fresh.isEmpty) return (s, const []);
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return (
      s.copyWith(
        unlocked: {...s.unlocked, for (final b in fresh) b.id: t},
        xp: s.xp + Xp.badge * fresh.length,
      ),
      fresh,
    );
  }
}

class GameController extends Notifier<GameState> {
  static const _key = 'grabClub';

  final _moments = <GameMoment>[];

  /// Celebrations waiting to be shown; the shell drains this.
  List<GameMoment> takeMoments() {
    final m = [..._moments];
    _moments.clear();
    return m;
  }

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  GameState build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const GameState();
    try {
      return GameState.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return const GameState();
    }
  }

  bool get firstRun => !_prefs.containsKey(_key);

  /// Replaces progress with a restored backup (no celebrations).
  void restore(GameState s) {
    state = s;
    _prefs.setString(_key, jsonEncode(s.toJson()));
  }

  void _commit(GameState next, {bool celebrate = true}) {
    final before = state;
    final (checked, fresh) = GameRules.checkBadges(next);
    state = checked;
    _prefs.setString(_key, jsonEncode(checked.toJson()));
    if (!celebrate || !checked.enabled) return;
    if (checked.streak > before.streak &&
        checked.lastDay != before.lastDay &&
        checked.streak > 1) {
      _moments.add(StreakUp(checked.streak));
    }
    for (final m in milestones) {
      if (before.files < m && checked.files >= m) _moments.add(Milestone(m));
    }
    for (final b in fresh) {
      _moments.add(BadgeUnlocked(b));
    }
    if (checked.level.n > before.level.n) _moments.add(LevelUp(checked.level));
  }

  /// Credits finished jobs. On first run, history is credited quietly.
  void syncJobs(List<DownloadJob> jobs) {
    final quiet = firstRun;
    var s = state;
    // Oldest first, so the streak builds in order.
    final done =
        jobs
            .where(
              (j) => j.status == JobStatus.done && !s.counted.contains(j.id),
            )
            .toList()
          ..sort(
            (a, b) => (a.finishedAt ?? a.createdAt).compareTo(
              b.finishedAt ?? b.createdAt,
            ),
          );
    if (done.isEmpty) {
      if (quiet) _commit(s, celebrate: false);
      return;
    }
    for (final j in done) {
      s = GameRules.applyJob(s, j);
    }
    _commit(s, celebrate: !quiet);
  }

  void ringtone() => _commit(
    state.copyWith(ringtones: state.ringtones + 1, xp: state.xp + Xp.ringtone),
  );

  void playlist() => _commit(
    state.copyWith(playlists: state.playlists + 1, xp: state.xp + Xp.playlist),
  );

  void shared() => _commit(
    state.copyWith(shares: state.shares + 1, xp: state.xp + Xp.share),
  );

  void flag(String f) {
    if (state.has(f)) return;
    _commit(state.copyWith(flags: {...state.flags, f}));
  }

  void setEnabled(bool on) =>
      _commit(state.copyWith(enabled: on), celebrate: false);
}

final gameProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

/// "12.4 MB/s" -> bytes per second.
double? parseSpeed(String s) {
  final m = RegExp(
    r'([\d.]+)\s*([KMG]i?B)/s',
    caseSensitive: false,
  ).firstMatch(s);
  if (m == null) return null;
  final v = double.tryParse(m.group(1)!) ?? 0;
  final unit = m.group(2)!.toUpperCase()[0];
  return v *
      switch (unit) {
        'K' => 1024,
        'M' => 1024 * 1024,
        'G' => 1024 * 1024 * 1024,
        _ => 1,
      };
}

/// Opens the share sheet; a completed share counts towards the Sharer badge.
Future<void> shareAndCount(WidgetRef ref, ShareParams params) async {
  final r = await SharePlus.instance.share(params);
  if (r.status != ShareResultStatus.dismissed) {
    ref.read(gameProvider.notifier).shared();
  }
}

/// A playful word for a download's progress (0..100).
String cheerFor(double progress) => switch (progress) {
  <= 0 => 'Warming up…',
  < 30 => 'Grabbing…',
  < 60 => 'Halfway-ish…',
  < 90 => 'Almost there…',
  _ => 'Wrapping it up…',
};
