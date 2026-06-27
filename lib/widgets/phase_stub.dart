import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// Temporary, on-brand placeholder shown by skeleton screens whose real content
/// arrives in a later phase. Replaced as each phase is implemented.
class PhaseStub extends StatelessWidget {
  const PhaseStub({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.softBlue,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Icon(icon, color: colors.primary, size: 28),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: text.helper, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
