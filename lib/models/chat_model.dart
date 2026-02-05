import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, dealRequest }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // For deal IDs etc

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }
}

class ChatRoom {
  final String id;
  final List<String> participants; // [clientUid, masterUid]
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, dynamic> participantData; // {uid: {name: "...", photo: "..."}} for quick display

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.participantData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'participantData': participantData,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: DateTime.tryParse(map['lastMessageTime'] ?? '') ?? DateTime.now(),
      participantData: Map<String, dynamic>.from(map['participantData'] ?? {}),
    );
  }
}
