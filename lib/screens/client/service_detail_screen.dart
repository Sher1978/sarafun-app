import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/models/review_model.dart';
import 'package:sara_fun/screens/client/create_review_screen.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final ServiceCard service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseService = ref.watch(firebaseServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(service.mediaUrls),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${service.priceStars} Stars", 
                              style: const TextStyle(color: AppTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.bold)),
                          
                          // Service-to-Parent Link
                          FutureBuilder<AppUser?>(
                            future: firebaseService.getUser(service.masterId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox.shrink();
                              final master = snapshot.data!;
                              return TextButton.icon(
                                onPressed: () {
                                  context.push(Uri(path: '/discovery', queryParameters: {'masterId': service.masterId}).toString());
                                },
                                icon: const Icon(Icons.store, size: 16, color: AppTheme.primaryGold),
                                label: Text(
                                  master.businessName ?? master.displayName ?? "View Business",
                                  style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                                ),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                               Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CreateReviewScreen(serviceId: service.id ?? 'unknown'),
                                  ),
                              );
                            },
                            icon: const Icon(Icons.rate_review, color: Colors.black),
                            label: const Text("Write Review", style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Text("Description", style: Theme.of(context).textTheme.titleMedium),
                      const Gap(8),
                      Text(service.description, style: const TextStyle(color: Colors.white70)),
                      const Gap(32),
                      FutureBuilder<AppUser?>(
                        future: firebaseService.getUser(service.masterId),
                        builder: (context, snapshot) {
                          final masterName = snapshot.data?.telegramId.toString() ?? "Partner";
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.push('/client/confirm-deal', extra: {
                                  'serviceTitle': service.title,
                                  'masterName': masterName,
                                  'masterId': service.masterId,
                                  'amountStars': service.priceStars,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text("Book Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      ),
                      const Gap(24),
                      Text("Reviews", style: Theme.of(context).textTheme.titleLarge),
                      const Gap(4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          StreamBuilder<List<Review>>(
            stream: firebaseService.getReviewsForService(service.id ?? 'unknown'),
            builder: (context, snapshot) {
              if (snapshot.hasError) return SliverToBoxAdapter(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              
              final reviews = snapshot.data!;
              if (reviews.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No reviews yet. Be the first!", style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ReviewItem(review: reviews[index]),
                  childCount: reviews.length,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[800],
        child: const Center(child: Icon(Icons.spa, size: 64, color: Colors.white24)),
      );
    }
    
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return Image.network(
            urls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error)),
          );
        },
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(review.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppTheme.primaryGold,
                  )),
                ),
              ],
            ),
            const Gap(8),
            if (review.comment.isNotEmpty)
              Text(review.comment),
            
            if (review.photoUrls.isNotEmpty) ...[
              const Gap(12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photoUrls.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(review.photoUrls[index], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
             const Gap(8),
             Text(
              "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
