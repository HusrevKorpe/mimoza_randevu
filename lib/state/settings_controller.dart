import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-tunable preferences that aren't auth or theme: reminder timing and the
/// barber's working hours (which drive the time chips on the new-appointment
/// form). Backed by [SharedPreferences] so choices stick across launches.
///
/// Loads asynchronously after construction — sensible defaults apply until the
/// stored values arrive, then [notifyListeners] refreshes any listening screen.
/// All writes are guarded: a persistence hiccup just means the change won't
/// survive the next launch, never a crash.
class SettingsController extends ChangeNotifier {
  SettingsController() {
    _load();
  }

  // Preference keys.
  static const String _kRemindersEnabled = 'reminders_enabled';
  static const String _kReminderLead = 'reminder_lead_minutes';
  static const String _kWorkStartHour = 'work_start_hour';
  static const String _kWorkEndHour = 'work_end_hour';
  static const String _kSlotMinutes = 'slot_minutes';

  /// Selectable "how long before" values, in minutes (15 dk · 30 dk · 1 sa · 1 gün).
  static const List<int> reminderLeadOptions = <int>[15, 30, 60, 1440];

  /// Selectable slot intervals for the time chips, in minutes.
  static const List<int> slotOptions = <int>[15, 30, 60];

  /// Earliest / latest hour the barber works (24h). Bounds the hour steppers.
  static const int minWorkHour = 6;
  static const int maxWorkHour = 23;

  bool _remindersEnabled = true;
  int _reminderLeadMinutes = 15;
  int _workStartHour = 9;
  int _workEndHour = 22;
  int _slotMinutes = 30;

  /// Whether a reminder fires before each appointment.
  bool get remindersEnabled => _remindersEnabled;

  /// How many minutes before the appointment the reminder fires.
  int get reminderLeadMinutes => _reminderLeadMinutes;

  /// First selectable hour of the working day (inclusive).
  int get workStartHour => _workStartHour;

  /// Last selectable hour of the working day (inclusive).
  int get workEndHour => _workEndHour;

  /// Spacing between preset time chips, in minutes.
  int get slotMinutes => _slotMinutes;

  Future<void> setRemindersEnabled(bool value) async {
    if (value == _remindersEnabled) return;
    _remindersEnabled = value;
    notifyListeners();
    await _save((p) => p.setBool(_kRemindersEnabled, value));
  }

  Future<void> setReminderLeadMinutes(int minutes) async {
    if (minutes == _reminderLeadMinutes) return;
    _reminderLeadMinutes = minutes;
    notifyListeners();
    await _save((p) => p.setInt(_kReminderLead, minutes));
  }

  /// Sets the start hour, clamped to bounds and kept below the end hour so the
  /// generated slot list can never be empty or inverted.
  Future<void> setWorkStartHour(int hour) async {
    final next = hour.clamp(minWorkHour, _workEndHour - 1);
    if (next == _workStartHour) return;
    _workStartHour = next;
    notifyListeners();
    await _save((p) => p.setInt(_kWorkStartHour, next));
  }

  /// Sets the end hour, clamped to bounds and kept above the start hour.
  Future<void> setWorkEndHour(int hour) async {
    final next = hour.clamp(_workStartHour + 1, maxWorkHour);
    if (next == _workEndHour) return;
    _workEndHour = next;
    notifyListeners();
    await _save((p) => p.setInt(_kWorkEndHour, next));
  }

  Future<void> setSlotMinutes(int minutes) async {
    if (minutes == _slotMinutes) return;
    _slotMinutes = minutes;
    notifyListeners();
    await _save((p) => p.setInt(_kSlotMinutes, minutes));
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _remindersEnabled = p.getBool(_kRemindersEnabled) ?? _remindersEnabled;
      _reminderLeadMinutes = p.getInt(_kReminderLead) ?? _reminderLeadMinutes;
      _slotMinutes = p.getInt(_kSlotMinutes) ?? _slotMinutes;
      // Read end before start so the start clamp below has the stored end to
      // validate against rather than the default.
      final end = p.getInt(_kWorkEndHour) ?? _workEndHour;
      final start = p.getInt(_kWorkStartHour) ?? _workStartHour;
      _workEndHour = end.clamp(minWorkHour + 1, maxWorkHour);
      _workStartHour = start.clamp(minWorkHour, _workEndHour - 1);
      notifyListeners();
    } catch (_) {
      // Keep the defaults; the screen still works, just unpersisted.
    }
  }

  Future<void> _save(Future<void> Function(SharedPreferences) write) async {
    try {
      write(await SharedPreferences.getInstance());
    } catch (_) {
      // Best-effort persistence; the in-session change already took effect.
    }
  }
}

/// Turkish label for a reminder lead time, e.g. 15 → "15 dakika", 60 → "1 saat",
/// 1440 → "1 gün". Shared by the settings screen and the new-appointment hint so
/// they never drift.
String reminderLeadLabel(int minutes) {
  if (minutes >= 1440 && minutes % 1440 == 0) {
    final days = minutes ~/ 1440;
    return '$days gün';
  }
  if (minutes >= 60 && minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return '$hours saat';
  }
  return '$minutes dakika';
}

/// Compact label for a slot interval, e.g. 30 → "30 dk", 60 → "1 saat".
String slotIntervalLabel(int minutes) {
  if (minutes >= 60 && minutes % 60 == 0) return '${minutes ~/ 60} saat';
  return '$minutes dk';
}

/// Two-digit clock label for a whole hour, e.g. 9 → "09:00".
String wholeHourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';
