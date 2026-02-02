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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BUSINESS PANEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, size: 20),
            onPressed: () => _openLocationPicker(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCard(context),
            const Gap(32),
            _buildSectionHeader("MY SERVICES"),
            const Gap(16),
            _buildServiceList(ref),
            const Gap(32),
            _buildSectionHeader("BUSINESS TOOLS"),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCompactToolButton(
                  context,
                  icon: Icons.qr_code_scanner,
                  label: "SCANNER",
                  onPressed: () => context.push('/scanner'),
                ),
                _buildCompactToolButton(
                  context,
                  icon: Icons.add_circle_outline,
                  label: "NEW SERVICE",
                  onPressed: () => _showAddServiceDialog(context, ref),
                ),
                _buildCompactToolButton(
                  context,
                  icon: Icons.history,
                  label: "HISTORY",
                  onPressed: () => context.push('/business/history'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primaryGold,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildCompactToolButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text("DEPOSIT BALANCE", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const Gap(8),
          Text("${master.depositBalance} Stars", style: const TextStyle(color: AppTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.w900)),
          const Gap(16),
          const Text("Status: Active & Visible", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildServiceList(WidgetRef ref) {
    final firebaseService = ref.read(firebaseServiceProvider);
    return StreamBuilder<List<ServiceCard>>(
      stream: firebaseService.getServiceCardsStream(master.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final cards = snapshot.data!;

        if (cards.isEmpty) {
          return const Center(child: Text("No services created yet.", style: TextStyle(color: Colors.white24)));
        }

        return SizedBox(
          height: AppTheme.compactCardHeight + 10,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Gap(16),
            itemBuilder: (context, index) {
              return _CompactMasterServiceCard(card: cards[index]);
            },
          ),
        );
      },
    );
  }
}

class _CompactMasterServiceCard extends StatelessWidget {
  final ServiceCard card;
  const _CompactMasterServiceCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppTheme.compactCardWidth,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: AppTheme.compactImageHeight,
              width: double.infinity,
              child: card.mediaUrls.isNotEmpty
                  ? Image.network(card.mediaUrls.first, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.spa, color: Colors.white24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900), maxLines: 1),
                const Gap(4),
                Text("${card.priceStars} Stars", style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                const Gap(8),
                Row(
                  children: [
                    Icon(card.isActive ? Icons.visibility : Icons.visibility_off, size: 12, color: card.isActive ? Colors.green : Colors.red),
                    const Gap(4),
                    Text(card.isActive ? "ACTIVE" : "HIDDEN", style: TextStyle(fontSize: 9, color: card.isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
