import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/utils/links.dart';
import '../../core/widgets/morph.dart';
import '../../core/widgets/dock_inset.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../data/db/app_database.dart';
import '../../data/engine/media_info.dart';
import '../detail/download_detail_screen.dart';
import 'fetch_controller.dart';
import 'format_sheet.dart';
import 'playlist_sheet.dart';
import '../../core/utils/haptics.dart';

/// Home: paste or share a link, fetch it, then choose a format in the sheet.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onQueued, this.onFetch});

  /// Called after a download is queued (the shell switches to Downloads).
  final VoidCallback? onQueued;

  /// Called whenever a link starts fetching, however it got here.
  final ValueChanged<String>? onFetch;

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final _url = TextEditingController();

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  /// Fills the field with [link] and fetches it. Used by paste, share and the clipboard offer.
  void fetchLink(String link) {
    _url.text = link;
    _fetch();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final link = extractLink(data?.text) ?? data?.text?.trim();
    if (link == null || link.isEmpty) return;
    fetchLink(link);
  }

  /// Format sheet for one item; the picker for a playlist or profile.
  Future<void> _choose(MediaInfo info) async {
    final queued = info.isPlaylist && info.entries.isNotEmpty
        ? await showPlaylistSheet(context, info)
        : await showFormatSheet(context);
    if (queued) widget.onQueued?.call();
  }

  void _fetch() {
    FocusScope.of(context).unfocus();
    final link = extractLink(_url.text) ?? _url.text.trim();
    if (link.isEmpty) return;
    if (link != _url.text) _url.text = link;
    widget.onFetch?.call(link);
    ref.read(fetchControllerProvider.notifier).fetch(link);
  }

  @override
  Widget build(BuildContext context) {
    // Open the format sheet as soon as a fetch succeeds.
    ref.listen(fetchControllerProvider.select((s) => s.info), (
      prev,
      next,
    ) async {
      if (prev is AsyncLoading && next is AsyncData && next.value != null) {
        Haptics.light();
        await _choose(next.value!);
      }
    });

    final s = ref.watch(fetchControllerProvider);
    final version = ref.watch(engineVersionProvider);
    final recent = (ref.watch(jobsProvider).value ?? const <DownloadJob>[])
        .where((j) => j.status == JobStatus.done)
        .take(3)
        .toList();
    final detected = platformOf(extractLink(_url.text) ?? _url.text);
    final still = Pop.reduceMotion(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            DockInset.listBottom(context),
          ),
          children: [
            Row(
              children: [
                const Text(
                  'Grab',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                PopIconButton(
                  icon: Icons.content_paste_rounded,
                  tooltip: 'Paste link and fetch',
                  onPressed: _paste,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 112,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Text(
                        'Paste a link.\nGet the file.',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                          letterSpacing: -0.6,
                        ),
                      )
                      .animate(target: still ? null : 1)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _LinkField(
              controller: _url,
              busy: s.info.isLoading,
              onFetch: _fetch,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in platforms)
                  _PlatformChip(label: p, active: p == detected),
                const _PlatformChip(label: '+ 1,800 more', active: false),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              version.when(
                data: (v) => 'yt-dlp ${v ?? ''}',
                loading: () => 'Starting engine…',
                error: (e, _) => 'Engine failed to start',
              ),
              style: TextStyle(fontSize: 12, color: context.pop.muted),
            ),
            ...switch (s.info) {
              AsyncLoading() => [
                const SizedBox(height: 24),
                const _FetchingCard(),
              ],
              AsyncError(:final error) => [
                const SizedBox(height: 24),
                _ErrorCard(message: '$error', onRetry: _fetch),
              ],
              AsyncData(:final value?) => [
                const SizedBox(height: 24),
                _ReadyCard(info: value, onOpen: () => _choose(value)),
              ],
              _ => const <Widget>[],
            },
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 28),
              const PopSection('Recent'),
              for (final (i, j) in recent.indexed)
                _RecentRow(job: j)
                    .animate(target: still ? null : 1)
                    .fadeIn(duration: Pop.medium, delay: (60 * i).ms)
                    .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill text field with the Fetch button inside it.
class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.controller,
    required this.busy,
    required this.onFetch,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: context.pop.field,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => onFetch(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: 'Paste a video link',
                filled: false,
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty && !busy)
            IconButton(
              tooltip: 'Clear',
              onPressed: controller.clear,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          PopButton(
            label: 'Fetch',
            onPressed: onFetch,
            busy: busy,
            expand: false,
            height: 48,
          ),
        ],
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Pop.medium,
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: active ? context.pop.strong : context.pop.soft,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? context.pop.onStrong : context.pop.text,
        ),
      ),
    );
  }
}

/// Placeholder while yt-dlp reads the link.
class _FetchingCard extends StatelessWidget {
  const _FetchingCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: context.pop.track,
        borderRadius: BorderRadius.circular(h),
      ),
    );
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.pop.card,
        borderRadius: Pop.cardRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.pop.track,
              borderRadius: Pop.thumbRadius,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(double.infinity, 14),
                const SizedBox(height: 10),
                bar(120, 12),
                const SizedBox(height: 10),
                Text(
                  'Reading the link…',
                  style: TextStyle(color: context.pop.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (Pop.reduceMotion(context)) return card;
    return card
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: context.pop.bg);
  }
}

/// Shown after a fetch, in case the sheet was closed without downloading.
class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.info, required this.onOpen});

  final MediaInfo info;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: Pop.cardRadius,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.pop.soft,
          borderRadius: Pop.cardRadius,
        ),
        child: Row(
          children: [
            PopThumb(seed: info.url, url: info.thumbnail, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.isPlaylist
                        ? 'Pick from ${info.entries.length} items'
                        : 'Choose format',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
          decoration: BoxDecoration(
            color: context.pop.errorSoft,
            borderRadius: Pop.cardRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Couldn't read that link",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(message, maxLines: 4, overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  TextButton(
                    onPressed: onRetry,
                    child: const Text(
                      'Try again',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: message)),
                    child: const Text('Copy error'),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(target: Pop.reduceMotion(context) ? null : 1)
        .shakeX(hz: 4, amount: 4, duration: 350.ms);
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.job});

  final DownloadJob job;

  @override
  Widget build(BuildContext context) {
    final mode = DownloadMode.values.byName(job.mode);
    final audio = mode == DownloadMode.audioOnly;
    final what = switch (mode) {
      DownloadMode.audioOnly => job.audioFormat.toUpperCase(),
      DownloadMode.subtitlesOnly => 'Subtitles',
      _ => [
        job.container.toUpperCase(),
        if (job.maxHeight != null) '${job.maxHeight}p',
      ].join(' · '),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Morph(
        color: context.pop.card,
        page: (_) => DownloadDetailScreen(jobId: job.id),
        builder: (context, open) => InkWell(
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                PopThumb(
                  seed: job.id,
                  url: job.thumbnail,
                  audio: audio,
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
                          style: TextStyle(
                            color: context.pop.muted,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 8),
                      PopTag(what),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, semanticLabel: 'Open'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
