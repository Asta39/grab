import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../data/engine/desktop_engine.dart';
import '../../data/engine/engine_channel.dart';

/// Makes GIFs and stickers: natively on Android, with FFmpeg on desktops.
abstract final class ClipMaker {
  static const _clip = MethodChannel('grab/clip');
  static const _ringtone = MethodChannel('grab/ringtone');

  /// Length of a saved file in seconds.
  static Future<double?> duration(String path) async {
    if (Platform.isAndroid) {
      return _ringtone.invokeMethod<double>('duration', {'input': path});
    }
    final probe = await _desktop.tool('ffprobe');
    final r = await Process.run(probe, [
      '-v', 'error', '-show_entries', 'format=duration', //
      '-of', 'default=nw=1:nk=1', path,
    ]);
    return double.tryParse('${r.stdout}'.trim());
  }

  /// Makes the clip; returns the file to preview and share.
  static Future<String> make({
    required String input,
    required double start,
    required double end,
    required String kind,
    required String title,
  }) async {
    if (Platform.isAndroid) {
      final r = await _clip.invokeMapMethod<String, String>('make', {
        'input': input,
        'start': start,
        'end': end,
        'kind': kind,
        'title': title,
      });
      return r!['path']!;
    }
    final sticker = kind == 'sticker';
    final length = (end - start).clamp(0.5, sticker ? 6.0 : 10.0);
    final name = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ').trim();
    final t = start.toInt();
    final stamp = '${t ~/ 60}-${(t % 60).toString().padLeft(2, '0')}';
    final dir = Directory(p.join(_pictures, 'Grab'))
      ..createSync(recursive: true);
    var out = File(
      p.join(
        dir.path,
        '${name.isEmpty ? 'Grab clip' : name} $stamp.${sticker ? 'webp' : 'gif'}',
      ),
    );
    for (var n = 2; out.existsSync(); n++) {
      out = File(out.path.replaceFirst(RegExp(r'(\.\w+)$'), ' ($n)\$1'));
    }
    final ffmpeg = await _desktop.tool('ffmpeg');
    final cut = [
      '-hide_banner', '-nostdin', '-y', //
      '-ss', start.toStringAsFixed(2), '-t', length.toStringAsFixed(2),
      '-i', input, '-an',
    ];
    Future<bool> run(List<String> args) async =>
        (await Process.run(ffmpeg, [...cut, ...args, out.path])).exitCode == 0;
    bool ok;
    if (sticker) {
      const vf =
          'fps=15,scale=512:512:force_original_aspect_ratio=decrease,'
          'pad=512:512:(ow-iw)/2:(oh-ih)/2:color=0x00000000,format=yuva420p';
      ok =
          await run([
            '-vf',
            vf,
            '-c:v',
            'libwebp_anim',
            '-q:v',
            '55',
            '-loop',
            '0',
          ]) ||
          await run(['-vf', vf, '-c:v', 'libwebp', '-q:v', '55', '-loop', '0']);
    } else {
      ok = await run([
        '-vf',
        "fps=12,scale='min(480,iw)':-2:flags=lanczos,split[a][b];"
            '[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=4',
        '-loop',
        '0',
      ]);
    }
    if (!ok || !out.existsSync() || out.lengthSync() == 0) {
      throw PlatformException(
        code: 'clip',
        message: sticker
            ? "This computer's video tools can't make stickers"
            : "Couldn't make the GIF",
      );
    }
    return out.path;
  }

  static DesktopEngine get _desktop => Engine.instance as DesktopEngine;

  static String get _pictures {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return p.join(home, 'Pictures');
  }
}
