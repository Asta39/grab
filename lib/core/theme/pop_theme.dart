import 'package:flutter/material.dart';

/// Pop design tokens (style 8 on the mockup canvas).
abstract final class Pop {
  static const yellow = Color(0xFFFFD84D);
  static const ink = Color(0xFF141414);
  static const softYellow = Color(0xFFFFF1B8);
  static const card = Color(0xFFF7F7F7);
  static const muted = Color(0xFF555555);
  static const thumbs = [Color(0xFFFFD84D), Color(0xFF9FD8FF), Color(0xFFFFB2C8)];

  static const pill = StadiumBorder();
  static const cardRadius = BorderRadius.all(Radius.circular(28));
  static const thumbRadius = BorderRadius.all(Radius.circular(20));
}

/// Light Pop theme. Fonts and motion arrive in milestone 3.
ThemeData popTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Pop.yellow,
    primary: Pop.ink,
    onPrimary: Pop.yellow,
    secondary: Pop.yellow,
    onSecondary: Pop.ink,
    surface: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Pop.ink, elevation: 0, scrolledUnderElevation: 0),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: Pop.pill),
    ),
    chipTheme: const ChipThemeData(shape: StadiumBorder(), side: BorderSide.none, backgroundColor: Pop.softYellow),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF4F4F4),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(999)), borderSide: BorderSide.none),
    ),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: Pop.yellow),
    cardTheme: const CardThemeData(color: Pop.card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: Pop.cardRadius)),
  );
}
