import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';

/// Firestore access for one barber's appointments. Scoped to `users/{uid}/
/// appointments` so each profile only ever reads/writes its own defter.
///
/// Reads are narrow live queries (a month range for calendar dots, a single day
/// for the list) so the UI stays in sync without over-fetching. The day list is
/// sorted client-side by [Appointment.start] to avoid needing a composite index.
class AppointmentRepository {
  AppointmentRepository(this._uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('appointments');

  /// Live appointments for the whole [month] — used to mark days that have one.
  Stream<List<Appointment>> watchMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return _collection
        .where(
          'dateKey',
          isGreaterThanOrEqualTo: Appointment.dateKeyFor(first),
          isLessThanOrEqualTo: Appointment.dateKeyFor(last),
        )
        .orderBy('dateKey')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Appointment.fromDoc(doc)).toList());
  }

  /// Live appointments from [from] forward through [days] days, ordered by
  /// start. A bounded forward window keeps the query cheap and the resulting
  /// reminder set small — used by the notification scheduler, not the UI.
  Stream<List<Appointment>> watchUpcoming(DateTime from, {int days = 7}) {
    final start = DateTime(from.year, from.month, from.day);
    final end = start.add(Duration(days: days));
    return _collection
        .where(
          'dateKey',
          isGreaterThanOrEqualTo: Appointment.dateKeyFor(start),
          isLessThanOrEqualTo: Appointment.dateKeyFor(end),
        )
        .orderBy('dateKey')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => Appointment.fromDoc(doc)).toList();
      list.sort((a, b) => a.start.compareTo(b.start));
      return list;
    });
  }

  /// Live appointments for a single [day], ordered by start time.
  Stream<List<Appointment>> watchDay(DateTime day) {
    return _collection
        .where('dateKey', isEqualTo: Appointment.dateKeyFor(day))
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => Appointment.fromDoc(doc)).toList();
      list.sort((a, b) => a.start.compareTo(b.start));
      return list;
    });
  }

  /// Create a new appointment. Returns when the local write is queued (offline
  /// persistence lets this resolve without a round-trip).
  Future<void> add(Appointment appointment) =>
      _collection.add(appointment.toCreateData());

  /// Update an existing appointment by id.
  Future<void> update(Appointment appointment) =>
      _collection.doc(appointment.id).update(appointment.toUpdateData());

  /// Delete an appointment by id.
  Future<void> delete(String id) => _collection.doc(id).delete();
}
