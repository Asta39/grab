import 'dart:io';

import 'package:video_player/video_player.dart';

/// Grab on a phone (share sheet, haptics, notifications, ringtones) or on a
/// computer (Windows, macOS).
bool get isPhone => Platform.isAndroid || Platform.isIOS;
bool get isDesktop => !isPhone;

/// Android shows video best in a real Android view; desktops use textures.
VideoViewType get videoViewType =>
    Platform.isAndroid ? VideoViewType.platformView : VideoViewType.textureView;
