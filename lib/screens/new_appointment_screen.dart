import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/auth_service.dart';
import '../services/contacts_service.dart';
import '../state/settings_controller.dart';
import '../theme/app_theme.dart';
import '../utils/time_slots.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_label.dart';
import '../widgets/time_chip.dart';

part 'new_appointment_fields.dart';

/// Yeni Randevu — the create *and* edit form: name (+ contact picker), phone,
/// date and a single time chip. Saves through [AppointmentRepository]; the
/// calendar's live streams pick the change up automatically.
///
/// The route argument decides the mode:
/// * an [Appointment] → edit it (pre-fills the fields, pops with the updated
///   appointment so the detail screen can refresh);
/// * a [DateTime] → create a new appointment defaulting to that day;
/// * nothing → create defaulting to today.
class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  static final DateFormat _dateLabel =
      DateFormat('EEEE, d MMMM yyyy', 'tr_TR');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  /// Non-null when editing an existing appointment; null when creating one.
  Appointment? _editing;

  DateTime _date = DateTime.now();
  String? _time;
  bool _saving = false;
  bool _pickingContact = false;
  bool _initialized = false;

  bool get _isEditing => _editing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Appointment) {
      _editing = arg;
      _nameController.text = arg.name;
      _phoneController.text = arg.phone;
      _date = DateTime(arg.start.year, arg.start.month, arg.start.day);
      _time = arg.time;
    } else if (arg is DateTime) {
      _date = DateTime(arg.year, arg.month, arg.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    if (_pickingContact) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pickingContact = true);
    try {
      final contact = await ContactsService.pick();
      if (contact != null) {
        _nameController.text = contact.name;
        _phoneController.text = contact.phone;
      }
    } on ContactsPermissionException catch (e) {
      AppSnack.fromMessenger(messenger, e.message, type: AppSnackType.error);
    } catch (_) {
      AppSnack.fromMessenger(
        messenger,
        'Rehber açılamadı.',
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _pickingContact = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(
        () => _date = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  /// Opens a time picker (keyboard-entry first) so any exact minute can be set,
  /// e.g. 16:47 — not just the half-hour chips. Forced to 24-hour format.
  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(_time) ?? const TimeOfDay(hour: 9, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'SAAT GİR',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _time = _formatTime(picked));
    }
  }

  static String _formatTime(TimeOfDay value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();
    final time = _time;

    if (name.isEmpty) {
      AppSnack.fromMessenger(messenger, 'İsim girin.', type: AppSnackType.info);
      return;
    }
    if (time == null) {
      AppSnack.fromMessenger(messenger, 'Saat seçin.', type: AppSnackType.info);
      return;
    }

    final parts = time.split(':');
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final appointment = Appointment(
      id: _editing?.id ?? '',
      name: name,
      phone: _phoneController.text.trim(),
      dateKey: Appointment.dateKeyFor(_date),
      time: time,
      start: start,
      note: _editing?.note,
    );

    setState(() => _saving = true);
    try {
      final uid = context.read<AuthService>().user!.uid;
      final repository = AppointmentRepository(uid);
      if (_isEditing) {
        await repository.update(appointment);
        navigator.pop(appointment);
      } else {
        await repository.add(appointment);
        navigator.pop();
      }
    } on FirebaseException catch (e, stack) {
      if (mounted) setState(() => _saving = false);
      debugPrint('Appointment save failed: ${e.code} — ${e.message}\n$stack');
      final reason = e.code == 'permission-denied'
          ? ' (yetki reddedildi — Firestore kuralları)'
          : ' (${e.code})';
      AppSnack.fromMessenger(
        messenger,
        (_isEditing ? 'Değişiklikler kaydedilemedi' : 'Randevu kaydedilemedi') +
            reason,
        type: AppSnackType.error,
      );
    } catch (e, stack) {
      if (mounted) setState(() => _saving = false);
      debugPrint('Appointment save failed: $e\n$stack');
      AppSnack.fromMessenger(
        messenger,
        _isEditing
            ? 'Değişiklikler kaydedilemedi. Tekrar dene.'
            : 'Randevu kaydedilemedi. Tekrar dene.',
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final timeSlots = buildTimeSlots(
      startHour: settings.workStartHour,
      endHour: settings.workEndHour,
      slotMinutes: settings.slotMinutes,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Randevuyu Düzenle' : 'Yeni Randevu'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NameField(
                        controller: _nameController,
                        onPick: _pickContact,
                        picking: _pickingContact,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _PhoneField(controller: _phoneController),
                      const SizedBox(height: AppSpacing.xl),
                      _DateField(
                        label: _dateLabel.format(_date),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _TimeField(
                        slots: timeSlots,
                        selected: _time,
                        onSelect: (slot) => setState(() => _time = slot),
                        onCustom: _pickCustomTime,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _ReminderHint(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _isEditing
                    ? 'Değişiklikleri Kaydet'
                    : 'Randevuyu Kaydet',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
