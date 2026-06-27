import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round initials badge (soft-blue fill, primary initials). Reused on the login
/// profile cards and the appointment detail header.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.size = 48,
    this.background,
    this.foreground,
  });

  final String initials;
  final double size;

  /// Defaults to the soft-blue token when null (resolved per active theme).
  final Color? background;

  /// Defaults to the primary accent when null (resolved per active theme).
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? colors.softBlue,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: context.text.dayTitle.copyWith(
          color: foreground ?? colors.primary,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
