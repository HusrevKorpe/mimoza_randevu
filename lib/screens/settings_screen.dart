import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/settings_controller.dart';
import '../state/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_controls.dart';

/// Ayarlar — appearance, reminders, working hours and account in one place.
///
/// Each section is its own widget that watches only the controller it needs, so
/// flipping the theme never rebuilds the working-hours steppers and vice versa.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _AppearanceSection(),
              SizedBox(height: AppSpacing.xxl),
              _ReminderSection(),
              SizedBox(height: AppSpacing.xxl),
              _WorkingHoursSection(),
              SizedBox(height: AppSpacing.xxl),
              _AccountSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Görünüm — Sistem / Açık / Koyu theme selector.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ThemeController, ThemeMode>((c) => c.mode);
    return SettingsSection(
      label: 'GÖRÜNÜM',
      children: [
        SettingsSegmented<ThemeMode>(
          value: mode,
          onChanged: context.read<ThemeController>().setMode,
          options: const [
            SettingsOption(ThemeMode.system, 'Sistem'),
            SettingsOption(ThemeMode.light, 'Açık'),
            SettingsOption(ThemeMode.dark, 'Koyu'),
          ],
        ),
      ],
    );
  }
}

/// Hatırlatma — on/off plus how long before the appointment it fires.
class _ReminderSection extends StatelessWidget {
  const _ReminderSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return SettingsSection(
      label: 'HATIRLATMA',
      children: [
        SettingsSwitchRow(
          title: 'Hatırlatma',
          subtitle: 'Randevudan önce bildirim al',
          value: settings.remindersEnabled,
          onChanged: settings.setRemindersEnabled,
        ),
        if (settings.remindersEnabled)
          SettingsSegmented<int>(
            title: 'Ne kadar önce?',
            value: settings.reminderLeadMinutes,
            onChanged: settings.setReminderLeadMinutes,
            options: [
              for (final m in SettingsController.reminderLeadOptions)
                SettingsOption(m, _leadChip(m)),
            ],
          ),
      ],
    );
  }

  /// Compact label that fits the segmented control: 30 → "30 dk", 60 → "1 sa".
  static String _leadChip(int minutes) {
    if (minutes >= 60 && minutes % 60 == 0) return '${minutes ~/ 60} sa';
    return '$minutes dk';
  }
}

/// Çalışma saatleri — start / end hour and the slot interval that together feed
/// the time chips on the new-appointment form.
class _WorkingHoursSection extends StatelessWidget {
  const _WorkingHoursSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final start = settings.workStartHour;
    final end = settings.workEndHour;
    return SettingsSection(
      label: 'ÇALIŞMA SAATLERİ',
      children: [
        SettingsStepper(
          title: 'Başlangıç',
          valueLabel: wholeHourLabel(start),
          onDecrement: start > SettingsController.minWorkHour
              ? () => settings.setWorkStartHour(start - 1)
              : null,
          onIncrement: start < end - 1
              ? () => settings.setWorkStartHour(start + 1)
              : null,
        ),
        SettingsStepper(
          title: 'Bitiş',
          valueLabel: wholeHourLabel(end),
          onDecrement: end > start + 1
              ? () => settings.setWorkEndHour(end - 1)
              : null,
          onIncrement: end < SettingsController.maxWorkHour
              ? () => settings.setWorkEndHour(end + 1)
              : null,
        ),
        SettingsSegmentedCustom<int>(
          title: 'Slot aralığı',
          value: settings.slotMinutes,
          onChanged: settings.setSlotMinutes,
          options: const [
            SettingsOption(30, '30 dk'),
            SettingsOption(60, '1 saat'),
          ],
          // The custom segment shows "Özel" until a non-preset value is set,
          // then displays that value (e.g. "45 dk").
          customLabel: SettingsController.slotPresets.contains(settings.slotMinutes)
              ? 'Özel'
              : slotIntervalLabel(settings.slotMinutes),
          onCustomTap: () => _editCustomSlot(context, settings),
        ),
      ],
    );
  }
}

/// Asks for a custom slot interval in minutes. The value is clamped by
/// [SettingsController.setSlotMinutes], so out-of-range input still lands safely.
Future<void> _editCustomSlot(
  BuildContext context,
  SettingsController settings,
) async {
  final minutes = await showDialog<int>(
    context: context,
    builder: (_) => _CustomSlotDialog(initial: settings.slotMinutes),
  );
  if (minutes != null) settings.setSlotMinutes(minutes);
}

/// Dialog that owns its [TextEditingController] so it is disposed with the State
/// — after the route's exit animation fully completes — rather than the instant
/// `showDialog` returns. Disposing it earlier would touch the field while it is
/// still mounted and animating out (risking a "used after disposed" error).
class _CustomSlotDialog extends StatefulWidget {
  const _CustomSlotDialog({required this.initial});

  final int initial;

  @override
  State<_CustomSlotDialog> createState() => _CustomSlotDialogState();
}

class _CustomSlotDialogState extends State<_CustomSlotDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value != null) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Özel slot aralığı'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dakika cinsinden gir '
            '(${SettingsController.minSlotMinutes}–'
            '${SettingsController.maxSlotMinutes}).',
            style: context.text.helper,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Örn. 45',
              suffixText: 'dk',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}

/// Hesap — which account is signed in, and the sign-out action.
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthService>().user?.email ?? '—';
    return SettingsSection(
      label: 'HESAP',
      children: [
        SettingsInfoRow(
          icon: Icons.account_circle_outlined,
          title: 'Giriş yapılan hesap',
          subtitle: email,
        ),
        _SignOutRow(onTap: () => _confirmSignOut(context)),
      ],
    );
  }
}

/// Destructive, full-width tappable row in the account card.
class _SignOutRow extends StatelessWidget {
  const _SignOutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.logout_rounded, size: 20, color: colors.red),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Çıkış yap',
            style: context.text.name.copyWith(color: colors.red),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmSignOut(BuildContext context) async {
  final auth = context.read<AuthService>();
  final navigator = Navigator.of(context);
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Çıkış yap'),
      content: const Text('Oturumu kapatmak istiyor musun?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: ctx.colors.red),
          child: const Text('Çıkış yap'),
        ),
      ],
    ),
  );
  if (shouldSignOut ?? false) {
    // Leave Settings first so AuthGate swaps in the login screen cleanly.
    navigator.pop();
    await auth.signOut();
  }
}
