import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';
import '../library/library_items.dart';
import 'buddy.dart';
import 'game.dart';
import 'rewards.dart';

/// The last seven days of grabbing.
@immutable
class WeeklyStats {
  const WeeklyStats({
    required this.files,
    required this.bytes,
    required this.days,
    required this.topSite,
    required this.perDay,
    required this.audios,
  });

  final int files, bytes, audios;

  /// Days (of 7) with at least one grab.
  final int days;
  final String? topSite;

  /// Grabs per day, oldest first, ending today.
  final List<int> perDay;

  static WeeklyStats of(List<DownloadJob> jobs, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 6));
    final perDay = List.filled(7, 0);
    final bySite = <String, int>{};
    var bytes = 0, audios = 0;
    for (final j in jobs) {
      if (j.status != JobStatus.done) continue;
      final at = (j.finishedAt ?? j.createdAt).toLocal();
      final day = DateTime(at.year, at.month, at.day);
      if (day.isBefore(from) || day.isAfter(today)) continue;
      perDay[day.difference(from).inDays]++;
      final s = siteName(j.site);
      bySite[s] = (bySite[s] ?? 0) + 1;
      bytes += j.estimatedBytes ?? 0;
      if (j.mode == DownloadMode.audioOnly.name) audios++;
    }
    final top = bySite.entries.isEmpty
        ? null
        : bySite.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    return WeeklyStats(
      files: perDay.fold(0, (a, b) => a + b),
      bytes: bytes,
      days: perDay.where((n) => n > 0).length,
      topSite: top,
      perDay: perDay,
      audios: audios,
    );
  }
}

/// Weekend and Monday: time for the weekly recap.
bool isRecapDay([DateTime? now]) {
  final w = (now ?? DateTime.now()).weekday;
  return w == DateTime.saturday || w == DateTime.sunday || w == DateTime.monday;
}

const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A small "your week" card for Home, shareable as an image.
class WeeklyRecapCard extends ConsumerStatefulWidget {
  const WeeklyRecapCard({super.key});

  @override
  ConsumerState<WeeklyRecapCard> createState() => _WeeklyRecapCardState();
}

class _WeeklyRecapCardState extends ConsumerState<WeeklyRecapCard> {
  final _shot = GlobalKey();

  Future<void> _share() async {
    Haptics.medium();
    final b =
        _shot.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return;
    final image = await b.toImage(pixelRatio: 1080 / b.size.width);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final f = File('${(await getTemporaryDirectory()).path}/grab-week.png');
    await f.writeAsBytes(data.buffer.asUint8List());
    if (!mounted) return;
    await shareAndCount(
      ref,
      ShareParams(files: [XFile(f.path)], text: 'My week on Grab 💛'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final s = WeeklyStats.of(ref.watch(jobsProvider).value ?? const [], now);
    final streak = ref.watch(gameProvider).liveStreak(now);
    if (s.files == 0) return const SizedBox.shrink();
    final most = s.perDay.fold(1, (a, b) => a > b ? a : b);
    // Day letters for the last seven days, ending today.
    final letters = [
      for (var i = 6; i >= 0; i--)
        _days[now.subtract(Duration(days: i)).weekday - 1],
    ];
    return RepaintBoundary(
      key: _shot,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF9FD8FF),
          borderRadius: Pop.cardRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR WEEK',
                    style: TextStyle(
                      color: Pop.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.files} grab${s.files == 1 ? '' : 's'}'
                    '${s.topSite == null ? '' : ' · mostly ${s.topSite}'}',
                    style: const TextStyle(
                      color: Pop.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    '${s.days} of 7 days'
                    '${streak > 1 ? ' · $streak-day streak 🔥' : ''}',
                    style: TextStyle(
                      color: Pop.ink.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 46,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: FractionallySizedBox(
                                      heightFactor: s.perDay[i] == 0
                                          ? 0.08
                                          : s.perDay[i] / most,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: i == 6 ? Pop.yellow : Pop.ink,
                                          border: i == 6
                                              ? Border.all(
                                                  color: Pop.ink,
                                                  width: 1.5,
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    letters[i],
                                    style: const TextStyle(
                                      color: Pop.ink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                DressedBuddy(
                  mood: s.days >= 5 ? BuddyMood.cheer : BuddyMood.happy,
                  hat: Rewards.hat.value,
                  size: 76,
                ),
                IconButton.filled(
                  tooltip: 'Share my week',
                  style: IconButton.styleFrom(
                    backgroundColor: Pop.ink,
                    foregroundColor: Pop.yellow,
                  ),
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
