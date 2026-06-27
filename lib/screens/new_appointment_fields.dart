part of 'new_appointment_screen.dart';

/// A field group: uppercase label above its input/control.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.onPick,
    required this.picking,
  });

  final TextEditingController controller;
  final VoidCallback onPick;
  final bool picking;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: 'İSİM',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'Ad Soyad'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ContactPickButton(onTap: onPick, busy: picking),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: context.colors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Rehberden seç — isim ve numara otomatik gelsin',
                  style: context.text.helper
                      .copyWith(color: context.colors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Accent square button that opens the contact picker; shows a spinner while
/// the picker is being prepared.
class _ContactPickButton extends StatelessWidget {
  const _ContactPickButton({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  static const double _width = 54;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: _width,
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.field),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colors.onPrimary,
                    ),
                  )
                : Icon(
                    Icons.person_add_alt_1_rounded,
                    color: colors.onPrimary,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: 'TELEFON',
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: 'Telefon numarası',
          prefixIcon: Icon(
            Icons.phone_outlined,
            color: context.colors.textMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Read-only, tappable field styled like the text inputs; opens a date picker.
class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(AppRadius.field);
    return _LabeledField(
      label: 'TARİH',
      child: Material(
        color: colors.card,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: context.text.body)),
                  Icon(
                    Icons.event_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle line telling the barber when a reminder fires, reflecting the current
/// reminder settings so the silent local-notification feature is discoverable.
/// Reads [SettingsController] so it updates if the lead time or on/off changes.
class _ReminderHint extends StatelessWidget {
  const _ReminderHint();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final muted = context.colors.textMuted;
    final enabled = settings.remindersEnabled;
    final text = enabled
        ? 'Randevudan ${reminderLeadLabel(settings.reminderLeadMinutes)} '
            'önce hatırlatma alırsın.'
        : 'Hatırlatma kapalı. Ayarlar’dan açabilirsin.';
    return Row(
      children: [
        Icon(
          enabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          size: 15,
          color: muted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: context.text.helper)),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.slots,
    required this.selected,
    required this.onSelect,
    required this.onCustom,
  });

  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onCustom;

  /// Target chip width — the column count adapts to keep chips close to this so
  /// the grid stays aligned (uniform columns) across phone sizes.
  static const double _targetChipWidth = 86;
  static const double _spacing = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    // A selected time that isn't one of the preset slots came from the picker.
    final customTime =
        selected != null && !slots.contains(selected) ? selected : null;
    return _LabeledField(
      label: 'SAAT',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = ((width + _spacing) / (_targetChipWidth + _spacing))
              .floor()
              .clamp(3, 5);
          final chipWidth = (width - _spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              // "Özel" first — the exact-minute picker leads the grid.
              SizedBox(
                width: chipWidth,
                child: _CustomTimeChip(time: customTime, onTap: onCustom),
              ),
              for (final slot in slots)
                SizedBox(
                  width: chipWidth,
                  child: TimeChip(
                    label: slot,
                    selected: slot == selected,
                    onTap: () => onSelect(slot),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Leading chip that opens a time picker for an exact minute (e.g. 16:47).
/// When such a time is active it shows the value, highlighted like a selected
/// slot; otherwise it reads "Özel" with a clock icon. The soft-blue idle fill
/// sets it apart from the preset white slots without crowding the grid.
class _CustomTimeChip extends StatelessWidget {
  const _CustomTimeChip({required this.time, required this.onTap});

  final String? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = time != null;
    final borderRadius = BorderRadius.circular(AppRadius.chip);
    final foreground = selected ? colors.onPrimary : colors.primary;
    return Material(
      color: selected ? colors.primary : colors.softBlue,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.more_time_rounded, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                time ?? 'Özel',
                style: context.text.timeChip.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
