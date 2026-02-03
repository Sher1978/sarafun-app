import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/screens/client/discovery_screen.dart'; // Reuse components if possible, or create common ones

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final firebaseService = ref.watch(firebaseServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text("FAVORITES", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: Colors.white30,
          tabs: const [
            Tab(text: "SERVICES"),
            Tab(text: "MASTERS"),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Please login"));

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFavoriteServices(user, firebaseService),
              _buildFavoriteMasters(user, firebaseService),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildFavoriteServices(AppUser user, dynamic firebaseService) {
    return StreamBuilder<List<ServiceCard>>(
      stream: firebaseService.getAllServiceCardsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final favoriteCards = snapshot.data!
            .where((card) => user.favoriteServices.contains(card.id))
            .toList();

        if (favoriteCards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.white.withOpacity(0.1)),
                const Gap(16),
                const Text("No favorite services saved", style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: favoriteCards.length,
          itemBuilder: (context, index) {
            final card = favoriteCards[index];
            return // Note: Re-using _CompactServiceCard from discovery_screen but would need it to be public
                // For now, I'll recommend making it public or duplicating/extracting it.
                // I'll assume for simplicity I'll extract it to a common file if needed, 
                // but for now I'll just use a simplified version or the one in discovery if I export it.
                _FavoriteGridItem(
                  title: card.title,
                  imageUrl: card.mediaUrls.isNotEmpty ? card.mediaUrls.first : null,
                  onTap: () => context.push('/discovery/detail', extra: card),
                  isService: true,
                );
          },
        );
      },
    );
  }

  Widget _buildFavoriteMasters(AppUser user, dynamic firebaseService) {
    return StreamBuilder<List<AppUser>>(
      stream: firebaseService.getDiscoveryMastersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final favoriteMasters = snapshot.data!
            .where((m) => user.favoriteMasters.contains(m.uid))
            .toList();

        if (favoriteMasters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.white.withOpacity(0.1)),
                const Gap(16),
                const Text("No favorite masters yet", style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: favoriteMasters.length,
          itemBuilder: (context, index) {
            final master = favoriteMasters[index];
            return _FavoriteGridItem(
              title: master.displayName ?? "Elite Partner",
              imageUrl: null, // Masters don't have images yet
              onTap: () => context.push(Uri(path: '/discovery', queryParameters: {'masterId': master.uid}).toString()),
              isService: false,
            );
          },
        );
      },
    );
  }
}

class _FavoriteGridItem extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isService;

  const _FavoriteGridItem({
    required this.title,
    this.imageUrl,
    required this.onTap,
    required this.isService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: imageUrl != null 
                  ? Image.network(imageUrl!, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: Colors.white.withOpacity(0.05),
                      child: Center(
                        child: Icon(
                          isService ? Icons.spa : Icons.person,
                          color: AppTheme.primaryGold.withOpacity(0.2),
                          size: 40,
                        ),
                      ),
                    ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Text(
                      isService ? "Service" : "Master",
                      style: const TextStyle(color: AppTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.w900),
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
