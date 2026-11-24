import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../club/game.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/widgets/morph.dart';
import '../../core/widgets/dock_inset.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';
import '../../data/repositories/download_repository.dart';
import '../detail/download_detail_screen.dart';

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
            final running = all
                .where((j) => j.status == JobStatus.running)
                .length;
            final waiting = all
                .where((j) => j.status == JobStatus.queued)
                .length;
            final paused = all
                .where((j) => j.status == JobStatus.paused)
                .length;
            final offline = all
                .where((j) => j.status == JobStatus.waiting)
                .length;
            final active = all.where((j) => _isActive(j.status)).toList();
            final history = all.where((j) => !active.contains(j)).toList();
            return ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                DockInset.listBottom(context),
              ),
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Downloads',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  active.isEmpty
                      ? 'Nothing running'
                      : [
                          '$running active',
                          if (waiting > 0) '$waiting waiting',
                          if (paused > 0) '$paused paused',
                          if (offline > 0) '$offline need connection',
                        ].join(' · '),
                  style: TextStyle(color: context.pop.muted, fontSize: 15),
                ),
                const SizedBox(height: 20),
                if (all.isEmpty) const _Empty(),
                for (final j in active) _JobCard(key: ValueKey(j.id), job: j),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const PopSection('History'),
                  for (final j in history)
                    _JobCard(key: ValueKey(j.id), job: j),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _isActive(JobStatus s) =>
    s == JobStatus.running ||
    s == JobStatus.queued ||
    s == JobStatus.paused ||
    s == JobStatus.waiting;

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.pop.soft,
        borderRadius: Pop.cardRadius,
      ),
      child: Column(
        children: [
          Image.asset('assets/buddy/sleep.png', width: 110, height: 110),
          SizedBox(height: 10),
          Text(
            'Quiet in here… zzz',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Wake me up with a link: paste one on Home, shake your phone, or share one to Grab from TikTok, YouTube or Pinterest.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.pop.muted),
          ),
        ],
      ),
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
        DownloadMode.video => 'Video',
        DownloadMode.videoAndAudio => 'Video + audio file',
        DownloadMode.audioOnly => 'Audio · ${job.audioFormat.toUpperCase()}',
        DownloadMode.subtitlesOnly => 'Subtitles · ${job.subLangs}',
      },
      if (job.maxHeight != null &&
          (mode == DownloadMode.video || mode == DownloadMode.videoAndAudio))
        '${job.maxHeight}p',
      if (job.subLangs.isNotEmpty && mode != DownloadMode.subtitlesOnly)
        'subs ${job.subLangs}',
      if (job.trimStart != null || job.trimEnd != null)
        'clip ${clockLabel(job.trimStart ?? 0)}–${job.trimEnd == null ? 'end' : clockLabel(job.trimEnd!)}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(downloadRepositoryProvider);
    final files = job.paths.isEmpty ? const <String>[] : job.paths.split('\n');
    final active = _isActive(job.status);
    final pct = job.progress.toStringAsFixed(0);
    final still = Pop.reduceMotion(context);

    final playful = ref.watch(gameProvider.select((g) => g.enabled));
    final status = switch (job.status) {
      JobStatus.queued => playful ? 'In line, stretching…' : 'Waiting',
      JobStatus.running when job.progress >= 100 =>
        playful ? 'Tying the bow… 🎁' : 'Finishing…',
      JobStatus.running => [
        if (playful) cheerFor(job.progress),
        job.progress <= 0
            ? (playful ? '' : 'Starting…')
            : '${job.progress.toStringAsFixed(0)}%',
        ?ref.watch(speedsProvider).value?[job.id],
        if (job.eta != null && job.eta! > 0) '${_eta(job.eta!)} left',
      ].where((x) => x.isNotEmpty).join(' · '),
      JobStatus.done =>
        files.isEmpty ? 'Saved' : files.map(p.basename).join('\n'),
      JobStatus.failed => job.error ?? 'Failed',
      JobStatus.canceled => 'Canceled',
      JobStatus.paused => job.progress > 0 ? 'Paused at $pct%' : 'Paused',
      JobStatus.waiting =>
        'Connection lost · trying again by itself (${job.attempts} of ${DownloadRepository.maxAutoRetries})',
    };

    final card = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 14),
      decoration: BoxDecoration(
        color: job.status == JobStatus.running
            ? context.pop.soft
            : context.pop.card,
        borderRadius: Pop.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PopThumb(
                seed: job.id,
                url: job.thumbnail,
                audio: _mode == DownloadMode.audioOnly,
                size: 96,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (job.site != null)
                      Text(
                        job.site!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pop.muted,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    PopTag(
                      _what,
                      // The running card is soft yellow itself.
                      color: job.status == JobStatus.running
                          ? context.pop.bg
                          : null,
                    ),
                  ],
                ),
              ),
              _StatusIcon(
                job: job,
                onCancel: () => repo.cancel(job.id),
                onRetry: () => repo.retry(job.id),
                onPause: () => repo.pause(job.id),
                onResume: () => repo.unpause(job.id),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: PopProgressBar(
                value: job.status == JobStatus.queued && job.progress == 0
                    ? null
                    : job.progress / 100,
                track: job.status == JobStatus.running
                    ? context.pop.trackOnSoft
                    : context.pop.track,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    status,
                    maxLines: job.status == JobStatus.failed ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: job.status == JobStatus.failed
                          ? Pop.error
                          : context.pop.muted,
                    ),
                  ),
                ),
                if (active && job.status != JobStatus.running)
                  GestureDetector(
                    onTap: () => repo.cancel(job.id),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                if (!active)
                  GestureDetector(
                    onTap: () => repo.remove(job.id),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    // Finished cards grow into their detail page when tapped.
    final tappable = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: active
          ? card
          : Morph(
              color: context.pop.card,
              page: (_) => DownloadDetailScreen(jobId: job.id),
              builder: (context, open) => GestureDetector(
                onTap: open,
                behavior: HitTestBehavior.opaque,
                child: card,
              ),
            ),
    );
    return still
        ? tappable
        : tappable
              .animate()
              .fadeIn(duration: Pop.medium)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  static String _eta(int s) => s >= 60 ? '${s ~/ 60}m ${s % 60}s' : '${s}s';
}

/// Cancel while running, a check that pops in when done, retry after a failure.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.job,
    required this.onCancel,
    required this.onRetry,
    required this.onPause,
    required this.onResume,
  });

  final DownloadJob job;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (job.status) {
      JobStatus.running => PopIconButton(
        key: const ValueKey('pause'),
        icon: Icons.pause_rounded,
        tooltip: 'Pause download',
        background: context.pop.bg,
        onPressed: onPause,
      ),
      JobStatus.queued || JobStatus.waiting => PopIconButton(
        key: const ValueKey('pause-waiting'),
        icon: Icons.pause_rounded,
        tooltip: 'Pause download',
        background: context.pop.bg,
        onPressed: onPause,
      ),
      JobStatus.paused => PopIconButton(
        key: const ValueKey('resume'),
        icon: Icons.play_arrow_rounded,
        tooltip: 'Resume download',
        background: context.pop.strong,
        foreground: context.pop.onStrong,
        onPressed: onResume,
      ),
      JobStatus.done => SizedBox(
        key: const ValueKey('done'),
        width: 48,
        height: 48,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            color: context.pop.strong,
          ),
          child: Icon(
            Icons.check_rounded,
            color: context.pop.onStrong,
            semanticLabel: 'Done',
          ),
        ),
      ),
      JobStatus.failed || JobStatus.canceled => PopIconButton(
        key: const ValueKey('retry'),
        icon: Icons.refresh_rounded,
        tooltip: 'Try again',
        background: context.pop.bg,
        onPressed: onRetry,
      ),
    };
    return AnimatedSwitcher(
      duration: Pop.reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 420),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (c, a) => ScaleTransition(
        scale: a,
        child: RotationTransition(
          turns: Tween(begin: -0.15, end: 0.0).animate(a),
          child: c,
        ),
      ),
      child: child,
    );
  }
}
