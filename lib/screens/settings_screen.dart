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

  /// Compact label that fits a four-segment control: 60 → "1 sa", 1440 → "1 gün".
  static String _leadChip(int minutes) {
    if (minutes >= 1440 && minutes % 1440 == 0) return '${minutes ~/ 1440} gün';
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
        SettingsSegmented<int>(
          title: 'Slot aralığı',
          value: settings.slotMinutes,
          onChanged: settings.setSlotMinutes,
          options: [
            for (final m in SettingsController.slotOptions)
              SettingsOption(m, slotIntervalLabel(m)),
          ],
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
