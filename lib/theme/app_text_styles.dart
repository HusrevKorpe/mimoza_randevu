import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Manrope typographic tokens (Stil A scale).
///
/// Manrope is embedded as a single *variable* TTF. To make the `wght` axis
/// render correctly on every platform, each style sets both [TextStyle.fontWeight]
/// and a matching `wght` [FontVariation]. Build every style through [_style] so
/// this stays consistent (DRY) — never hardcode font sizes/weights in widgets.
///
/// Read styles through `context.text` so the right text color for the active
/// theme is used and widgets rebuild on a theme switch. The per-brightness
/// [AppTextStyles] sets are built once and cached, so reads allocate nothing.
abstract final class AppText {
  static const String family = 'Manrope';

  static FontWeight _weightOf(int wght) {
    switch (wght) {
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      default:
        return FontWeight.w500;
    }
  }

  static TextStyle _style(
    double size,
    int wght, {
    required Color color,
    double? letterSpacing,
    double height = 1.25,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
      fontWeight: _weightOf(wght),
      fontVariations: <FontVariation>[FontVariation('wght', wght.toDouble())],
    );
  }

  static final Map<Brightness, AppTextStyles> _cache =
      <Brightness, AppTextStyles>{};

  /// The cached [AppTextStyles] for [brightness].
  static AppTextStyles of(Brightness brightness) => _cache.putIfAbsent(
        brightness,
        () => AppTextStyles(
          brightness == Brightness.dark ? AppColors.dark : AppColors.light,
        ),
      );

  /// Material [TextTheme] for a given [brightness] — used when building the
  /// app's [ThemeData] so framework widgets (dialogs, pickers) inherit Manrope.
  static TextTheme materialTextTheme(Brightness brightness) {
    final s = of(brightness);
    return TextTheme(
      displaySmall: s.screenTitle,
      headlineSmall: s.screenTitle,
      titleLarge: s.sectionTitle,
      titleMedium: s.dayTitle,
      titleSmall: s.name,
      bodyLarge: s.body,
      bodyMedium: s.body,
      bodySmall: s.helper,
      labelLarge: s.button,
      labelSmall: s.topLabel,
    );
  }
}

/// The full Manrope scale resolved for one [AppPalette]. Built once per
/// brightness and cached by [AppText]; read via `context.text`.
class AppTextStyles {
  AppTextStyles(AppPalette p)
      : screenTitle =
            AppText._style(26, 800, height: 1.1, color: p.textDark),
        sectionTitle = AppText._style(18, 700, color: p.textDark),
        dayTitle = AppText._style(17, 700, color: p.textDark),
        name = AppText._style(14.5, 600, color: p.textDark),
        helper = AppText._style(12, 500, color: p.textSecondary),
        muted = AppText._style(12, 500, color: p.textMuted),
        body = AppText._style(14, 500, color: p.textSecondary),
        topLabel = AppText._style(11, 700,
            color: p.textMuted, letterSpacing: 1.4),
        time = AppText._style(16, 700, color: p.primary),
        timeChip = AppText._style(15, 700, color: p.primary),
        button = AppText._style(15.5, 700, color: p.onPrimary);

  /// Screen-level large title, e.g. "Haziran 2026".
  final TextStyle screenTitle;

  /// Section heading.
  final TextStyle sectionTitle;

  /// Day / list header, e.g. "Cuma, 26 Haziran".
  final TextStyle dayTitle;

  /// Appointment name in a list row.
  final TextStyle name;

  /// Helper / secondary line (e.g. phone number).
  final TextStyle helper;

  /// Muted hint text.
  final TextStyle muted;

  /// Body text.
  final TextStyle body;

  /// Small uppercase, letter-spaced top label, e.g. "RANDEVU DEFTERİ".
  final TextStyle topLabel;

  /// Time value (list / widget / chip).
  final TextStyle time;

  /// Time chip label.
  final TextStyle timeChip;

  /// Primary button label.
  final TextStyle button;
}

/// Ergonomic access to the active text styles from any widget.
extension AppTextContext on BuildContext {
  /// The [AppTextStyles] matching this context's theme brightness.
  AppTextStyles get text => AppText.of(colors.brightness);
}
