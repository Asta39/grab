import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';

/// Downloads: active and queued jobs on top, finished below.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24))),
      body: jobs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          if (all.isEmpty) {
            return const Center(child: Text('Nothing yet. Paste a link on Home.'));
          }
          final active = all.where((j) => j.status == JobStatus.running || j.status == JobStatus.queued).toList();
          final rest = all.where((j) => !active.contains(j)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              for (final j in active) _JobCard(job: j),
              if (rest.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Text('HISTORY', style: TextStyle(color: Pop.muted, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                ),
                for (final j in rest) _JobCard(job: j),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job});

  final DownloadJob job;

  String get _what {
    final mode = DownloadMode.values.byName(job.mode);
    final parts = [
      switch (mode) {
        DownloadMode.videoAndAudio => 'Video + audio',
        DownloadMode.videoOnly => 'Video only',
        DownloadMode.audioOnly => 'Audio · ${job.audioFormat.toUpperCase()}',
        DownloadMode.subtitlesOnly => 'Subtitles only',
      },
      if (job.maxHeight != null && mode != DownloadMode.audioOnly && mode != DownloadMode.subtitlesOnly) '${job.maxHeight}p',
      if (job.subLangs.isNotEmpty && mode != DownloadMode.subtitlesOnly) 'subs ${job.subLangs}${job.subEmbed ? ' (inside)' : ''}',
      if (mode == DownloadMode.subtitlesOnly) job.subLangs,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(downloadRepositoryProvider);
    final files = job.paths.isEmpty ? const <String>[] : job.paths.split('\n');
    final status = switch (job.status) {
      JobStatus.queued => 'Waiting',
      JobStatus.running => job.progress >= 100
          ? 'Finishing…'
          : '${job.progress.toStringAsFixed(0)}%${job.eta != null && job.eta! > 0 ? ' · ${job.eta}s left' : ''}',
      JobStatus.done => 'Saved ${files.length} file${files.length == 1 ? '' : 's'}',
      JobStatus.failed => 'Failed',
      JobStatus.canceled => 'Canceled',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text([job.site, _what].whereType<String>().join(' · '), style: const TextStyle(color: Pop.muted, fontSize: 13)),
              ]),
            ),
            ...switch (job.status) {
              JobStatus.queued || JobStatus.running => [
                  IconButton(tooltip: 'Cancel', onPressed: () => repo.cancel(job.id), icon: const Icon(Icons.close_rounded)),
                ],
              JobStatus.failed || JobStatus.canceled => [
                  IconButton(tooltip: 'Retry', onPressed: () => repo.retry(job.id), icon: const Icon(Icons.refresh_rounded)),
                  IconButton(tooltip: 'Remove', onPressed: () => repo.remove(job.id), icon: const Icon(Icons.delete_outline_rounded)),
                ],
              JobStatus.done => [
                  IconButton(tooltip: 'Remove from list', onPressed: () => repo.remove(job.id), icon: const Icon(Icons.delete_outline_rounded)),
                ],
            },
          ]),
          if (job.status == JobStatus.running || job.status == JobStatus.queued) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: job.status == JobStatus.queued ? 0 : (job.progress / 100).clamp(0, 1),
                  backgroundColor: const Color(0xFFEFEFEF),
                  color: Pop.ink,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(status, style: const TextStyle(fontSize: 12, color: Pop.muted)),
          if (job.error != null) SelectableText(job.error!, style: const TextStyle(fontSize: 12, color: Color(0xFFB00020))),
          for (final f in files) Text(p.basename(f), style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
