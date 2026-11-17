# Grab

Paste a link. Get the file.

Grab is a free, open-source Android app that downloads video, audio and subtitles from TikTok, YouTube, Instagram, Pinterest, X, Facebook and [1,800+ other sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md). It is built with Flutter and runs [yt-dlp](https://github.com/yt-dlp/yt-dlp) and FFmpeg on the phone through [youtubedl-android](https://github.com/yausername/youtubedl-android).

## Features

- Video + audio, video only, or audio only, with file sizes before you download
- Subtitles as `.srt` files, embedded in the video, or on their own
- Share a link into Grab from any app; Grab also offers a link you just copied
- Background downloads with progress and "Saved" notifications
- Library with search, filters, a built-in player, share and delete
- Settings: default mode and quality, MP4/MKV/WEBM, MP3/M4A/Opus/FLAC, downloads at once, light/dark theme
- In-app yt-dlp updates, so a site change doesn't need a new app release

Files are saved to `Download/Grab` on the phone.

## Build

Requirements: Flutter 3.44+, Android SDK 37, JDK 17.

```bash
flutter pub get
dart run build_runner build
flutter build apk --release --split-per-abi
```

The APKs land in `build/app/outputs/flutter-apk/`. Most phones need `app-arm64-v8a-release.apk`.

### Release signing

Create `android/key.properties` (it is git-ignored):

```properties
storeFile=/absolute/path/to/grab-release.jks
storePassword=...
keyAlias=grab
keyPassword=...
```

Without it, release builds are signed with the debug key.

## Architecture

| Layer | Where |
| --- | --- |
| UI (Pop design) | `lib/features/*`, `lib/core/widgets` |
| State (Riverpod) | `lib/app/providers.dart`, feature controllers |
| Data | `lib/data/repositories` (download queue), `lib/data/db` (drift), `lib/data/settings` |
| Engine | `lib/data/engine` (Dart) and `android/app/src/main/kotlin/app/grab/grab` (Kotlin plugin + foreground service) |

## Tests

```bash
flutter test
```

## License

GPL-3.0. See [LICENSE](LICENSE). Download only what you have the right to save, and respect each site's rules.
