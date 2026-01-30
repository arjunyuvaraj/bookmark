import 'package:bookmark/models/note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new note
  Future<String?> createNote(String userId, NoteModel note) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add(note.toJson());

      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Error creating note: $e');
      return null;
    }
  }

  /// Get all notes for a user
  Future<List<NoteModel>> getUserNotes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NoteModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting notes: $e');
      return [];
    }
  }

  /// Get a specific note
  Future<NoteModel?> getNote(String userId, String noteId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .get();

      if (!doc.exists) return null;
      return NoteModel.fromJson(doc.data()!, id: doc.id);
    } catch (e) {
      if (kDebugMode) print('Error getting note: $e');
      return null;
    }
  }

  /// Update a note
  Future<bool> updateNote(String userId, String noteId, NoteModel note) async {
    try {
      note.updatedAt = DateTime.now();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .update(note.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating note: $e');
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting note: $e');
      return false;
    }
  }

  /// Stream notes for real-time updates
  Stream<List<NoteModel>> streamUserNotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NoteModel.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Search notes by title or subject
  Future<List<NoteModel>> searchNotes(String userId, String query) async {
    try {
      final allNotes = await getUserNotes(userId);
      final queryLower = query.toLowerCase();

      return allNotes.where((note) =>
        note.title.toLowerCase().contains(queryLower) ||
        note.subject.toLowerCase().contains(queryLower)
      ).toList();
    } catch (e) {
      if (kDebugMode) print('Error searching notes: $e');
      return [];
    }
  }
}
