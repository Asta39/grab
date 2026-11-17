import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:toastification/toastification.dart';

import '../core/theme/pop_theme.dart';
import '../core/utils/links.dart';
import '../core/audio/audio_playback.dart';
import '../core/widgets/app_scale.dart';
import '../core/widgets/dock_inset.dart';
import '../core/widgets/clipboard_offer.dart';
import '../features/library/audio_player_screen.dart';
import '../core/widgets/pop_widgets.dart';
import '../core/widgets/toasts.dart';
import '../data/db/app_database.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/welcome/welcome_screen.dart';
import 'providers.dart';
import '../core/utils/haptics.dart';

class GrabApp extends ConsumerWidget {
  const GrabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    // AppScale sits above everything (toasts included) so the whole app scales together.
    return MediaQuery.fromView(
      view: View.of(context),
      child: AppScale(
        child: ToastificationWrapper(
          child: MaterialApp(
            title: 'Grab',
            debugShowCheckedModeBanner: false,
            theme: popTheme(),
            darkTheme: popTheme(brightness: Brightness.dark),
            themeMode: themeMode,
            // Status bar icons follow the theme: dark on light, light on dark.
            // Yellow pages (welcome, About) set their own.
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: Theme.of(context).brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light.copyWith(
                      statusBarColor: Colors.transparent,
                    )
                  : SystemUiOverlayStyle.dark.copyWith(
                      statusBarColor: Colors.transparent,
                    ),
              child: child!,
            ),
            home: const _FirstRun(),
          ),
        ),
      ),
    );
  }
}

/// Shows the welcome pages once, then the app.
class _FirstRun extends ConsumerStatefulWidget {
  const _FirstRun();

  @override
  ConsumerState<_FirstRun> createState() => _FirstRunState();
}

class _FirstRunState extends ConsumerState<_FirstRun> {
  late var _seen = WelcomeScreen.seen(ref.read(sharedPrefsProvider));

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Pop.medium,
      child: _seen
          ? const _Shell()
          : WelcomeScreen(
              onDone: () {
                ref
                    .read(sharedPrefsProvider)
                    .setBool(WelcomeScreen.seenKey, true);
                setState(() => _seen = true);
              },
            ),
    );
  }
}

/// Tabs, plus app-wide moments: share-into-app, clipboard offer, and the "done" celebration.
class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> with WidgetsBindingObserver {
  final _home = GlobalKey<HomeScreenState>();
  final _confetti = ConfettiController(
    duration: const Duration(milliseconds: 700),
  );
  StreamSubscription<List<SharedMediaFile>>? _shares;
  var _tab = 0;
  String? _lastOffered;
  ({String link, String platform})? _offer;
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A link shared to Grab while it was closed, then any shared while it is open.
    ReceiveSharingIntent.instance.getInitialMedia().then(_onShared);
    _shares = ReceiveSharingIntent.instance.getMediaStream().listen(_onShared);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerClipboard());
    // Quick Settings tile: open Grab and fetch whatever link is copied.
    _launch.setMethodCallHandler((call) async {
      if (call.method == 'action') _onLaunchAction(call.arguments as String?);
    });
    _launch
        .invokeMethod<String>('takeAction')
        .then(_onLaunchAction, onError: (_) {});
  }

  static const _launch = MethodChannel('grab/launch');

  void _onLaunchAction(String? action) {
    if (action != 'grabClipboard') return;
    // The clipboard is readable once the window has focus.
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final link = extractLink(data?.text);
      if (!mounted) return;
      if (link == null) {
        popToast(
          'No link copied',
          icon: Icons.link_off_rounded,
          detail: 'Copy a video link, then tap the Grab tile again.',
          error: true,
        );
        return;
      }
      _lastOffered = link;
      _dismissOffer();
      setState(() => _tab = 0);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _home.currentState?.fetchLink(link),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shares?.cancel();
    _offerTimer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android only lets the app read the clipboard once it has focus, so wait a moment.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 400), _offerClipboard);
    }
  }

  void _onShared(List<SharedMediaFile> items) {
    if (items.isEmpty) return;
    final link = items
        .map((f) => extractLink(f.path) ?? extractLink(f.message))
        .nonNulls
        .firstOrNull;
    ReceiveSharingIntent.instance.reset();
    if (link == null) {
      popToast(
        'No link in what was shared',
        icon: Icons.link_off_rounded,
        error: true,
      );
      return;
    }
    _lastOffered = link;
    setState(() => _tab = 0);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _home.currentState?.fetchLink(link),
    );
  }

  /// If the clipboard holds a link from a known platform, offer to fetch it once.
  Future<void> _offerClipboard() async {
    if (!mounted) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final link = extractLink(data?.text);
    final platform = platformOf(link);
    if (link == null || platform == null || link == _lastOffered || !mounted) {
      return;
    }
    // Already offered, fetched or downloaded (even with different share
    // tracking, even before a restart)? Then stay quiet.
    final key = linkKey(link);
    final jobs = ref.read(jobsProvider).value ?? const <DownloadJob>[];
    if (_seenLinks.contains(key) || jobs.any((j) => linkKey(j.url) == key)) {
      _lastOffered = link;
      return;
    }
    _remember(link);
    _lastOffered = link;
    Haptics.soft();
    setState(() => _offer = (link: link, platform: platform));
    _offerTimer?.cancel();
    _offerTimer = Timer(const Duration(seconds: 25), _dismissOffer);
  }

  static const _seenKey = 'seenLinks';

  List<String> get _seenLinks =>
      ref.read(sharedPrefsProvider).getStringList(_seenKey) ?? const [];

  /// Remembers a link as handled, so the clipboard card never offers it again.
  void _remember(String link) {
    final key = linkKey(link);
    final seen = [..._seenLinks.where((k) => k != key), key];
    ref
        .read(sharedPrefsProvider)
        .setStringList(
          _seenKey,
          seen.length > 300 ? seen.sublist(seen.length - 300) : seen,
        );
  }

  void _dismissOffer() {
    _offerTimer?.cancel();
    if (mounted && _offer != null) setState(() => _offer = null);
  }

  void _grabOffer() {
    final o = _offer;
    if (o == null) return;
    Haptics.medium();
    setState(() => _tab = 0);
    _home.currentState?.fetchLink(o.link);
  }

  /// Celebrate jobs that just finished; warn about ones that just failed.
  void _onJobsChanged(List<DownloadJob>? before, List<DownloadJob> after) {
    if (before == null) return;
    final was = {for (final j in before) j.id: j.status};
    for (final j in after) {
      final prev = was[j.id];
      if (prev == null || prev == j.status) continue;
      if (j.status == JobStatus.done) {
        Haptics.success();
        if (!Pop.reduceMotion(context)) _confetti.play();
        popToast('Saved', icon: Icons.check_circle_rounded, detail: j.title);
      } else if (j.status == JobStatus.failed) {
        Haptics.error();
        popToast(
          'Download failed',
          icon: Icons.error_rounded,
          error: true,
          detail: j.title,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingLinkProvider, (_, link) {
      if (link == null) return;
      ref.read(pendingLinkProvider.notifier).set(null);
      _lastOffered = link;
      setState(() => _tab = 0);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _home.currentState?.fetchLink(link),
      );
    });
    ref.listen(jobsProvider, (prev, next) {
      final after = next.value;
      if (after != null) _onJobsChanged(prev?.value, after);
    });
    final active = ref.watch(activeCountProvider);

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: ValueListenableBuilder(
            valueListenable: AudioPlayback.current,
            builder: (context, playing, child) =>
                DockInset(extra: playing == null ? 0 : 64, child: child!),
            child: IndexedStack(
              index: _tab,
              // Hidden tabs stay alive but stop animating, so the Home blobs
              // (and anything else that ticks) cost nothing on other tabs.
              children: [
                for (final (i, page) in <Widget>[
                  HomeScreen(
                    key: _home,
                    onQueued: () => setState(() => _tab = 1),
                    // Any fetch, pasted, typed or offered, makes the offer moot.
                    onFetch: (link) {
                      _remember(link);
                      _dismissOffer();
                    },
                  ),
                  const DownloadsScreen(),
                  const LibraryScreen(),
                  const SettingsScreen(),
                ].indexed)
                  TickerMode(enabled: i == _tab, child: page),
              ],
            ),
          ),
          bottomNavigationBar: PopTabBar(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
            tabs: [
              const PopTab(Icons.home_rounded, 'Home'),
              PopTab(Icons.download_rounded, 'Downloads', badge: active),
              const PopTab(Icons.video_library_rounded, 'Library'),
              const PopTab(Icons.tune_rounded, 'Settings'),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: Pop.medium,
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: _offer == null
                    ? const SizedBox.shrink()
                    : ClipboardOffer(
                        key: ValueKey(_offer!.link),
                        platform: _offer!.platform,
                        link: _offer!.link,
                        onGrab: _grabOffer,
                        onDismiss: _dismissOffer,
                      ),
              ),
              const SizedBox(height: 8),
              const MiniPlayer(),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 28,
            maxBlastForce: 28,
            minBlastForce: 10,
            gravity: 0.25,
            emissionFrequency: 0.0,
            colors: const [
              Pop.yellow,
              Pop.ink,
              Color(0xFF9FD8FF),
              Color(0xFFFFB2C8),
            ],
          ),
        ),
      ],
    );
  }
}
