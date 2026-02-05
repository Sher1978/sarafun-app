import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/services/referral_engine.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {
              context.push('/settings');
            },
          ),
          const Gap(8),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("User not found"));
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Gap(40),
                _buildQrSection(user),
                const Gap(40),
                _buildActionButton(context, user),
                const Gap(40),
                _buildInfoSection(context, user),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildQrSection(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: QrImageView(
        data: user.uid,
        version: QrVersions.auto,
        size: 200.0,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppUser user) {
    final isMaster = user.role == UserRole.master;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
              onPressed: () async {
              if (isMaster) {
                context.go('/business');
              } else {
                context.push('/master-onboarding');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
            ),
            child: Text(
              isMaster ? 'OPEN DASHBOARD' : 'LAUNCH MY BUSINESS',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ),
        const Gap(16),
        // Persistent Scanner Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (isMaster) {
                context.push('/scanner');
              } else {
                 context.push('/master-onboarding'); // Logic: Client scanner leads to business info
              }
            },
            icon: Icon(Icons.qr_code_scanner, color: isMaster ? AppTheme.primaryGold : Colors.white70),
            label: Text(
              isMaster ? 'SCAN CLIENT QR' : 'BECOME A MASTER',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                letterSpacing: 1,
                color: isMaster ? AppTheme.primaryGold : Colors.white70,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isMaster ? Colors.black : Colors.grey[800],
              side: isMaster ? BorderSide(color: AppTheme.primaryGold.withOpacity(0.5)) : BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, AppUser user) {
    return Column(
      children: [
        _buildInfoRow("Telegram ID", user.telegramId.toString()),
        const Gap(16),
        _buildInfoRow(
          "Referral Link", 
          "COPY LINK", 
          isGold: true, 
          icon: Icons.link,
          onTap: () {
            final link = ReferralEngine.generateDeepLink(referrerId: user.uid);
            Clipboard.setData(ClipboardData(text: link));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard!")));
          }
        ),
        const Gap(16),
        _buildInfoRow("Role", user.role.name.toUpperCase()),
        const Gap(16),
        _buildInfoRow("Balance", "${user.balanceStars} Stars", isGold: true),
        const Gap(16),
        _buildInfoRow(
          "My Wallet", 
          "OPEN", 
          icon: Icons.account_balance_wallet_outlined, 
          onTap: () => context.push('/wallet')
        ),
        const Gap(16),
        _buildInfoRow(
          "Settings", 
          "OPEN", 
          icon: Icons.settings_outlined, 
          onTap: () => context.push('/settings')
        ),
        if (user.role == UserRole.master) ...[
          const Gap(16),
          _buildInfoRow(
            "Business Dashboard", 
            "MANAGE", 
            icon: Icons.business_center_outlined, 
            onTap: () => context.go('/business')
          ),
        ],
        if (user.role == UserRole.admin) ...[
          const Gap(16),
          _buildInfoRow(
            "Admin Panel", 
            "MANAGE", 
            icon: Icons.admin_panel_settings_outlined, 
            onTap: () => context.push('/admin')
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isGold = false, IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isGold && onTap != null ? AppTheme.primaryGold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: isGold ? AppTheme.primaryGold : Colors.white60, size: 18),
                  const Gap(12),
                ],
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: isGold ? AppTheme.primaryGold : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
