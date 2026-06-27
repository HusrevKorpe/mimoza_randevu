import 'package:flutter/widgets.dart';

/// Corner radii (Stil A): kart 18–28 · buton/chip 12–16 · FAB 20.
abstract final class AppRadius {
  static const double card = 22;
  static const double cardLarge = 28;
  static const double field = 14;
  static const double button = 14;
  static const double chip = 12;
  static const double fab = 20;

  /// Today / selected calendar cell — filled blue square.
  static const double todayCell = 12;
}

/// Spacing scale — multiples of 2/4. Screen edge padding 22–26.
abstract final class AppSpacing {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 24;

  /// Default screen edge padding.
  static const double screen = 24;
}

/// Elevation shadows (Stil A). The card shadow is theme-dependent and lives on
/// [AppPalette.cardShadow] (read via `context.colors.cardShadow`); only the
/// theme-independent FAB glow lives here.
abstract final class AppShadows {
  /// FAB / primary button: `0 14px 26px rgba(46,85,230,.4)`.
  static const List<BoxShadow> fab = <BoxShadow>[
    BoxShadow(
      color: Color(0x662E55E6),
      offset: Offset(0, 14),
      blurRadius: 26,
    ),
  ];
}

/// Opacity tokens for muted states.
abstract final class AppOpacity {
  /// Faded look for an appointment whose time has already passed.
  static const double past = 0.5;
}

/// Implicit animation durations — snappy, 60/120fps friendly.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 240);
}
