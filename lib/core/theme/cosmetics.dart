import 'package:flutter/material.dart';

import 'pop_theme.dart';

/// How a dock bubble is filled.
enum DockStyle { solid, stripes, stars, mesh, holo, stickers }

/// Looks unlocked through Grab Club: the dock bubble and the audio-cover
/// style. Widgets listen to [Cosmetics.dock] and [Cosmetics.cover] directly.
@immutable
class DockColor {
  const DockColor(
    this.id,
    this.name,
    this.level,
    this.color, {
    this.onColor = Pop.ink,
    this.gradient,
    this.style = DockStyle.solid,
    this.badge,
    this.blurb = '',
  });

  final String id;
  final String name;

  /// Grab Club level that unlocks it (when there's no [badge]).
  final int level;

  /// A badge that unlocks it instead of a level.
  final String? badge;

  /// The main colour, used for swatches and as a fallback.
  final Color color;

  /// Icon and label colour on top of it.
  final Color onColor;

  /// Colours the fill moves through.
  final List<Color>? gradient;
  final DockStyle style;
  final String blurb;
}

@immutable
class CoverStyle {
  const CoverStyle(
    this.id,
    this.name,
    this.level, {
    required this.bg,
    required this.ink,
    required this.bgDark,
    required this.inkDark,
  });

  final String id;
  final String name;
  final int level;
  final Color bg, ink, bgDark, inkDark;
}

abstract final class Cosmetics {
  static const docks = [
    DockColor('yellow', 'Sunny', 1, Pop.yellow, blurb: 'The classic'),
    DockColor('mint', 'Mint', 2, Color(0xFF7BE0B5), blurb: 'Fresh'),
    DockColor(
      'candy',
      'Candy',
      3,
      Color(0xFFFFB2C8),
      style: DockStyle.stripes,
      gradient: [Color(0xFFFF9EC4), Color(0xFFFFF1F6)],
      blurb: 'Stripes that roll',
    ),
    DockColor(
      'night',
      'Night sky',
      1,
      Color(0xFF1B2250),
      onColor: Pop.yellow,
      style: DockStyle.stars,
      badge: 'night_owl',
      gradient: [Color(0xFF0E1236), Color(0xFF2D3A8C)],
      blurb: 'Twinkling stars',
    ),
    DockColor(
      'lava',
      'Lava lamp',
      1,
      Color(0xFFFF8A4C),
      style: DockStyle.mesh,
      badge: 'streak_30',
      gradient: [
        Color(0xFFFF5E62),
        Color(0xFFFFB347),
        Color(0xFFFF9EC4),
        Color(0xFFFFD84D),
      ],
      blurb: 'Slow, warm blobs',
    ),
    DockColor(
      'aurora',
      'Aurora',
      4,
      Color(0xFF7BE0B5),
      style: DockStyle.mesh,
      gradient: [
        Color(0xFF7BE0B5),
        Color(0xFF8CCBFF),
        Color(0xFFC9B6FF),
        Color(0xFF52FFB8),
      ],
      blurb: 'Northern lights',
    ),
    DockColor(
      'stickers',
      'Sticker bomb',
      1,
      Pop.yellow,
      style: DockStyle.stickers,
      badge: 'sharer',
      blurb: 'Covered in stickers',
    ),
    DockColor(
      'holo',
      'Holo foil',
      5,
      Color(0xFFC9B6FF),
      style: DockStyle.holo,
      gradient: [
        Color(0xFFFFD84D),
        Color(0xFFFF9EC4),
        Color(0xFF8CCBFF),
        Color(0xFF7BE0B5),
        Color(0xFFC9B6FF),
        Color(0xFFFFD84D),
      ],
      blurb: 'Shifts as it moves',
    ),
  ];

  static const covers = [
    CoverStyle(
      'classic',
      'Classic',
      1,
      bg: Color(0xFFFFF3C4),
      ink: Pop.ink,
      bgDark: Color(0xFF2B2612),
      inkDark: Pop.yellow,
    ),
    CoverStyle(
      'retro',
      'Retro',
      3,
      bg: Color(0xFFFFE2C6),
      ink: Color(0xFF6B2E12),
      bgDark: Color(0xFF3A1E10),
      inkDark: Color(0xFFFFB27A),
    ),
    CoverStyle(
      'neon',
      'Neon',
      5,
      bg: Color(0xFF1B1035),
      ink: Color(0xFF52FFB8),
      bgDark: Color(0xFF120A26),
      inkDark: Color(0xFFFF6BD6),
    ),
  ];

  static final dock = ValueNotifier<DockColor>(docks.first);
  static final cover = ValueNotifier<CoverStyle>(covers.first);

  static DockColor dockById(String? id) =>
      docks.where((d) => d.id == id).firstOrNull ?? docks.first;
  static CoverStyle coverById(String? id) =>
      covers.where((c) => c.id == id).firstOrNull ?? covers.first;
}
