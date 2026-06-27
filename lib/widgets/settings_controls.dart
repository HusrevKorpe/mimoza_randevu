import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';
import 'icon_action_button.dart';
import 'section_label.dart';

/// One choice in a [SettingsSegmented]: the value it sets and its visible label.
class SettingsOption<T> {
  const SettingsOption(this.value, this.label);

  final T value;
  final String label;
}

/// A titled group: an uppercase [label] above a card holding [children], with a
/// hairline divider drawn between each pair. The building block every settings
/// section is made of, so the screen itself stays declarative.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: children[i],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ],
    );
  }
}

/// A label above a horizontal segmented control. Each segment fills an equal
/// share of the width; the active one carries the primary fill. Selection is
/// implicitly animated so the highlight slides in without a rebuild flash.
class SettingsSegmented<T> extends StatelessWidget {
  const SettingsSegmented({
    super.key,
    this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String? title;
  final List<SettingsOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final track = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.softBlue,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment(
                label: option.label,
                selected: option.value == value,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
    if (title == null) return track;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title!, style: context.text.body),
        const SizedBox(height: AppSpacing.sm),
        track,
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.text.name.copyWith(
      color: selected ? colors.onPrimary : colors.textSecondary,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip - 4),
        ),
        child: Center(child: Text(label, style: style)),
      ),
    );
  }
}

/// A title row with a value in the middle and −/＋ buttons that step it. Pass a
/// null callback for a bound to disable (and dim) that button.
class SettingsStepper extends StatelessWidget {
  const SettingsStepper({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String title;
  final String valueLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.body)),
        IconActionButton(
          icon: Icons.remove_rounded,
          size: 36,
          onTap: onDecrement,
          foreground: onDecrement == null ? colors.textMuted : null,
        ),
        SizedBox(
          width: 64,
          child: Text(
            valueLabel,
            textAlign: TextAlign.center,
            style: context.text.dayTitle,
          ),
        ),
        IconActionButton(
          icon: Icons.add_rounded,
          size: 36,
          onTap: onIncrement,
          foreground: onIncrement == null ? colors.textMuted : null,
        ),
      ],
    );
  }
}

/// A title (+ optional subtitle) with a trailing switch.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.name),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.text.helper),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: colors.primary,
        ),
      ],
    );
  }
}

/// A leading icon, a title + subtitle, and an optional trailing widget. Used for
/// the account row (and any read-only info line).
class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.helper),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.text.name),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}
