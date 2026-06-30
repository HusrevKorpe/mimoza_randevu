import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/calendar_controller.dart';
import '../theme/app_theme.dart';
import 'day_appointments_section.dart';

/// The selected day's page: a date heading followed by the RANDEVULAR section in
/// one lazy scroll. The section owns its own day stream, so it loads and updates
/// independently. (Money + notes live on the Günlük tab.)
class DayLog extends StatelessWidget {
  const DayLog({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _DayHeading()),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        DayAppointmentsSection(),
        // Clearance so the last appointment clears the FAB.
        SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

/// "Cuma, 26 Haziran" — the selected day, rebuilt only when the day changes.
class _DayHeading extends StatelessWidget {
  const _DayHeading();

  @override
  Widget build(BuildContext context) {
    final day = context.select<CalendarController, DateTime>(
      (c) => c.selectedDate,
    );
    final label = DateFormat('EEEE, d MMMM', 'tr_TR').format(day);
    return Text(label, style: context.text.dayTitle);
  }
}
