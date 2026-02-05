import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/transaction_model.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final transactionsAsync = ref.watch(userTransactionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text(
          'WALLET',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) => transactionsAsync.when(
          data: (transactions) => _buildBody(context, user, transactions),
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
          error: (err, _) => Center(child: Text('Error loading transactions: $err', style: const TextStyle(color: Colors.red))),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildBody(BuildContext context, dynamic user, List<Transaction> transactions) {
    // Sort transactions by date just in case
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        _buildBalanceHeader(user),
        _buildEarningsBreakdown(context, transactions),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    'HISTORY',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: sortedTransactions.isEmpty 
                    ? const Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.white24)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: sortedTransactions.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (context, index) {
                          return _buildTransactionItem(sortedTransactions[index])
                              .animate(delay: (100 * index).ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsBreakdown(BuildContext context, List<Transaction> transactions) {
    num networkTotal = 0; // L1-L3
    num directTotal = 0;  // 2% recommender + 2% opener
    num cashbackTotal = 0;

    final now = DateTime.now();
    final currentMonthTransactions = transactions.where((tx) => 
      tx.createdAt.year == now.year && tx.createdAt.month == now.month).toList();

    for (var tx in currentMonthTransactions) {
      if (tx.type == TransactionType.referralBonus) {
        // Network Income (L1-L3)
        networkTotal += tx.amount;
      } else if (tx.type == TransactionType.directBonus || tx.type == TransactionType.openerBonus) {
        // Direct Bonus (2%)
        directTotal += tx.amount;
      } else if (tx.type == TransactionType.cashback) {
        // Personal Cashback
        cashbackTotal += tx.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONTHLY REWARDS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.push('/wallet/history', extra: transactions);
                },
                child: const Row(
                  children: [
                    Text("VIEW HISTORY", style: TextStyle(color: AppTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    Gap(4),
                    Icon(Icons.arrow_forward_ios, color: AppTheme.primaryGold, size: 8),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              _buildBreakdownItem('Network Income', networkTotal, Icons.account_tree_outlined),
              const Gap(12),
              _buildBreakdownItem('Direct Bonus (2%)', directTotal, Icons.stars_rounded),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              _buildBreakdownItem('Personal Cashback', cashbackTotal, Icons.savings_outlined),
              const Gap(12),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, num amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 18),
            const Gap(12),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const Gap(4),
            Text(
              '${amount.toStringAsFixed(0)} Stars',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(AppUser user) {
    final num balance = user.balanceStars;
    final bool isVip = user.isVip;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text(
            'TOTAL STARS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: AppTheme.primaryGold, size: 32),
              const Gap(10),
              Text(
                '$balance',
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: (isVip ? AppTheme.primaryGold : Colors.white).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (isVip ? AppTheme.primaryGold : Colors.white).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Status: ${isVip ? "VIP Elite" : "Base Member"}',
                  style: TextStyle(
                    color: isVip ? AppTheme.primaryGold : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (user.businessRecommenderId != null) ...[
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Text(
                    'Partner Program Active',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    final String dateStr = DateFormat('MMM d, HH:mm').format(tx.createdAt);
    final bool isIncoming = tx.type != TransactionType.withdrawal && tx.type != TransactionType.payment;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.deepBlack, // Item background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: AppTheme.primaryGold,
              size: 20,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Gap(4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncoming ? '+' : '-'}${tx.amount}',
            style: const TextStyle(
              color: AppTheme.primaryGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
