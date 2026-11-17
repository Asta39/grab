import 'package:flutter/material.dart';

/// Pop design tokens (style 8 on the mockup canvas).
/// Colors that change between light and dark live in [PopColors]; read them with `context.pop`.
abstract final class Pop {
  /// Brand yellow and ink. Same in both themes; use [ink] for text and icons that sit on yellow.
  static const yellow = Color(0xFFFFD84D);
  static const ink = Color(0xFF141414);
  static const navIdle = Color(0xFFBDBDBD);
  static const error = Color(0xFFB3261E);
  static const thumbs = [
    Color(0xFFFFD84D),
    Color(0xFF9FD8FF),
    Color(0xFFFFB2C8),
  ];

  static const font = 'Outfit';
  static const cardRadius = BorderRadius.all(Radius.circular(28));
  static const thumbRadius = BorderRadius.all(Radius.circular(20));

  /// Motion durations. Kept short: the app should feel quick, not floaty.
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);

  /// Picks a stable thumb tint for an item.
  static Color tintFor(String key) =>
      thumbs[key.hashCode.abs() % thumbs.length];

  /// True when the user turned on "remove animations" in system settings.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Theme-dependent Pop colors.
@immutable
class PopColors extends ThemeExtension<PopColors> {
  const PopColors({
    required this.bg,
    required this.text,
    required this.muted,
    required this.card,
    required this.field,
    required this.track,
    required this.soft,
    required this.trackOnSoft,
    required this.strong,
    required this.onStrong,
    required this.bar,
    required this.disabled,
    required this.errorSoft,
  });

  /// Page background.
  final Color bg;
  final Color text;
  final Color muted;

  /// Cards and list rows.
  final Color card;

  /// Text fields, segmented control track, icon buttons.
  final Color field;

  /// Empty part of progress bars.
  final Color track;

  /// Soft yellow: selected options, chips, the running download card.
  final Color soft;
  final Color trackOnSoft;

  /// Primary buttons and selected states: ink in light, yellow in dark.
  final Color strong;
  final Color onStrong;

  /// Floating tab bar.
  final Color bar;
  final Color disabled;
  final Color errorSoft;

  static const light = PopColors(
    bg: Colors.white,
    text: Pop.ink,
    muted: Color(0xFF555555),
    card: Color(0xFFF7F7F7),
    field: Color(0xFFF4F4F4),
    track: Color(0xFFEFEFEF),
    soft: Color(0xFFFFF1B8),
    trackOnSoft: Colors.white,
    strong: Pop.ink,
    onStrong: Pop.yellow,
    bar: Pop.ink,
    disabled: Color(0xFF3A3A3A),
    errorSoft: Color(0xFFFFE1E1),
  );

  static const dark = PopColors(
    bg: Color(0xFF121212),
    text: Color(0xFFF4F4F4),
    muted: Color(0xFFA8A8A8),
    card: Color(0xFF1E1E1E),
    field: Color(0xFF262626),
    track: Color(0xFF333333),
    soft: Color(0xFF3A3215),
    trackOnSoft: Color(0xFF1E1A0B),
    strong: Pop.yellow,
    onStrong: Pop.ink,
    bar: Color(0xFF242424),
    disabled: Color(0xFF3A3A3A),
    errorSoft: Color(0xFF4A2020),
  );

  @override
  PopColors copyWith() => this;

  @override
  PopColors lerp(PopColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PopColors(
      bg: l(bg, other.bg),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      card: l(card, other.card),
      field: l(field, other.field),
      track: l(track, other.track),
      soft: l(soft, other.soft),
      trackOnSoft: l(trackOnSoft, other.trackOnSoft),
      strong: l(strong, other.strong),
      onStrong: l(onStrong, other.onStrong),
      bar: l(bar, other.bar),
      disabled: l(disabled, other.disabled),
      errorSoft: l(errorSoft, other.errorSoft),
    );
  }
}

extension PopContext on BuildContext {
  PopColors get pop => Theme.of(this).extension<PopColors>() ?? PopColors.light;
}

ThemeData popTheme({Brightness brightness = Brightness.light}) {
  final c = brightness == Brightness.dark ? PopColors.dark : PopColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: Pop.yellow,
    brightness: brightness,
    primary: c.strong,
    onPrimary: c.onStrong,
    secondary: Pop.yellow,
    onSecondary: Pop.ink,
    surface: c.bg,
    onSurface: c.text,
    error: Pop.error,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Pop.font,
    brightness: brightness,
  );
  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.bg,
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    iconTheme: IconThemeData(color: c.text),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.field,
      hintStyle: TextStyle(color: c.muted),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        borderSide: BorderSide.none,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: c.soft,
      selectedColor: c.strong,
      checkmarkColor: c.onStrong,
      labelStyle: TextStyle(
        fontFamily: Pop.font,
        fontWeight: FontWeight.w600,
        color: c.text,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: Pop.font,
        fontWeight: FontWeight.w600,
        color: c.onStrong,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.onStrong : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.strong : c.track,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStateProperty.all(c.text)),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bg,
      showDragHandle: true,
      dragHandleColor: c.muted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(color: c.track),
  );
}
