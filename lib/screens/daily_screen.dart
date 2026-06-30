import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../services/auth_service.dart';
import '../services/cash_repository.dart';
import '../services/note_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/general_notes_section.dart';
import '../widgets/icon_action_button.dart';
import '../widgets/month_cash_section.dart';

/// Günlük — the second tab: the month's expenses (with a running total) plus a
/// general notes list, in one lazy scroll. Provides the per-user repositories,
/// then renders the month selector and the combined sections. The FAB adds an
/// expense; notes have their own inline add field.
class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().user!.uid;
    return MultiProvider(
      providers: [
        Provider<CashRepository>(create: (_) => CashRepository(uid)),
        Provider<NoteRepository>(create: (_) => NoteRepository(uid)),
      ],
      child: const _DailyView(),
    );
  }
}

class _DailyView extends StatefulWidget {
  const _DailyView();

  @override
  State<_DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<_DailyView> {
  late DateTime _month = _firstOfThisMonth();

  static DateTime _firstOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Günlük', style: context.text.screenTitle),
                    ),
                    IconActionButton(
                      icon: Icons.settings_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _MonthSelector(
                  month: _month,
                  onPrevious: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: SingleChildScrollView(
                    // Clearance so the last note clears the FAB.
                    padding: const EdgeInsets.only(bottom: 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MonthCashSection(month: _month),
                        const SizedBox(height: AppSpacing.xxl),
                        const GeneralNotesSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.newCash),
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

/// Month label between previous/next chevrons.
class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy', 'tr_TR').format(month);
    return Row(
      children: [
        IconActionButton(
          icon: Icons.chevron_left_rounded,
          circle: false,
          onTap: onPrevious,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.dayTitle,
          ),
        ),
        IconActionButton(
          icon: Icons.chevron_right_rounded,
          circle: false,
          onTap: onNext,
        ),
      ],
    );
  }
}
