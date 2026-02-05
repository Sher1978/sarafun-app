import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sara_fun/models/chat_model.dart';
import 'package:sara_fun/models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Rooms ---

  /// Get or Create a chat room between two users
  Future<String> getOrCreateChatRoom(AppUser currentUser, AppUser otherUser) async {
    // 1. Check if room exists
    // We order participants to ensure consistency regardless of who initiates
    final participants = [currentUser.uid, otherUser.uid]..sort();
    final roomId = participants.join('_'); // Simple composite ID

    final docRef = _firestore.collection('chat_rooms').doc(roomId);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Create new room
      final room = ChatRoom(
        id: roomId,
        participants: participants,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        participantData: {
          currentUser.uid: {
            'name': currentUser.displayName ?? currentUser.username,
            'photo': currentUser.photoURL
          },
          otherUser.uid: {
            'name': otherUser.businessName ?? otherUser.displayName ?? otherUser.username,
            'photo': otherUser.photoURL
          }
        },
      );
      await docRef.set(room.toMap());
    }

    return roomId;
  }

  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data())).toList();
    });
  }

  // --- Messages ---

  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList();
    });
  }

  Future<void> sendMessage(String roomId, String senderId, String text, {MessageType type = MessageType.text, Map<String, dynamic>? metadata}) async {
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final newMessage = ChatMessage(
      id: messageRef.id,
      senderId: senderId,
      text: text,
      type: type,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    final batch = _firestore.batch();
    
    // Add message
    batch.set(messageRef, newMessage.toMap());
    
    // Update room summary
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    batch.update(roomRef, {
      'lastMessage': type == MessageType.image ? '📷 Image' : text,
      'lastMessageTime': newMessage.createdAt.toIso8601String(),
    });

    await batch.commit();
  }
}
