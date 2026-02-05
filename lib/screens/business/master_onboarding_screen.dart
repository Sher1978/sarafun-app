import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';

class BecomeMasterOnboardingScreen extends ConsumerStatefulWidget {
  const BecomeMasterOnboardingScreen({super.key});

  @override
  ConsumerState<BecomeMasterOnboardingScreen> createState() => _BecomeMasterOnboardingScreenState();
}

class _BecomeMasterOnboardingScreenState extends ConsumerState<BecomeMasterOnboardingScreen> {
  bool _isLoading = false;

  Future<void> _activateMaster() async {
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider).asData?.value;
      if (user == null) return;

      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.upgradeToMaster(user.uid);
      
      // Refresh local state (automatic via StreamProvider)
      
      if (mounted) {
        context.go('/business');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGold.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(40),
                  const Icon(Icons.stars_rounded, color: AppTheme.primaryGold, size: 48)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(delay: 200.ms),
                  const Gap(24),
                  const Text(
                    "PARTNER\nPROGRAM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1, end: 0),
                  const Gap(16),
                  const Text(
                    "Monetize your influence. Join the global elite network of SaraFun partners.",
                    style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const Spacer(),
                  
                  _buildBenefitItem(
                    Icons.account_tree_outlined,
                    "Multi-level Rewards",
                    "Earn from recommendations across 3 levels of your network.",
                  ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),
                  
                  const Gap(24),
                  
                  _buildBenefitItem(
                    Icons.public_rounded,
                    "Global Exposure",
                    "List your business on the worldwide map and attract international clients.",
                  ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1, end: 0),
                  
                  const Gap(24),
                  
                  _buildBenefitItem(
                    Icons.analytics_outlined,
                    "Business Insights",
                    "Track your earnings with detailed monthly analytics and transaction logs.",
                  ).animate(delay: 900.ms).fadeIn().slideY(begin: 0.1, end: 0),
                  
                  const Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _activateMaster,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "ACTIVATE MASTER STATUS",
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                    ),
                  ).animate(delay: 1100.ms).fadeIn().scale(),
                  const Gap(40),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryGold, size: 24),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(4),
              Text(
                description,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
