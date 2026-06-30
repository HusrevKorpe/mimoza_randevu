import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';

/// Firestore access for one barber's notes (to-dos). Scoped to
/// `users/{uid}/notes`.
///
/// Notes are general (not tied to a day). Sorted client-side oldest-first so
/// checking one off never reorders the list (no jank), and a new note lands at
/// the bottom beside the add field.
class NoteRepository {
  NoteRepository(this._uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('notes');

  /// Live notes, oldest first.
  Stream<List<Note>> watchAll() {
    return _collection.snapshots().map((snap) {
      final list = snap.docs.map((doc) => Note.fromDoc(doc)).toList();
      list.sort(_byOldest);
      return list;
    });
  }

  /// Add a note. Returns when the local write is queued.
  Future<void> add(String text) {
    final note = Note(id: '', text: text, done: false);
    return _collection.add(note.toCreateData());
  }

  /// Check / uncheck a note.
  Future<void> setDone(String id, bool done) =>
      _collection.doc(id).update(<String, dynamic>{'done': done});

  /// Delete a note by id.
  Future<void> delete(String id) => _collection.doc(id).delete();

  /// Oldest first; a pending `createdAt` (local write) sorts last so a new note
  /// appears at the bottom, beside the add field.
  static int _byOldest(Note a, Note b) {
    final ac = a.createdAt;
    final bc = b.createdAt;
    if (ac == null && bc == null) return 0;
    if (ac == null) return 1;
    if (bc == null) return -1;
    return ac.compareTo(bc);
  }
}
