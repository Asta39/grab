import 'dart:convert';

/// What the user wants out of a link.
enum DownloadMode { videoAndAudio, videoOnly, audioOnly, subtitlesOnly }

/// One subtitle language a link offers.
class SubtitleTrack {
  const SubtitleTrack({required this.lang, required this.name, this.auto = false});

  /// yt-dlp language code, e.g. "en", "pt-BR", "en-orig".
  final String lang;
  final String name;

  /// True for machine-made captions (YouTube auto captions).
  final bool auto;
}

/// Which subtitles to fetch with a download.
class SubtitleChoice {
  const SubtitleChoice({this.langs = const [], this.includeAuto = false, this.embed = false});

  static const none = SubtitleChoice();

  final List<String> langs;
  final bool includeAuto;

  /// Put the subtitles inside the video file instead of a separate .srt.
  final bool embed;

  bool get isEmpty => langs.isEmpty;
}

/// One raw format reported by yt-dlp.
class MediaFormat {
  const MediaFormat({
    required this.id,
    this.height,
    this.ext,
    this.hasVideo = false,
    this.hasAudio = false,
    this.bytes,
  });

  final String id;
  final int? height;
  final String? ext;
  final bool hasVideo;
  final bool hasAudio;

  /// Exact or estimated size in bytes, when known.
  final int? bytes;

  factory MediaFormat.fromJson(Map<String, dynamic> j, double? duration) {
    final vcodec = j['vcodec'] as String?;
    final acodec = j['acodec'] as String?;
    final height = (j['height'] as num?)?.toInt();
    // yt-dlp leaves codecs null when it doesn't know; treat height as a video hint.
    final hasVideo = vcodec != null ? vcodec != 'none' : height != null;
    final hasAudio = acodec != null ? acodec != 'none' : !hasVideo;
    var bytes = (j['filesize'] as num?)?.toInt() ?? (j['filesize_approx'] as num?)?.toInt();
    final tbr = (j['tbr'] as num?)?.toDouble();
    if (bytes == null && tbr != null && duration != null) {
      bytes = (tbr * 1000 / 8 * duration).round();
    }
    return MediaFormat(
      id: '${j['format_id']}',
      height: height,
      ext: j['ext'] as String?,
      hasVideo: hasVideo,
      hasAudio: hasAudio,
      bytes: bytes,
    );
  }
}

/// A choice shown on the Choose format screen.
class QualityOption {
  const QualityOption({required this.label, this.height, this.bytes});

  /// e.g. "1080p" or "Best audio".
  final String label;

  /// Max height for video modes, null for audio.
  final int? height;

  /// Estimated size, null when unknown.
  final int? bytes;
}

/// Metadata for one link, parsed from `yt-dlp --dump-single-json`.
class MediaInfo {
  const MediaInfo({
    required this.url,
    required this.title,
    this.id,
    this.subtitles = const [],
    this.thumbnail,
    this.duration,
    this.uploader,
    this.site,
    this.formats = const [],
    this.isPlaylist = false,
    this.entryCount = 0,
  });

  final String url;
  final String title;

  /// The site's own id for the item, used in file names.
  final String? id;

  /// Subtitle languages: uploaded ones first, then auto captions.
  final List<SubtitleTrack> subtitles;
  final String? thumbnail;
  final double? duration;
  final String? uploader;
  final String? site;
  final List<MediaFormat> formats;
  final bool isPlaylist;
  final int entryCount;

  factory MediaInfo.fromJsonString(String url, String raw) =>
      MediaInfo.fromJson(url, jsonDecode(raw) as Map<String, dynamic>);

  factory MediaInfo.fromJson(String url, Map<String, dynamic> j) {
    final duration = (j['duration'] as num?)?.toDouble();
    final rawFormats = (j['formats'] as List?) ?? const [];
    var formats = rawFormats
        .whereType<Map<String, dynamic>>()
        .map((f) => MediaFormat.fromJson(f, duration))
        .toList();
    // Some extractors return a single file with no formats list.
    if (formats.isEmpty && j['format_id'] != null) {
      formats = [MediaFormat.fromJson(j, duration)];
    }
    final isPlaylist = j['_type'] == 'playlist';
    return MediaInfo(
      url: url,
      id: j['id']?.toString(),
      subtitles: [..._tracks(j['subtitles'], auto: false), ..._tracks(j['automatic_captions'], auto: true)],
      title: (j['title'] as String?)?.trim().isNotEmpty == true ? j['title'] as String : 'Untitled',
      thumbnail: j['thumbnail'] as String? ?? _lastThumb(j['thumbnails']),
      duration: duration,
      uploader: j['uploader'] as String? ?? j['channel'] as String?,
      site: j['extractor_key'] as String? ?? j['ie_key'] as String?,
      formats: formats,
      isPlaylist: isPlaylist,
      entryCount: isPlaylist ? ((j['entries'] as List?)?.length ?? 0) : 0,
    );
  }

  static List<SubtitleTrack> _tracks(Object? raw, {required bool auto}) {
    if (raw is! Map) return const [];
    final out = <SubtitleTrack>[];
    raw.forEach((lang, list) {
      final code = lang.toString();
      if (code == 'live_chat') return;
      // YouTube lists ~150 machine translations; keep only the original-language track.
      if (auto && !code.endsWith('-orig')) return;
      final first = list is List && list.isNotEmpty && list.first is Map ? list.first as Map : const {};
      out.add(SubtitleTrack(lang: code, name: (first['name'] as String?) ?? code, auto: auto));
    });
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  static String? _lastThumb(Object? thumbs) {
    if (thumbs is List && thumbs.isNotEmpty) {
      final last = thumbs.last;
      if (last is Map && last['url'] is String) return last['url'] as String;
    }
    return null;
  }

  /// Quality choices for [mode], best first.
  List<QualityOption> optionsFor(DownloadMode mode) {
    if (mode == DownloadMode.subtitlesOnly) return const [QualityOption(label: 'Subtitles (.srt)')];
    final bestAudio = _largest(formats.where((f) => f.hasAudio && !f.hasVideo));
    if (mode == DownloadMode.audioOnly) {
      final src = bestAudio ?? _largest(formats.where((f) => f.hasAudio));
      return [QualityOption(label: 'Best audio', bytes: src?.bytes)];
    }
    final heights = formats.where((f) => f.hasVideo && f.height != null).map((f) => f.height!).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (heights.isEmpty) return [const QualityOption(label: 'Best available')];
    return [
      for (final h in heights)
        QualityOption(
          label: '${h}p',
          height: h,
          bytes: _sizeAt(h, mode, bestAudio),
        ),
    ];
  }

  int? _sizeAt(int height, DownloadMode mode, MediaFormat? bestAudio) {
    final atHeight = formats.where((f) => f.hasVideo && f.height == height);
    if (mode == DownloadMode.videoAndAudio) {
      final muxed = _largest(atHeight.where((f) => f.hasAudio));
      final videoOnly = _largest(atHeight.where((f) => !f.hasAudio));
      if (videoOnly?.bytes != null && bestAudio?.bytes != null) {
        return videoOnly!.bytes! + bestAudio!.bytes!;
      }
      return muxed?.bytes ?? videoOnly?.bytes;
    }
    return (_largest(atHeight.where((f) => !f.hasAudio)) ?? _largest(atHeight))?.bytes;
  }

  static MediaFormat? _largest(Iterable<MediaFormat> fs) {
    MediaFormat? best;
    for (final f in fs) {
      if (best == null || (f.bytes ?? 0) > (best.bytes ?? 0)) best = f;
    }
    return best;
  }
}

/// Builds the yt-dlp arguments for a download.
List<String> buildDownloadArgs({
  required DownloadMode mode,
  int? maxHeight,
  String container = 'mp4',
  String audioFormat = 'mp3',
  SubtitleChoice subtitles = SubtitleChoice.none,
}) {
  return [..._mediaArgs(mode, maxHeight, container, audioFormat), ..._subtitleArgs(mode, subtitles)];
}

List<String> _subtitleArgs(DownloadMode mode, SubtitleChoice s) {
  if (s.isEmpty || mode == DownloadMode.audioOnly) return const [];
  final embed = s.embed && mode != DownloadMode.subtitlesOnly;
  return [
    '--write-subs',
    if (s.includeAuto) '--write-auto-subs',
    '--sub-langs', s.langs.join(','),
    '--convert-subs', 'srt',
    if (embed) '--embed-subs',
  ];
}

List<String> _mediaArgs(DownloadMode mode, int? maxHeight, String container, String audioFormat) {
  final h = maxHeight == null ? '' : '[height<=$maxHeight]';
  switch (mode) {
    case DownloadMode.subtitlesOnly:
      return ['--skip-download'];
    case DownloadMode.videoAndAudio:
      return ['-f', 'bv*$h+ba/b$h/bv*+ba/b', ..._compat(container), '--merge-output-format', container];
    case DownloadMode.videoOnly:
      // Prefer a video-only stream; if the site only has combined files,
      // remux and strip the audio track.
      return [
        '-f', 'bv*$h/bv*/b$h/b',
        ..._compat(container),
        '--remux-video', container,
        '--ppa', 'VideoRemuxer:-an',
      ];
    case DownloadMode.audioOnly:
      return ['-f', 'ba/b', '-x', '--audio-format', audioFormat, '--audio-quality', '0'];
  }
}

/// MP4 plays everywhere only with H.264 video and AAC audio; prefer those when they exist.
List<String> _compat(String container) =>
    container == 'mp4' ? const ['-S', 'vcodec:h264,acodec:aac'] : const [];

/// File-name suffix per mode, so a video-only file never collides with the full video.
String fileSuffix(DownloadMode mode) => mode == DownloadMode.videoOnly ? ' (video only)' : '';

/// "48 MB", "820 KB", or null.
String? formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return null;
  const mb = 1024 * 1024;
  if (bytes >= 1024 * mb) return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
  if (bytes >= mb) return '${(bytes / mb).round()} MB';
  return '${(bytes / 1024).round()} KB';
}
