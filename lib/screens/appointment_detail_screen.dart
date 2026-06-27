import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/contacts_service.dart';
import '../theme/app_theme.dart';
import '../utils/initials.dart';
import '../widgets/app_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/icon_action_button.dart';
import '../widgets/primary_button.dart';
import '../widgets/profile_avatar.dart';

/// Randevu Detayı — view a single appointment and act on it: call, save to the
/// address book, edit or delete.
///
/// The appointment arrives via route arguments. Editing reuses the create form
/// ([AppRoutes.newAppointment]) which pops back the updated [Appointment], so we
/// refresh in place without a round-trip. Delete is scoped to the signed-in uid
/// (read from [AuthService], like every other screen) and pops on success.
class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  Appointment? _appointment;
  bool _deleting = false;
  bool _savingContact = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appointment ??=
        ModalRoute.of(context)?.settings.arguments as Appointment?;
  }

  Future<void> _edit() async {
    final appointment = _appointment;
    if (appointment == null) return;
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.newAppointment,
      arguments: appointment,
    );
    if (result is Appointment && mounted) {
      setState(() => _appointment = result);
    }
  }

  Future<void> _call() async {
    final appointment = _appointment;
    if (appointment == null || appointment.phone.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    bool launched;
    try {
      launched = await CallService.dial(appointment.phone);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      AppSnack.fromMessenger(
        messenger,
        'Arama başlatılamadı.',
        type: AppSnackType.error,
      );
    }
  }

  Future<void> _saveToContacts() async {
    final appointment = _appointment;
    if (appointment == null || _savingContact) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _savingContact = true);
    try {
      final saved = await ContactsService.save(
        name: appointment.name,
        phone: appointment.phone,
      );
      if (saved) {
        AppSnack.fromMessenger(
          messenger,
          'Rehbere kaydedildi.',
          type: AppSnackType.success,
        );
      }
    } catch (_) {
      AppSnack.fromMessenger(
        messenger,
        'Rehbere kaydedilemedi.',
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _savingContact = false);
    }
  }

  Future<void> _delete() async {
    final appointment = _appointment;
    if (appointment == null || _deleting) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final uid = context.read<AuthService>().user!.uid;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randevuyu sil'),
        content: Text('${appointment.name} için randevu silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await AppointmentRepository(uid).delete(appointment.id);
      navigator.pop();
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
      AppSnack.fromMessenger(
        messenger,
        'Randevu silinemedi. Tekrar dene.',
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu'),
        actions: [
          if (appointment != null)
            IconButton(
              onPressed: _deleting ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Düzenle',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: appointment == null
            ? const _NotFound()
            : _DetailBody(
                appointment: appointment,
                savingContact: _savingContact,
                deleting: _deleting,
                onCall: _call,
                onSaveToContacts: _saveToContacts,
                onEdit: _edit,
                onDelete: _delete,
              ),
      ),
    );
  }
}

/// The full detail layout: header, phone row and the save-to-contacts CTA in a
/// scroll view, with the edit / delete actions pinned to the bottom.
class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.appointment,
    required this.savingContact,
    required this.deleting,
    required this.onCall,
    required this.onSaveToContacts,
    required this.onEdit,
    required this.onDelete,
  });

  final Appointment appointment;
  final bool savingContact;
  final bool deleting;
  final VoidCallback onCall;
  final VoidCallback onSaveToContacts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.screen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(appointment: appointment),
                const SizedBox(height: AppSpacing.xl),
                _PhoneRow(phone: appointment.phone, onCall: onCall),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Rehbere Kaydet',
                  icon: Icons.person_add_alt_1_rounded,
                  loading: savingContact,
                  onPressed: onSaveToContacts,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Düzenle',
                  icon: Icons.edit_rounded,
                  background: context.colors.softBlue,
                  foreground: context.colors.primary,
                  onPressed: deleting ? null : onEdit,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ActionButton(
                  label: 'Sil',
                  icon: Icons.delete_outline_rounded,
                  background: context.colors.red.withValues(alpha: 0.10),
                  foreground: context.colors.red,
                  loading: deleting,
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Initials avatar + name + time/date chips.
class _Header extends StatelessWidget {
  const _Header({required this.appointment});

  final Appointment appointment;

  static final DateFormat _dateLabel =
      DateFormat('EEEE, d MMMM yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(initials: initialsFrom(appointment.name), size: 64),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.name, style: context.text.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: appointment.time,
                  ),
                  _InfoChip(
                    icon: Icons.event_rounded,
                    label: _dateLabel.format(appointment.start),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Soft-blue pill: small leading icon + label (e.g. time, date).
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.colors.softBlue,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.colors.primary),
          const SizedBox(width: 6),
          Text(label, style: context.text.timeChip.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Phone number with a green call button (matches the list row).
class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone, required this.onCall});

  final String phone;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone.trim().isNotEmpty;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_outlined,
            color: context.colors.textMuted,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              hasPhone ? phone : 'Telefon yok',
              style: hasPhone ? context.text.dayTitle : context.text.muted,
            ),
          ),
          if (hasPhone)
            IconActionButton(
              icon: Icons.phone_rounded,
              background: context.colors.green,
              foreground: context.colors.onPrimary,
              onTap: onCall,
            ),
        ],
      ),
    );
  }
}

/// Tinted, icon + label action button used for the bottom edit / delete row.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;
  final bool loading;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final borderRadius = BorderRadius.circular(AppRadius.button);
    return Material(
      color: background,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: _height,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: foreground,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: foreground, size: 19),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        label,
                        style: context.text.button.copyWith(color: foreground),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the screen is opened without a valid appointment argument.
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: context.colors.textMuted,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Randevu bulunamadı.', style: context.text.muted),
        ],
      ),
    );
  }
}
