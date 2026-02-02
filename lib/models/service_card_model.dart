import 'package:equatable/equatable.dart';

class ServiceCard extends Equatable {
  final String? id; // Nullable for creation
  final String masterId;
  final String title;
  final String description;
  final int priceStars;
  final bool isActive;
  final String category;
  final List<String> mediaUrls;

  const ServiceCard({
    this.id,
    required this.masterId,
    required this.title,
    required this.description,
    required this.priceStars,
    this.category = 'Other',
    this.isActive = true,
    this.mediaUrls = const [],
  });

  @override
  List<Object?> get props => [id, masterId, title, description, priceStars, category, isActive, mediaUrls];

  Map<String, dynamic> toMap() {
    return {
      'master_id': masterId,
      'title': title,
      'description': description,
      'price_stars': priceStars,
      'category': category,
      'is_active': isActive,
      'media_urls': mediaUrls,
    };
  }

  factory ServiceCard.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceCard(
      id: docId,
      masterId: map['master_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      priceStars: map['price_stars'] as int,
      category: map['category'] as String? ?? 'Other',
      isActive: map['is_active'] as bool? ?? true,
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
    );
  }
}
