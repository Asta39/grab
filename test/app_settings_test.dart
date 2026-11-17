import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grab/data/engine/media_info.dart';
import 'package:grab/data/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppSettings.load(await SharedPreferences.getInstance());
    expect(s.themeMode, ThemeMode.system);
    expect(s.defaultMode, DownloadMode.video);
    expect(s.maxHeight, isNull);
    expect(s.maxParallel, 2);
  });

  test('round-trips through storage', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await const AppSettings(
      themeMode: ThemeMode.dark,
      defaultMode: DownloadMode.audioOnly,
      maxHeight: 720,
      container: 'mkv',
      audioFormat: 'opus',
      maxParallel: 3,
    ).save(p);
    final s = AppSettings.load(p);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.defaultMode, DownloadMode.audioOnly);
    expect(s.maxHeight, 720);
    expect(s.container, 'mkv');
    expect(s.audioFormat, 'opus');
    expect(s.maxParallel, 3);
  });

  test('ignores bad stored values', () async {
    SharedPreferences.setMockInitialValues({
      'mode': 'subtitlesOnly',
      'container': 'avi',
      'maxHeight': 999,
      'maxParallel': 40,
    });
    final s = AppSettings.load(await SharedPreferences.getInstance());
    expect(s.defaultMode, DownloadMode.video);
    expect(s.container, 'mp4');
    expect(s.maxHeight, isNull);
    expect(s.maxParallel, 3);
  });

  test('picks the closest quality without going over', () {
    const opts = [
      QualityOption(label: '1080p', height: 1080),
      QualityOption(label: '720p', height: 720),
      QualityOption(label: '360p', height: 360),
    ];
    expect(const AppSettings().preferredOptionIndex(opts), 0);
    expect(const AppSettings(maxHeight: 720).preferredOptionIndex(opts), 1);
    expect(const AppSettings(maxHeight: 480).preferredOptionIndex(opts), 2);
    expect(const AppSettings(maxHeight: 240).preferredOptionIndex(opts), 2);
  });
}
