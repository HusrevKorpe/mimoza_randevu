import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/auth_service.dart';
import '../state/calendar_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/day_log.dart';
import '../widgets/icon_action_button.dart';
import '../widgets/month_calendar.dart';
import '../widgets/reminder_sync.dart';
import '../widgets/widget_sync.dart';

/// Randevu Defteri — the app's main screen and deep-link target.
///
/// Provides the appointment repository and the calendar view state, then renders
/// the month grid and the selected day's page ([DayLog]: appointments). Scoped
/// to the signed-in uid (guaranteed non-null here since [AuthGate] only shows
/// this when signed in). Money + notes live on the Günlük tab.
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
                Expanded(child: DayLog()),
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

/// Month label + previous/next navigation and settings. Listens only to the
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
