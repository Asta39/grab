import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/pop_theme.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/home/home_screen.dart';
import 'providers.dart';

class GrabApp extends StatelessWidget {
  const GrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grab',
      debugShowCheckedModeBanner: false,
      theme: popTheme(),
      home: const _Shell(),
    );
  }
}

/// Bottom tabs. Library and Settings join in milestone 4.
class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeCountProvider);
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        HomeScreen(onQueued: () => setState(() => _tab = 1)),
        const DownloadsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Badge(isLabelVisible: active > 0, label: Text('$active'), child: const Icon(Icons.download_outlined)),
            selectedIcon: Badge(isLabelVisible: active > 0, label: Text('$active'), child: const Icon(Icons.download_rounded)),
            label: 'Downloads',
          ),
        ],
      ),
    );
  }
}
