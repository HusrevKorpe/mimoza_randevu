import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/appointment.dart';

/// Schedules a local "yaklaşan randevu" reminder a configurable lead time
/// before each appointment and keeps the scheduled set reconciled with the
/// defter. The lead time and an on/off switch come from the user's settings.
///
/// All `flutter_local_notifications` / `timezone` interaction is funnellednoti
/// through here so screens never touch the plugin directly (mirrors
/// [WidgetService]). It's best-effort: every call is guarded so a denied
/// permission or platform hiccup degrades silently instead of crashing.
///
/// The device timezone is fixed to Europe/Istanbul — the app is Turkish-only
/// (tr_TR locale, Turkish UI) and appointment times are wall-clock local times,
/// so resolving the IANA zone statically keeps reminders correct without an
/// extra platform plugin.
abstract final class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Upper bound on pending reminders. iOS caps an app at 64 scheduled local
  /// notifications; staying well under leaves head-room for the OS.
  static const int _maxScheduled = 32;

  static const String _timeZone = 'Europe/Istanbul';

  static const String _channelId = 'reminders';
  static const String _channelName = 'Randevu hatırlatmaları';
  static const String _channelDesc =
      'Randevudan kısa süre önce gönderilen hatırlatmalar.';
  static const String _title = 'Yaklaşan randevu';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static bool _ready = false;

  /// Ids currently scheduled — drives reconciliation in [syncReminders].
  static Set<int> _active = <int>{};

  /// Initialize the plugin, timezone database and Android channel. Safe to call
  /// once during start-up; later calls are no-ops. Never throws.
  static Future<void> init() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_timeZone));

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission is requested explicitly later (after sign-in), not here.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      _ready = true;
    } catch (error) {
      _report('init', error);
    }
  }

  /// Ask the user for notification permission (iOS + Android 13+) and, where
  /// applicable, the exact-alarm permission so reminders fire on time. Best
  /// effort — a refusal just means no reminders.
  static Future<void> requestPermissions() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (error) {
      _report('permissions', error);
    }
  }

  /// Reconcile scheduled reminders against [upcoming] (appointments from today
  /// forward). When [enabled] is false every scheduled reminder is cancelled and
  /// none are added. Otherwise each reminder fires [leadTime] before its
  /// appointment; ones already past are skipped, the nearest [_maxScheduled] are
  /// kept, and stale reminders (deleted or moved appointments) are cancelled.
  static Future<void> syncReminders(
    List<Appointment> upcoming, {
    Duration leadTime = const Duration(minutes: 15),
    bool enabled = true,
  }) async {
    if (!_ready) return;
    if (!enabled) {
      await _cancelActive();
      return;
    }
    final now = DateTime.now();
    final eligible = <_Reminder>[];
    for (final appointment in upcoming) {
      final at = appointment.start.subtract(leadTime);
      if (at.isAfter(now)) {
        eligible.add(_Reminder(_idFor(appointment.id), appointment, at));
      }
    }
    eligible.sort((a, b) => a.at.compareTo(b.at));
    final keep = eligible.take(_maxScheduled).toList();
    final desiredIds = {for (final r in keep) r.id};

    try {
      for (final staleId in _active.difference(desiredIds)) {
        await _plugin.cancel(id: staleId);
      }
      for (final reminder in keep) {
        await _scheduleOne(reminder);
      }
      _active = desiredIds;
    } catch (error) {
      _report('sync', error);
    }
  }

  /// Cancel every scheduled reminder — used on sign-out so the next barber never
  /// inherits the previous one's reminders.
  static Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      _active = <int>{};
    } catch (error) {
      _report('cancelAll', error);
    }
  }

  /// Cancel just the reminders we currently track — used when the user turns
  /// reminders off, so existing appointments keep their data but stop notifying.
  static Future<void> _cancelActive() async {
    if (_active.isEmpty) return;
    try {
      for (final id in _active) {
        await _plugin.cancel(id: id);
      }
      _active = <int>{};
    } catch (error) {
      _report('disable', error);
    }
  }

  static Future<void> _scheduleOne(_Reminder reminder) async {
    final at = reminder.at;
    final when = tz.TZDateTime(
      tz.local,
      at.year,
      at.month,
      at.day,
      at.hour,
      at.minute,
    );
    final body = '${reminder.appointment.time} · ${reminder.appointment.name}';
    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: _title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException {
      // Exact alarms not permitted on this device — fall back to an inexact
      // schedule so the reminder still fires, just less precisely.
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: _title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Stable, positive 31-bit id derived from the Firestore document id so the
  /// same appointment always maps to the same notification slot.
  static int _idFor(String docId) => docId.hashCode & 0x7fffffff;

  static void _report(String op, Object error) {
    // Reminders are a convenience — never let them crash the app.
    debugPrint('NotificationService.$op failed: $error');
  }
}

/// A resolved reminder: the notification id, its appointment and when it fires.
class _Reminder {
  const _Reminder(this.id, this.appointment, this.at);

  final int id;
  final Appointment appointment;
  final DateTime at;
}
