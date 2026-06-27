import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';

/// Pushes a small summary of *today's* defter to the home-screen widget and
/// relays widget taps back as a deep link.
///
/// All `home_widget` interaction (App Group, shared storage, WidgetKit /
/// AppWidget reloads) is funnelled through here so the rest of the app never
/// touches the plugin directly. The stored keys are mirrored verbatim by the
/// iOS (`ios/RandevuWidget`) and Android (`RandevuWidgetProvider`) widgets — a
/// rename here must be made there too.
abstract final class WidgetService {
  /// iOS App Group shared between the app and the WidgetKit extension. Must match
  /// the `App Groups` entitlement on both the Runner and RandevuWidget targets.
  static const String _appGroupId = 'group.com.mimoza.randevu';

  /// iOS widget `kind` — the reload target for [HomeWidget.updateWidget].
  static const String _iOSName = 'RandevuWidget';

  /// Fully-qualified Android provider class — the reload target.
  static const String _androidProvider =
      'com.mimoza.randevu.RandevuWidgetProvider';

  /// Deep link delivered when the widget is tapped.
  static final Uri launchUri = Uri.parse('mimozarandevu://calendar');

  // Shared-storage keys — kept in sync with the native widgets.
  static const String _kDate = 'date';
  static const String _kTotal = 'total';
  static const String _kRemaining = 'remaining';
  static const String _kSlot1Time = 'n1_time';
  static const String _kSlot1Name = 'n1_name';
  static const String _kSlot2Time = 'n2_time';
  static const String _kSlot2Name = 'n2_name';

  static final DateFormat _dateLabel = DateFormat('d MMMM EEEE', 'tr_TR');

  /// Register the App Group so reads/writes hit the shared container on iOS.
  /// A no-op on Android. Call once during app start-up.
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (error) {
      _report('init', error);
    }
  }

  /// Write the summary for [todays] (one day's appointments, sorted by start)
  /// and reload the widget. "Remaining" and the next two slots are computed
  /// relative to now, so already-passed appointments drop off.
  static Future<void> updateToday(List<Appointment> todays) async {
    final now = DateTime.now();
    final upcoming = todays.where((a) => a.start.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    await _write(
      date: _dateLabel.format(now),
      total: todays.length,
      remaining: upcoming.length,
      slot1: upcoming.isNotEmpty ? upcoming[0] : null,
      slot2: upcoming.length > 1 ? upcoming[1] : null,
    );
  }

  /// Reset the widget to an empty state — used on sign-out so the next barber's
  /// home screen never shows the previous one's appointments.
  static Future<void> clear() => _write(
        date: _dateLabel.format(DateTime.now()),
        total: 0,
        remaining: 0,
        slot1: null,
        slot2: null,
      );

  /// Emits the [launchUri] each time the widget is tapped while the app runs.
  static Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  static Future<void> _write({
    required String date,
    required int total,
    required int remaining,
    required Appointment? slot1,
    required Appointment? slot2,
  }) async {
    try {
      await Future.wait<void>([
        HomeWidget.saveWidgetData<String>(_kDate, date),
        HomeWidget.saveWidgetData<int>(_kTotal, total),
        HomeWidget.saveWidgetData<int>(_kRemaining, remaining),
        HomeWidget.saveWidgetData<String>(_kSlot1Time, slot1?.time ?? ''),
        HomeWidget.saveWidgetData<String>(_kSlot1Name, slot1?.name ?? ''),
        HomeWidget.saveWidgetData<String>(_kSlot2Time, slot2?.time ?? ''),
        HomeWidget.saveWidgetData<String>(_kSlot2Name, slot2?.name ?? ''),
      ]);
      await HomeWidget.updateWidget(
        iOSName: _iOSName,
        qualifiedAndroidName: _androidProvider,
      );
    } catch (error) {
      _report('write', error);
    }
  }

  static void _report(String op, Object error) {
    // Widget sync is best-effort — never let it crash the app.
    debugPrint('WidgetService.$op failed: $error');
  }
}
