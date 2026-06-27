import 'package:flutter/material.dart';

/// Stil A semantic colors for one brightness, carried on [ThemeData] as a
/// [ThemeExtension]. Read it through `context.colors` so any widget — even a
/// `const` one — rebuilds correctly when the theme switches (the dependency on
/// [Theme] is what triggers the rebuild; a plain static could not).
///
/// Two const instances exist: [AppColors.light] and [AppColors.dark].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.primary,
    required this.softBlue,
    required this.textDark,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.green,
    required this.red,
    required this.onPrimary,
    required this.cardShadow,
  });

  final Brightness brightness;

  /// Screen background.
  final Color background;

  /// Card / surface.
  final Color card;

  /// Primary accent (blue).
  final Color primary;

  /// Soft blue — chip / subtle button background.
  final Color softBlue;

  /// Primary text.
  final Color textDark;

  /// Secondary text.
  final Color textSecondary;

  /// Muted / hint text.
  final Color textMuted;

  /// Input / hairline border.
  final Color border;

  /// Call action (green).
  final Color green;

  /// Delete action (red).
  final Color red;

  /// Foreground over the primary accent (text / icons).
  final Color onPrimary;

  /// Soft elevation shadow for cards, tuned per brightness.
  final List<BoxShadow> cardShadow;

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? card,
    Color? primary,
    Color? softBlue,
    Color? textDark,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? green,
    Color? red,
    Color? onPrimary,
    List<BoxShadow>? cardShadow,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      softBlue: softBlue ?? this.softBlue,
      textDark: textDark ?? this.textDark,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      green: green ?? this.green,
      red: red ?? this.red,
      onPrimary: onPrimary ?? this.onPrimary,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      softBlue: Color.lerp(softBlue, other.softBlue, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
    );
  }
}

/// The two palettes — single source of truth for color. Never hardcode a
/// `Color(0x...)` elsewhere; read the active set through `context.colors`.
abstract final class AppColors {
  /// Stil A — Sade Modern (mavi), the light palette.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFEEF2F9),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF2E55E6),
    softBlue: Color(0xFFEAF0FF),
    textDark: Color(0xFF16203A),
    textSecondary: Color(0xFF46506A),
    textMuted: Color(0xFF8A94AC),
    border: Color(0xFFE6EBF5),
    green: Color(0xFF34C759),
    red: Color(0xFFFF3B30),
    onPrimary: Color(0xFFFFFFFF),
    cardShadow: <BoxShadow>[
      BoxShadow(color: Color(0x0D141E3C), offset: Offset(0, 6), blurRadius: 16),
    ],
  );

  /// Dark counterpart — same accent language on a deep navy ground.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F1218),
    card: Color(0xFF1A1F2B),
    primary: Color(0xFF5C7CFA),
    softBlue: Color(0xFF222C44),
    textDark: Color(0xFFEEF0F6),
    textSecondary: Color(0xFFAEB6CA),
    textMuted: Color(0xFF79839B),
    border: Color(0xFF2C3447),
    green: Color(0xFF30D158),
    red: Color(0xFFFF453A),
    onPrimary: Color(0xFFFFFFFF),
    cardShadow: <BoxShadow>[
      BoxShadow(color: Color(0x59000000), offset: Offset(0, 8), blurRadius: 20),
    ],
  );
}

/// Ergonomic access to the active palette from any widget.
extension AppColorsContext on BuildContext {
  /// The active [AppPalette] for this context's theme.
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppColors.light;
}
