import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A single to-do line: free text plus a done flag.
///
/// General (not tied to a day) — it lives on the Günlük tab. Stored under
/// `users/{uid}/notes`; Firestore (de)serialization lives here so the repository
/// stays thin. Tolerates docs that still carry a legacy `date` field (from when
/// notes were day-scoped); it's simply ignored.
@immutable
class Note {
  const Note({
    required this.id,
    required this.text,
    required this.done,
    this.createdAt,
  });

  final String id;
  final String text;

  /// Whether it's been checked off.
  final bool done;

  /// Server-stamped creation time; null while a fresh local write is pending.
  final DateTime? createdAt;

  /// Read a model from a Firestore document, tolerating missing fields.
  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawCreated = data['createdAt'];
    return Note(
      id: doc.id,
      text: (data['text'] as String?)?.trim() ?? '',
      done: data['done'] == true,
      createdAt: rawCreated is Timestamp ? rawCreated.toDate() : null,
    );
  }

  /// Payload for creating a new document (server-stamped `createdAt`).
  Map<String, dynamic> toCreateData() => <String, dynamic>{
        'text': text,
        'done': done,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
