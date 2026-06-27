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

  /// Selectable "how long before" values, in minutes (15 dk · 30 dk · 1 sa).
  static const List<int> reminderLeadOptions = <int>[15, 30, 60];

  /// The preset slot intervals offered as quick segments; any other stored value
  /// is a custom interval the user typed in.
  static const List<int> slotPresets = <int>[30, 60];

  /// Bounds for a custom slot interval, in minutes — keeps the generated chip
  /// list sane (never zero, never thousands of chips).
  static const int minSlotMinutes = 5;
  static const int maxSlotMinutes = 180;

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

  /// Sets the slot interval, clamped to [minSlotMinutes]–[maxSlotMinutes] so a
  /// custom value can never empty the chip list (≤0) or flood it (tiny step).
  Future<void> setSlotMinutes(int minutes) async {
    final next = minutes.clamp(minSlotMinutes, maxSlotMinutes);
    if (next == _slotMinutes) return;
    _slotMinutes = next;
    notifyListeners();
    await _save((p) => p.setInt(_kSlotMinutes, next));
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _remindersEnabled = p.getBool(_kRemindersEnabled) ?? _remindersEnabled;
      final lead = p.getInt(_kReminderLead) ?? _reminderLeadMinutes;
      // Migrate a value that's no longer offered (e.g. the retired "1 gün") to the
      // longest remaining option so the segmented control always has a selection.
      _reminderLeadMinutes =
          reminderLeadOptions.contains(lead) ? lead : reminderLeadOptions.last;
      // Clamp on load too, so a stale or out-of-range stored value can't slip
      // past the bounds that setSlotMinutes enforces.
      _slotMinutes =
          (p.getInt(_kSlotMinutes) ?? _slotMinutes)
              .clamp(minSlotMinutes, maxSlotMinutes);
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

/// Turkish label for a reminder lead time, e.g. 15 → "15 dakika", 60 → "1 saat".
/// Shared by the settings screen and the new-appointment hint so they never drift.
String reminderLeadLabel(int minutes) {
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
