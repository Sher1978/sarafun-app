import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/services/firebase_service.dart';
import 'package:gap/gap.dart';

class ClientHomeScreen extends ConsumerWidget {
  final AppUser user;

  const ClientHomeScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SaraFun Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/client/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(context),
            const Gap(32),
            OutlinedButton.icon(
              onPressed: () => context.go('/client/history'),
              icon: const Icon(Icons.history),
              label: const Text("View Transaction History"),
            ),
            const Gap(12),
             ElevatedButton.icon(
              onPressed: () => context.go('/client/discovery'),
              icon: const Icon(Icons.search, color: Colors.black),
              label: const Text("Find Services", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
              ),
            ),
            const Gap(12),
            OutlinedButton.icon(
              onPressed: () => context.push('/client/map'),
              icon: const Icon(Icons.map_outlined, color: AppTheme.primaryGold),
              label: const Text("Explore Partners on Map", style: TextStyle(color: AppTheme.primaryGold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGold),
              ),
            ),
            const Gap(40),
            // Master Onboarding Promotion
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    "WANT TO EARN AS A PARTNER?",
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(12),
                  const Text(
                    "Join our worldwide elite network and start profiting from recommendations globally.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const Gap(20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/master-onboarding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("LAUNCH MY BUSINESS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchRole(WidgetRef ref) async {
    final firebaseService = ref.read(firebaseServiceProvider);
    
    // Switch to master role
    final updatedUser = user.copyWith(role: UserRole.master);
    await firebaseService.saveUser(updatedUser);
    
    // Update provider to trigger UI update / redirect
    ref.read(currentUserProvider.notifier).state = AsyncValue.data(updatedUser);
  }

  Widget _buildStatusCard(BuildContext context) {
    final bool isVip = user.isVip;
    final color = isVip ? AppTheme.primaryGold : Colors.white;
    final statusText = isVip ? "VIP Client" : "Base Client";
    final cashbackText = isVip ? "10% Cashback" : "5% Cashback";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(statusText,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const Gap(8),
          Text("${user.dealCountMonthly}/10 deals this month"),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(cashbackText, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: QrImageView(
        data: user.uid,
        version: QrVersions.auto,
        size: 250.0,
        backgroundColor: Colors.white,
      ),
    );
  }
}
