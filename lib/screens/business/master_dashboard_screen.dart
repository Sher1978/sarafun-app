import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/screens/business/master_location_picker.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/service_card_model.dart';
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
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BUSINESS PANEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppTheme.primaryGold),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, size: 20, color: Colors.white70),
            onPressed: () => _openLocationPicker(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCard(context, ref),
            _buildAnalyticsCards(context, ref),
            const Gap(32),
            _buildSectionHeader("BUSINESS TOOLS"),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
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
                _buildCompactToolButton(
                  context,
                  icon: Icons.contacts,
                  label: "LEADS",
                  onPressed: () => context.go('/business/leads'),
                ),
              ],
            ),
            const Gap(32),
            _buildSectionHeader("MY SERVICES"),
            const Gap(16),
            _buildServiceList(ref),
            const Gap(32),
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

  Widget _buildServiceList(WidgetRef ref) {
    final firebaseService = ref.read(firebaseServiceProvider);
    
    return StreamBuilder<List<ServiceCard>>(
      stream: firebaseService.getServiceCardsStream(master.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final cards = snapshot.data!;
        
        // 2x5 Grid = 10 slots fixed
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            if (index < cards.length) {
              return _buildServiceTile(context, ref, cards[index]);
            } else {
              return _buildEmptyServiceTile(context, ref);
            }
          },
        );
      },
    );
  }

  Widget _buildServiceTile(BuildContext context, WidgetRef ref, ServiceCard card) {
    return GestureDetector(
      onTap: () {
        // Edit Service
        // context.push('/business/service/${card.id}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit Service Coming Soon")));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          image: card.mediaUrls.isNotEmpty 
            ? DecorationImage(
                image: NetworkImage(card.mediaUrls.first), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
              )
            : null,
        ),
        child: Stack(
          children: [
            if (card.mediaUrls.isEmpty)
              const Center(child: Icon(Icons.spa, color: Colors.white24, size: 40)),
            
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    "${card.priceStars} Stars", 
                    style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
             Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(card.isActive ? Icons.circle : Icons.circle_outlined, size: 8, color: card.isActive ? Colors.green : Colors.grey),
                    const Gap(4),
                    Text(card.isActive ? "ON" : "OFF", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyServiceTile(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAddServiceDialog(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid), // Dashed would be better but solid is fine
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppTheme.primaryGold, size: 24),
            ),
            const Gap(12),
            Text(
              "Add Service",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref) {
    // 1. We need the services to calculate the threshold (Max Price * 0.2)
    final firebaseService = ref.read(firebaseServiceProvider);
    
    return StreamBuilder<List<ServiceCard>>(
      stream: firebaseService.getServiceCardsStream(master.uid),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        
        // Calculate Threshold
        double maxPrice = 0;
        if (cards.isNotEmpty) {
           maxPrice = cards
               .where((c) => c.isActive)
               .map((c) => c.priceStars.toDouble())
               .fold(0, (prev, curr) => curr > prev ? curr : prev);
        }
        final threshold = maxPrice * 0.2;
        final isLowBalance = master.depositBalance < threshold;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Dynamic Background
            gradient: isLowBalance 
              ? const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF300000)], // Deep Red Warning
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)], // Standard Dark Luxury
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLowBalance ? Colors.redAccent : AppTheme.primaryGold.withValues(alpha: 0.1),
              width: isLowBalance ? 1.5 : 1.0,
            ),
            boxShadow: isLowBalance 
              ? [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)]
              : [],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("DEPOSIT BALANCE", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  if (isLowBalance)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: const Text("OFFLINE", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
              const Gap(8),
              Text("${master.depositBalance} Stars", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const Gap(4),
               Text(
                "Threshold: ${threshold.toStringAsFixed(1)} Stars", 
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)
              ),
              const Gap(16),
              
              if (isLowBalance) ...[
                const Divider(color: Colors.white24),
                const Gap(8),
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    Gap(8),
                    Expanded(
                      child: Text(
                        "LOW BALANCE. SERVICES HIDDEN.",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Mock Top Up or Navigation
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Top Up feature coming soon via Telegram Payments!")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[900],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("TOP UP NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                 const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    Gap(6),
                    Text("active & visible", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }




  Widget _buildAnalyticsCards(BuildContext context, WidgetRef ref) {
    final firebaseService = ref.read(firebaseServiceProvider);
    
    return Column(
      children: [
        const Gap(32), // Spacing from Balance Card
        Row(
           children: [
             Expanded(
               child: StreamBuilder<int>(
                 stream: firebaseService.getProfileViews(master.uid),
                 builder: (context, snapshot) => _buildStatCard("PROFILE VIEWS", "${snapshot.data ?? 0}", Icons.visibility, Colors.purpleAccent),
               ),
             ),
             const Gap(12),
             Expanded(
               child: StreamBuilder<int>(
                 stream: firebaseService.getLeadsCount(master.uid),
                 builder: (context, snapshot) => _buildStatCard("TOTAL LEADS", "${snapshot.data ?? 0}", Icons.person_add, Colors.blueAccent),
               ),
             ),
           ],
        ),
        const Gap(12),
        Row(
           children: [
             Expanded(
               child: _buildStatCard("CONVERSION RATE", "0.0%", Icons.trending_up, Colors.greenAccent), // TODO: Calculate
             ),
             const Gap(12),
             Expanded(
               child: StreamBuilder<num>(
                 stream: firebaseService.getMonthlyEarnings(master.uid),
                 builder: (context, snapshot) => _buildStatCard("MONTHLY EARNINGS", "${snapshot.data?.toStringAsFixed(0) ?? 0} Stars", Icons.monetization_on, AppTheme.primaryGold),
               ),
             ),
           ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(4),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
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
            child: Text("Cancel", style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
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
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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


