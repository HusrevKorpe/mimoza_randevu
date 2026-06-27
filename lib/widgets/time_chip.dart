import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Single-select time chip (e.g. "09:30"). Selected → filled accent with white
/// text; otherwise a card with a hairline border and secondary text.
///
/// Label is centered and fills the available width, so the chip lines up as a
/// clean grid cell when sized by a fixed-width parent (see `_TimeField`).
class TimeChip extends StatelessWidget {
  const TimeChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(AppRadius.chip);
    final foreground = selected ? colors.onPrimary : colors.textSecondary;

    return Material(
      color: selected ? colors.primary : colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: selected
            ? BorderSide.none
            : BorderSide(color: colors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Center(
            heightFactor: 1,
            child: Text(
              label,
              style: context.text.timeChip.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
