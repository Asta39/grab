import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/media_info.dart';

/// User preferences. Stored in SharedPreferences; small and read at startup.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultMode = DownloadMode.video,
    this.maxHeight,
    this.container = 'mp4',
    this.audioFormat = 'mp3',
    this.maxParallel = 2,
    this.saveBase = 'download',
    this.saveFolder = 'Grab',
    this.fileTemplate = defaultFileTemplate,
  });

  final ThemeMode themeMode;
  final DownloadMode defaultMode;

  /// Preferred video height; null = best available.
  final int? maxHeight;
  final String container;
  final String audioFormat;
  final int maxParallel;

  /// Public folder files go in: download | movies | music.
  final String saveBase;

  /// Folder name inside [saveBase].
  final String saveFolder;

  /// File names, e.g. "{title} - {site}".
  final String fileTemplate;

  static const saveBases = ['download', 'movies', 'music'];

  static String baseLabel(String b) => switch (b) {
    'movies' => 'Movies',
    'music' => 'Music',
    _ => 'Download',
  };

  /// "Download/Grab"
  String get savePath => '${baseLabel(saveBase)}/$saveFolder';

  static const containers = ['mp4', 'mkv', 'webm'];
  static const audioFormats = ['mp3', 'm4a', 'opus', 'flac'];
  static const heights = [null, 2160, 1440, 1080, 720, 480, 360];

  AppSettings copyWith({
    ThemeMode? themeMode,
    DownloadMode? defaultMode,
    int? Function()? maxHeight,
    String? container,
    String? audioFormat,
    int? maxParallel,
    String? saveBase,
    String? saveFolder,
    String? fileTemplate,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    defaultMode: defaultMode ?? this.defaultMode,
    maxHeight: maxHeight != null ? maxHeight() : this.maxHeight,
    container: container ?? this.container,
    audioFormat: audioFormat ?? this.audioFormat,
    maxParallel: maxParallel ?? this.maxParallel,
    saveBase: saveBase ?? this.saveBase,
    saveFolder: saveFolder ?? this.saveFolder,
    fileTemplate: fileTemplate ?? this.fileTemplate,
  );

  static AppSettings load(SharedPreferences p) {
    T pick<T>(List<T> options, T? value, T fallback) =>
        value != null && options.contains(value) ? value : fallback;
    final mode = p.getString(
      'mode',
    ); // 'defaultMode' held the old mode names; ignored
    final theme = p.getString('themeMode');
    final h = p.getInt('maxHeight');
    return AppSettings(
      themeMode:
          ThemeMode.values.where((m) => m.name == theme).firstOrNull ??
          ThemeMode.system,
      // Subtitles-only is per-link; it is never a default.
      defaultMode:
          DownloadMode.values
              .where((m) => m.name == mode && m != DownloadMode.subtitlesOnly)
              .firstOrNull ??
          DownloadMode.video,
      maxHeight: h != null && heights.contains(h) ? h : null,
      container: pick(containers, p.getString('container'), 'mp4'),
      audioFormat: pick(audioFormats, p.getString('audioFormat'), 'mp3'),
      maxParallel: (p.getInt('maxParallel') ?? 2).clamp(1, 3),
      saveBase: pick(saveBases, p.getString('saveBase'), 'download'),
      saveFolder: p.getString('saveFolder') ?? 'Grab',
      fileTemplate: p.getString('fileTemplate') ?? defaultFileTemplate,
    );
  }

  Future<void> save(SharedPreferences p) async {
    await p.setString('themeMode', themeMode.name);
    await p.setString('mode', defaultMode.name);
    if (maxHeight == null) {
      await p.remove('maxHeight');
    } else {
      await p.setInt('maxHeight', maxHeight!);
    }
    await p.setString('container', container);
    await p.setString('audioFormat', audioFormat);
    await p.setInt('maxParallel', maxParallel);
    await p.setString('saveBase', saveBase);
    await p.setString('saveFolder', saveFolder);
    await p.setString('fileTemplate', fileTemplate);
  }

  /// Index of the quality option closest to [maxHeight] without going over.
  /// Options are best first, so with no preference that is index 0.
  int preferredOptionIndex(List<QualityOption> options) {
    if (maxHeight == null) return 0;
    final i = options.indexWhere(
      (o) => o.height != null && o.height! <= maxHeight!,
    );
    return i < 0 ? options.length - 1 : i;
  }
}
