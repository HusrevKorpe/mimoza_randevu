import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';
import 'login_screen.dart';

/// Top-level gate. Shows a splash until the persisted session is restored, then
/// the Randevu Defteri when signed in, or the login screen otherwise. Listens to
/// [AuthService] so sign-in / sign-out swap the screen automatically.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    final Widget child;
    if (!auth.isReady) {
      child = const _Splash(key: ValueKey('splash'));
    } else if (auth.isSignedIn) {
      child = const CalendarScreen(key: ValueKey('calendar'));
    } else {
      child = const LoginScreen(key: ValueKey('login'));
    }

    return AnimatedSwitcher(duration: AppDurations.normal, child: child);
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}
