import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact inline state for a day-page section body: a small left-aligned
/// icon + message (empty / error), or a centered spinner while loading. Lighter
/// than a full-screen state since it sits inside a section, not the whole list.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({super.key, this.icon, this.text})
      : loading = false;

  const SectionPlaceholder.loading({super.key})
      : icon = null,
        text = null,
        loading = true;

  final IconData? icon;
  final String? text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: loading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            )
          : Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colors.textMuted, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(text ?? '', style: context.text.muted),
                ),
              ],
            ),
    );
  }
}
