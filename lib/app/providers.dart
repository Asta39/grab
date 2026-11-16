import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/engine/engine_channel.dart';
import '../data/repositories/download_repository.dart';

/// App-wide singletons. Screens read these; nothing else creates them.

final engineProvider = Provider<EngineChannel>((ref) => EngineChannel());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final repo = DownloadRepository(ref.watch(databaseProvider), ref.watch(engineProvider));
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
  return jobs.where((j) => j.status == JobStatus.queued || j.status == JobStatus.running).length;
});

/// Starts the engine (unpacks Python on first run) and returns the yt-dlp version.
final engineVersionProvider = FutureProvider<String?>((ref) => ref.watch(engineProvider).init());
