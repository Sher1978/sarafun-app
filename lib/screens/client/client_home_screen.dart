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
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text('SHERLOCK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(context),
            const Gap(32),
            const Text(
              "OUR ECOSYSTEM",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const Gap(16),
            _buildBusinessCard(
              context,
              title: "SARAFUN",
              subtitle: "Global Services & Elite Masters",
              icon: Icons.spa_outlined,
              imagePath: "assets/images/sarafun_bg.jpg", // Placeholder logic
              gradient: const LinearGradient(
                colors: [Color(0xFF333333), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => context.go('/home/discovery'),
              isPrimary: true,
            ),
            const Gap(16),
            _buildBusinessCard(
              context,
              title: "SHERLOCK CARS",
              subtitle: "Premium Car Rental & Leasing",
              icon: Icons.directions_car_filled_outlined,
              gradient: LinearGradient(
                colors: [const Color(0xFF1E2a38), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => _showComingSoon(context),
            ),
            const Gap(16),
            _buildBusinessCard(
              context,
              title: "AUTO-SERVICE",
              subtitle: "On-Demand Mechanics & Tyres",
              icon: Icons.build_circle_outlined,
              gradient: LinearGradient(
                colors: [const Color(0xFF2d241c), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => _showComingSoon(context),
            ),
            const Gap(40),
            // _buildQrCode(context), // Moved to Profile
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    String? imagePath,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPrimary ? AppTheme.primaryGold.withOpacity(0.3) : Colors.white.withOpacity(0.05),
            width: isPrimary ? 1.5 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Background Pattern/Icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 120,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPrimary ? AppTheme.primaryGold : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isPrimary ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      color: isPrimary ? AppTheme.primaryGold : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isPrimary)
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "LIVE",
                    style: TextStyle(color: AppTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.cardColor,
        content: const Text("Coming Soon to Dubai", style: TextStyle(color: Colors.white)),
        action: SnackBarAction(label: "Dismiss", onPressed: () {}, textColor: AppTheme.primaryGold),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final bool isVip = user.isVip;
    final color = isVip ? AppTheme.primaryGold : Colors.white;
    final statusText = isVip ? "VIP MEMBER" : "BASE MEMBER";
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WELCOME BACK,",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const Gap(4),
                Text(
                  user.displayName?.toUpperCase() ?? "SHER",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${user.balanceStars}",
                style: TextStyle(color: AppTheme.primaryGold, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Inter'),
              ),
              const Text(
                "STARS",
                style: TextStyle(color: AppTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
