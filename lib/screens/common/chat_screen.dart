import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/chat_model.dart';

class ChatScreen extends ConsumerWidget {
  final String roomId;
  
  const ChatScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatService = ref.watch(chatServiceProvider);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final messageController = TextEditingController();

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text("CHAT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatService.getMessages(roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                }
                
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                        const Gap(16),
                        const Text("No messages yet", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Show newest at bottom (requires reverse list logic usually, or just normal reverse)
                  // If 'orderBy descending' in backend, then msg[0] is newest. Use reverse: true to show msg[0] at bottom.
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;
                    return _ChatBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                   Expanded(
                     child: TextField(
                       controller: messageController,
                       style: const TextStyle(color: Colors.white),
                       decoration: InputDecoration(
                         hintText: "Type a message...",
                         hintStyle: const TextStyle(color: Colors.grey),
                         filled: true,
                         fillColor: Colors.black,
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(24),
                           borderSide: BorderSide.none,
                         ),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                       ),
                     ),
                   ),
                   const Gap(12),
                   IconButton(
                     onPressed: () {
                        if (messageController.text.trim().isNotEmpty && currentUser != null) {
                           chatService.sendMessage(roomId, currentUser.uid, messageController.text.trim());
                           messageController.clear();
                           AppHaptics.lightImpact();
                        }
                     },
                     style: IconButton.styleFrom(
                       backgroundColor: AppTheme.primaryGold,
                       foregroundColor: Colors.black,
                     ),
                     icon: const Icon(Icons.send_rounded),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryGold : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
             topLeft: const Radius.circular(16),
             topRight: const Radius.circular(16),
             bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
             bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Gap(4),
            Text(
              "${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}", // Simple time
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.black54 : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
