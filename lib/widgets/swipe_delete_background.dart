import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Red rounded panel revealed behind a row as it's swiped left to delete.
/// Matches the card radius so the trash icon slides out from under the tile.
class SwipeDeleteBackground extends StatelessWidget {
  const SwipeDeleteBackground({super.key, this.radius = AppRadius.card});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.red,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        color: context.colors.onPrimary,
        size: 24,
      ),
    );
  }
}
