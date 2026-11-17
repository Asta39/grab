import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/update/app_update.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../core/widgets/toasts.dart';
import '../../data/engine/media_info.dart';

/// About Grab: version, updates from GitHub releases, links and credits.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

enum _Stage { idle, checking, upToDate, available, downloading, ready, error }

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _app;
  var _stage = _Stage.idle;
  Release? _release;
  ReleaseAsset? _asset;
  double _progress = 0;
  File? _apk;
  String? _error;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (!mounted) return;
      setState(() => _app = i);
      _check(quiet: true);
    });
  }

  Future<void> _check({bool quiet = false}) async {
    if (!quiet) Haptics.light();
    setState(() {
      _stage = _Stage.checking;
      _error = null;
    });
    try {
      final r = await fetchLatestRelease();
      final abis = await phoneAbis();
      if (!mounted) return;
      final newer = r != null && isNewerVersion(r.version, _app!.version);
      setState(() {
        _release = r;
        _asset = newer ? r.assetFor(abis) : null;
        _stage = newer ? _Stage.available : _Stage.upToDate;
      });
      if (newer) Haptics.success();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = quiet ? _Stage.idle : _Stage.error;
        _error = "Couldn't reach GitHub. Check your connection and try again.";
      });
    }
  }

  Future<void> _download() async {
    final asset = _asset;
    if (asset == null) {
      openUrl(_release!.pageUrl);
      return;
    }
    Haptics.medium();
    setState(() {
      _stage = _Stage.downloading;
      _progress = 0;
    });
    try {
      final apk = await downloadUpdate(
        asset,
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      );
      if (!mounted) return;
      setState(() {
        _apk = apk;
        _stage = _Stage.ready;
      });
      await _install();
    } catch (e) {
      if (!mounted) return;
      Haptics.error();
      setState(() {
        _stage = _Stage.error;
        _error = 'The download stopped. Try again.';
      });
    }
  }

  Future<void> _install() async {
    Haptics.light();
    final started = await installUpdate(_apk!);
    if (!started) {
      popToast(
        'Allow Grab to install updates',
        icon: Icons.security_update_good_rounded,
        detail:
            'Turn on "Allow from this source", come back, then tap Install.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    final still = Pop.reduceMotion(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Pop.yellow,
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              color: Pop.ink,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                        borderRadius: BorderRadius.circular(26),
                                        child: Image.asset(
                                          'assets/brand/icon.png',
                                          width: 96,
                                          height: 96,
                                          semanticLabel: 'Grab icon',
                                        ),
                                      )
                                      .animate(target: still ? null : 1)
                                      .scaleXY(
                                        begin: 0.8,
                                        end: 1,
                                        curve: Curves.easeOutBack,
                                        duration: 500.ms,
                                      ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Grab',
                                    style: TextStyle(
                                      color: Pop.ink,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Paste a link. Get the file.',
                                    style: TextStyle(
                                      color: Pop.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  DecoratedBox(
                                    decoration: const ShapeDecoration(
                                      shape: StadiumBorder(),
                                      color: Pop.ink,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        app == null
                                            ? '…'
                                            : 'Version ${app.version} · build ${app.buildNumber}',
                                        style: const TextStyle(
                                          color: Pop.yellow,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              sliver: SliverList.list(
                children: [
                  const PopSection('Updates'),
                  _updateCard(context),
                  const SizedBox(height: 22),
                  const PopSection('Project'),
                  _Links(
                    items: [
                      (
                        Icons.code_rounded,
                        'Source code',
                        'github.com/Asta39/grab',
                        repoUrl,
                      ),
                      (
                        Icons.new_releases_rounded,
                        'All releases',
                        'Changelogs and older versions',
                        '$repoUrl/releases',
                      ),
                      (
                        Icons.bug_report_rounded,
                        'Report a problem',
                        'Include the link that failed',
                        '$repoUrl/issues/new',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const PopSection('Privacy'),
                  _InfoCard(
                    icon: Icons.verified_user_rounded,
                    title: 'No account, no ads, no tracking',
                    body:
                        'Grab only talks to the sites you download from, and to GitHub when it checks for updates. Your downloads and history stay on this phone.',
                  ),
                  const SizedBox(height: 22),
                  const PopSection('Built with'),
                  _Links(
                    items: [
                      (
                        Icons.terminal_rounded,
                        'yt-dlp',
                        'The download engine',
                        'https://github.com/yt-dlp/yt-dlp',
                      ),
                      (
                        Icons.movie_filter_rounded,
                        'FFmpeg',
                        'Merging, audio and clips',
                        'https://ffmpeg.org',
                      ),
                      (
                        Icons.android_rounded,
                        'youtubedl-android',
                        'Runs both on your phone',
                        'https://github.com/yausername/youtubedl-android',
                      ),
                      (
                        Icons.flutter_dash_rounded,
                        'Flutter',
                        'The app itself',
                        'https://flutter.dev',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Links(
                    items: const [],
                    extra: ListTile(
                      leading: const Icon(Icons.gavel_rounded),
                      title: const Text(
                        'Open-source licenses',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Grab is free software under GPL-3.0',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'Grab',
                        applicationVersion: app?.version,
                        applicationLegalese:
                            'Free software under GPL-3.0. Uses yt-dlp, FFmpeg and Python.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "Download only what you have the right to save. Respect creators and each site's rules. Grab isn't affiliated with any site it supports.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.pop.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _updateCard(BuildContext context) {
    final r = _release;
    final (IconData icon, String title, String? body) = switch (_stage) {
      _Stage.idle => (
        Icons.system_update_rounded,
        'Check for updates',
        'Looks for the latest release on GitHub.',
      ),
      _Stage.checking => (Icons.sync_rounded, 'Checking…', null),
      _Stage.upToDate => (
        Icons.check_circle_rounded,
        "You're up to date",
        r == null
            ? 'No releases published yet.'
            : 'Latest release is ${r.tag}.',
      ),
      _Stage.available => (
        Icons.celebration_rounded,
        '${r!.name.isEmpty ? r.tag : r.name} is out',
        _asset == null
            ? 'Open the release page to download it.'
            : 'Installs over this version. Your downloads, settings and history stay.',
      ),
      _Stage.downloading => (
        Icons.downloading_rounded,
        'Downloading ${r!.tag}… ${(_progress * 100).round()}%',
        null,
      ),
      _Stage.ready => (
        Icons.install_mobile_rounded,
        'Ready to install ${r!.tag}',
        'Android will ask you to confirm. Nothing on your phone is removed.',
      ),
      _Stage.error => (Icons.wifi_off_rounded, 'Something went wrong', _error),
    };
    final highlight = _stage == _Stage.available || _stage == _Stage.ready;
    return AnimatedContainer(
      duration: Pop.medium,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlight ? context.pop.soft : context.pop.card,
        borderRadius: Pop.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body, style: TextStyle(color: context.pop.muted)),
          ],
          if (_stage == _Stage.available && r!.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.pop.bg,
                borderRadius: Pop.thumbRadius,
              ),
              child: SingleChildScrollView(
                child: Text(
                  r.notes,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ),
          ],
          if (_stage == _Stage.downloading) ...[
            const SizedBox(height: 14),
            PopProgressBar(value: _progress, track: context.pop.track),
          ],
          const SizedBox(height: 16),
          switch (_stage) {
            _Stage.available => PopButton(
              label: _asset == null
                  ? 'Open release page'
                  : [
                      'Download & install',
                      ?formatBytes(_asset!.size),
                    ].join(' · '),
              icon: Icons.download_rounded,
              onPressed: _download,
            ),
            _Stage.ready => PopButton(
              label: 'Install',
              icon: Icons.install_mobile_rounded,
              onPressed: _install,
            ),
            _Stage.downloading => const SizedBox.shrink(),
            _ => PopButton(
              label: _stage == _Stage.error ? 'Try again' : 'Check now',
              icon: Icons.refresh_rounded,
              busy: _stage == _Stage.checking,
              height: 48,
              onPressed: _stage == _Stage.checking ? null : _check,
            ),
          },
        ],
      ),
    );
  }
}

/// A card of tappable links in the Pop style.
class _Links extends StatelessWidget {
  const _Links({required this.items, this.extra});

  final List<(IconData, String, String, String)> items;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.pop.card,
        borderRadius: Pop.cardRadius,
      ),
      child: Column(
        children: [
          for (final (icon, title, sub, url) in items)
            ListTile(
              leading: Icon(icon),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(sub),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () {
                Haptics.selection();
                openUrl(url);
              },
            ),
          ?extra,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.pop.card,
        borderRadius: Pop.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: context.pop.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
