import 'dart:io';
import 'package:bookmark/models/flashcard_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FlashcardSetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // METHOD: Build flashcard set
  Future<String?> createSet(
    String userId,
    SetModel set, {
    File? file,
    Uint8List? webFile,
  }) async {
    try {
      if (file != null || webFile != null) {
        final fileData = await _uploadFile(userId, set.title, file, webFile);
        set.fileUrl = fileData['url'];
        set.fileName = fileData['name'];
      }

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .add(set.toJson());

      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Error creating set: $e');
      return null;
    }
  }

  // METHOD: Handle uploading a file, and push it firebase storage
  Future<Map<String, String>> _uploadFile(
    String userId,
    String setTitle,
    File? file,
    Uint8List? webFile,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = file?.path.split('/').last ?? 'file_$timestamp';
    final ref = _storage.ref().child('users/$userId/sets/$setTitle/$fileName');

    if (kIsWeb && webFile != null) {
      await ref.putData(webFile);
    } else if (file != null) {
      await ref.putFile(file);
    }

    final url = await ref.getDownloadURL();
    return {'url': url, 'name': fileName};
  }

  // METHOD: Get the users(found using UIDs) sets
  Future<List<SetModel>> getUserSets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .orderBy('dateAdded', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SetModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting sets: $e');
      return [];
    }
  }

  // METHOD: Get a set provided the userID and setID
  Future<SetModel?> getSet(String userId, String setId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .doc(setId)
          .get();

      if (!doc.exists) return null;
      return SetModel.fromJson(doc.data()!, id: doc.id);
    } catch (e) {
      if (kDebugMode) print('Error getting set: $e');
      return null;
    }
  }

  // METHOD: Update the set
  Future<bool> updateSet(String userId, String setId, SetModel set) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .doc(setId)
          .update(set.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating set: $e');
      return false;
    }
  }

  // METHOD: Remove set
  Future<bool> deleteSet(String userId, String setId, {String? fileUrl}) async {
    try {
      if (fileUrl != null) {
        try {
          await _storage.refFromURL(fileUrl).delete();
        } catch (e) {
          // File might not exist, continue with set deletion
          if (kDebugMode) print('Error deleting file: $e');
        }
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .doc(setId)
          .delete();

      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting set: $e');
      return false;
    }
  }

  // METHOD: Update session count
  Future<void> incrementSessions(String userId, String setId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .doc(setId)
          .update({'sessions': FieldValue.increment(1)});
    } catch (e) {
      if (kDebugMode) print('Error incrementing sessions: $e');
    }
  }

  // METHOD: Add new card
  Future<bool> addCard(String userId, String setId, Flashcard card) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .doc(setId)
          .update({
            'cards': FieldValue.arrayUnion([card.toJson()]),
          });
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding card: $e');
      return false;
    }
  }

  // METHOD: Upload additional file to existing set
  Future<Map<String, String>?> uploadAdditionalFile(
    String userId,
    String setTitle,
    File? file,
    Uint8List? webFile,
  ) async {
    try {
      if (file == null && webFile == null) return null;
      return await _uploadFile(userId, setTitle, file, webFile);
    } catch (e) {
      if (kDebugMode) print('Error uploading additional file: $e');
      return null;
    }
  }

  // METHOD: Determine file type from extension
  FileType _getFileTypeFromName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return FileType.pdf;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return FileType.video;
      case 'csv':
        return FileType.csv;
      default:
        return FileType.none;
    }
  }

  // METHOD: Update set to add additional file reference
  Future<bool> addFileToSet(
    String userId,
    String setId,
    String fileUrl,
    String fileName,
  ) async {
    try {
      final fileType = _getFileTypeFromName(fileName);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sets')
          .doc(setId)
          .update({
            'fileUrl': fileUrl,
            'fileName': fileName,
            'fileType': fileType.name,
          });
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding file to set: $e');
      return false;
    }
  }

  // METHOD: Build an active stream for users
  Stream<List<SetModel>> streamUserSets(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sets')
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SetModel.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }
}
