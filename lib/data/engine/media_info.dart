import 'dart:convert';

/// What the user wants out of a link.
enum DownloadMode {
  /// The video as is, with its sound. One file.
  video,

  /// The video with its sound, plus the audio extracted to its own file. Two files.
  videoAndAudio,

  /// Only the extracted audio.
  audioOnly,

  /// Only subtitle files.
  subtitlesOnly,
}

/// One subtitle language a link offers.
class SubtitleTrack {
  const SubtitleTrack({
    required this.lang,
    required this.name,
    this.auto = false,
  });

  /// yt-dlp language code, e.g. "en", "pt-BR", "en-orig".
  final String lang;
  final String name;

  /// True for machine-made captions (YouTube auto captions).
  final bool auto;
}

/// Which subtitles to fetch with a download.
class SubtitleChoice {
  const SubtitleChoice({
    this.langs = const [],
    this.includeAuto = false,
    this.embed = false,
  });

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
    this.url,
    this.protocol,
    this.headers = const {},
  });

  final String id;

  /// The same format with [cookie] added to (or merged into) its Cookie header.
  MediaFormat withCookie(String? cookie) {
    if (cookie == null || cookie.isEmpty) return this;
    final h = {...headers};
    h['Cookie'] = h['Cookie'] == null ? cookie : '${h['Cookie']}; $cookie';
    return MediaFormat(
      id: id,
      height: height,
      ext: ext,
      hasVideo: hasVideo,
      hasAudio: hasAudio,
      bytes: bytes,
      url: url,
      protocol: protocol,
      headers: h,
    );
  }

  /// Direct stream address and the headers the site wants, for previews.
  final String? url;
  final String? protocol;
  final Map<String, String> headers;
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
    var bytes =
        (j['filesize'] as num?)?.toInt() ??
        (j['filesize_approx'] as num?)?.toInt();
    final tbr = (j['tbr'] as num?)?.toDouble();
    if (bytes == null && tbr != null && duration != null) {
      bytes = (tbr * 1000 / 8 * duration).round();
    }
    final rawHeaders = j['http_headers'];
    final headers = <String, String>{
      if (rawHeaders is Map)
        for (final e in rawHeaders.entries) '${e.key}': '${e.value}',
    };
    // Sites like TikTok only serve the file with the cookies yt-dlp got.
    final cookie = cookieHeader(j['cookies'] as String?);
    if (cookie != null) headers['Cookie'] = cookie;
    return MediaFormat(
      url: j['url'] as String?,
      protocol: j['protocol'] as String?,
      headers: headers,
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

/// One item of a playlist or profile (from yt-dlp's flat listing).
class PlaylistEntry {
  const PlaylistEntry({
    required this.url,
    required this.title,
    this.id,
    this.thumbnail,
    this.duration,
  });

  final String url;
  final String title;
  final String? id;
  final String? thumbnail;
  final double? duration;

  /// Null when the entry has no usable link (private or removed items).
  static PlaylistEntry? fromJson(Map<String, dynamic> j) {
    var url = j['webpage_url'] as String? ?? j['url'] as String?;
    final id = j['id']?.toString();
    if (url != null && !url.startsWith('http')) {
      url = (j['ie_key'] == 'Youtube' && id != null)
          ? 'https://www.youtube.com/watch?v=$id'
          : null;
    }
    if (url == null) return null;
    final title = (j['title'] as String?)?.trim();
    return PlaylistEntry(
      url: url,
      id: id,
      title: title == null || title.isEmpty ? 'Untitled' : title,
      thumbnail:
          j['thumbnail'] as String? ?? MediaInfo._lastThumb(j['thumbnails']),
      duration: (j['duration'] as num?)?.toDouble(),
    );
  }
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
    this.entries = const [],
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

  /// Items of a playlist or profile, in order.
  final List<PlaylistEntry> entries;

  factory MediaInfo.fromJsonString(
    String url,
    String raw, {
    String? cookieJar,
  }) => MediaInfo.fromJson(
    url,
    jsonDecode(raw) as Map<String, dynamic>,
    cookieJar: cookieJar,
  );

  factory MediaInfo.fromJson(
    String url,
    Map<String, dynamic> j, {
    String? cookieJar,
  }) {
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
    // Add the cookies yt-dlp collected for each stream's host, so the preview
    // player is let in like yt-dlp was.
    if (cookieJar != null && cookieJar.trim().isNotEmpty) {
      formats = [
        for (final f in formats)
          f.url == null ? f : f.withCookie(cookiesForUrl(cookieJar, f.url!)),
      ];
    }
    final isPlaylist = j['_type'] == 'playlist';
    final entries = isPlaylist
        ? ((j['entries'] as List?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PlaylistEntry.fromJson)
              .nonNulls
              .toList()
        : const <PlaylistEntry>[];
    return MediaInfo(
      url: url,
      id: j['id']?.toString(),
      subtitles: [
        ..._tracks(j['subtitles'], auto: false),
        ..._tracks(j['automatic_captions'], auto: true),
      ],
      title: (j['title'] as String?)?.trim().isNotEmpty == true
          ? j['title'] as String
          : 'Untitled',
      thumbnail:
          j['thumbnail'] as String? ??
          _lastThumb(j['thumbnails']) ??
          entries.map((e) => e.thumbnail).nonNulls.firstOrNull,
      duration: duration,
      uploader: j['uploader'] as String? ?? j['channel'] as String?,
      site: j['extractor_key'] as String? ?? j['ie_key'] as String?,
      formats: formats,
      isPlaylist: isPlaylist,
      entryCount: isPlaylist ? ((j['entries'] as List?)?.length ?? 0) : 0,
      entries: entries,
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
      final first = list is List && list.isNotEmpty && list.first is Map
          ? list.first as Map
          : const {};
      out.add(
        SubtitleTrack(
          lang: code,
          name: (first['name'] as String?) ?? code,
          auto: auto,
        ),
      );
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

  /// A small stream with picture and sound that the preview player can open:
  /// the lowest height of at least 240p, MP4 over HTTPS preferred. Null when
  /// the site only offers separate video and audio streams.
  MediaFormat? get previewFormat {
    final playable = formats.where(
      (f) =>
          f.hasVideo &&
          f.hasAudio &&
          f.url != null &&
          (f.protocol == null ||
              f.protocol!.startsWith('http') ||
              f.protocol!.startsWith('m3u8')),
    );
    if (playable.isEmpty) return null;
    int score(MediaFormat f) {
      final h = f.height ?? 360;
      return (h < 240 ? 2000 : 0) +
          (h - 360).abs() +
          (f.ext == 'mp4' ? 0 : 300) +
          (f.protocol?.startsWith('m3u8') == true ? 150 : 0);
    }

    return (playable.toList()..sort((a, b) => score(a) - score(b))).first;
  }

  /// Quality choices for [mode], best first.
  List<QualityOption> optionsFor(DownloadMode mode) {
    if (mode == DownloadMode.subtitlesOnly) {
      return const [QualityOption(label: 'Subtitles (.srt)')];
    }
    final bestAudio = _largest(formats.where((f) => f.hasAudio && !f.hasVideo));
    if (mode == DownloadMode.audioOnly) {
      final src = bestAudio ?? _largest(formats.where((f) => f.hasAudio));
      return [QualityOption(label: 'Best audio', bytes: src?.bytes)];
    }
    final heights =
        formats
            .where((f) => f.hasVideo && f.height != null)
            .map((f) => f.height!)
            .toSet()
            .toList()
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
    final muxed = _largest(atHeight.where((f) => f.hasAudio));
    final silent = _largest(atHeight.where((f) => !f.hasAudio));
    final withSound = silent?.bytes != null && bestAudio?.bytes != null
        ? silent!.bytes! + bestAudio!.bytes!
        : muxed?.bytes ?? silent?.bytes;
    if (mode == DownloadMode.videoAndAudio && withSound != null) {
      // Plus the extracted audio file, roughly the size of the best audio stream.
      return withSound + (bestAudio?.bytes ?? 0);
    }
    return withSound;
  }

  static MediaFormat? _largest(Iterable<MediaFormat> fs) {
    MediaFormat? best;
    for (final f in fs) {
      if (best == null || (f.bytes ?? 0) > (best.bytes ?? 0)) best = f;
    }
    return best;
  }
}

/// yt-dlp's "cookies" field ("a=1; Domain=.x.com; Path=/; b=2; Secure") as a
/// Cookie request header ("a=1; b=2"). Null when there are none.
String? cookieHeader(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  const attrs = {
    'domain',
    'path',
    'expires',
    'max-age',
    'secure',
    'httponly',
    'samesite',
    'comment',
    'version',
    'discard',
  };
  final pairs = <String>[];
  for (final part in raw.split(';')) {
    final p = part.trim();
    final i = p.indexOf('=');
    final key = (i < 0 ? p : p.substring(0, i)).trim();
    if (i <= 0 || attrs.contains(key.toLowerCase())) continue;
    pairs.add(p);
  }
  return pairs.isEmpty ? null : pairs.join('; ');
}

/// Cookie header for [url] from a Netscape cookie file (as yt-dlp writes it).
String? cookiesForUrl(String jar, String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.isEmpty) return null;
  final pairs = <String>[];
  for (var line in jar.split('\n')) {
    // yt-dlp marks HttpOnly cookies with this prefix; they still count.
    if (line.startsWith('#HttpOnly_')) line = line.substring(10);
    if (line.isEmpty || line.startsWith('#')) continue;
    final f = line.split('\t');
    if (f.length < 7) continue;
    final domain = f[0].toLowerCase().replaceFirst(RegExp(r'^\.'), '');
    if (host == domain || host.endsWith('.$domain')) {
      pairs.add('${f[5]}=${f[6].trim()}');
    }
  }
  return pairs.isEmpty ? null : pairs.join('; ');
}

/// Builds the yt-dlp arguments for a download.
List<String> buildDownloadArgs({
  required DownloadMode mode,
  int? maxHeight,
  String container = 'mp4',
  String audioFormat = 'mp3',
  SubtitleChoice subtitles = SubtitleChoice.none,
  double? trimStart,
  double? trimEnd,
}) {
  final trim =
      mode != DownloadMode.subtitlesOnly &&
      (trimStart != null || trimEnd != null);
  return [
    ..._mediaArgs(mode, maxHeight, container, audioFormat),
    ..._subtitleArgs(mode, subtitles),
    if (trim) ...[
      '--download-sections',
      '*${_secs(trimStart ?? 0)}-${trimEnd == null ? 'inf' : _secs(trimEnd)}',
    ],
  ];
}

String _secs(double s) => s.toStringAsFixed(s == s.roundToDouble() ? 0 : 1);

/// File-name suffix for a trimmed download, e.g. " (0m10s-1m05s)", so it never
/// overwrites the full version. Empty when not trimmed.
String trimSuffix(double? start, double? end) {
  if (start == null && end == null) return '';
  String t(double s) {
    final d = Duration(milliseconds: (s * 1000).round());
    return '${d.inMinutes}m${d.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
  }

  return ' (${t(start ?? 0)}-${end == null ? 'end' : t(end)})';
}

/// "1:05", "1:02:03".
String clockLabel(double seconds) {
  final d = Duration(seconds: seconds.round());
  final m = d.inMinutes
      .remainder(60)
      .toString()
      .padLeft(d.inHours > 0 ? 2 : 1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

List<String> _subtitleArgs(DownloadMode mode, SubtitleChoice s) {
  if (s.isEmpty || mode == DownloadMode.audioOnly) return const [];
  final embed = s.embed && mode != DownloadMode.subtitlesOnly;
  return [
    '--write-subs',
    if (s.includeAuto) '--write-auto-subs',
    '--sub-langs',
    s.langs.join(','),
    '--convert-subs',
    'srt',
    if (embed) '--embed-subs',
  ];
}

List<String> _mediaArgs(
  DownloadMode mode,
  int? maxHeight,
  String container,
  String audioFormat,
) {
  final h = maxHeight == null ? '' : '[height<=$maxHeight]';
  switch (mode) {
    case DownloadMode.subtitlesOnly:
      return ['--skip-download'];
    case DownloadMode.video:
      return _videoArgs(h, container);
    case DownloadMode.videoAndAudio:
      // Extract the audio from the finished video and keep the video (-k).
      return [..._videoArgs(h, container), ..._extractArgs(audioFormat), '-k'];
    case DownloadMode.audioOnly:
      return ['-f', 'ba/b', ..._extractArgs(audioFormat)];
  }
}

List<String> _videoArgs(String h, String container) => [
  '-f',
  'bv*$h+ba/b$h/bv*+ba/b',
  ..._compat(container),
  '--merge-output-format',
  container,
];

List<String> _extractArgs(String audioFormat) => [
  '-x',
  '--audio-format',
  audioFormat,
  '--audio-quality',
  '0',
];

/// MP4 plays everywhere only with H.264 video and AAC audio; prefer those when they exist.
List<String> _compat(String container) =>
    container == 'mp4' ? const ['-S', 'vcodec:h264,acodec:aac'] : const [];

/// "48 MB", "820 KB", or null.
String? formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return null;
  const mb = 1024 * 1024;
  if (bytes >= 1024 * mb) {
    return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
  }
  if (bytes >= mb) return '${(bytes / mb).round()} MB';
  return '${(bytes / 1024).round()} KB';
}

/// Name template tokens the user can type, e.g. "{title} - {site}".
const fileNameTokens = {
  '{title}': '%(title).80B',
  '{id}': '%(id)s',
  '{site}': '%(extractor_key)s',
  '{uploader}': '%(uploader,channel|Unknown)s',
  '{date}': '%(upload_date>%Y-%m-%d|undated)s',
};

const defaultFileTemplate = '{title} [{id}]';

/// Turns the user's template into a yt-dlp output name (no extension).
/// Unknown braces and path characters are removed; empty falls back to the default.
String ytDlpTemplate(String template) {
  final clean = _cleanTemplate(template);
  // Escape yt-dlp's own % in the user's text, then swap in the tokens.
  var t = clean.replaceAll('%', '%%');
  fileNameTokens.forEach((k, v) => t = t.replaceAll(k, v));
  return t;
}

/// Drops path characters and unknown {tokens}; empty falls back to the default.
String _cleanTemplate(String template) {
  var t = template
      .replaceAllMapped(
        RegExp(r'\{[^}]*\}'),
        (m) => fileNameTokens.containsKey(m[0]) ? m[0]! : '',
      )
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (!fileNameTokens.keys.any(t.contains)) t = defaultFileTemplate;
  return t;
}

/// What a template produces for a sample video, for the Settings preview.
String previewFileName(String template, {String ext = 'mp4'}) {
  var t = _cleanTemplate(template);
  const sample = {
    '{title}': 'Sunset timelapse',
    '{id}': 'dQw4w9WgXcQ',
    '{site}': 'Youtube',
    '{uploader}': 'Nature Clips',
    '{date}': '2026-11-17',
  };
  sample.forEach((k, v) => t = t.replaceAll(k, v));
  return '$t.$ext';
}
