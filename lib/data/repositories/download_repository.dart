import 'dart:async';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../engine/engine_channel.dart';
import '../engine/media_info.dart';

/// What the queue needs from the engine. [EngineChannel] implements it; tests use a fake.
abstract interface class DownloadEngine {
  Stream<EngineEvent> get events;
  Future<void> download({
    required String id,
    required String url,
    required List<String> args,
    String suffix,
    String? match,
    String title,
  });
  Future<bool> cancel(String id);
}

/// A download the user asked for, before it is queued.
class DownloadRequest {
  const DownloadRequest({
    required this.info,
    required this.mode,
    this.maxHeight,
    this.estimatedBytes,
    this.subtitles = SubtitleChoice.none,
    this.container = 'mp4',
    this.audioFormat = 'mp3',
  });

  final MediaInfo info;
  final DownloadMode mode;
  final int? maxHeight;
  final int? estimatedBytes;
  final SubtitleChoice subtitles;
  final String container;
  final String audioFormat;
}

/// Owns the download queue: saves jobs first, runs up to [maxParallel] at a time,
/// and records progress and results from engine events.
class DownloadRepository {
  DownloadRepository(this._db, this._engine, {this.maxParallel = 2, DateTime Function()? clock})
      : _now = clock ?? DateTime.now {
    _sub = _engine.events.listen(_onEvent);
  }

  final AppDatabase _db;
  final DownloadEngine _engine;
  final DateTime Function() _now;
  int maxParallel;
  late final StreamSubscription<EngineEvent> _sub;
  final _lastWrite = <String, double>{};
  var _idCounter = 0;

  /// All jobs, newest first.
  Stream<List<DownloadJob>> watchAll() =>
      (_db.select(_db.downloadJobs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  /// Call once at app start: jobs that were running when the app died go back in the queue.
  Future<void> resume() async {
    await (_db.update(_db.downloadJobs)..where((t) => t.status.equalsValue(JobStatus.running)))
        .write(const DownloadJobsCompanion(status: Value(JobStatus.queued), progress: Value(0)));
    await _pump();
  }

  Future<String> enqueue(DownloadRequest r) async {
    final id = '${_now().microsecondsSinceEpoch}-${_idCounter++}';
    await _db.into(_db.downloadJobs).insert(DownloadJobsCompanion.insert(
          id: id,
          url: r.info.url,
          title: r.info.title,
          itemId: Value(r.info.id),
          thumbnail: Value(r.info.thumbnail),
          site: Value(r.info.site),
          mode: r.mode.name,
          maxHeight: Value(r.maxHeight),
          container: Value(r.container),
          audioFormat: Value(r.audioFormat),
          subLangs: Value(r.subtitles.langs.join(',')),
          subAuto: Value(r.subtitles.includeAuto),
          subEmbed: Value(r.subtitles.embed),
          estimatedBytes: Value(r.estimatedBytes),
          status: JobStatus.queued,
          createdAt: _now(),
        ));
    await _pump();
    return id;
  }

  Future<void> cancel(String id) async {
    final job = await _get(id);
    if (job == null) return;
    if (job.status == JobStatus.queued) {
      await _set(id, const DownloadJobsCompanion(status: Value(JobStatus.canceled)));
    } else if (job.status == JobStatus.running) {
      await _engine.cancel(id);
    }
  }

  Future<void> retry(String id) async {
    await _set(id, const DownloadJobsCompanion(
      status: Value(JobStatus.queued),
      progress: Value(0),
      error: Value(null),
    ));
    await _pump();
  }

  /// Removes the job from history. Files on disk are kept.
  Future<void> remove(String id) async {
    await cancel(id);
    await (_db.delete(_db.downloadJobs)..where((t) => t.id.equals(id))).go();
  }

  Future<void> dispose() => _sub.cancel();

  // ---- queue ----

  var _pumping = false;

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        final running = await (_db.select(_db.downloadJobs)..where((t) => t.status.equalsValue(JobStatus.running))).get();
        if (running.length >= maxParallel) return;
        final next = await (_db.select(_db.downloadJobs)
              ..where((t) => t.status.equalsValue(JobStatus.queued))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
        if (next == null) return;
        await _set(next.id, const DownloadJobsCompanion(status: Value(JobStatus.running)));
        await _start(next);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _start(DownloadJob job) async {
    final mode = DownloadMode.values.byName(job.mode);
    final subs = SubtitleChoice(
      langs: job.subLangs.isEmpty ? const [] : job.subLangs.split(','),
      includeAuto: job.subAuto,
      embed: job.subEmbed,
    );
    try {
      await _engine.download(
        id: job.id,
        url: job.url,
        args: buildDownloadArgs(
          mode: mode,
          maxHeight: job.maxHeight,
          container: job.container,
          audioFormat: job.audioFormat,
          subtitles: subs,
        ),
        suffix: fileSuffix(mode),
        match: job.itemId == null ? null : '[${job.itemId}]',
        title: job.title,
      );
    } catch (e) {
      await _finish(job.id, JobStatus.failed, error: '$e');
    }
  }

  Future<void> _onEvent(EngineEvent e) async {
    switch (e.status) {
      case 'running':
        final p = e.progress ?? 0;
        // Write at most once per whole percent to keep the database quiet.
        if ((p - (_lastWrite[e.id] ?? -1)).abs() < 1) return;
        _lastWrite[e.id] = p;
        await _set(e.id, DownloadJobsCompanion(progress: Value(p), eta: Value(e.eta)));
      case 'done':
        await _finish(e.id, JobStatus.done, paths: e.paths);
      case 'error':
        await _finish(e.id, JobStatus.failed, error: e.error);
      case 'canceled':
        await _finish(e.id, JobStatus.canceled);
    }
  }

  Future<void> _finish(String id, JobStatus status, {List<String> paths = const [], String? error}) async {
    _lastWrite.remove(id);
    await _set(id, DownloadJobsCompanion(
      status: Value(status),
      progress: Value(status == JobStatus.done ? 100 : 0),
      paths: Value(paths.join('\n')),
      error: Value(error),
      finishedAt: Value(_now()),
    ));
    await _pump();
  }

  Future<DownloadJob?> _get(String id) =>
      (_db.select(_db.downloadJobs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> _set(String id, DownloadJobsCompanion c) =>
      (_db.update(_db.downloadJobs)..where((t) => t.id.equals(id))).write(c);
}
