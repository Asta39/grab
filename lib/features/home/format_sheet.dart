import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../core/widgets/toasts.dart';
import '../../data/engine/media_info.dart';
import 'fetch_controller.dart';

/// Opens the Choose format sheet for the fetched link.
/// Returns true when a download was queued.
Future<bool> showFormatSheet(BuildContext context) async {
  final queued = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FormatSheet(),
  );
  return queued ?? false;
}

class FormatSheet extends ConsumerWidget {
  const FormatSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(fetchControllerProvider);
    final c = ref.read(fetchControllerProvider.notifier);
    final info = s.info.value;
    if (info == null) return const SizedBox(height: 200);

    final modes = [
      DownloadMode.videoAndAudio,
      DownloadMode.videoOnly,
      DownloadMode.audioOnly,
      if (info.subtitles.isNotEmpty) DownloadMode.subtitlesOnly,
    ];
    const labels = {
      DownloadMode.videoAndAudio: 'Video',
      DownloadMode.videoOnly: 'No sound',
      DownloadMode.audioOnly: 'Audio',
      DownloadMode.subtitlesOnly: 'Subs',
    };
    final still = Pop.reduceMotion(context);

    Future<void> download() async {
      final id = await c.download();
      if (id == null || !context.mounted) return;
      HapticFeedback.mediumImpact();
      popToast('Added to downloads', icon: Icons.download_rounded, detail: info.title);
      Navigator.of(context).pop(true);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          const Text('Choose format', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Stack(children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: PopThumb(seed: info.url, url: info.thumbnail, size: double.infinity, radius: Pop.cardRadius),
            ),
            if (info.duration != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: const ShapeDecoration(shape: StadiumBorder(), color: Pop.ink),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(_duration(info.duration!), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          Text(info.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.15)),
          const SizedBox(height: 4),
          Text([info.site, info.uploader, if (info.isPlaylist) '${info.entryCount} items'].whereType<String>().join(' · '),
              style: const TextStyle(color: Pop.muted)),
          const SizedBox(height: 18),
          PopSegmented<DownloadMode>(
            values: modes,
            labels: [for (final m in modes) labels[m]!],
            selected: s.mode,
            onChanged: c.setMode,
          ),
          const SizedBox(height: 18),
          if (s.mode != DownloadMode.subtitlesOnly) ...[
            PopSection(s.mode == DownloadMode.audioOnly ? 'Audio' : 'Quality'),
            for (final (i, o) in s.options.indexed)
              _OptionTile(
                label: o.label,
                size: formatBytes(o.bytes),
                selected: i == s.optionIndex.clamp(0, s.options.length - 1),
                onTap: () => c.setOption(i),
              )
                  .animate(target: still ? null : 1)
                  .fadeIn(duration: Pop.medium, delay: (40 * i).ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
          ],
          if (s.mode != DownloadMode.audioOnly) ..._subtitles(info, s, c),
          const SizedBox(height: 24),
          PopButton(
            label: switch (s.mode) {
              DownloadMode.subtitlesOnly => s.subLangs.isEmpty ? 'Pick a language' : 'Download subtitles',
              _ => ['Download', ?formatBytes(s.selected?.bytes)].join(' · '),
            },
            icon: Icons.download_rounded,
            onPressed: s.canDownload ? download : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _subtitles(MediaInfo info, FetchState s, FetchController c) {
    if (info.subtitles.isEmpty) {
      return const [
        SizedBox(height: 8),
        Text('No subtitles for this link.', style: TextStyle(color: Pop.muted)),
      ];
    }
    return [
      const SizedBox(height: 12),
      const PopSection('Subtitles'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in info.subtitles)
          FilterChip(
            label: Text(t.auto ? '${t.name} · auto' : t.name),
            selected: s.subLangs.contains(t.lang),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              c.toggleLang(t.lang);
            },
          ),
      ]),
      if (s.mode != DownloadMode.subtitlesOnly && s.subLangs.isNotEmpty)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Put subtitles inside the video', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Off: saved next to it as .srt files'),
          value: s.embedSubs,
          onChanged: c.setEmbed,
        ),
    ];
  }

  static String _duration(double seconds) {
    final d = Duration(seconds: seconds.round());
    final m = d.inMinutes.remainder(60).toString().padLeft(d.inHours > 0 ? 2 : 1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.size, required this.selected, required this.onTap});

  final String label;
  final String? size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: Pop.cardRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: Pop.fast,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: selected ? Pop.softYellow : Pop.card,
              borderRadius: Pop.cardRadius,
              border: Border.all(color: selected ? Pop.ink : Colors.transparent, width: 2),
            ),
            child: Row(children: [
              AnimatedSwitcher(
                duration: Pop.fast,
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  key: ValueKey(selected),
                  color: Pop.ink,
                ),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (size != null) Text(size!, style: const TextStyle(color: Pop.muted, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}
