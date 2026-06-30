import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App-wide bottom navigation bar (Stil A). Two destinations — Defter and
/// Günlük — drawn from tokens so it matches every other surface and flips
/// cleanly between themes. Stateless: the parent ([HomeShell]) owns the index.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Keep only a slim clearance over the home indicator instead of the full
    // safe-area inset, so the bar sits low without a big empty band beneath it.
    final inset = MediaQuery.of(context).padding.bottom;
    final bottomGap = inset == 0 ? 0.0 : (inset * 0.35).clamp(6.0, inset);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              _BottomBarItem(
                icon: Icons.event_note_rounded,
                label: 'Defter',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _BottomBarItem(
                icon: Icons.receipt_long_rounded,
                label: 'Günlük',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable destination. Color alone marks the active tab (primary vs muted)
/// — the embedded Manrope is a variable font, so we don't fight its weight axis.
class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: context.text.helper.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
