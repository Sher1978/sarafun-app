import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/screens/client/service_detail_screen.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  final String? filterMasterId;
  const DiscoveryScreen({super.key, this.filterMasterId});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "All";
  final List<String> _categories = ["All", "Cars", "Health", "Dance"];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = ref.watch(firebaseServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text("Discovery", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildCategorySlider(),
          Expanded(
            child: StreamBuilder<List<ServiceCard>>(
              stream: firebaseService.getAllServiceCardsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white54)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                }

                final allCards = snapshot.data!;
                final filteredCards = allCards.where((card) {
                  final matchesSearch = card.title.toLowerCase().contains(_searchQuery) ||
                                      card.description.toLowerCase().contains(_searchQuery);
                  final matchesCategory = _selectedCategory == "All" || card.category == _selectedCategory;
                  final matchesMaster = widget.filterMasterId == null || card.masterId == widget.filterMasterId;
                  return matchesSearch && matchesCategory && matchesMaster;
                }).toList();

                if (filteredCards.isEmpty) {
                  return const Center(child: Text("No services found in this category.", style: TextStyle(color: Colors.white54)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: filteredCards.length,
                  separatorBuilder: (_, __) => const Gap(24),
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    return _ServiceCardItem(card: card);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search services...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCategorySlider() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Gap(12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGold : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGold : Colors.white12,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCardItem extends StatelessWidget {
  final ServiceCard card;
  const _ServiceCardItem({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  (card.mediaUrls.isNotEmpty)
                      ? Image.network(card.mediaUrls.first, fit: BoxFit.cover, width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.image_not_supported, color: Colors.white24)))
                      : const Center(child: Icon(Icons.spa, size: 50, color: Colors.white24)),
                  // Category Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                      ),
                      child: Text(
                        card.category,
                        style: const TextStyle(color: AppTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        card.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.star_rounded, color: AppTheme.primaryGold, size: 16),
                          Gap(4),
                          Text("4.9", style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  card.description,
                  style: const TextStyle(color: Colors.white54, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Price", style: TextStyle(color: Colors.white24, fontSize: 12)),
                        Text("${card.priceStars} Stars", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/confirm-deal', extra: {
                          'serviceTitle': card.title,
                          'serviceId': card.id ?? '',
                          'masterName': "Partner", // Will be fetched in ConfirmDealScreen
                          'masterId': card.masterId,
                          'amountStars': card.priceStars,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("View Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
