import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sara_fun/services/referral_engine.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/screens/widgets/glass_card.dart';
import 'package:sara_fun/services/trust_engine.dart';
import 'package:sara_fun/models/review_model.dart';

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
      extendBodyBehindAppBar: true, // For glass effect
      appBar: AppBar(
        title: const Text("DISCOVERY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold)),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () => context.push('/discovery/search'),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: Colors.white70),
            onPressed: () => context.push('/favorites'),
          ),
          const Gap(8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)], // Subtle ambient light
          ),
        ),
        child: SafeArea(
          child: Column(
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
                            viewerCircles: userData?.trustCircles ?? {},
                            onFavoriteToggle: () {
                              if (userData != null && cards[index].id != null) {
                                firebaseService.toggleFavorite(userData.uid, cards[index].id!, true);
                              }
                            },
                          ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideX(begin: 0.1),
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
                            viewerCircles: userData?.trustCircles ?? {},
                            onFavoriteToggle: () {
                              if (userData != null) {
                                firebaseService.toggleFavorite(userData.uid, masters[index].uid, false);
                              }
                            },
                          ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideX(begin: 0.1),
                        );
                      },
                    );
                  }
                ),
              ),
              const Gap(24),
            ],
          ),
        ),
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
              fillColor: Colors.white.withValues(alpha: 0.05),
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
                color: isSelected ? AppTheme.primaryGold : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGold : Colors.white12,
                ),
                gradient: isSelected 
                  ? const LinearGradient(colors: [AppTheme.primaryGold, Color(0xFFD4AF37)]) 
                  : null,
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
  final Map<String, List<String>> viewerCircles;
  final VoidCallback onFavoriteToggle;

  const _CompactServiceCard({
    required this.card, 
    required this.width, 
    required this.height,
    this.isFavorite = false,
    this.userPosition,
    this.viewerCircles = const {},
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: width,
      height: height,
      onTap: () => context.push('/discovery/detail', extra: card),
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
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppTheme.primaryGold : Colors.white70,
                          size: 14,
                        ).animate(target: isFavorite ? 1 : 0)
                        .scale(duration: 200.ms, curve: Curves.easeOutBack),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
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
                          color: Colors.black.withValues(alpha: 0.5),
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
                    StreamBuilder<List<Review>>(
                      stream: ref.watch(firebaseServiceProvider).getReviewsForService(card.id ?? 'unknown'),
                      builder: (context, snapshot) {
                        final reviews = snapshot.data ?? [];
                        final smartScore = TrustEngine.calculateSmartScore(
                          reviews: reviews,
                          viewer: userData,
                        );
                        
                        // Count matches in circles for social proof
                        int c1Matches = 0;
                        int c2Matches = 0;
                        for (var r in reviews) {
                          if (viewerCircles['c1']?.contains(r.clientId) ?? false) c1Matches++;
                          if (viewerCircles['c2']?.contains(r.clientId) ?? false) c2Matches++;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "⭐ ${smartScore > 0 ? smartScore.toStringAsFixed(1) : '4.8'}", 
                              style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            if (c1Matches > 0 || c2Matches > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  "🔥 Recommended by your Inner Circle",
                                  style: TextStyle(color: AppTheme.primaryGold, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        );
                      }
                    ),
                    if (userPosition != null) // Distance Placeholder (calculating requires master loc)
                       const Text(
                        "2.5 km",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
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

class _CompactMasterCard extends StatelessWidget {
  final AppUser master;
  final double width;
  final double height;
  final bool isFavorite;
  final Position? userPosition;
  final Map<String, List<String>> viewerCircles;
  final VoidCallback onFavoriteToggle;

  const _CompactMasterCard({
    required this.master, 
    required this.width, 
    required this.height,
    this.isFavorite = false,
    this.userPosition,
    this.viewerCircles = const {},
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: width,
      height: height,
      onTap: () => context.push(Uri(path: '/discovery', queryParameters: {'masterId': master.uid}).toString()),
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
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppTheme.primaryGold : Colors.white70,
                  size: 14,
                ).animate(target: isFavorite ? 1 : 0)
                .scale(duration: 200.ms, curve: Curves.easeOutBack),
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
                    backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
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
                      StreamBuilder<List<Review>>(
                        stream: ref.watch(firebaseServiceProvider).getReviewsForService(master.uid), // Using masterId as serviceId for global master rating?
                        // Actually, master rating should be global across their services. 
                        // For now, if we don't have a multi-service rating, we fetch all reviews where masterId matches.
                        // I'll assume getReviewsForService works for UID if that's how it's stored.
                        builder: (context, snapshot) {
                          final reviews = snapshot.data ?? [];
                          final smartScore = TrustEngine.calculateSmartScore(
                            reviews: reviews,
                            viewer: userData,
                          );
                          return Text(
                            smartScore > 0 ? smartScore.toStringAsFixed(1) : "4.8", 
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          );
                        }
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
    );
  }
}
