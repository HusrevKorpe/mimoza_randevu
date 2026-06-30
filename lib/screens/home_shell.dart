import 'dart:async';

import 'package:flutter/material.dart';

import '../services/widget_service.dart';
import '../widgets/app_bottom_bar.dart';
import 'calendar_screen.dart';
import 'daily_screen.dart';

/// The app shell behind the bottom navigation bar. Hosts the two top-level tabs
/// — Randevu Defteri and Günlük — in an [IndexedStack] so each keeps its state
/// (and live Firestore streams) across tab switches.
///
/// This is the first route under [AuthGate], so it also owns the home-screen
/// widget deep link: a tap drops any pushed screens and surfaces the Defter tab
/// (the widget summarizes appointments).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    _widgetClicks = WidgetService.clicks.listen((_) {
      if (!mounted) return;
      // Bring the app to the Randevu Defteri: pop pushed routes, select tab 0.
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (_index != 0) setState(() => _index = 0);
    });
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    super.dispose();
  }

  void _select(int index) {
    if (index != _index) setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [CalendarScreen(), DailyScreen()],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _index,
        onTap: _select,
      ),
    );
  }
}
