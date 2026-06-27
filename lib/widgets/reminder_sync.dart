import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/notification_service.dart';
import '../state/settings_controller.dart';

/// Keeps local reminder notifications in sync with the upcoming defter and the
/// user's reminder settings while the signed-in shell is mounted.
///
/// Lives inside the [AppointmentRepository] subtree (like [WidgetSync]),
/// subscribes to the upcoming window and forwards each change to
/// [NotificationService] using the lead time and on/off switch from
/// [SettingsController]. It also re-syncs whenever those settings change, so
/// toggling reminders off cancels them immediately and changing the lead time
/// reschedules. Requests notification permission when reminders are on; on
/// resume it rolls the window over at midnight. When the shell unmounts
/// (sign-out) it cancels everything so the next barber never inherits the
/// previous one's reminders. Renders [child] untouched.
class ReminderSync extends StatefulWidget {
  const ReminderSync({super.key, required this.child});

  final Widget child;

  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync>
    with WidgetsBindingObserver {
  StreamSubscription<List<Appointment>>? _sub;
  late final SettingsController _settings;
  List<Appointment> _lastItems = const <Appointment>[];
  bool _enabledBefore = false;
  DateTime _day = _dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = context.read<SettingsController>();
    _settings.addListener(_onSettingsChanged);
    _enabledBefore = _settings.remindersEnabled;
    // Ask once, right after the signed-in shell appears — only if reminders are
    // actually on; turning them on later requests permission then.
    if (_settings.remindersEnabled) NotificationService.requestPermissions();
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = context.read<AppointmentRepository>().watchUpcoming(_day).listen(
      (items) {
        _lastItems = items;
        _sync();
      },
      onError: (_) {/* best-effort; keep the last scheduled set */},
    );
  }

  void _onSettingsChanged() {
    final enabled = _settings.remindersEnabled;
    // Reminders just went from off to on — make sure we hold permission.
    if (enabled && !_enabledBefore) NotificationService.requestPermissions();
    _enabledBefore = enabled;
    _sync();
  }

  void _sync() {
    NotificationService.syncReminders(
      _lastItems,
      leadTime: Duration(minutes: _settings.reminderLeadMinutes),
      enabled: _settings.remindersEnabled,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final today = _dateOnly(DateTime.now());
    if (today != _day) {
      _day = today;
      _subscribe(); // advance the window so passed days drop out
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _sub?.cancel();
    NotificationService.cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
