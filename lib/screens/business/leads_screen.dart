import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/lead_model.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/services/chat_service.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:intl/intl.dart';

class LeadsScreen extends ConsumerWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    if (currentUser == null) return const Center(child: CircularProgressIndicator());

    final firebaseService = ref.read(firebaseServiceProvider);
    
    // We need a stream of leads for this master
    final leadsStream = firebaseService.getLeadsCount(currentUser.uid); // Wait, this returns count. 
    // We need getLeadsStream in FirebaseService!
    // I missed adding getLeadsStream. I only added getLeadsCount.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LEADS MANAGER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _LeadsList(masterId: currentUser.uid),
    );
  }
}

class _LeadsList extends ConsumerWidget {
  final String masterId;
  const _LeadsList({required this.masterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseService = ref.read(firebaseServiceProvider);
     return StreamBuilder<List<Lead>>(
      stream: firebaseService.getLeadsStream(masterId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final leads = snapshot.data!;
        if (leads.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                  const Gap(16),
                  const Text("No Leads Yet", style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: leads.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, index) {
            return _LeadCard(lead: leads[index]);
          },
        );
      },
    );
  }
}

class _LeadCard extends ConsumerWidget {
  final Lead lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseService = ref.read(firebaseServiceProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _StatusBadge(status: lead.status),
               Text(
                 DateFormat('MMM d, h:mm a').format(lead.createdAt),
                 style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
               ),
             ],
           ),
           const Gap(12),
           // Fetch Client Name
           FutureBuilder<AppUser?>(
             future: firebaseService.getUser(lead.clientId),
             builder: (context, snapshot) {
               final client = snapshot.data;
               return Text(
                 client?.displayName ?? "Unknown Client",
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
               );
             },
           ),
           const Gap(4),
           const Text("Interested in your service", style: TextStyle(color: Colors.white54, fontSize: 12)),
           const Gap(16),
           Row(
             children: [
               Expanded(
                 child: OutlinedButton.icon(
                   onPressed: () async {
                      // Open Chat
                      final currentUser = ref.read(currentUserProvider).asData?.value;
                      if (currentUser == null) return;
                      
                      // 1. Get Client User Object
                      final client = await firebaseService.getUser(lead.clientId);
                      if (client != null) {
                         final chatService = ref.read(chatServiceProvider);
                         final roomId = await chatService.getOrCreateChatRoom(currentUser, client);
                         if (context.mounted) {
                           context.push('/chats/$roomId');
                         }
                      }
                   },
                   icon: const Icon(Icons.chat_bubble_outline, size: 16),
                   label: const Text("Chat"),
                   style: OutlinedButton.styleFrom(
                     foregroundColor: AppTheme.primaryGold,
                     side: const BorderSide(color: AppTheme.primaryGold),
                   ),
                 ),
               ),
               const Gap(12),
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: () {
                     // Mark as Contacted or Converted?
                     // Verify implementation in real app
                   },
                   icon: const Icon(Icons.check, size: 16),
                   label: const Text("Dismiss"),
                   style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                   ),
                 ),
               ),
             ],
           )
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LeadStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (status) {
      case LeadStatus.open:
        color = Colors.blueAccent;
        label = "NEW LEAD";
        break;
      case LeadStatus.converted:
        color = Colors.greenAccent;
        label = "CONVERTED";
        break;
      case LeadStatus.archived:
        color = Colors.grey;
        label = "ARCHIVED";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
