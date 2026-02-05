import 'package:flutter_test/flutter_test.dart';
import 'package:sara_fun/models/chat_model.dart';

void main() {
  group('ChatModel Tests', () {
    test('ChatMessage Serialization', () {
      final msg = ChatMessage(
        id: 'msg1',
        senderId: 'user1',
        text: 'Hello',
        type: MessageType.text,
        createdAt: DateTime(2023, 1, 1),
      );

      final map = msg.toMap();
      expect(map['id'], 'msg1');
      expect(map['senderId'], 'user1');
      expect(map['type'], 'text');

      final fromMap = ChatMessage.fromMap(map);
      expect(fromMap.id, msg.id);
      expect(fromMap.text, msg.text);
      expect(fromMap.type, msg.type);
    });

    test('ChatRoom Serialization', () {
      final room = ChatRoom(
        id: 'room1',
        participants: ['u1', 'u2'],
        lastMessage: 'Hi',
        lastMessageTime: DateTime(2023, 1, 1),
        participantData: {'u1': {'name': 'Alice'}},
      );

      final map = room.toMap();
      expect(map['id'], 'room1');
      expect(map['participants'], ['u1', 'u2']);

      final fromMap = ChatRoom.fromMap(map);
      expect(fromMap.id, room.id);
      expect(fromMap.participants.length, 2);
      expect(fromMap.participantData['u1']['name'], 'Alice');
    });
  });
}
