import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cash_entry.dart';

/// Firestore access for one barber's expense entries.
///
/// Scoped to the `users/{uid}/expenses` subcollection. Reads are narrow month
/// ranges over [CashEntry.date], sorted client-side (newest first) to avoid
/// composite indexes — mirroring [AppointmentRepository].
class CashRepository {
  CashRepository(this._uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('expenses');

  /// Live entries for the whole [month], newest first.
  Stream<List<CashEntry>> watchMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _rangeStream(start, end);
  }

  /// Half-open [start, end) range query on the day field. A single-field range
  /// needs no composite index; results are sorted client-side.
  Stream<List<CashEntry>> _rangeStream(DateTime start, DateTime end) {
    return _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => CashEntry.fromDoc(doc)).toList();
      list.sort(_byNewest);
      return list;
    });
  }

  /// Create a new entry.
  Future<void> add(CashEntry entry) => _collection.add(entry.toCreateData());

  /// Update an existing entry by id.
  Future<void> update(CashEntry entry) =>
      _collection.doc(entry.id).update(entry.toUpdateData());

  /// Delete an entry by id.
  Future<void> delete(String id) => _collection.doc(id).delete();

  /// Newest first: by day, then by creation time. A pending `createdAt` (null on
  /// a just-queued local write) sorts ahead so new rows appear at the top.
  static int _byNewest(CashEntry a, CashEntry b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    final ac = a.createdAt;
    final bc = b.createdAt;
    if (ac == null && bc == null) return 0;
    if (ac == null) return -1;
    if (bc == null) return 1;
    return bc.compareTo(ac);
  }
}
