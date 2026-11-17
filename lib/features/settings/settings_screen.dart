import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/providers.dart';
import '../../core/theme/pop_theme.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../core/widgets/toasts.dart';
import '../../data/engine/media_info.dart';
import '../../data/settings/app_settings.dart';

final _outputDirProvider = FutureProvider<String?>(
  (ref) => ref.watch(engineProvider).outputDir(),
);
final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Settings: download defaults, the yt-dlp engine, appearance, about.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _updating = false;

  Future<void> _updateEngine() async {
    setState(() => _updating = true);
    try {
      final r = await ref.read(engineProvider).update();
      ref.invalidate(engineVersionProvider);
      popToast(
        r == 'updated' ? 'yt-dlp updated' : 'Already up to date',
        icon: Icons.system_update_alt_rounded,
      );
    } on PlatformException catch (e) {
      popToast('Update failed', error: true, detail: e.message);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final set = ref.read(settingsProvider.notifier).update;
    final version = ref.watch(engineVersionProvider);
    final folder = ref.watch(_outputDirProvider).value;
    final app = ref.watch(_packageInfoProvider).value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 20),
            const PopSection('Downloads'),
            _Group(
              children: [
                _Row(
                  label: 'Save to',
                  value: folder == null ? '…' : _shortPath(folder),
                  onTap: () => popToast(
                    'Files go to Download/Grab',
                    icon: Icons.folder_rounded,
                    detail: 'Open them from Library, or any file manager.',
                  ),
                ),
                _Row(
                  label: 'Default mode',
                  value: _modeLabel(s.defaultMode),
                  onTap: () => _pick<DownloadMode>(
                    title: 'Default mode',
                    options: const [
                      DownloadMode.video,
                      DownloadMode.videoAndAudio,
                      DownloadMode.audioOnly,
                    ],
                    current: s.defaultMode,
                    label: _modeLabel,
                    onPick: (v) => set((x) => x.copyWith(defaultMode: v)),
                  ),
                ),
                _Row(
                  label: 'Default quality',
                  value: s.maxHeight == null
                      ? 'Best available'
                      : '${s.maxHeight}p',
                  onTap: () => _pick<int?>(
                    title: 'Default quality',
                    options: AppSettings.heights,
                    current: s.maxHeight,
                    label: (h) =>
                        h == null ? 'Best available' : '${h}p or lower',
                    onPick: (v) => set((x) => x.copyWith(maxHeight: () => v)),
                  ),
                ),
                _Row(
                  label: 'Video format',
                  value: s.container.toUpperCase(),
                  onTap: () => _pick<String>(
                    title: 'Video format',
                    options: AppSettings.containers,
                    current: s.container,
                    label: (c) => switch (c) {
                      'mp4' => 'MP4 · plays everywhere',
                      'mkv' => 'MKV · keeps every track',
                      _ => 'WEBM · smaller files',
                    },
                    onPick: (v) => set((x) => x.copyWith(container: v)),
                  ),
                ),
                _Row(
                  label: 'Audio format',
                  value: s.audioFormat.toUpperCase(),
                  onTap: () => _pick<String>(
                    title: 'Audio format',
                    options: AppSettings.audioFormats,
                    current: s.audioFormat,
                    label: (f) => switch (f) {
                      'mp3' => 'MP3 · plays everywhere',
                      'm4a' => 'M4A · good for Apple devices',
                      'opus' => 'Opus · smallest files',
                      _ => 'FLAC · lossless, large',
                    },
                    onPick: (v) => set((x) => x.copyWith(audioFormat: v)),
                  ),
                ),
                _Row(
                  label: 'Downloads at once',
                  value: '${s.maxParallel}',
                  onTap: () => _pick<int>(
                    title: 'Downloads at once',
                    options: const [1, 2, 3],
                    current: s.maxParallel,
                    label: (n) => n == 1
                        ? '1 · one after another'
                        : '$n at the same time',
                    onPick: (v) => set((x) => x.copyWith(maxParallel: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const PopSection('Engine'),
            _Group(
              children: [
                _Row(
                  label: 'yt-dlp',
                  value: version.when(
                    data: (v) => v ?? 'unknown',
                    loading: () => 'starting…',
                    error: (_, _) => 'failed to start',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: PopButton(
                    label: 'Check for engine update',
                    icon: Icons.system_update_alt_rounded,
                    busy: _updating,
                    height: 48,
                    onPressed: _updateEngine,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                'Sites change often. If a link stops working, update the engine first.',
                style: TextStyle(fontSize: 13, color: context.pop.muted),
              ),
            ),
            const SizedBox(height: 16),
            const PopSection('Appearance'),
            PopSegmented<ThemeMode>(
              values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
              labels: const ['System', 'Light', 'Dark'],
              selected: s.themeMode,
              onChanged: (m) => set((x) => x.copyWith(themeMode: m)),
            ),
            const SizedBox(height: 16),
            const PopSection('About'),
            _Group(
              children: [
                _Row(
                  label: 'Grab',
                  value: app == null ? '' : 'v${app.version}',
                ),
                _Row(
                  label: 'Open-source licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Grab',
                    applicationVersion: app?.version,
                    applicationLegalese:
                        'Free software under GPL-3.0. Uses yt-dlp, FFmpeg and Python.',
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(
                'Download only what you have the right to save. Respect creators and each site\'s rules.',
                style: TextStyle(fontSize: 12, color: context.pop.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) label,
    required ValueChanged<T> onPick,
  }) async {
    final picked = await showModalBottomSheet<(T,)>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            for (final o in options)
              PopOptionTile(
                label: label(o),
                selected: o == current,
                onTap: () => Navigator.of(context).pop((o,)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onPick(picked.$1);
  }

  static String _modeLabel(DownloadMode m) => switch (m) {
    DownloadMode.video => 'Video',
    DownloadMode.videoAndAudio => 'Video + audio file',
    DownloadMode.audioOnly => 'Audio only',
    DownloadMode.subtitlesOnly => 'Subtitles only',
  };

  static String _shortPath(String p) {
    final i = p.indexOf('/Download/');
    return i >= 0 ? p.substring(i + 1) : p;
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.pop.card,
        borderRadius: Pop.cardRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: context.pop.track,
              ),
            c,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value ?? '',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.pop.muted, fontSize: 15),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: context.pop.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
