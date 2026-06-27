import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/widget_service.dart';

/// Keeps the home-screen widget in sync with *today's* defter while the signed-in
/// shell is mounted.
///
/// Lives inside the [AppointmentRepository] subtree, subscribes to today's
/// appointments and forwards each change to [WidgetService]. On resume it rolls
/// the watched day over at midnight and re-pushes so "remaining" stays fresh.
/// When the shell unmounts (sign-out) it clears the widget, so the next barber
/// never sees the previous one's appointments. Renders [child] untouched.
class WidgetSync extends StatefulWidget {
  const WidgetSync({super.key, required this.child});

  final Widget child;

  @override
  State<WidgetSync> createState() => _WidgetSyncState();
}

class _WidgetSyncState extends State<WidgetSync> with WidgetsBindingObserver {
  StreamSubscription<List<Appointment>>? _sub;
  List<Appointment> _latest = const [];
  DateTime _day = _dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = context.read<AppointmentRepository>().watchDay(_day).listen(
      (items) {
        _latest = items;
        WidgetService.updateToday(items);
      },
      onError: (_) {/* best-effort; keep the last good summary */},
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final today = _dateOnly(DateTime.now());
    if (today != _day) {
      _day = today;
      _subscribe();
    } else {
      // Same day — re-push so passed appointments drop out of "remaining".
      WidgetService.updateToday(_latest);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    WidgetService.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
