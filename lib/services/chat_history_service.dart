import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bookmark/models/chat_model.dart';

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat
  Future<String?> createChat(String userId, ChatModel chat) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .add(chat.toJson());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Error creating chat: $e');
      return null;
    }
  }

  // Update an existing chat
  Future<bool> updateChat(String userId, String chatId, ChatModel chat) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .update(chat.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating chat: $e');
      return false;
    }
  }

  // Get a single chat
  Future<ChatModel?> getChat(String userId, String chatId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .get();

      if (!doc.exists) return null;
      return ChatModel.fromJson(doc.data()!, id: doc.id);
    } catch (e) {
      if (kDebugMode) print('Error getting chat: $e');
      return null;
    }
  }

  // Get all chats for a user (most recent first)
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting chats: $e');
      return [];
    }
  }

  // Stream chats for real-time updates
  Stream<List<ChatModel>> streamUserChats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  // Delete a chat
  Future<bool> deleteChat(String userId, String chatId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting chat: $e');
      return false;
    }
  }

  // Generate a title from the first message
  String generateTitle(String firstMessage) {
    // Take first 50 characters or until first newline
    String title = firstMessage.split('\n').first;
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }
    return title.isEmpty ? 'New Chat' : title;
  }
}
