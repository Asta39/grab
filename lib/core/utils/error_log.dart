import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last few problems Grab ran into, kept on the device only, so a user
/// can choose to attach them to a bug report. Nothing is sent anywhere.
abstract final class ErrorLog {
  static const _key = 'errorLog';
  static const _max = 30;
  static SharedPreferences? _prefs;

  /// Starts catching Flutter and Dart errors, and picks up a native crash
  /// saved from the last run (Android).
  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final flutterError = FlutterError.onError;
    FlutterError.onError = (d) {
      record('Flutter: ${d.exceptionAsString()}', d.stack);
      flutterError?.call(d);
    };
    PlatformDispatcher.instance.onError = (e, s) {
      record('Uncaught: $e', s);
      return false;
    };
    if (Platform.isAndroid) {
      try {
        final crash = await const MethodChannel(
          'grab/app',
        ).invokeMethod<String>('takeCrash');
        if (crash != null && crash.isNotEmpty) {
          record('Crash (last run): $crash');
        }
      } catch (_) {}
    }
  }

  /// Adds one problem, with the first lines of its stack.
  static void record(String what, [StackTrace? stack]) {
    final p = _prefs;
    if (p == null) return;
    final lines = stack?.toString().split('\n').take(8).join('\n');
    final entry = {
      't': DateTime.now().toIso8601String(),
      'm': _scrub(what.length > 2000 ? what.substring(0, 2000) : what),
      if (lines != null && lines.isNotEmpty) 's': lines,
    };
    final list = entries..add(entry);
    p.setString(
      _key,
      jsonEncode(list.length > _max ? list.sublist(list.length - _max) : list),
    );
  }

  static List<Map<String, dynamic>> get entries {
    try {
      final raw = _prefs?.getString(_key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static void clear() => _prefs?.remove(_key);

  /// The log as plain text, newest last.
  static String asText({int last = 10}) {
    final e = entries;
    if (e.isEmpty) return 'No errors recorded.';
    return e
        .skip(e.length > last ? e.length - last : 0)
        .map(
          (x) => '[${x['t']}] ${x['m']}${x['s'] == null ? '' : '\n${x['s']}'}',
        )
        .join('\n\n');
  }

  /// Keeps personal paths out: the user's home folder becomes "~".
  static String _scrub(String s) {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    var out = s;
    if (home != null && home.length > 1) out = out.replaceAll(home, '~');
    return out.replaceAll(RegExp(r'/storage/emulated/0'), '/sdcard');
  }
}
