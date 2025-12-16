import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:walkmypet/models/message_model.dart';
import 'package:walkmypet/models/conversation_model.dart';
import 'package:walkmypet/services/notification_service.dart';

class MessageService {
  late final FirebaseFirestore _firestore;
  late final NotificationService _notificationService;

  MessageService() {
    _firestore = FirebaseFirestore.instance;
    _notificationService = NotificationService();
  }

  /// Get or create a conversation between two users
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userName1,
    required String userPhoto1,
    required String userId2,
    required String userName2,
    required String userPhoto2,
  }) async {
    try {
      // Check if conversation already exists
      final existingConv = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId1)
          .get();

      for (var doc in existingConv.docs) {
        final conversation = Conversation.fromFirestore(doc);
        if (conversation.participantIds.contains(userId2)) {
          return doc.id;
        }
      }

      // Create new conversation
      final conversation = Conversation(
        id: '',
        participantIds: [userId1, userId2],
        participantNames: {
          userId1: userName1,
          userId2: userName2,
        },
        participantPhotos: {
          userId1: userPhoto1,
          userId2: userPhoto2,
        },
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: '',
        unreadCount: {
          userId1: 0,
          userId2: 0,
        },
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('conversations')
          .add(conversation.toFirestore());

      return docRef.id;
    } catch (e) {
      debugPrint('Error getting or creating conversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Send a message
  Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderPhotoUrl,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = Message(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        metadata: metadata,
      );

      // Add message to messages collection
      final docRef = await _firestore
          .collection('messages')
          .add(message.toFirestore());

      // Update conversation with last message
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      final conversationDoc = await conversationRef.get();
      if (conversationDoc.exists) {
        final conversation = Conversation.fromFirestore(conversationDoc);
        final updatedUnreadCount = Map<String, int>.from(conversation.unreadCount);
        updatedUnreadCount[receiverId] = (updatedUnreadCount[receiverId] ?? 0) + 1;

        await conversationRef.update({
          'lastMessage': content,
          'lastMessageTime': Timestamp.fromDate(DateTime.now()),
          'lastMessageSenderId': senderId,
          'unreadCount': updatedUnreadCount,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Send push notification to receiver
      await _notificationService.createNotification(
        userId: receiverId,
        title: 'New message from $senderName',
        message: content.length > 50 ? '${content.substring(0, 50)}...' : content,
        type: 'message',
        data: {
          'conversationId': conversationId,
          'senderId': senderId,
          'senderName': senderName,
        },
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for a conversation (stream)
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  /// Get conversations for a user (stream)
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Update all unread messages in the conversation
      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Update conversation unread count
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      final conversationDoc = await conversationRef.get();
      if (conversationDoc.exists) {
        final conversation = Conversation.fromFirestore(conversationDoc);
        final updatedUnreadCount = Map<String, int>.from(conversation.unreadCount);
        updatedUnreadCount[userId] = 0;

        await conversationRef.update({
          'unreadCount': updatedUnreadCount,
        });
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Get a specific conversation
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return Conversation.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return null;
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();

      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation
      batch.delete(_firestore.collection('conversations').doc(conversationId));

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Get total unread message count for a user
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final conversations = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (var doc in conversations.docs) {
        final conversation = Conversation.fromFirestore(doc);
        totalUnread += conversation.getUnreadCountForUser(userId);
      }

      return totalUnread;
    } catch (e) {
      debugPrint('Error getting total unread count: $e');
      return 0;
    }
  }
}
