import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'firebase_options.dart';
import 'screens/appointment_detail_screen.dart';
import 'screens/auth_gate.dart';
import 'screens/calendar_screen.dart';
import 'screens/new_appointment_screen.dart';
import 'screens/new_cash_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'state/settings_controller.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';

const Locale _trLocale = Locale('tr', 'TR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Turkish date/number formatting for the whole app.
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';
  // Bind the App Group so the home-screen widget can read shared data.
  await WidgetService.init();
  // Prepare local reminder notifications (timezone, channel, plugin).
  await NotificationService.init();
  // Resolve the initial theme before the first frame: the saved choice if any,
  // otherwise follow the system — so the app opens in the right brightness.
  final initialMode = await ThemeController.loadSavedMode() ?? ThemeMode.system;
  runApp(BerberRandevuApp(initialThemeMode: initialMode));
}

class BerberRandevuApp extends StatelessWidget {
  const BerberRandevuApp({super.key, required this.initialThemeMode});

  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(initialThemeMode),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(),
        ),
      ],
      // Only the theme mode drives MaterialApp here, so a toggle rebuilds the
      // whole tree with the new ThemeData — exactly what a theme switch needs.
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          title: 'Berber Randevu Defteri',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.mode,
          // Switch crisply so every surface flips in the same frame — no
          // partial-transition where some colors lag behind.
          themeAnimationDuration: Duration.zero,
          locale: _trLocale,
          supportedLocales: const [_trLocale],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // AuthGate decides between splash / login / HomeShell; it also serves
          // as the '/' route, so the route table only holds pushable screens.
          // HomeShell owns the widget deep link (pop to it, select Defter tab).
          home: const AuthGate(),
          routes: {
            AppRoutes.calendar: (_) => const CalendarScreen(),
            AppRoutes.newAppointment: (_) => const NewAppointmentScreen(),
            AppRoutes.newCash: (_) => const NewCashScreen(),
            AppRoutes.detail: (_) => const AppointmentDetailScreen(),
            AppRoutes.settings: (_) => const SettingsScreen(),
          },
        ),
      ),
    );
  }
}
