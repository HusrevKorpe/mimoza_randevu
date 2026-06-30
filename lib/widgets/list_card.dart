import 'package:flutter/material.dart';

import 'app_card.dart';

/// A grouped list panel: rows stacked in one rounded card with hairline dividers
/// between them (iOS-style inset list). Reuses [AppCard], whose clip rounds each
/// row's corners — so per-row swipe-to-delete backgrounds round with the panel
/// instead of poking out square.
///
/// Used by the Günlük tab's expense + notes lists so each reads as one clean
/// panel rather than a stack of floating cards. Rows are built eagerly (the lists
/// are small, bounded sets), but each section still owns a live stream upstream.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}
