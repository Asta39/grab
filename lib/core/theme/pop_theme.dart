import 'package:flutter/material.dart';

/// Pop design tokens (style 8 on the mockup canvas).
abstract final class Pop {
  static const yellow = Color(0xFFFFD84D);
  static const ink = Color(0xFF141414);
  static const softYellow = Color(0xFFFFF1B8);
  static const card = Color(0xFFF7F7F7);
  static const field = Color(0xFFF4F4F4);
  static const track = Color(0xFFEFEFEF);
  static const muted = Color(0xFF555555);
  static const navIdle = Color(0xFFBDBDBD);
  static const error = Color(0xFFB3261E);
  static const ok = Color(0xFF1E7A46);
  static const thumbs = [Color(0xFFFFD84D), Color(0xFF9FD8FF), Color(0xFFFFB2C8)];

  static const font = 'Outfit';
  static const cardRadius = BorderRadius.all(Radius.circular(28));
  static const thumbRadius = BorderRadius.all(Radius.circular(20));

  /// Motion durations. Kept short: the app should feel quick, not floaty.
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);

  /// Picks a stable thumb tint for an item.
  static Color tintFor(String key) => thumbs[key.hashCode.abs() % thumbs.length];

  /// True when the user turned on "remove animations" in system settings.
  static bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

ThemeData popTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Pop.yellow,
    primary: Pop.ink,
    onPrimary: Pop.yellow,
    secondary: Pop.yellow,
    onSecondary: Pop.ink,
    surface: Colors.white,
    error: Pop.error,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: Pop.font);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    textTheme: base.textTheme.apply(bodyColor: Pop.ink, displayColor: Pop.ink),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Pop.ink, elevation: 0, scrolledUnderElevation: 0),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Pop.field,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(999)), borderSide: BorderSide.none),
    ),
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: Pop.softYellow,
      selectedColor: Pop.ink,
      checkmarkColor: Pop.yellow,
      labelStyle: TextStyle(fontFamily: Pop.font, fontWeight: FontWeight.w600, color: Pop.ink),
      secondaryLabelStyle: TextStyle(fontFamily: Pop.font, fontWeight: FontWeight.w600, color: Pop.yellow),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Pop.yellow : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Pop.ink : Pop.track),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
