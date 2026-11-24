import 'dart:io';

import 'package:video_player/video_player.dart';

/// Grab on a phone (share sheet, haptics, notifications, ringtones) or on a
/// computer (Windows, macOS).
bool get isPhone => Platform.isAndroid || Platform.isIOS;
bool get isDesktop => !isPhone;

/// Video is drawn into a texture everywhere. On Android the "platform view"
/// mode crashed the whole app (a null video format in video_player) when a
/// file's video track couldn't be decoded or the file had no picture.
VideoViewType get videoViewType => VideoViewType.textureView;
