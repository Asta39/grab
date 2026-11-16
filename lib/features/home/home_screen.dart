import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../data/engine/media_info.dart';
import 'fetch_controller.dart';

/// Home: paste a link, fetch it, choose what to download.
/// Pop styling and motion are finished in milestone 3.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onQueued});

  /// Called after a download is queued (the shell switches to Downloads).
  final VoidCallback? onQueued;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _url.text = data!.text!.trim();
    _fetch();
  }

  void _fetch() {
    FocusScope.of(context).unfocus();
    ref.read(fetchControllerProvider.notifier).fetch(_url.text);
  }

  Future<void> _download() async {
    final id = await ref.read(fetchControllerProvider.notifier).download();
    if (id == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to downloads')));
    widget.onQueued?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(fetchControllerProvider);
    final c = ref.read(fetchControllerProvider.notifier);
    final version = ref.watch(engineVersionProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Grab', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Paste a link.\nGet the file.', style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: Pop.ink, height: 1.05)),
          const SizedBox(height: 20),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _fetch(),
            decoration: InputDecoration(
              hintText: 'TikTok, YouTube, Instagram, Pinterest…',
              suffixIcon: IconButton(onPressed: _paste, tooltip: 'Paste and fetch', icon: const Icon(Icons.content_paste_rounded)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: s.info.isLoading ? null : _fetch,
            child: Text(s.info.isLoading ? 'Fetching…' : 'Fetch'),
          ),
          const SizedBox(height: 8),
          Text(
            version.when(
              data: (v) => 'Engine: yt-dlp ${v ?? 'unknown'}',
              loading: () => 'Starting engine…',
              error: (e, _) => 'Engine failed to start: $e',
            ),
            style: text.bodySmall?.copyWith(color: Pop.muted),
          ),
          ...switch (s.info) {
            AsyncError(:final error) => [const SizedBox(height: 16), _ErrorBox(message: '$error', onRetry: _fetch)],
            AsyncData(:final value?) => _choose(context, value, s, c),
            _ => const <Widget>[],
          },
        ],
      ),
    );
  }

  List<Widget> _choose(BuildContext context, MediaInfo info, FetchState s, FetchController c) {
    final text = Theme.of(context).textTheme;
    return [
      const SizedBox(height: 24),
      if (info.thumbnail != null)
        ClipRRect(
          borderRadius: Pop.cardRadius,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(info.thumbnail!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: Pop.softYellow)),
          ),
        ),
      const SizedBox(height: 12),
      Text(info.title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      Text([info.site, info.uploader, if (info.isPlaylist) '${info.entryCount} items'].whereType<String>().join(' · '),
          style: text.bodyMedium?.copyWith(color: Pop.muted)),
      const SizedBox(height: 16),
      SegmentedButton<DownloadMode>(
        showSelectedIcon: false,
        segments: [
          const ButtonSegment(value: DownloadMode.videoAndAudio, label: Text('Video')),
          const ButtonSegment(value: DownloadMode.videoOnly, label: Text('No sound')),
          const ButtonSegment(value: DownloadMode.audioOnly, label: Text('Audio')),
          if (info.subtitles.isNotEmpty) const ButtonSegment(value: DownloadMode.subtitlesOnly, label: Text('Subs')),
        ],
        selected: {s.mode},
        onSelectionChanged: (v) => c.setMode(v.first),
      ),
      const SizedBox(height: 8),
      if (s.mode != DownloadMode.subtitlesOnly)
        RadioGroup<int>(
          groupValue: s.optionIndex,
          onChanged: (v) => c.setOption(v ?? 0),
          child: Column(children: [
            for (final (i, o) in s.options.indexed)
              RadioListTile<int>(value: i, title: Text(o.label), secondary: Text(formatBytes(o.bytes) ?? '')),
          ]),
        ),
      if (s.mode != DownloadMode.audioOnly) ..._subtitles(context, info, s, c),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: s.canDownload ? _download : null,
        child: Text(switch (s.mode) {
          DownloadMode.subtitlesOnly => s.subLangs.isEmpty ? 'Pick a language' : 'Download subtitles',
          _ => ['Download', ?formatBytes(s.selected?.bytes)].join(' · '),
        }),
      ),
    ];
  }

  List<Widget> _subtitles(BuildContext context, MediaInfo info, FetchState s, FetchController c) {
    if (info.subtitles.isEmpty) {
      return [
        const SizedBox(height: 8),
        Text('No subtitles available for this link.', style: TextStyle(color: Pop.muted)),
      ];
    }
    return [
      const SizedBox(height: 16),
      Text('SUBTITLES', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Pop.muted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in info.subtitles)
          FilterChip(
            label: Text(t.auto ? '${t.name} · auto' : t.name),
            selected: s.subLangs.contains(t.lang),
            onSelected: (_) => c.toggleLang(t.lang),
          ),
      ]),
      if (s.mode != DownloadMode.subtitlesOnly && s.subLangs.isNotEmpty)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Put subtitles inside the video'),
          subtitle: const Text('Off: saved next to it as .srt files'),
          value: s.embedSubs,
          onChanged: c.setEmbed,
        ),
    ];
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFE4E4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Couldn't read that link", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SelectableText(message),
          Row(children: [
            TextButton(onPressed: onRetry, child: const Text('Try again')),
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: message)),
              child: const Text('Copy error'),
            ),
          ]),
        ]),
      ),
    );
  }
}
