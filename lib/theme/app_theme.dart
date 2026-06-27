import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';

// Barrel: a single `import '../theme/app_theme.dart';` exposes every token.
export 'app_colors.dart';
export 'app_dimens.dart';
export 'app_text_styles.dart';

/// Builds the app-wide [ThemeData] from the Stil A tokens. Both [light] and
/// [dark] share one [_build] so the two themes never drift — only the
/// [AppPalette] differs. All visual defaults (colors, font, radii, component
/// themes) come from here, so screens stay clean.
abstract final class AppTheme {
  /// Light theme — Stil A (Sade Modern, mavi).
  static ThemeData light() => _build(AppColors.light);

  /// Dark theme — same design language on a deep navy ground.
  static ThemeData dark() => _build(AppColors.dark);

  static ThemeData _build(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      surface: p.card,
      onSurface: p.textDark,
      error: p.red,
      onError: p.onPrimary,
      outline: p.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      // Carry the full Stil A palette so widgets read it via `context.colors`.
      extensions: <ThemeExtension<dynamic>>[p],
      scaffoldBackgroundColor: p.background,
      fontFamily: AppText.family,
      textTheme: AppText.materialTextTheme(p.brightness),
      splashColor: p.softBlue,
      highlightColor: p.softBlue,
      iconTheme: IconThemeData(color: p.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.textDark,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: p.brightness,
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.card),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        hintStyle: AppText.of(p.brightness).muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _fieldBorder(p.border),
        enabledBorder: _fieldBorder(p.border),
        focusedBorder: _fieldBorder(p.primary, width: 1.6),
        errorBorder: _fieldBorder(p.red),
        focusedErrorBorder: _fieldBorder(p.red, width: 1.6),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
