import 'package:flutter_test/flutter_test.dart';
import 'package:grab/data/db/app_database.dart';
import 'package:grab/features/library/library_items.dart';

DownloadJob job(
  String id,
  String paths, {
  JobStatus status = JobStatus.done,
  int minute = 0,
  String title = 'Clip',
}) => DownloadJob(
  id: id,
  url: 'u',
  title: title,
  mode: 'videoAndAudio',
  container: 'mp4',
  audioFormat: 'mp3',
  subLangs: '',
  subAuto: false,
  subEmbed: false,
  status: status,
  progress: 100,
  attempts: 0,
  paths: paths,
  createdAt: DateTime(2026, 1, 1, 0, minute),
  finishedAt: DateTime(2026, 1, 1, 0, minute),
);

void main() {
  test(
    'lists existing files of finished jobs, newest first, without duplicates',
    () {
      final items = buildLibrary([
        job('a', '/d/Old [x].mp4', minute: 1),
        job('b', '/d/New [y].mp3\n/d/gone.mp4', minute: 5),
        job('c', '/d/Old [x].mp4', minute: 3),
        job('d', '/d/Queued.mp4', status: JobStatus.running),
      ], exists: (p) => p != '/d/gone.mp4');
      expect(items.map((i) => i.fileName), ['New [y].mp3', 'Old [x].mp4']);
      expect(items.first.kind, LibraryKind.audio);
    },
  );

  test(
    'filters by kind and search, hiding subtitles that belong to a video',
    () {
      final items = buildLibrary([
        job(
          'a',
          '/d/Talk [t].mp4\n/d/Talk [t].en.srt',
          title: 'Conference talk',
        ),
        job('b', '/d/Song [s].mp3', title: 'Song'),
        job('c', '/d/Lecture [l].en.srt', title: 'Lecture'),
      ], exists: (_) => true);

      expect(filterLibrary(items).map((i) => i.fileName), [
        'Talk [t].mp4',
        'Song [s].mp3',
        'Lecture [l].en.srt',
      ]);
      expect(
        filterLibrary(items, kind: LibraryKind.audio).single.fileName,
        'Song [s].mp3',
      );
      expect(filterLibrary(items, kind: LibraryKind.subtitles).length, 2);
      expect(
        filterLibrary(items, query: 'TALK').single.kind,
        LibraryKind.video,
      );
    },
  );
}
