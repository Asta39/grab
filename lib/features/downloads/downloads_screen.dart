import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';

/// Downloads: active and waiting jobs on top, history below.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: jobs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
            final running = all.where((j) => j.status == JobStatus.running).length;
            final waiting = all.where((j) => j.status == JobStatus.queued).length;
            final active = all.where((j) => j.status == JobStatus.running || j.status == JobStatus.queued).toList();
            final history = all.where((j) => !active.contains(j)).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
              children: [
                const SizedBox(height: 6),
                const Text('Downloads', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                const SizedBox(height: 2),
                Text(
                  active.isEmpty ? 'Nothing running' : '$running active · $waiting waiting',
                  style: const TextStyle(color: Pop.muted, fontSize: 15),
                ),
                const SizedBox(height: 20),
                if (all.isEmpty) const _Empty(),
                for (final j in active) _JobCard(key: ValueKey(j.id), job: j),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const PopSection('History'),
                  for (final j in history) _JobCard(key: ValueKey(j.id), job: j),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(color: Pop.softYellow, borderRadius: Pop.cardRadius),
      child: const Column(children: [
        Icon(Icons.download_rounded, size: 40),
        SizedBox(height: 10),
        Text('Nothing here yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        Text('Paste a link on Home, or share one to Grab from TikTok, YouTube or Pinterest.',
            textAlign: TextAlign.center, style: TextStyle(color: Pop.muted)),
      ]),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({super.key, required this.job});

  final DownloadJob job;

  DownloadMode get _mode => DownloadMode.values.byName(job.mode);

  String get _what {
    final mode = _mode;
    return [
      switch (mode) {
        DownloadMode.videoAndAudio => 'Video + audio',
        DownloadMode.videoOnly => 'No sound',
        DownloadMode.audioOnly => 'Audio · ${job.audioFormat.toUpperCase()}',
        DownloadMode.subtitlesOnly => 'Subtitles · ${job.subLangs}',
      },
      if (job.maxHeight != null && (mode == DownloadMode.videoAndAudio || mode == DownloadMode.videoOnly)) '${job.maxHeight}p',
      if (job.subLangs.isNotEmpty && mode != DownloadMode.subtitlesOnly) 'subs ${job.subLangs}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(downloadRepositoryProvider);
    final files = job.paths.isEmpty ? const <String>[] : job.paths.split('\n');
    final active = job.status == JobStatus.running || job.status == JobStatus.queued;
    final still = Pop.reduceMotion(context);

    final status = switch (job.status) {
      JobStatus.queued => 'Waiting',
      JobStatus.running when job.progress >= 100 => 'Finishing…',
      JobStatus.running => '${job.progress.toStringAsFixed(0)}%${job.eta != null && job.eta! > 0 ? ' · ${_eta(job.eta!)} left' : ''}',
      JobStatus.done => files.isEmpty ? 'Saved' : files.map(p.basename).join('\n'),
      JobStatus.failed => job.error ?? 'Failed',
      JobStatus.canceled => 'Canceled',
    };

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 14),
      decoration: BoxDecoration(
        color: job.status == JobStatus.running ? Pop.softYellow : Pop.card,
        borderRadius: Pop.cardRadius,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          PopThumb(seed: job.id, url: job.thumbnail, audio: _mode == DownloadMode.audioOnly, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text([job.site, _what].whereType<String>().join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Pop.muted, fontSize: 13)),
            ]),
          ),
          _StatusIcon(job: job, onCancel: () => repo.cancel(job.id), onRetry: () => repo.retry(job.id)),
        ]),
        if (active) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PopProgressBar(
              value: job.status == JobStatus.queued ? null : job.progress / 100,
              track: job.status == JobStatus.running ? Colors.white : Pop.track,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(status,
                  maxLines: job.status == JobStatus.failed ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: job.status == JobStatus.failed ? Pop.error : Pop.muted)),
            ),
            if (!active)
              GestureDetector(
                onTap: () => repo.remove(job.id),
                child: const Text('Remove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
              ),
          ]),
        ),
      ]),
    );
    return still ? card : card.animate().fadeIn(duration: Pop.medium).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  static String _eta(int s) => s >= 60 ? '${s ~/ 60}m ${s % 60}s' : '${s}s';
}

/// Cancel while running, a check that pops in when done, retry after a failure.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.job, required this.onCancel, required this.onRetry});

  final DownloadJob job;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (job.status) {
      JobStatus.queued || JobStatus.running => PopIconButton(
          key: const ValueKey('cancel'),
          icon: Icons.close_rounded,
          tooltip: 'Cancel download',
          background: Colors.white,
          onPressed: onCancel,
        ),
      JobStatus.done => const SizedBox(
          key: ValueKey('done'),
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: ShapeDecoration(shape: CircleBorder(), color: Pop.ink),
            child: Icon(Icons.check_rounded, color: Pop.yellow, semanticLabel: 'Done'),
          ),
        ),
      JobStatus.failed || JobStatus.canceled => PopIconButton(
          key: const ValueKey('retry'),
          icon: Icons.refresh_rounded,
          tooltip: 'Try again',
          background: Colors.white,
          onPressed: onRetry,
        ),
    };
    return AnimatedSwitcher(
      duration: Pop.reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 420),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: RotationTransition(turns: Tween(begin: -0.15, end: 0.0).animate(a), child: c)),
      child: child,
    );
  }
}
