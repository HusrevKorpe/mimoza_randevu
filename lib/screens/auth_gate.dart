import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_splash.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Top-level gate. Shows a splash until the persisted session is restored, then
/// the [HomeShell] (Defter + Giderler tabs) when signed in, or the login screen
/// otherwise. Listens to [AuthService] so sign-in / sign-out swap automatically.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    final Widget child;
    if (!auth.isReady) {
      child = const AppSplash(key: ValueKey('splash'));
    } else if (auth.isSignedIn) {
      child = const HomeShell(key: ValueKey('home'));
    } else {
      child = const LoginScreen(key: ValueKey('login'));
    }

    return AnimatedSwitcher(duration: AppDurations.normal, child: child);
  }
}
