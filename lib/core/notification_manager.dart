import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/transaction_model.dart';

class NotificationManager extends ConsumerWidget {
  final Widget child;

  const NotificationManager({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for changes in the transactions stream
    ref.listen<AsyncValue<List<Transaction>>>(userTransactionsProvider, (previous, next) {
      next.when(
        data: (transactions) {
          final prevList = previous?.value ?? [];
          
          // Check if we have a new transaction (more items than before, and recent)
          // Also handle initial load (previous == null) - usually suppress notifications on initial load
          // But if previous is NOT null and we have more items:
          if (previous != null && transactions.length > prevList.length) {
             final newTx = transactions.first;
             
             // Verify it's actually new (compare IDs) and recent
             if (prevList.isEmpty || newTx.id != prevList.first.id) {
                // Ensure it happened recently (e.g., last 10 seconds) to avoid spam on reconnect
                final timeDiff = DateTime.now().difference(newTx.createdAt);
                if (timeDiff.inSeconds < 30) {
                   _showTransactionSnackBar(context, newTx);
                }
             }
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    });

    return child;
  }

  void _showTransactionSnackBar(BuildContext context, Transaction tx) {
    final bool isPositive = tx.amount > 0;
    IconData icon;
    String title;
    
    switch (tx.type) {
      case TransactionType.cashback:
        icon = Icons.savings_rounded;
        title = "Cashback Received!";
        break;
      case TransactionType.referralBonus:
      case TransactionType.directBonus:
      case TransactionType.openerBonus:
        icon = Icons.account_tree_rounded;
        title = "Bonus Earned!";
        break;
      case TransactionType.payment:
        icon = Icons.payment_rounded;
        title = "Payment Successful";
        break;
      case TransactionType.topup:
        icon = Icons.add_card_rounded;
        title = "Top Up Successful";
        break;
      case TransactionType.withdrawal:
        icon = Icons.account_balance_rounded;
        title = "Withdrawal Processed";
        break;
      default:
        icon = Icons.notifications_active_rounded;
        title = "New Transaction";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isPositive ? Colors.greenAccent : Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    "${isPositive ? '+' : ''}${tx.amount.toStringAsFixed(1)} Stars • ${tx.note}", 
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.primaryGold, width: 0.5),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
