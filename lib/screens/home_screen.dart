import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Theme(
      data: AppTheme.darkLuxury,
      child: Scaffold(
        backgroundColor: AppTheme.deepBlack,
        body: SafeArea(
          child: userAsync.when(
            data: (user) => _buildContent(context, user),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: AppTheme.errorRed),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppUser? user) {
    final String userId = user?.uid ?? 'unknown';
    final num stars = user?.balanceStars ?? 0;

    return Column(
      children: [
        const Gap(60),
        // Header / Greeting (Optional but adds to luxury feel)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SaraFun',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
              const Gap(4),
              Text(
                'Exclusive Loyalty Club',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // QR Code Section
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: QrImageView(
              data: userId,
              version: QrVersions.auto,
              size: 220.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutBack)
                .scale(begin: const Offset(0.9, 0.9), duration: 800.ms),
        ),
        const Spacer(),
        // Gold Balance Card
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFE14D), // Lighter Gold
                  Color(0xFFB8860B), // Darker Gold for depth
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'STARS BALANCE',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Gap(8),
                Text(
                  '$stars',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Your status: ${user?.isVip == true ? "VIP Elite" : "Base Member"}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 400.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
        ),
        const Gap(20),
      ],
    );
  }
}
