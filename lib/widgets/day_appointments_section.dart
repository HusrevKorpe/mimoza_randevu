import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/call_service.dart';
import '../state/calendar_controller.dart';
import '../theme/app_theme.dart';
import 'app_snackbar.dart';
import 'appointment_tile.dart';
import 'day_section_sliver.dart';
import 'section_placeholder.dart';
import 'swipe_delete_background.dart';

/// RANDEVULAR — the selected day's appointments as one sliver in the day log.
/// Owns a per-day stream; rows keep the original call / edit / swipe-to-delete
/// behavior.
class DayAppointmentsSection extends StatefulWidget {
  const DayAppointmentsSection({super.key});

  @override
  State<DayAppointmentsSection> createState() => _DayAppointmentsSectionState();
}

class _DayAppointmentsSectionState extends State<DayAppointmentsSection> {
  Stream<List<Appointment>>? _stream;
  DateTime? _streamDay;

  @override
  Widget build(BuildContext context) {
    final day = context.select<CalendarController, DateTime>(
      (c) => c.selectedDate,
    );
    if (_streamDay != day) {
      _streamDay = day;
      _stream = context.read<AppointmentRepository>().watchDay(day);
    }

    return StreamBuilder<List<Appointment>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const DaySectionSliver(
            title: 'RANDEVULAR',
            count: 0,
            placeholder: SectionPlaceholder(
              icon: Icons.error_outline_rounded,
              text: 'Randevular yüklenemedi.',
            ),
            itemBuilder: _never,
          );
        }
        if (!snapshot.hasData) {
          return const DaySectionSliver(
            title: 'RANDEVULAR',
            count: 0,
            placeholder: SectionPlaceholder.loading(),
            itemBuilder: _never,
          );
        }
        final items = snapshot.data!;
        // Computed once per build so every row judges "past" against one instant.
        final now = DateTime.now();
        return DaySectionSliver(
          title: 'RANDEVULAR',
          count: items.length,
          trailing: items.isEmpty
              ? null
              : Text('${items.length} randevu', style: context.text.helper),
          placeholder: const SectionPlaceholder(
            icon: Icons.event_available_rounded,
            text: 'Bu güne randevu yok.',
          ),
          itemBuilder: (context, i) => _Row(appointment: items[i], now: now),
        );
      },
    );
  }

  /// Unreachable: the placeholder branches pass [count] 0, so no item is built.
  static Widget _never(BuildContext context, int index) =>
      const SizedBox.shrink();
}

class _Row extends StatelessWidget {
  const _Row({required this.appointment, required this.now});

  final Appointment appointment;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Dismissible(
        key: ValueKey(appointment.id),
        direction: DismissDirection.endToStart,
        background: const SwipeDeleteBackground(),
        // Confirm, delete, then always return false: the Firestore stream
        // removes the row, so Dismissible never holds a dismissed child.
        confirmDismiss: (_) => _confirmDelete(context, appointment),
        child: AppointmentTile(
          appointment: appointment,
          past: appointment.isPastAt(now),
          onCall: () => _call(context, appointment.phone),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.detail,
            arguments: appointment,
          ),
        ),
      ),
    );
  }
}

/// Swipe-to-delete handler: confirms, then removes via the repository. Always
/// resolves `false` so the live stream — not the [Dismissible] — drives removal.
Future<bool> _confirmDelete(
  BuildContext context,
  Appointment appointment,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final repository = context.read<AppointmentRepository>();
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
  if (confirmed != true) return false;
  try {
    await repository.delete(appointment.id);
  } catch (_) {
    AppSnack.fromMessenger(
      messenger,
      'Randevu silinemedi. Tekrar dene.',
      type: AppSnackType.error,
    );
  }
  return false;
}

Future<void> _call(BuildContext context, String phone) async {
  final messenger = ScaffoldMessenger.of(context);
  bool launched;
  try {
    launched = await CallService.dial(phone);
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
