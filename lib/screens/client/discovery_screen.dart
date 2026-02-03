import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sara_fun/services/referral_engine.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/models/user_model.dart';
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
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

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
        title: const Text("Discovery", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: AppTheme.primaryGold),
            onPressed: () => context.push('/favorites'),
          ),
          const Gap(8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilter(),
          
          // Services Section
          _buildSectionHeader("GLOBAL SERVICES"),
          Expanded(
            flex: 35, // 35% of remaining height
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardHeight = constraints.maxHeight - 20;
                final cardWidth = cardHeight * 0.72;
                
                return StreamBuilder<List<ServiceCard>>(
                  stream: firebaseService.getAllServiceCardsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                    final cards = snapshot.data!.where((card) {
                      final matchesSearch = card.title.toLowerCase().contains(_searchQuery) ||
                                          card.description.toLowerCase().contains(_searchQuery);
                      final matchesCategory = _selectedCategory == "All" || card.category == _selectedCategory;
                      final matchesMaster = widget.filterMasterId == null || card.masterId == widget.filterMasterId;
                      return matchesSearch && matchesCategory && matchesMaster;
                    }).toList();

                    if (cards.isEmpty) return const Center(child: Text("No services", style: TextStyle(color: Colors.white24)));

                    final userData = ref.watch(currentUserProvider).asData?.value;

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (context, index) => _CompactServiceCard(
                        card: cards[index],
                        width: cardWidth,
                        height: cardHeight,
                        isFavorite: userData?.favoriteServices.contains(cards[index].id) ?? false,
                        userPosition: _currentPosition,
                        onFavoriteToggle: () {
                          if (userData != null && cards[index].id != null) {
                            firebaseService.toggleFavorite(userData.uid, cards[index].id!, true);
                          }
                        },
                      ),
                    );
                  },
                );
              }
            ),
          ),

          const Gap(24),

          // Masters Section
          _buildSectionHeader("ELITE MASTERS"),
          Expanded(
            flex: 25, // 25% of remaining height
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardHeight = constraints.maxHeight - 20;
                final cardWidth = cardHeight * 0.75;

                return StreamBuilder<List<AppUser>>(
                  stream: firebaseService.getDiscoveryMastersStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                    final masters = snapshot.data!;
                    final userData = ref.watch(currentUserProvider).asData?.value;
                    
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: masters.length,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (context, index) => _CompactMasterCard(
                        master: masters[index],
                        width: cardWidth,
                        height: cardHeight,
                        isFavorite: userData?.favoriteMasters.contains(masters[index].uid) ?? false,
                        userPosition: _currentPosition,
                        onFavoriteToggle: () {
                          if (userData != null) {
                            firebaseService.toggleFavorite(userData.uid, masters[index].uid, false);
                          }
                        },
                      ),
                    );
                  },
                );
              }
            ),
          ),
          const Gap(24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryGold,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search services...",
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const Gap(16),
          _buildCategorySlider(),
        ],
      ),
    );
  }

  Widget _buildCategorySlider() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGold : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGold : Colors.white12,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompactServiceCard extends StatelessWidget {
  final ServiceCard card;
  final double width;
  final double height;
  final bool isFavorite;
  final Position? userPosition;

  const _CompactServiceCard({
    required this.card, 
    required this.width, 
    required this.height,
    this.isFavorite = false,
    this.userPosition,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => context.push('/discovery/detail', extra: card),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: height * 0.45,
                width: double.infinity,
                child: Stack(
                  children: [
                    if (card.mediaUrls.isNotEmpty)
                      PageView.builder(
                        itemCount: card.mediaUrls.length,
                        itemBuilder: (context, index) => Image.network(
                          card.mediaUrls[index], 
                          fit: BoxFit.cover, 
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.image_not_supported, color: Colors.white24)),
                        ),
                      )
                    else
                      const Center(child: Icon(Icons.spa, size: 30, color: Colors.white24)),
                    
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppTheme.primaryGold,
                            size: 14,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          card.category,
                          style: const TextStyle(color: AppTheme.primaryGold, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () {
                           final link = ReferralEngine.generateDeepLink(serviceId: card.id);
                           Clipboard.setData(ClipboardData(text: link));
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service link copied!")));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.link, color: AppTheme.primaryGold, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    card.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "⭐ 4.8", // Hardcoded per requirements if not in model
                        style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      if (userPosition != null) // Distance Placeholder (calculating requires master loc)
                         Text(
                          "2.5 km",
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMasterCard extends StatelessWidget {
  final AppUser master;
  final double width;
  final double height;
  final bool isFavorite;
  final Position? userPosition;

  const _CompactMasterCard({
    required this.master, 
    required this.width, 
    required this.height,
    this.isFavorite = false,
    this.userPosition,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => context.push(Uri(path: '/discovery', queryParameters: {'masterId': master.uid}).toString()),
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavoriteToggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : AppTheme.primaryGold,
                    size: 14,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppTheme.primaryGold, size: 28),
                    ),
                    const Gap(8),
                    Text(
                      master.displayName ?? "Elite Partner",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: AppTheme.primaryGold, size: 12),
                        const Gap(4),
                        Text(
                          master.rating > 0 ? master.rating.toStringAsFixed(1) : "4.8", 
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        if (userPosition != null && master.latitude != null && master.longitude != null) ...[
                          const Gap(6),
                          Builder(builder: (context) {
                            final dist = Geolocator.distanceBetween(
                              userPosition!.latitude, 
                              userPosition!.longitude, 
                              master.latitude!, 
                              master.longitude!
                            ) / 1000;
                            return Text(
                                "${dist.toStringAsFixed(1)} km",
                                style: const TextStyle(color: AppTheme.primaryGold, fontSize: 10),
                            );
                          }),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
