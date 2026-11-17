import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grab/data/db/app_database.dart';
import 'package:grab/data/engine/engine_channel.dart';
import 'package:grab/data/engine/media_info.dart';
import 'package:grab/data/repositories/download_repository.dart';

import 'download_repository_test.dart' show FakeEngine;

void main() {
  late AppDatabase db;
  late FakeEngine engine;
  late DownloadRepository repo;
  late StreamController<bool> online;
  final suffixes = <String, String>{};
  var tick = 0;

  const info = MediaInfo(url: 'https://example.com/v', title: 'Clip', id: 'v1');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    engine = FakeEngine();
    online = StreamController<bool>.broadcast();
    suffixes.clear();
    tick = 0;
    repo = DownloadRepository(
      db,
      engine,
      maxParallel: 2,
      clock: () => DateTime(2026, 1, 1).add(Duration(seconds: tick++)),
      online: online.stream,
      retryDelay: const Duration(hours: 1),
    );
  });

  tearDown(() async {
    await repo.dispose();
    await online.close();
    await db.close();
  });

  Future<DownloadJob> job(String id) =>
      (db.select(db.downloadJobs)..where((t) => t.id.equals(id))).getSingle();
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('pause keeps progress, resume runs it again', () async {
    final id = await repo.enqueue(
      const DownloadRequest(info: info, mode: DownloadMode.video),
    );
    engine.emit(EngineEvent(id: id, status: 'running', progress: 42));
    await settle();
    await repo.pause(id);
    expect(engine.canceled, [id]);
    engine.emit(EngineEvent(id: id, status: 'canceled'));
    await settle();
    var j = await job(id);
    expect(j.status, JobStatus.paused);
    expect(j.progress, 42);

    engine.started.clear();
    await repo.unpause(id);
    await settle();
    j = await job(id);
    expect(j.status, JobStatus.running);
    expect(engine.started.keys, [id]);
  });

  test('paused and waiting jobs can be canceled', () async {
    final id = await repo.enqueue(
      const DownloadRequest(info: info, mode: DownloadMode.video),
    );
    await repo.pause(id);
    engine.emit(EngineEvent(id: id, status: 'canceled'));
    await settle();
    expect((await job(id)).status, JobStatus.paused);
    await repo.cancel(id);
    expect((await job(id)).status, JobStatus.canceled);
  });

  test('a paused job frees its slot for the next one', () async {
    final a = await repo.enqueue(
      const DownloadRequest(info: info, mode: DownloadMode.video),
    );
    await repo.enqueue(
      const DownloadRequest(info: info, mode: DownloadMode.video),
    );
    final c = await repo.enqueue(
      const DownloadRequest(info: info, mode: DownloadMode.video),
    );
    await repo.pause(a);
    engine.emit(EngineEvent(id: a, status: 'canceled'));
    await settle();
    expect((await job(c)).status, JobStatus.running);
  });

  test('a connection drop waits, then retries once back online', () async {
    final id = await repo.enqueue(
      const DownloadRequest(info: info, mode: DownloadMode.video),
    );
    online.add(false);
    engine.emit(
      EngineEvent(
        id: id,
        status: 'error',
        error:
            'ERROR: Unable to download webpage: <urlopen error [Errno 7] No address associated with hostname>',
      ),
    );
    await settle();
    var j = await job(id);
    expect(j.status, JobStatus.waiting);
    expect(j.attempts, 1);

    engine.started.clear();
    online.add(true);
    await settle();
    j = await job(id);
    expect(j.status, JobStatus.running);
    expect(engine.started.keys, [id]);
  });

  test('nothing new starts while offline', () async {
    online.add(false);
    await settle();
    final id = await repo.enqueue(
      const DownloadRequest(info: info, mode: DownloadMode.video),
    );
    expect((await job(id)).status, JobStatus.queued);
    online.add(true);
    await settle();
    expect((await job(id)).status, JobStatus.running);
  });

  test(
    'a real error still fails, and so does the 6th connection drop',
    () async {
      final id = await repo.enqueue(
        const DownloadRequest(info: info, mode: DownloadMode.video),
      );
      engine.emit(
        EngineEvent(id: id, status: 'error', error: 'ERROR: Video unavailable'),
      );
      await settle();
      expect((await job(id)).status, JobStatus.failed);

      final b = await repo.enqueue(
        const DownloadRequest(info: info, mode: DownloadMode.video),
      );
      for (var i = 0; i < DownloadRepository.maxAutoRetries + 1; i++) {
        engine.emit(
          EngineEvent(id: b, status: 'error', error: 'Read timed out'),
        );
        await settle();
        online
          ..add(false)
          ..add(true);
        await settle();
      }
      expect((await job(b)).status, JobStatus.failed);
    },
  );

  test('playlist entries are parsed, broken ones skipped', () {
    final info = MediaInfo.fromJson('https://youtube.com/playlist?list=x', {
      '_type': 'playlist',
      'title': 'Mix',
      'entries': [
        {
          'id': 'a1',
          'ie_key': 'Youtube',
          'url': 'a1',
          'title': 'One',
          'duration': 61,
        },
        {'id': 'b2', 'url': 'https://www.tiktok.com/@u/video/b2', 'title': ''},
        {'id': 'c3', 'title': 'No link'},
      ],
    });
    expect(info.isPlaylist, isTrue);
    expect(info.entries.map((e) => e.url), [
      'https://www.youtube.com/watch?v=a1',
      'https://www.tiktok.com/@u/video/b2',
    ]);
    expect(info.entries[1].title, 'Untitled');
    expect(info.entries.first.duration, 61);
  });

  test('preview picks a small stream with sound', () {
    final i = MediaInfo.fromJson('u', {
      'title': 't',
      'duration': 60,
      'formats': [
        {
          'format_id': 'v',
          'vcodec': 'avc1',
          'acodec': 'none',
          'height': 360,
          'url': 'v',
        },
        {
          'format_id': '18',
          'vcodec': 'avc1',
          'acodec': 'mp4a',
          'height': 360,
          'ext': 'mp4',
          'url': 'p',
          'protocol': 'https',
          'http_headers': {'User-Agent': 'x'},
        },
        {
          'format_id': '22',
          'vcodec': 'avc1',
          'acodec': 'mp4a',
          'height': 720,
          'ext': 'mp4',
          'url': 'q',
          'protocol': 'https',
        },
      ],
    });
    expect(i.previewFormat!.url, 'p');
    expect(i.previewFormat!.headers['User-Agent'], 'x');
  });

  test('cookie header from yt-dlp cookies', () {
    expect(
      cookieHeader(
        'tt_chain_token=abc; Domain=.tiktok.com; Path=/; Expires=1799999999; Secure; ttwid=1%7Cx; Domain=.tiktok.com; HttpOnly',
      ),
      'tt_chain_token=abc; ttwid=1%7Cx',
    );
    expect(cookieHeader(null), isNull);
    expect(cookieHeader('Domain=.x.com; Path=/'), isNull);
  });

  test('cookies from the jar match the stream host', () {
    const jar =
        '# Netscape HTTP Cookie File\n'
        '.tiktok.com\tTRUE\t/\tTRUE\t1799999999\ttt_chain_token\tabc\n'
        '#HttpOnly_.tiktok.com\tTRUE\t/\tTRUE\t0\tttwid\txyz\n'
        '.youtube.com\tTRUE\t/\tTRUE\t0\tYSC\tnope\n';
    expect(
      cookiesForUrl(jar, 'https://v16-webapp.tiktok.com/video/1.mp4'),
      'tt_chain_token=abc; ttwid=xyz',
    );
    expect(cookiesForUrl(jar, 'https://example.com/x'), isNull);
  });

  test('speed labels', () {
    expect(DownloadRepository.speedLabel('2.30MiB/s'), '2.3 MB/s');
    expect(DownloadRepository.speedLabel('512.00KiB/s'), '512 KB/s');
    expect(DownloadRepository.speedLabel('900B/s'), '900 B/s');
    expect(DownloadRepository.speedLabel('Unknown B/s'), isNull);
  });

  test('trim adds download sections', () {
    final args = buildDownloadArgs(
      mode: DownloadMode.audioOnly,
      trimStart: 10,
      trimEnd: 65.5,
    );
    expect(args.join(' '), contains('--download-sections *10-65.5'));
    expect(trimSuffix(10, 65.5), ' (0m10s-1m05s)');
    expect(trimSuffix(null, null), '');
    expect(
      buildDownloadArgs(mode: DownloadMode.video, trimStart: 30).join(' '),
      contains('*30-inf'),
    );
  });
}
