import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/deal_model.dart';
import 'package:sara_fun/services/referral_engine.dart';

class ConfirmDealScreen extends ConsumerStatefulWidget {
  final String serviceTitle;
  final String serviceId;
  final String masterName;
  final String masterId;
  final int amountStars;

  const ConfirmDealScreen({
    super.key,
    required this.serviceTitle,
    required this.serviceId,
    required this.masterName,
    required this.masterId,
    required this.amountStars,
  });

  @override
  ConsumerState<ConfirmDealScreen> createState() => _ConfirmDealScreenState();
}

class _ConfirmDealScreenState extends ConsumerState<ConfirmDealScreen> {
  int _rating = 0;
  bool _isProcessing = false;

  void _onRatingSelected(int rating) {
    setState(() => _rating = rating);
  }

  Future<void> _handlePayment() async {
    if (_rating == 0) return;

    setState(() => _isProcessing = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final client = ref.read(currentUserProvider).value!;
      
      // Fetch Master profile to get referral data (businessAgents)
      final master = await firebaseService.getUser(widget.masterId);
      if (master == null) throw "Master profile not found";

      // 0. Check for Deep Link Recommender
      String? businessRecommenderOverride;
      final deepLinkData = ref.read(deepLinkDataProvider);
      if (deepLinkData != null && deepLinkData.masterId == widget.masterId) {
        businessRecommenderOverride = deepLinkData.referrerId;
      }

      // 1. Calculate Distribution
      final distribution = ReferralEngine.calculateDistribution(
        widget.amountStars, 
        client, 
        master,
        businessRecommenderIdOverride: businessRecommenderOverride,
      );

      // 2. Create Deal Object (status completed because it's confirmed now)
      final deal = Deal(
        id: "deal_${DateTime.now().millisecondsSinceEpoch}",
        clientId: client.uid,
        masterId: widget.masterId,
        serviceId: widget.serviceId,
        amountStars: widget.amountStars,
        commissionDistribution: distribution.toMap(),
        rating: _rating,
        status: DealStatus.completed,
        createdAt: DateTime.now(),
      );

      // 3. Process Atomic Transaction
      await firebaseService.processDealTransaction(deal, distribution, client, master);

      if (mounted) {
        _showSuccessAnimation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Failed: $e"), backgroundColor: AppTheme.errorRed),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.primaryGold, size: 100)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .then()
                  .shake(duration: 400.ms),
              const Gap(24),
              const Text(
                "Payment Successful!",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Gap(32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/discovery'); // Go home/discovery
                },
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text("Confirm Payment"),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              children: [
                _buildGlassCard(),
                const Spacer(),
                _buildConfirmButton(),
                const Gap(40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              const Icon(Icons.stars_rounded, color: AppTheme.primaryGold, size: 48),
              const Gap(16),
              const Text(
                "PAYMENT DETAILS",
                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
              const Gap(24),
              _buildDetailRow("Service", widget.serviceTitle),
              const Gap(16),
              _buildDetailRow("Partner", widget.masterName),
              const Divider(color: Colors.white12, height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(
                    "${widget.amountStars} Stars",
                    style: const TextStyle(color: AppTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Gap(40),
              const Text(
                "RATE YOUR EXPERIENCE",
                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
              const Gap(16),
              _buildStarRating(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          onPressed: () => _onRatingSelected(starIndex),
          icon: Icon(
            starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppTheme.primaryGold,
            size: 40,
          ),
        );
      }),
    );
  }

  Widget _buildConfirmButton() {
    final bool isEnabled = _rating > 0 && !_isProcessing;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: isEnabled ? [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? _handlePayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppTheme.primaryGold : Colors.white10,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isProcessing 
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(
              "Confirm & Pay",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: isEnabled ? Colors.black : Colors.white24,
              ),
            ),
      ),
    );
  }
}
