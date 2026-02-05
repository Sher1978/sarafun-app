import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/deal_model.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/transaction_model.dart';
import 'package:sara_fun/core/providers.dart';

class HistoryScreen extends ConsumerWidget {
  final AppUser client;
  final List<dynamic>? initialData; // Can be List<Deal> or List<Transaction>

  const HistoryScreen({super.key, required this.client, this.initialData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseService = ref.watch(firebaseServiceProvider);

    if (initialData != null && initialData!.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.deepBlack,
        appBar: AppBar(title: const Text("PAYMENT HISTORY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)), backgroundColor: Colors.transparent, elevation: 0),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          itemCount: initialData!.length,
          separatorBuilder: (_, __) => const Gap(8),
          itemBuilder: (context, index) {
            final item = initialData![index];
            if (item is Transaction) {
              return _buildTransactionItem(item);
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(title: const Text("BOOKING HISTORY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)), backgroundColor: Colors.transparent, elevation: 0),
      body: StreamBuilder<List<Deal>>(
        stream: firebaseService.getDealsForUser(client.uid, isClient: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
          }

          final deals = snapshot.data!;
          if (deals.isEmpty) {
            return const Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.white24, fontSize: 12)));
          }

          deals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: deals.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (context, index) {
              final deal = deals[index];
              return _buildDealItem(deal);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    final dateStr = DateFormat('MMM d, HH:mm').format(tx.createdAt);
    final isIncoming = tx.type != TransactionType.withdrawal && tx.type != TransactionType.payment;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Icon(
            isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: AppTheme.primaryGold,
            size: 18,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.note, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isIncoming ? '+' : '-'}${tx.amount}',
            style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildDealItem(Deal deal) {
    final dateStr = DateFormat('MMM d • HH:mm').format(deal.createdAt);
    final cashback = deal.commissionDistribution['clientReward'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGold, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${deal.amountStars} Stars Paid", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("CASHBACK", style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900)),
              Text("+$cashback", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
