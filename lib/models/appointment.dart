import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// A single appointment — intentionally just name, phone and date/time.
///
/// [dateKey] ("2026-06-26") is the day bucket used for month/day Firestore
/// queries; [start] is the sortable instant; [time] ("09:30") is the display
/// label. Firestore (de)serialization lives here so the repository stays thin.
@immutable
class Appointment {
  const Appointment({
    required this.id,
    required this.name,
    required this.phone,
    required this.dateKey,
    required this.time,
    required this.start,
    this.note,
  });

  final String id;
  final String name;
  final String phone;

  /// Day bucket, "yyyy-MM-dd". Drives the month/day queries.
  final String dateKey;

  /// Display time, "HH:mm".
  final String time;

  /// Sortable start instant.
  final DateTime start;

  /// Optional free-text note.
  final String? note;

  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  /// The "yyyy-MM-dd" key for [day] (date part only).
  static String dateKeyFor(DateTime day) => _keyFormat.format(day);

  /// Read a model from a Firestore document. Tolerates missing fields so a
  /// malformed doc degrades gracefully instead of crashing the list.
  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawStart = data['start'];
    final note = (data['note'] as String?)?.trim();
    return Appointment(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      dateKey: (data['dateKey'] as String?) ?? '',
      time: (data['time'] as String?) ?? '',
      start: rawStart is Timestamp
          ? rawStart.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      note: (note == null || note.isEmpty) ? null : note,
    );
  }

  /// Payload for creating a new document (server-stamped `createdAt`).
  Map<String, dynamic> toCreateData() => <String, dynamic>{
        'name': name,
        'phone': phone,
        'dateKey': dateKey,
        'time': time,
        'start': Timestamp.fromDate(start),
        if (note != null && note!.isNotEmpty) 'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Payload for updating an existing document. Clears the note when emptied.
  Map<String, dynamic> toUpdateData() => <String, dynamic>{
        'name': name,
        'phone': phone,
        'dateKey': dateKey,
        'time': time,
        'start': Timestamp.fromDate(start),
        'note': (note != null && note!.isNotEmpty) ? note : FieldValue.delete(),
      };
}
