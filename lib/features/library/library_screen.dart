import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/audio/audio_playback.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/dock_inset.dart';
import '../../core/widgets/morph.dart';
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
  late var _sort =
      LibrarySort.values.asNameMap()[ref
          .read(sharedPrefsProvider)
          .getString('librarySort')] ??
      LibrarySort.newest;
  late var _group =
      ref.read(sharedPrefsProvider).getBool('libraryGroup') ?? false;

  /// Paths picked in selection mode; empty = not selecting.
  final _picked = <String>{};
  bool get _selecting => _picked.isNotEmpty;

  void _setSort(LibrarySort s) {
    Haptics.selection();
    setState(() => _sort = s);
    ref.read(sharedPrefsProvider).setString('librarySort', s.name);
  }

  void _setGroup(bool g) {
    Haptics.selection();
    setState(() => _group = g);
    ref.read(sharedPrefsProvider).setBool('libraryGroup', g);
  }

  void _toggle(LibraryItem i) {
    Haptics.selection();
    setState(
      () => _picked.contains(i.path)
          ? _picked.remove(i.path)
          : _picked.add(i.path),
    );
  }

  Future<void> _shareSelected(List<LibraryItem> all) async {
    final files = [
      for (final i in all)
        if (_picked.contains(i.path)) XFile(i.path),
    ];
    if (files.isEmpty) return;
    await SharePlus.instance.share(ShareParams(files: files));
  }

  Future<void> _deleteSelected() async {
    final n = _picked.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(n == 1 ? 'Delete 1 file?' : 'Delete $n files?'),
        content: const Text(
          "They will be removed from your phone. This can't be undone.",
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
              style: TextStyle(color: Pop.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var failed = 0;
    for (final path in _picked) {
      try {
        await AudioPlayback.forget(path);
        await File(path).delete();
      } catch (_) {
        failed++;
      }
    }
    setState(_picked.clear);
    ref.invalidate(libraryProvider);
    Haptics.success();
    popToast(
      failed == 0 ? 'Deleted $n' : 'Deleted ${n - failed}, $failed failed',
      icon: Icons.delete_rounded,
      error: failed > 0,
    );
  }

  static int _size(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  Widget _grid(List<LibraryItem> items, {double bottom = 18}) {
    final still = Pop.reduceMotion(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom),
      sliver: SliverGrid.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 18,
          crossAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, i) {
          final item = items[i];
          final tile = _Tile(
            key: ValueKey(item.path),
            item: item,
            selecting: _selecting,
            selected: _picked.contains(item.path),
            onToggle: () => _toggle(item),
          );
          return still
              ? tile
              : tile
                    .animate()
                    .fadeIn(duration: Pop.medium, delay: (30 * (i % 10)).ms)
                    .scaleXY(begin: 0.94, end: 1, curve: Curves.easeOutBack);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(libraryProvider);
    final items = sortLibrary(
      filterLibrary(all, kind: _kind, query: _query),
      _sort,
      sizeOf: _size,
    );
    // Drop picks for files that disappeared.
    _picked.removeWhere((p) => !all.any((i) => i.path == p));

    // Back leaves selection mode first.
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_picked.clear);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                sliver: SliverList.list(
                  children: [
                    AnimatedSwitcher(
                      duration: Pop.medium,
                      child: _selecting
                          ? _SelectionBar(
                              key: const ValueKey('select'),
                              count: _picked.length,
                              onClose: () => setState(_picked.clear),
                              onAll: () => setState(
                                () => _picked.addAll(items.map((i) => i.path)),
                              ),
                              onShare: () => _shareSelected(all),
                              onDelete: _deleteSelected,
                            )
                          : const SizedBox(
                              key: ValueKey('title'),
                              height: 48,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Library',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        PopupMenuButton<LibrarySort>(
                          tooltip: 'Sort',
                          initialValue: _sort,
                          onSelected: _setSort,
                          itemBuilder: (_) => [
                            for (final s in LibrarySort.values)
                              CheckedPopupMenuItem(
                                value: s,
                                checked: s == _sort,
                                child: Text(s.label),
                              ),
                          ],
                          child: Chip(
                            avatar: const Icon(Icons.sort_rounded, size: 18),
                            label: Text(_sort.label),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.pop.text,
                          ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: _group
                              ? null
                              : const Icon(Icons.workspaces_rounded, size: 18),
                          label: const Text('By platform'),
                          selected: _group,
                          onSelected: _setGroup,
                        ),
                        const Spacer(),
                        if (!_selecting && items.isNotEmpty)
                          TextButton(
                            onPressed: () => _toggle(items.first),
                            child: const Text(
                              'Select',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      DockInset.listBottom(context),
                    ),
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
              else if (!_group)
                _grid(items, bottom: DockInset.listBottom(context))
              else ...[
                for (final (name, group) in groupBySite(items)) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: PopSection('$name · ${group.length}'),
                    ),
                  ),
                  _grid(group),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(height: DockInset.listBottom(context) - 20),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({
    super.key,
    required this.item,
    required this.selecting,
    required this.selected,
    required this.onToggle,
  });

  final LibraryItem item;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = item.kind == LibraryKind.subtitles;
    return Semantics(
      button: true,
      label:
          '${item.title}, ${item.ext}${selecting ? (selected ? ', selected' : ', not selected') : ''}',
      excludeSemantics: true,
      // The whole tile grows into the download's page.
      child: Morph(
        // No rounding here: the thumbnail rounds itself, and rounded corners on
        // the whole tile clipped the first letter of the caption.
        shape: const RoundedRectangleBorder(),
        page: (_) => DownloadDetailScreen(jobId: item.jobId),
        builder: (context, open) => InkWell(
          borderRadius: Pop.thumbRadius,
          onTap: selecting ? onToggle : open,
          // Long-press starts picking several files.
          onLongPress: onToggle,
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
                    if (selected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: Pop.thumbRadius,
                            border: Border.all(color: Pop.yellow, width: 4),
                            color: Pop.ink.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: selecting
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: AnimatedContainer(
                                duration: Pop.medium,
                                width: 28,
                                height: 28,
                                decoration: ShapeDecoration(
                                  color: selected ? Pop.yellow : Colors.black38,
                                  shape: const CircleBorder(
                                    side: BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: Pop.ink,
                                      )
                                    : null,
                              ),
                            )
                          : IconButton(
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
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
          await AudioPlayback.forget(item.path);
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

/// Replaces the Library title while picking files.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    super.key,
    required this.count,
    required this.onClose,
    required this.onAll,
    required this.onShare,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onAll;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Done',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(
              '$count selected',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(onPressed: onAll, child: const Text('All')),
          PopIconButton(
            icon: Icons.share_rounded,
            tooltip: 'Share selected',
            onPressed: onShare,
          ),
          const SizedBox(width: 6),
          PopIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete selected',
            background: context.pop.errorSoft,
            foreground: Pop.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
