import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../state/calendar_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/icon_action_button.dart';
import '../widgets/month_calendar.dart';
import '../widgets/reminder_sync.dart';
import '../widgets/widget_sync.dart';

/// Randevu Defteri — the app's main screen and deep-link target.
///
/// Provides the per-user repository and the calendar view state, then renders
/// the month grid and the selected day's appointments. Scoped to the signed-in
/// uid (guaranteed non-null here since [AuthGate] only shows this when signed in).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().user!.uid;
    return MultiProvider(
      providers: [
        Provider<AppointmentRepository>(
          create: (_) => AppointmentRepository(uid),
        ),
        ChangeNotifierProvider<CalendarController>(
          create: (_) => CalendarController(),
        ),
      ],
      child: const WidgetSync(
        child: ReminderSync(child: _CalendarView()),
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;
    // This screen has no AppBar, so set the status-bar icon brightness here so
    // it stays legible against the background in both themes.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: colors.brightness,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.screen,
              AppSpacing.screen,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _TitleRow(),
                SizedBox(height: AppSpacing.xl),
                _MonthSection(),
                SizedBox(height: AppSpacing.xl),
                Expanded(child: _DaySection()),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.newAppointment,
            arguments: context.read<CalendarController>().selectedDate,
          ),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.fab),
          ),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}

/// Month label + previous/next navigation and sign-out. Listens only to the
/// visible month so selecting a day doesn't rebuild it.
class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    final month =
        context.select<CalendarController, DateTime>((c) => c.visibleMonth);
    final controller = context.read<CalendarController>();
    final label = DateFormat('MMMM yyyy', 'tr_TR').format(month);

    return Row(
      children: [
        Expanded(child: Text(label, style: context.text.screenTitle)),
        IconActionButton(
          icon: Icons.chevron_left_rounded,
          circle: false,
          onTap: controller.previousMonth,
        ),
        const SizedBox(width: AppSpacing.xs),
        IconActionButton(
          icon: Icons.chevron_right_rounded,
          circle: false,
          onTap: controller.nextMonth,
        ),
        const SizedBox(width: AppSpacing.xs),
        IconActionButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
    );
  }
}

/// The calendar card. Caches the month stream so re-selecting a day (which
/// rebuilds for the highlight) doesn't resubscribe Firestore.
class _MonthSection extends StatefulWidget {
  const _MonthSection();

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection> {
  Stream<List<Appointment>>? _stream;
  DateTime? _streamMonth;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CalendarController>();
    final month = controller.visibleMonth;
    if (_streamMonth != month) {
      _streamMonth = month;
      _stream = context.read<AppointmentRepository>().watchMonth(month);
    }

    return AppCard(
      child: StreamBuilder<List<Appointment>>(
        stream: _stream,
        builder: (context, snapshot) {
          final marked = <String>{
            for (final a in snapshot.data ?? const <Appointment>[]) a.dateKey,
          };
          return MonthCalendar(
            month: month,
            selectedDate: controller.selectedDate,
            today: DateTime.now(),
            markedDateKeys: marked,
            onSelectDay: controller.selectDay,
          );
        },
      ),
    );
  }
}

/// Selected day's header (date + count) and appointment list. One cached stream
/// feeds both, with loading / empty / error states.
class _DaySection extends StatefulWidget {
  const _DaySection();

  @override
  State<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<_DaySection> {
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
        final items = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DayHeader(date: day, count: items?.length),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildBody(context, snapshot)),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Appointment>> snapshot,
  ) {
    if (snapshot.hasError) {
      return const _DayMessage(
        icon: Icons.error_outline_rounded,
        text: 'Randevular yüklenemedi.\nBağlantını kontrol et.',
      );
    }
    if (!snapshot.hasData) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    final items = snapshot.data!;
    if (items.isEmpty) {
      return const _DayMessage(
        icon: Icons.event_available_rounded,
        text: 'Bu güne randevu yok.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final appointment = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Dismissible(
            key: ValueKey(appointment.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            // Confirm, delete, then always return false: the Firestore stream
            // removes the row, so Dismissible never holds a dismissed child.
            confirmDismiss: (_) => _confirmDelete(context, appointment),
            child: AppointmentTile(
              appointment: appointment,
              onCall: () => _call(context, appointment.phone),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.detail,
                arguments: appointment,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.count});

  final DateTime date;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, d MMMM', 'tr_TR').format(date);
    return Row(
      children: [
        Expanded(child: Text(label, style: context.text.dayTitle)),
        if (count != null)
          Text('$count randevu', style: context.text.helper),
      ],
    );
  }
}

/// Red rounded panel revealed behind a row as it's swiped left, matching the
/// card's radius so the trash icon slides out from under the tile.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.red,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        color: context.colors.onPrimary,
        size: 24,
      ),
    );
  }
}

/// Centered icon + message for the day list's empty / error states.
class _DayMessage extends StatelessWidget {
  const _DayMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.colors.textMuted, size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: context.text.muted, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Swipe-to-delete handler: asks for confirmation, then removes the appointment
/// through the repository. Always resolves `false` so the live stream — not the
/// [Dismissible] — drives the row's removal (avoids the dismissed-child assert).
Future<bool> _confirmDelete(BuildContext context, Appointment appointment) async {
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

