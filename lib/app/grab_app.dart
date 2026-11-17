import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:toastification/toastification.dart';

import '../core/theme/pop_theme.dart';
import '../core/utils/links.dart';
import '../core/widgets/pop_widgets.dart';
import '../core/widgets/toasts.dart';
import '../data/db/app_database.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/home/home_screen.dart';
import 'providers.dart';

class GrabApp extends StatelessWidget {
  const GrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Grab',
        debugShowCheckedModeBanner: false,
        theme: popTheme(),
        home: const _Shell(),
      ),
    );
  }
}

/// Tabs, plus app-wide moments: share-into-app, clipboard offer, and the "done" celebration.
/// Library and Settings join in milestone 4.
class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> with WidgetsBindingObserver {
  final _home = GlobalKey<HomeScreenState>();
  final _confetti = ConfettiController(duration: const Duration(milliseconds: 700));
  StreamSubscription<List<SharedMediaFile>>? _shares;
  var _tab = 0;
  String? _lastOffered;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A link shared to Grab while it was closed, then any shared while it is open.
    ReceiveSharingIntent.instance.getInitialMedia().then(_onShared);
    _shares = ReceiveSharingIntent.instance.getMediaStream().listen(_onShared);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerClipboard());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shares?.cancel();
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
    final link = items.map((f) => extractLink(f.path) ?? extractLink(f.message)).nonNulls.firstOrNull;
    ReceiveSharingIntent.instance.reset();
    if (link == null) {
      popToast('No link in what was shared', icon: Icons.link_off_rounded, error: true);
      return;
    }
    _lastOffered = link;
    setState(() => _tab = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _home.currentState?.fetchLink(link));
  }

  /// If the clipboard holds a link from a known platform, offer to fetch it once.
  Future<void> _offerClipboard() async {
    if (!mounted) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final link = extractLink(data?.text);
    final platform = platformOf(link);
    if (link == null || platform == null || link == _lastOffered || !mounted) return;
    _lastOffered = link;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: Pop.ink,
        shape: const StadiumBorder(),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        duration: const Duration(seconds: 6),
        content: Text('$platform link copied', style: const TextStyle(fontFamily: Pop.font, fontWeight: FontWeight.w600)),
        action: SnackBarAction(
          label: 'Grab it',
          textColor: Pop.yellow,
          onPressed: () {
            setState(() => _tab = 0);
            _home.currentState?.fetchLink(link);
          },
        ),
      ));
  }

  /// Celebrate jobs that just finished; warn about ones that just failed.
  void _onJobsChanged(List<DownloadJob>? before, List<DownloadJob> after) {
    if (before == null) return;
    final was = {for (final j in before) j.id: j.status};
    for (final j in after) {
      final prev = was[j.id];
      if (prev == null || prev == j.status) continue;
      if (j.status == JobStatus.done) {
        HapticFeedback.heavyImpact();
        if (!Pop.reduceMotion(context)) _confetti.play();
        popToast('Saved', icon: Icons.check_circle_rounded, detail: j.title);
      } else if (j.status == JobStatus.failed) {
        HapticFeedback.vibrate();
        popToast('Download failed', icon: Icons.error_rounded, error: true, detail: j.title);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(jobsProvider, (prev, next) {
      final after = next.value;
      if (after != null) _onJobsChanged(prev?.value, after);
    });
    final active = ref.watch(activeCountProvider);

    return Stack(children: [
      Scaffold(
        extendBody: true,
        body: IndexedStack(index: _tab, children: [
          HomeScreen(key: _home, onQueued: () => setState(() => _tab = 1)),
          const DownloadsScreen(),
        ]),
        bottomNavigationBar: PopTabBar(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
          tabs: [
            const PopTab(Icons.home_rounded, 'Home'),
            PopTab(Icons.download_rounded, 'Downloads', badge: active),
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
          colors: const [Pop.yellow, Pop.ink, Color(0xFF9FD8FF), Color(0xFFFFB2C8)],
        ),
      ),
    ]);
  }
}
