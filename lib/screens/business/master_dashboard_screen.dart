import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/screens/business/master_location_picker.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/services/firebase_service.dart';
import 'package:sara_fun/core/providers.dart';

class MasterDashboardScreen extends ConsumerWidget {
  final AppUser master;

  const MasterDashboardScreen({super.key, required this.master});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceStream = ref.watch(firebaseServiceProvider).getServiceCardsStream(master.uid);

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'PARTNER DASHBOARD',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: AppTheme.deepBlack.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const Gap(100),
            _buildTopCard(context),
            _buildLowBalanceAlert(master.depositBalance.toInt()),
            _buildStatsSection(master),
            _buildActionButtons(context),
            const Gap(32),
            _buildLocationSection(context, ref),
            const Gap(32),
            _buildServiceGridSection(context, serviceStream, ref),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFE14D),
              Color(0xFFB8860B),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OPERATING DEPOSIT',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const Gap(16),
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.black, size: 32),
                const Gap(12),
                Text(
                  '${master.depositBalance}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/scanner'),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('SCAN QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {}, // Add deposit logic here
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('TOP UP'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGold,
                side: const BorderSide(color: AppTheme.primaryGold),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowBalanceAlert(int balance) {
    final bool isLow = balance < 1000;
    if (!isLow) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 20),
            const Gap(12),
            const Expanded(
              child: Text(
                'Low Balance Alert: Top up to stay visible',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .custom(
         duration: 1500.ms,
         builder: (context, value, child) => Container(
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(12),
             boxShadow: [
               BoxShadow(
                 color: AppTheme.errorRed.withOpacity(0.15 * value),
                 blurRadius: 10 * value,
                 spreadRadius: 2 * value,
               ),
             ],
           ),
           child: child,
         ),
       ),
    );
  }

  Widget _buildStatsSection(AppUser master) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'MONTHLY DEALS',
              '${master.dealCountMonthly}',
              Icons.trending_up_rounded,
            ),
          ),
          const Gap(16),
          Expanded(
            child: _buildStatCard(
              'CURRENT STATUS',
              master.isVip ? 'VIP' : 'Standard',
              master.isVip ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 20),
          const Gap(12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppTheme.primaryGold, size: 24),
                Gap(12),
                Text(
                  'BUSINESS LOCATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show on Map',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Gap(4),
                    Text(
                      'Allow clients to find you',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: master.isMapVisible,
                  activeColor: AppTheme.primaryGold,
                  onChanged: (value) async {
                    await ref.read(firebaseServiceProvider).updateUserLocation(
                      master.uid,
                      isMapVisible: value,
                      lat: value ? master.latitude : null,
                      lng: value ? master.longitude : null,
                    );
                    // Update current user state in provider to reflect change immediately
                    final updatedUser = master.copyWith(
                      isMapVisible: value,
                      latitude: value ? master.latitude : null,
                      longitude: value ? master.longitude : null,
                    );
                    ref.read(currentUserProvider.notifier).state = AsyncValue.data(updatedUser);
                  },
                ),
              ],
            ),
            if (master.isMapVisible) ...[
              const Gap(24),
              const Divider(color: Colors.white10),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Coordinates',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const Gap(4),
                        Text(
                          master.latitude != null 
                            ? '${master.latitude!.toStringAsFixed(4)}, ${master.longitude!.toStringAsFixed(4)}'
                            : 'Location not set',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openLocationPicker(context, ref),
                    icon: const Icon(Icons.edit_location_alt_rounded, color: AppTheme.primaryGold),
                    label: const Text(
                      'Change',
                      style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openLocationPicker(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MasterLocationPicker(
          initialLocation: master.latitude != null 
            ? LatLng(master.latitude!, master.longitude!)
            : const LatLng(25.2048, 55.2708), // Default to Dubai
          onLocationPicked: (LatLng location) async {
            await ref.read(firebaseServiceProvider).updateUserLocation(
              master.uid,
              lat: location.latitude,
              lng: location.longitude,
              isMapVisible: true,
            );
            final updatedUser = master.copyWith(
              latitude: location.latitude,
              longitude: location.longitude,
              isMapVisible: true,
            );
            ref.read(currentUserProvider.notifier).state = AsyncValue.data(updatedUser);
          },
        ),
      ),
    );
  }

  Widget _buildServiceGridSection(BuildContext context, Stream<List<ServiceCard>> stream, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'YOUR SERVICES',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Gap(16),
        StreamBuilder<List<ServiceCard>>(
          stream: stream,
          builder: (context, snapshot) {
            final List<ServiceCard> services = snapshot.data ?? [];
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: 10, // Fixed to 10 slots
              itemBuilder: (context, index) {
                if (index < services.length) {
                  return _buildServiceItem(services[index]);
                } else {
                  return _buildAddServiceSlot(context, ref);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceItem(ServiceCard service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.circle, color: Color(0xFF34C759), size: 8),
              Text(
                '${service.priceStars} Stars',
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            service.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Gap(4),
          Text(
            service.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddServiceSlot(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAddServiceDialog(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            style: BorderStyle.none, // Can use custom painter for dashed border
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: _DashedBorderPainter(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: Colors.white.withOpacity(0.3), size: 24),
                const Gap(8),
                Text(
                  'Add Service',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddServiceDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Create New Service", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Service Title"),
            ),
            const Gap(12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Description"),
            ),
            const Gap(12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Price (Stars)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              final price = int.tryParse(priceController.text);
              if (titleController.text.isEmpty || price == null) return;

              final newCard = ServiceCard(
                masterId: master.uid,
                title: titleController.text,
                description: descController.text,
                priceStars: price,
              );
              
              ref.read(firebaseServiceProvider).createServiceCard(newCard);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Create"),
          ),
          const Gap(8),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ));

    var pathMetric = path.computeMetrics().first;
    double dashWidth = 8.0;
    double dashSpace = 6.0;
    double distance = 0.0;

    while (distance < pathMetric.length) {
      canvas.drawPath(
        pathMetric.extractPath(distance, distance + dashWidth),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
