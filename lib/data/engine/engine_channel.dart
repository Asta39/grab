import 'package:flutter/services.dart';

import '../repositories/download_repository.dart';
import 'media_info.dart';

/// A progress or status event for one download job.
class EngineEvent {
  const EngineEvent({
    required this.id,
    required this.status,
    this.progress,
    this.eta,
    this.line,
    this.paths = const [],
    this.error,
  });

  final String id;

  /// starting | running | done | canceled | error
  final String status;
  final double? progress;
  final int? eta;
  final String? line;

  /// Files written by a finished job: the media file and any .srt subtitles.
  final List<String> paths;
  final String? error;

  bool get isFinal =>
      status == 'done' || status == 'error' || status == 'canceled';

  factory EngineEvent.fromMap(Map<Object?, Object?> m) => EngineEvent(
    id: m['id'] as String,
    status: m['status'] as String,
    progress: (m['progress'] as num?)?.toDouble(),
    eta: (m['eta'] as num?)?.toInt(),
    line: m['line'] as String?,
    paths: ((m['paths'] as List?) ?? const []).cast<String>(),
    error: m['error'] as String?,
  );
}

/// Dart side of the Kotlin EnginePlugin (yt-dlp via youtubedl-android).
class EngineChannel implements DownloadEngine {
  static const _methods = MethodChannel('grab/engine');
  static const _events = EventChannel('grab/engine/progress');

  @override
  late final Stream<EngineEvent> events = _events.receiveBroadcastStream().map(
    (e) => EngineEvent.fromMap(e as Map<Object?, Object?>),
  );

  /// Unpacks Python and yt-dlp on first run. Returns the yt-dlp version.
  Future<String?> init() => _methods.invokeMethod<String>('init');

  Future<String?> update() => _methods.invokeMethod<String>('update');

  Future<String?> outputDir() => _methods.invokeMethod<String>('outputDir');

  Future<MediaInfo> fetch(String url) async {
    final raw = await _methods.invokeMethod<String>('fetch', {'url': url});
    return MediaInfo.fromJsonString(url, raw!);
  }

  /// [suffix] is added to the file name so different modes don't overwrite each other.
  /// [match] is text every output file name contains (the item id), used to find subtitle files.
  @override
  Future<void> download({
    required String id,
    required String url,
    required List<String> args,
    String suffix = '',
    String? match,
    String title = 'Download',
  }) => _methods.invokeMethod('download', {
    'id': id,
    'url': url,
    'args': args,
    'suffix': suffix,
    'match': match,
    'title': title,
  });

  /// Extracts the audio of a saved file with FFmpeg; progress arrives on [events] under [id].
  Future<void> extractAudio({
    required String id,
    required String input,
    required String format,
    String? title,
  }) => _methods.invokeMethod('extractAudio', {
    'id': id,
    'input': input,
    'format': format,
    'title': title,
  });

  @override
  Future<bool> cancel(String id) async =>
      await _methods.invokeMethod<bool>('cancel', {'id': id}) ?? false;
}
