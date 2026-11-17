# Contributing to Grab

Thanks for helping make Grab better. Bug reports, ideas, translations and code are all welcome.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting a bug

1. Check that you're on the [latest release](https://github.com/Asta39/grab/releases/latest), and update the engine in **Settings → Check for engine update**. Most "this link stopped working" problems are fixed by a newer yt-dlp.
2. Search [existing issues](https://github.com/Asta39/grab/issues) to see if it's already known.
3. Open a [bug report](https://github.com/Asta39/grab/issues/new?template=bug_report.yml) with the link that failed, your device and Grab version, and the error Grab showed (the **Copy error** button helps).

Please don't share links to private or copyrighted content you don't have the right to download.

## Suggesting a feature

Open a [feature request](https://github.com/Asta39/grab/issues/new?template=feature_request.yml). Explain the problem you want solved, not just the solution; it helps find the simplest way to do it.

## Working on the code

**You'll need:** Flutter 3.44+, the Android SDK (platform 37) and JDK 17. For desktop builds, Xcode on a Mac or Visual Studio on Windows.

```bash
git clone https://github.com/Asta39/grab.git
cd grab
flutter pub get
dart run build_runner build
flutter run
```

Before you open a pull request:

1. **One change per pull request.** Small, focused PRs are reviewed much faster.
2. **Run the checks** and make sure both pass:
   ```bash
   flutter analyze
   flutter test
   ```
3. **Add or update tests** when you change logic in `lib/data` or `lib/core`.
4. **Show UI changes** with a screenshot or short screen recording, in light and dark mode where it matters.
5. **Keep the style:** the Pop design (yellow `#FFD84D`, ink `#141414`, Outfit, pill shapes), plain-English labels, and haptics on taps.
6. **Write a clear commit message** that says what changed and why.

### Where things live

| Area | Folder |
| --- | --- |
| Screens | `lib/features/` |
| Shared widgets, theme, haptics | `lib/core/` |
| Download queue, database, settings | `lib/data/` |
| Android engine (yt-dlp, FFmpeg) | `android/app/src/main/kotlin/app/grab/grab/` |
| Desktop engine | `lib/data/engine/desktop_engine.dart` |
| Website | `website/` |

## Licence

Grab is licensed under [GPL-3.0](LICENSE). By contributing, you agree that your contribution is licensed the same way.
