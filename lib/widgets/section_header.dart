import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Header for a day-page section (RANDEVULAR / PARA / NOTLAR): an uppercase,
/// letter-spaced label with an optional [trailing] widget (a count or an add
/// button). Token-driven so every section lines up.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.topLabel)),
          ?trailing,
        ],
      ),
    );
  }
}
