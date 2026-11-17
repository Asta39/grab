# Grab on Orion Store

Orion Store reads its catalogue from [RookieEnough/Orion-Data](https://github.com/RookieEnough/Orion-Data) (`apps.json`). Each app is one JSON entry; the store then pulls the newest file from the app's GitHub releases whose name contains `releaseKeyword`. This is the same format PostVault's listing uses.

Grab gets **two entries**: one for Android, and one for computers (Orion's "PC" section), because each needs a different release file.

## Android entry

```json
{
  "id": "grab",
  "name": "Grab",
  "description": "Paste a link. Get the file. Grab saves video, audio and subtitles from TikTok, YouTube, Instagram, Pinterest, X, Facebook and 1,800+ other sites, powered by yt-dlp and FFmpeg right on your phone.\n\n- Video + audio, video only, audio only (MP3, M4A, Opus, FLAC) or subtitles\n- Preview the video and trim just the part you want\n- Pause, resume and automatic retry when the connection drops\n- Playlists and profiles: pick which items to grab\n- Library with sorting, platform groups, background audio player and ringtone maker\n- Share to Grab, copy a link, or use the Quick Settings tile\n- The engine updates itself daily; app updates install in place\n\nFree and open source (GPL-3.0). No account, no ads, no tracking.",
  "icon": "https://raw.githubusercontent.com/Asta39/grab/main/assets/brand/icon.png",
  "version": "Latest",
  "latestVersion": "Latest",
  "downloadUrl": "https://github.com/Asta39/grab/releases/latest",
  "repoUrl": "https://github.com/Asta39/grab",
  "githubRepo": "Asta39/grab",
  "gitlabRepo": "",
  "gitlabDomain": "",
  "packageName": "app.grab.grab",
  "category": "Media",
  "platform": "Android",
  "size": "Varies",
  "author": "Asta",
  "officialSite": "https://asta39.github.io/grab/",
  "screenshots": [
    "https://raw.githubusercontent.com/Asta39/grab/main/fastlane/metadata/android/en-US/images/phoneScreenshots/1_home.png",
    "https://raw.githubusercontent.com/Asta39/grab/main/fastlane/metadata/android/en-US/images/phoneScreenshots/2_trim.png",
    "https://raw.githubusercontent.com/Asta39/grab/main/fastlane/metadata/android/en-US/images/phoneScreenshots/3_downloads.png",
    "https://raw.githubusercontent.com/Asta39/grab/main/fastlane/metadata/android/en-US/images/phoneScreenshots/4_library.png",
    "https://raw.githubusercontent.com/Asta39/grab/main/fastlane/metadata/android/en-US/images/phoneScreenshots/5_detail.png",
    "https://raw.githubusercontent.com/Asta39/grab/main/fastlane/metadata/android/en-US/images/phoneScreenshots/6_about.png"
  ],
  "releaseKeyword": "arm64-v8a"
}
```

## Computer entry (Windows)

Orion's PC section downloads one file, so this points at the Windows build. Mac users are sent to the website through `officialSite`.

```json
{
  "id": "grab-pc",
  "name": "Grab",
  "description": "Paste a link. Get the file. Grab saves video, audio and subtitles from YouTube, TikTok, Instagram, Pinterest and 1,800+ other sites, powered by yt-dlp and FFmpeg.\n\n- Video, audio (MP3, M4A, Opus, FLAC) or subtitles, with sizes shown first\n- Preview and trim before you save\n- Pause, resume and automatic retry\n- Playlists, a tidy library and a built-in player\n- Copy a link and Grab offers to fetch it\n\nWindows 10/11 (this download) and macOS (from the website). Free and open source (GPL-3.0). No account, no ads, no tracking.",
  "icon": "https://raw.githubusercontent.com/Asta39/grab/main/assets/brand/icon.png",
  "version": "Latest",
  "latestVersion": "Latest",
  "downloadUrl": "https://github.com/Asta39/grab/releases/latest/download/grab-windows-x64.zip",
  "repoUrl": "https://github.com/Asta39/grab",
  "githubRepo": "Asta39/grab",
  "gitlabRepo": "",
  "gitlabDomain": "",
  "packageName": "",
  "category": "Media",
  "platform": "PC",
  "size": "Varies",
  "author": "Asta",
  "officialSite": "https://asta39.github.io/grab/",
  "screenshots": [
    "https://raw.githubusercontent.com/Asta39/grab/main/docs/screenshots/home.png",
    "https://raw.githubusercontent.com/Asta39/grab/main/docs/screenshots/trim.png",
    "https://raw.githubusercontent.com/Asta39/grab/main/docs/screenshots/library.png"
  ],
  "releaseKeyword": "windows"
}
```

## Plain fields (for a submission form)

| Field | Android | PC |
| --- | --- | --- |
| Name | Grab | Grab |
| ID | `grab` | `grab-pc` |
| Package name | `app.grab.grab` | (none) |
| Category | Media | Media |
| Platform | Android | PC |
| Author | Asta | Asta |
| GitHub repo | `Asta39/grab` | `Asta39/grab` |
| Release keyword | `arm64-v8a` | `windows` |
| Icon | `https://raw.githubusercontent.com/Asta39/grab/main/assets/brand/icon.png` | same |
| Website | `https://asta39.github.io/grab/` | same |
| Licence | GPL-3.0 | GPL-3.0 |
| Minimum OS | Android 7.0 | Windows 10 (macOS 12 via website) |

**Short tagline:** Paste a link. Get the file.

## Why these choices

- **`releaseKeyword: "arm64-v8a"`**: each Grab release has three APKs. A plain `apk` keyword could hand phones the x86 build; `arm64-v8a` matches the one almost every phone needs.
- **Category `Media`**: where Orion lists other video and audio downloaders.
- **`packageName: app.grab.grab`**: lets Orion recognise Grab once installed and offer updates.
- **Screenshots** are the clean, full-screen captures from the F-Droid folder, already on `main`.
- **Icon** is the 1024 px app icon on `main`.

## How to submit

Orion-Data's contributing note asks for an issue first for anything significant, and manifest changes that follow the existing schema. Two ways in:

1. **Pull request (fastest):** fork `RookieEnough/Orion-Data`, add the two entries to `apps.json` (keep its formatting: 2-space indent, same key order as other entries), and open a pull request titled "Add Grab (Android and PC)".
2. **Issue:** open an issue titled "App request: Grab" with a link to the repo and the JSON above.

Then add the badge to the README and website once it's listed:

```html
<a href="https://rookieenough.github.io/Orion-Data/app/?id=grab"><img src="https://raw.githubusercontent.com/RookieEnough/Orion-Store/refs/heads/main/assets/orion-badge.png" alt="Get it on Orion Store" height="60" /></a>
```
