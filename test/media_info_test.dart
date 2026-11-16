import 'package:flutter_test/flutter_test.dart';
import 'package:grab/data/engine/media_info.dart';

void main() {
  final youtubeLike = {
    'title': 'Rooftop session',
    'duration': 100,
    'extractor_key': 'Youtube',
    'formats': [
      {'format_id': '140', 'vcodec': 'none', 'acodec': 'mp4a', 'filesize': 1600000},
      {'format_id': '137', 'vcodec': 'avc1', 'acodec': 'none', 'height': 1080, 'filesize': 40000000},
      {'format_id': '136', 'vcodec': 'avc1', 'acodec': 'none', 'height': 720, 'filesize': 20000000},
      {'format_id': '18', 'vcodec': 'avc1', 'acodec': 'mp4a', 'height': 360, 'filesize_approx': 5000000},
    ],
  };

  test('lists video heights best first, adding best audio to the size', () {
    final info = MediaInfo.fromJson('u', youtubeLike);
    final opts = info.optionsFor(DownloadMode.videoAndAudio);
    expect(opts.map((o) => o.label), ['1080p', '720p', '360p']);
    expect(opts.first.bytes, 41600000);
    expect(opts.last.bytes, 5000000);
  });

  test('video only ignores audio size', () {
    final info = MediaInfo.fromJson('u', youtubeLike);
    expect(info.optionsFor(DownloadMode.videoOnly).first.bytes, 40000000);
  });

  test('audio only offers one best-audio option', () {
    final info = MediaInfo.fromJson('u', youtubeLike);
    final opts = info.optionsFor(DownloadMode.audioOnly);
    expect(opts.single.label, 'Best audio');
    expect(opts.single.bytes, 1600000);
  });

  test('single-file sites without a formats list still get an option', () {
    final info = MediaInfo.fromJson('u', {
      'title': 'Pin',
      'format_id': 'hls-720',
      'height': 720,
      'duration': 10,
      'tbr': 800,
    });
    final opts = info.optionsFor(DownloadMode.videoAndAudio);
    expect(opts.single.label, '720p');
    expect(opts.single.bytes, 1000000);
  });

  test('detects playlists such as Pinterest boards', () {
    final info = MediaInfo.fromJson('u', {
      '_type': 'playlist',
      'title': 'Board',
      'entries': [{}, {}, {}],
    });
    expect(info.isPlaylist, isTrue);
    expect(info.entryCount, 3);
  });

  test('builds yt-dlp args per mode', () {
    expect(buildDownloadArgs(mode: DownloadMode.videoAndAudio, maxHeight: 720),
        ['-f', 'bv*[height<=720]+ba/b[height<=720]/bv*+ba/b', '-S', 'vcodec:h264,acodec:aac', '--merge-output-format', 'mp4']);
    expect(buildDownloadArgs(mode: DownloadMode.audioOnly),
        ['-f', 'ba/b', '-x', '--audio-format', 'mp3', '--audio-quality', '0']);
    expect(buildDownloadArgs(mode: DownloadMode.videoOnly).contains('VideoRemuxer:-an'), isTrue);
  });

  test('formats sizes', () {
    expect(formatBytes(48 * 1024 * 1024), '48 MB');
    expect(formatBytes(null), isNull);
  });

  group('subtitles', () {
    final withSubs = {
      'id': 'abc',
      'title': 'Talk',
      'subtitles': {
        'fr': [{'ext': 'vtt', 'name': 'French'}],
        'en': [{'ext': 'vtt', 'name': 'English'}],
        'live_chat': [{'ext': 'json'}],
      },
      'automatic_captions': {
        'en-orig': [{'ext': 'vtt', 'name': 'English (Original)'}],
        'de': [{'ext': 'vtt', 'name': 'German'}],
      },
    };

    test('lists uploaded tracks, then the original-language auto track', () {
      final info = MediaInfo.fromJson('u', withSubs);
      expect(info.id, 'abc');
      expect(info.subtitles.map((t) => t.lang), ['en', 'fr', 'en-orig']);
      expect(info.subtitles.last.auto, isTrue);
    });

    test('adds subtitle args to a video download, embedded', () {
      final args = buildDownloadArgs(
        mode: DownloadMode.videoAndAudio,
        subtitles: const SubtitleChoice(langs: ['en', 'fr'], embed: true),
      );
      expect(args, containsAllInOrder(['--write-subs', '--sub-langs', 'en,fr', '--convert-subs', 'srt', '--embed-subs']));
      expect(args, isNot(contains('--write-auto-subs')));
    });

    test('subtitles only skips the media and never embeds', () {
      final args = buildDownloadArgs(
        mode: DownloadMode.subtitlesOnly,
        subtitles: const SubtitleChoice(langs: ['en-orig'], includeAuto: true, embed: true),
      );
      expect(args.first, '--skip-download');
      expect(args, contains('--write-auto-subs'));
      expect(args, isNot(contains('--embed-subs')));
      expect(args, isNot(contains('-f')));
    });

    test('audio downloads ignore subtitles', () {
      final args = buildDownloadArgs(
        mode: DownloadMode.audioOnly,
        subtitles: const SubtitleChoice(langs: ['en']),
      );
      expect(args, isNot(contains('--write-subs')));
    });
  });
}
