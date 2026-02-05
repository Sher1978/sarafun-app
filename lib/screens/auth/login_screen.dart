import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/service_card_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleDemoLogin(UserRole role) async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Authenticate Anonymously first to satisfy Firestore Rules
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final String uid = userCredential.user!.uid;

      final firebaseService = ref.read(firebaseServiceProvider);
      
      final int demoTgId = role == UserRole.master ? 999999 : 888888;
      
      // Create user object
      final user = AppUser(
        uid: uid,
        telegramId: demoTgId,
        role: role,
        balanceStars: role == UserRole.master ? 1000 : 500,
        depositBalance: role == UserRole.master ? 1000 : 0,
        isVip: role == UserRole.client, // Demo client is VIP
        isVisible: true,
      );

      // Save to Firestore
      await firebaseService.saveUser(user);

      // Create a demo service card for the master if it doesn't exist
      if (role == UserRole.master) {
          final demoService = ServiceCard(
              masterId: uid,
              title: "Luxury Car Rental",
              description: "Experience Dubai in a Lamborghini Huracan. Daily rentals available for VIP members.",
              priceStars: 2500,
              category: "Cars",
              mediaUrls: ["https://images.unsplash.com/photo-1544636331-e268592031c1?q=80&w=1000&auto=format&fit=crop"],
          );
          await firebaseService.createServiceCard(demoService);
      }
      
      // Update State (automatic via StreamProvider watching Auth & Firestore)
      
      // Router will redirect automatically based on auth state
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 80, color: AppTheme.primaryGold),
              const Gap(24),
              const Text(
                "Welcome to SaraFun",
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold
                ),
              ),
              const Gap(8),
              const Text(
                "The exclusive loyalty circle.",
                style: TextStyle(color: Colors.white70),
              ),
              const Gap(48),
              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.primaryGold)
              else ...[
                ElevatedButton.icon(
                  onPressed: () => _handleDemoLogin(UserRole.client),
                  icon: const Icon(Icons.person, color: Colors.black),
                  label: const Text("Demo Login: Client", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                const Gap(16),
                OutlinedButton.icon(
                  onPressed: () => _handleDemoLogin(UserRole.master),
                  icon: const Icon(Icons.business_center),
                  label: const Text("Demo Login: Master"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
