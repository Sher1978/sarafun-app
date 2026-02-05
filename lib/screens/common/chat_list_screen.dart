import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara_fun/core/theme/app_theme.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text("MESSAGES", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(child: Text("Chat List", style: TextStyle(color: Colors.white))),
    );
  }
}
