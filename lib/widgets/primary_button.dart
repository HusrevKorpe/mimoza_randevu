import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-width primary call-to-action (accent fill + glow shadow).
///
/// Disabled when [onPressed] is null or [loading] is true. While [loading] it
/// shows a spinner instead of the label so the same button handles async saves.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  static const double _height = 54;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null && !loading;
    final borderRadius = BorderRadius.circular(AppRadius.button);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: enabled ? AppShadows.fab : null,
      ),
      child: Material(
        color: enabled
            ? colors.primary
            : colors.primary.withValues(alpha: 0.5),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: double.infinity,
            height: _height,
            child: Center(child: _buildContent(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.colors;
    if (loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: colors.onPrimary,
        ),
      );
    }
    final text = Text(label, style: context.text.button);
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.onPrimary, size: 20),
        const SizedBox(width: AppSpacing.xs),
        text,
      ],
    );
  }
}
