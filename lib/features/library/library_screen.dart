import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../core/widgets/toasts.dart';
import '../detail/download_detail_screen.dart';
import 'library_items.dart';
import 'player_screen.dart';

/// Every saved file that still exists on the phone.
final libraryProvider = Provider<List<LibraryItem>>((ref) {
  final jobs = ref.watch(jobsProvider).value ?? const [];
  return buildLibrary(jobs, exists: (p) => File(p).existsSync());
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryKind? _kind;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(libraryProvider);
    final items = filterLibrary(all, kind: _kind, query: _query);
    final still = Pop.reduceMotion(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              sliver: SliverList.list(
                children: [
                  const Text(
                    'Library',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search downloads',
                      prefixIcon: Icon(Icons.search_rounded),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PopSegmented<LibraryKind?>(
                    values: const [
                      null,
                      LibraryKind.video,
                      LibraryKind.audio,
                      LibraryKind.subtitles,
                    ],
                    labels: const ['All', 'Video', 'Audio', 'Subs'],
                    selected: _kind,
                    onChanged: (k) => setState(() => _kind = k),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  child: Column(
                    children: [
                      Icon(
                        all.isEmpty
                            ? Icons.video_library_rounded
                            : Icons.search_off_rounded,
                        size: 44,
                        color: context.pop.muted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        all.isEmpty
                            ? 'Your downloads show up here'
                            : 'Nothing matches',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, i) {
                    final tile = _Tile(item: items[i]);
                    return still
                        ? tile
                        : tile
                              .animate()
                              .fadeIn(
                                duration: Pop.medium,
                                delay: (30 * (i % 10)).ms,
                              )
                              .scaleXY(
                                begin: 0.94,
                                end: 1,
                                curve: Curves.easeOutBack,
                              );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = item.kind == LibraryKind.subtitles;
    return Semantics(
      button: true,
      label: '${item.title}, ${item.ext}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: Pop.thumbRadius,
        onTap: () => openDownload(context, item.jobId),
        onLongPress: () => _actions(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: subs
                        ? Container(
                            decoration: BoxDecoration(
                              color: context.pop.soft,
                              borderRadius: Pop.thumbRadius,
                            ),
                            child: Icon(
                              Icons.subtitles_rounded,
                              size: 40,
                              color: context.pop.text,
                            ),
                          )
                        : PopThumb(
                            seed: item.jobId,
                            url: item.thumbnail,
                            audio: item.kind == LibraryKind.audio,
                            size: double.infinity,
                          ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: const ShapeDecoration(
                        shape: StadiumBorder(),
                        color: Pop.ink,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          item.ext,
                          style: const TextStyle(
                            color: Pop.yellow,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(
                      tooltip: 'More',
                      onPressed: () => _actions(context, ref),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              [
                item.site,
                fileSizeLabel(item.path),
              ].whereType<String>().join(' · '),
              style: TextStyle(color: context.pop.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.fileName,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (item.kind != LibraryKind.subtitles)
                ListTile(
                  leading: const Icon(Icons.play_arrow_rounded),
                  title: const Text('Play'),
                  onTap: () => Navigator.pop(context, 'play'),
                ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Pop.error,
                ),
                title: const Text(
                  'Delete file',
                  style: TextStyle(color: Pop.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'play':
        openPlayer(context, item);
      case 'share':
        await SharePlus.instance.share(
          ShareParams(files: [XFile(item.path)], subject: item.title),
        );
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this file?'),
            content: Text(
              '${item.fileName}\n\nIt will be removed from your phone. This can\'t be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Pop.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
        if (ok != true) return;
        try {
          await File(item.path).delete();
          ref.invalidate(libraryProvider);
          popToast(
            'Deleted',
            icon: Icons.delete_rounded,
            detail: item.fileName,
          );
        } catch (e) {
          popToast("Couldn't delete", error: true, detail: '$e');
        }
    }
  }
}
