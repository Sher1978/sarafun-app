import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Smart Consumption",
      description: "Experience the next level of luxury shopping with instant star cashback on every transaction.",
      icon: Icons.auto_awesome_rounded,
    ),
    OnboardingData(
      title: "Social Wealth",
      description: "Grow your assets through our exclusive multi-level referral system. Your network is your net worth.",
      icon: Icons.hub_rounded,
    ),
    OnboardingData(
      title: "Elite Dubai Network",
      description: "Join the most prestigious business circle in Dubai. Connect with masters and elite clients.",
      icon: Icons.location_city_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Future<void> _completeOnboarding() async {
    // 1. Update SharedPreferences (Legacy/Local Cache)
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_complete', true);

    // 2. Update Firestore (Source of Truth)
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.asData?.value;
    if (user != null) {
      final updatedUser = user.copyWith(onboardingComplete: true);
      await ref.read(firebaseServiceProvider).saveUser(updatedUser);
    }
    
    if (mounted) {
      context.go('/discovery');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return OnboardingPage(data: _pages[index]);
                    },
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text(
                "Skip",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isLastPage = _currentPage == _pages.length - 1;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
      child: Column(
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: const ExpandingDotsEffect(
              activeDotColor: AppTheme.primaryGold,
              dotColor: Colors.white10,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 4,
              spacing: 8,
            ),
          ),
          const Gap(40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                if (isLastPage) {
                  _completeOnboarding();
                } else {
                  _pageController.nextPage(
                    duration: 600.ms,
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isLastPage ? "Start Your Journey" : "Next",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Image Section with Parallax-like animation
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGold.withValues(alpha: 0.05),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
            ),
            child: Icon(
              data.icon,
              size: 100,
              color: AppTheme.primaryGold,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut)
           .shimmer(duration: 3.seconds, color: Colors.white30),
          
          const Gap(60),
          
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
          
          const Gap(24),
          
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white54,
              height: 1.6,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
