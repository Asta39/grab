import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/engine/engine_channel.dart';
import '../data/repositories/download_repository.dart';
import '../data/settings/app_settings.dart';

/// App-wide singletons. Screens read these; nothing else creates them.

final engineProvider = Provider<EngineChannel>((ref) => EngineChannel());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Loaded in main() before the app starts, then overridden into the scope.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main'),
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings.load(ref.watch(sharedPrefsProvider));

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await state.save(ref.read(sharedPrefsProvider));
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final repo = DownloadRepository(
    ref.watch(databaseProvider),
    ref.watch(engineProvider),
    maxParallel: ref.read(settingsProvider).maxParallel,
  );
  ref.listen(settingsProvider.select((s) => s.maxParallel), (_, n) {
    repo.maxParallel = n;
    repo.resume();
  });
  repo.resume();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Every job, newest first, kept live from the database.
final jobsProvider = StreamProvider<List<DownloadJob>>(
  (ref) => ref.watch(downloadRepositoryProvider).watchAll(),
);

/// Number of queued + running jobs, for the tab badge.
final activeCountProvider = Provider<int>((ref) {
  final jobs = ref.watch(jobsProvider).value ?? const [];
  return jobs
      .where(
        (j) => j.status == JobStatus.queued || j.status == JobStatus.running,
      )
      .length;
});

/// Starts the engine (unpacks Python on first run) and returns the yt-dlp version.
final engineVersionProvider = FutureProvider<String?>((ref) async {
  // After an in-app update the library reports "yt-dlp 2026.10.26"; keep just the version.
  final v = await ref.watch(engineProvider).init();
  return v
      ?.replaceFirst(RegExp(r'^yt-dlp\s*', caseSensitive: false), '')
      .trim();
});

/// A link to fetch on Home, set from anywhere ("Download again"). The shell consumes it.
class PendingLink extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? link) => state = link;
}

final pendingLinkProvider = NotifierProvider<PendingLink, String?>(
  PendingLink.new,
);
