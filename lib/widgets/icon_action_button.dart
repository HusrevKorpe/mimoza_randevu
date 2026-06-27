import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small tappable icon button used across the app (logout, month chevrons,
/// call). Soft-blue circle by default; pass [circle] `false` for a rounded
/// square, or override [background]/[foreground] for accent variants.
class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background,
    this.foreground,
    this.size = 40,
    this.iconSize = 20,
    this.circle = true,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// Defaults to the soft-blue token when null (resolved per active theme).
  final Color? background;

  /// Defaults to the primary accent when null (resolved per active theme).
  final Color? foreground;
  final double size;
  final double iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ShapeBorder shape = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          );

    return Material(
      color: background ?? colors.softBlue,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: foreground ?? colors.primary, size: iconSize),
        ),
      ),
    );
  }
}
