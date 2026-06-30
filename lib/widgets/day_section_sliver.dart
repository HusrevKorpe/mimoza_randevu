import 'package:flutter/material.dart';

import 'section_header.dart';

/// A day-page section rendered as one lazy sliver: a [SectionHeader] followed by
/// either [count] item rows (built by [itemBuilder]) or a single [placeholder]
/// when empty, plus an optional [footer] (e.g. the notes add field).
///
/// Used by every day section so the three of them share one scroll, stay lazy
/// (`SliverList.builder`), and line their headers up. Each section owns its own
/// stream; placing several of these in a [CustomScrollView] keeps loading/empty
/// states independent.
class DaySectionSliver extends StatelessWidget {
  const DaySectionSliver({
    super.key,
    required this.title,
    required this.count,
    required this.itemBuilder,
    this.trailing,
    this.placeholder,
    this.footer,
  });

  final String title;
  final int count;
  final IndexedWidgetBuilder itemBuilder;

  /// Trailing widget in the header — a count label or an add button.
  final Widget? trailing;

  /// Shown in place of the rows when [count] is 0. Null → render nothing
  /// (used by Notlar, which shows only its add field when empty).
  final Widget? placeholder;

  /// Optional row pinned after the items (the notes add field).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final hasFooter = footer != null;
    final bodyCount = count > 0 ? count : (placeholder != null ? 1 : 0);
    final total = 1 + bodyCount + (hasFooter ? 1 : 0);

    return SliverList.builder(
      itemCount: total,
      itemBuilder: (context, i) {
        if (i == 0) return SectionHeader(title: title, trailing: trailing);
        final bodyIndex = i - 1;
        if (hasFooter && bodyIndex == bodyCount) return footer!;
        if (count == 0) return placeholder ?? const SizedBox.shrink();
        return itemBuilder(context, bodyIndex);
      },
    );
  }
}
