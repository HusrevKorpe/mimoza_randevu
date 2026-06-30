import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A single expense entry — intentionally just a title, an amount and a day.
///
/// Stored under `users/{uid}/expenses`. Amounts are shown as written (no income
/// side, no signed totals). Firestore (de)serialization lives here so the
/// repository stays thin. Tolerates docs that still carry a legacy `type` field
/// (from the old two-sided ledger); it's simply ignored.
@immutable
class CashEntry {
  const CashEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.createdAt,
  });

  final String id;
  final String title;

  /// Amount in Turkish Lira, always positive.
  final double amount;

  /// The day this entry belongs to (date-only).
  final DateTime date;

  /// Server-stamped creation time; null while a fresh local write is pending.
  final DateTime? createdAt;

  /// Read a model from a Firestore document. Tolerates missing/malformed fields
  /// so one bad doc degrades gracefully instead of crashing the list.
  factory CashEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawAmount = data['amount'];
    final rawDate = data['date'];
    final rawCreated = data['createdAt'];
    return CashEntry(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      amount: rawAmount is num ? rawAmount.toDouble() : 0,
      date: rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: rawCreated is Timestamp ? rawCreated.toDate() : null,
    );
  }

  /// Payload for creating a new document (server-stamped `createdAt`).
  Map<String, dynamic> toCreateData() => <String, dynamic>{
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Payload for updating an existing document.
  Map<String, dynamic> toUpdateData() => <String, dynamic>{
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(date),
      };
}
