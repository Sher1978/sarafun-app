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
        title: const Text('SARAFUN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 20),
            onPressed: () => context.go('/client/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(context),
            const Gap(24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/discovery'),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text("SERVICES"),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/map'),
                    icon: const Icon(Icons.map_outlined, size: 18, color: AppTheme.primaryGold),
                    label: const Text("MAP", style: TextStyle(color: AppTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.w900)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGold),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(40),
            Center(
              child: _buildQrCode(context),
            ),
            const Gap(24),
            const Text(
              'SHOW QR TO COLLECT REWARDS',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const Gap(40),
            // Master Onboarding Promotion
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Text(
                    "WANT TO EARN AS A PARTNER?",
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(8),
                  const Text(
                    "Join our worldwide elite network and start profiting globally.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/master-onboarding'),
                      child: const Text("LAUNCH MY BUSINESS"),
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
    final statusText = isVip ? "VIP CLIENT" : "BASE CLIENT";
    final cashbackText = isVip ? "10% Cashback" : "5% Cashback";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(statusText,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Gap(4),
          Text("${user.dealCountMonthly}/10 deals this month", style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Gap(16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(cashbackText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: QrImageView(
        data: user.uid,
        version: QrVersions.auto,
        size: 180.0,
        backgroundColor: Colors.white,
      ),
    );
  }
}
