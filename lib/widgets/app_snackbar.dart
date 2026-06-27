import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visual intent of a snackbar — drives accent color + leading icon.
enum AppSnackType { info, success, error }

/// Stil A snackbar: a floating card with a soft shadow, rounded corners, a
/// colored icon badge and Manrope text. Single source for every in-app toast so
/// the look stays consistent (DRY). Never call `showSnackBar` directly.
abstract final class AppSnack {
  /// Show from a [BuildContext] (use before any `await`).
  static void show(
    BuildContext context,
    String message, {
    AppSnackType type = AppSnackType.info,
  }) {
    fromMessenger(ScaffoldMessenger.of(context), message, type: type);
  }

  /// Show from a captured [ScaffoldMessengerState] — safe across async gaps.
  /// The messenger's own context provides the active theme for styling.
  static void fromMessenger(
    ScaffoldMessengerState messenger,
    String message, {
    AppSnackType type = AppSnackType.info,
  }) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(_build(messenger.context, message, type));
  }

  static SnackBar _build(
    BuildContext context,
    String message,
    AppSnackType type,
  ) {
    final colors = context.colors;
    final accent = _accentOf(colors, type);
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 3),
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      dismissDirection: DismissDirection.horizontal,
      content: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.border),
          boxShadow: colors.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(_iconOf(type), color: accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message, style: context.text.name)),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentOf(AppPalette colors, AppSnackType type) {
    switch (type) {
      case AppSnackType.info:
        return colors.primary;
      case AppSnackType.success:
        return colors.green;
      case AppSnackType.error:
        return colors.red;
    }
  }

  static IconData _iconOf(AppSnackType type) {
    switch (type) {
      case AppSnackType.info:
        return Icons.info_outline_rounded;
      case AppSnackType.success:
        return Icons.check_circle_rounded;
      case AppSnackType.error:
        return Icons.error_outline_rounded;
    }
  }
}
