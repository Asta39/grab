import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../core/widgets/toasts.dart';
import '../club/buddy.dart';
import '../club/game.dart';
import '../library/library_items.dart';
import 'clip_editor.dart';
import 'clip_maker.dart';

enum ClipKind { gif, sticker }

extension on ClipKind {
  /// Longest clip: GIFs get big fast, WhatsApp caps animated stickers.
  double get max => this == ClipKind.gif ? 10 : 6;
  String get label => this == ClipKind.gif ? 'GIF' : 'Sticker';
}

/// Turn a few seconds of a saved video into a GIF or a WhatsApp sticker.
Future<void> showClipSheet(BuildContext context, LibraryItem item) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ClipSheet(item: item),
    );

class _ClipSheet extends ConsumerStatefulWidget {
  const _ClipSheet({required this.item});

  final LibraryItem item;

  @override
  ConsumerState<_ClipSheet> createState() => _ClipSheetState();
}

class _ClipSheetState extends ConsumerState<_ClipSheet> {
  double? _duration;
  RangeValues _range = const RangeValues(0, 3);
  var _kind = ClipKind.gif;
  var _busy = false;
  String? _made;
  var _adding = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    ClipMaker.duration(widget.item.path).then((d) {
      if (!mounted) return;
      final total = d ?? 10;
      setState(() {
        _duration = total;
        _range = RangeValues(0, total.clamp(1, 3).toDouble());
      });
    }, onError: (Object e) => setState(() => _error = e));
  }

  void _setKind(ClipKind k) {
    Haptics.selection();
    setState(() {
      _kind = k;
      _made = null;
      if (_range.end - _range.start > k.max) {
        _range = RangeValues(_range.start, _range.start + k.max);
      }
    });
  }

  Future<void> _make() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    Buddy.mood(BuddyMood.search, hold: const Duration(seconds: 20));
    try {
      final made = await ClipMaker.make(
        input: widget.item.path,
        start: _range.start,
        end: _range.end,
        kind: _kind.name,
        title: widget.item.title,
      );
      Haptics.success();
      Buddy.mood(BuddyMood.cheer);
      setState(() => _made = made);
    } on PlatformException catch (e) {
      Haptics.error();
      Buddy.mood(BuddyMood.sad);
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Adds the sticker to the "Grab stickers" pack in WhatsApp.
  Future<void> _addToWhatsApp(String path) async {
    setState(() => _adding = true);
    final r = await const MethodChannel(
      'grab/stickers',
    ).invokeMethod<String>('addToWhatsApp', {'path': path});
    if (!mounted) return;
    setState(() => _adding = false);
    switch (r) {
      case 'added':
        Haptics.success();
        Buddy.say('Sticker added! 🎉');
        popToast(
          'In your WhatsApp stickers',
          icon: Icons.check_circle_rounded,
          detail: 'Open the sticker tray and look for "Grab stickers".',
        );
      case 'cancelled':
        break;
      case 'noWhatsApp':
        popToast(
          "WhatsApp isn't installed",
          icon: Icons.info_rounded,
          detail: 'You can still share the sticker as an image.',
        );
      default:
        Haptics.error();
        popToast(
          "Couldn't add the sticker",
          error: true,
          detail: r?.replaceFirst('error:', ''),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _duration;
    final made = _made;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Make a GIF or sticker',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.pop.muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final k in ClipKind.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: k == ClipKind.gif ? 6 : 0,
                        left: k == ClipKind.gif ? 0 : 6,
                      ),
                      child: PopOptionTile(
                        label: k.label,
                        selected: _kind == k,
                        onTap: () => _setKind(k),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (made != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ColoredBox(
                    color: context.pop.card,
                    child: Image.file(
                      File(made),
                      height: 240,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              )
            else if (d == null && _error == null)
              const Center(child: CircularProgressIndicator())
            else if (d != null) ...[
              ClipEditor(
                path: widget.item.path,
                poster: widget.item.thumbnail,
                duration: d,
                maxLength: _kind.max,
                initialLength: 3,
                lengths: _kind == ClipKind.gif
                    ? const [2, 3, 5, 10]
                    : const [2, 3, 6],
                look: _kind == ClipKind.gif ? ClipLook.video : ClipLook.square,
                onChanged: (s, e) => _range = RangeValues(s, e),
              ),
              const SizedBox(height: 10),
              Text(
                _kind == ClipKind.gif
                    ? 'Up to 10 seconds, silent and looping.'
                    : 'Up to 6 seconds, 512 × 512, silent and looping.',
                style: TextStyle(color: context.pop.muted, fontSize: 12),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text('$_error', style: const TextStyle(color: Pop.error)),
            ],
            const SizedBox(height: 20),
            if (made == null)
              PopButton(
                label: 'Make ${_kind.label}',
                icon: Icons.gif_box_rounded,
                busy: _busy,
                onPressed: d == null || _busy ? null : _make,
              )
            else ...[
              Text(
                'Saved to Pictures/Grab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.pop.muted),
              ),
              const SizedBox(height: 12),
              if (_kind == ClipKind.sticker && Platform.isAndroid) ...[
                PopButton(
                  label: 'Add to WhatsApp stickers',
                  icon: Icons.add_reaction_rounded,
                  busy: _adding,
                  onPressed: _adding ? null : () => _addToWhatsApp(made),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () =>
                      shareAndCount(ref, ShareParams(files: [XFile(made)])),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share as an image instead'),
                ),
              ] else
                PopButton(
                  label: 'Share ${_kind.label}',
                  icon: Icons.ios_share_rounded,
                  onPressed: () =>
                      shareAndCount(ref, ShareParams(files: [XFile(made)])),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Haptics.selection();
                  setState(() => _made = null);
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Make another'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
