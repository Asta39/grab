import 'dart:io';

import 'package:path/path.dart' as p;

import '../../data/db/app_database.dart';

enum LibraryKind { video, audio, subtitles }

/// One saved file, shown as a tile in the Library.
class LibraryItem {
  const LibraryItem({
    required this.jobId,
    required this.path,
    required this.title,
    required this.kind,
    this.thumbnail,
    this.site,
    this.finishedAt,
  });

  final String jobId;
  final String path;
  final String title;
  final LibraryKind kind;
  final String? thumbnail;
  final String? site;
  final DateTime? finishedAt;

  String get fileName => p.basename(path);
  String get ext => p.extension(path).replaceFirst('.', '').toUpperCase();
}

const _audioExt = {'.mp3', '.m4a', '.opus', '.flac', '.ogg', '.wav', '.aac'};
const _subExt = {'.srt', '.vtt', '.ass'};

LibraryKind kindOf(String path) {
  final e = p.extension(path).toLowerCase();
  if (_audioExt.contains(e)) return LibraryKind.audio;
  if (_subExt.contains(e)) return LibraryKind.subtitles;
  return LibraryKind.video;
}

/// Files from finished jobs that still exist, newest first, one tile per file.
/// The same file saved by several jobs appears once.
List<LibraryItem> buildLibrary(
  Iterable<DownloadJob> jobs, {
  required bool Function(String path) exists,
}) {
  final done = jobs.where((j) => j.status == JobStatus.done).toList()
    ..sort(
      (a, b) =>
          (b.finishedAt ?? b.createdAt).compareTo(a.finishedAt ?? a.createdAt),
    );
  final seen = <String>{};
  final out = <LibraryItem>[];
  for (final j in done) {
    for (final path in j.paths.split('\n')) {
      if (path.isEmpty || !seen.add(path) || !exists(path)) continue;
      out.add(
        LibraryItem(
          jobId: j.id,
          path: path,
          title: j.title,
          kind: kindOf(path),
          thumbnail: j.thumbnail,
          site: j.site,
          finishedAt: j.finishedAt,
        ),
      );
    }
  }
  return out;
}

/// Library filter: null kind = everything except loose subtitle files.
List<LibraryItem> filterLibrary(
  List<LibraryItem> items, {
  LibraryKind? kind,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return items.where((i) {
    if (kind == null
        ? i.kind == LibraryKind.subtitles &&
              items.any(
                (o) => o.jobId == i.jobId && o.kind != LibraryKind.subtitles,
              )
        : i.kind != kind) {
      return false;
    }
    return q.isEmpty ||
        i.title.toLowerCase().contains(q) ||
        i.fileName.toLowerCase().contains(q);
  }).toList();
}

/// "614 KB", "48 MB", "1.2 GB", or null if the file is gone.
String? fileSizeLabel(String path) {
  try {
    final b = File(path).lengthSync();
    if (b >= 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(1)} GB';
    if (b >= 1 << 20) return '${(b / (1 << 20)).round()} MB';
    return '${(b / 1024).ceil()} KB';
  } catch (_) {
    return null;
  }
}
