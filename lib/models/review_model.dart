import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String serviceId;
  final String clientId;
  final String clientName; // Denormalized for display
  final Map<String, int> abcdScore;
  final bool isVerifiedPurchase;
  final bool isLegacy;
  final String? categoryContext;
  final String comment; // Max 360 chars
  final List<String> photoUrls; // Max 3 photos
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.clientName,
    this.abcdScore = const {'a': 5, 'b': 5, 'c': 5, 'd': 5},
    this.isVerifiedPurchase = false,
    this.isLegacy = false,
    this.categoryContext,
    required this.comment,
    required this.photoUrls,
    required this.createdAt,
  });

  double get rating {
    if (abcdScore.isEmpty) return 0.0;
    final total = abcdScore.values.fold(0, (sum, val) => sum + val);
    return total / abcdScore.length;
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        clientId,
        abcdScore,
        isVerifiedPurchase,
        isLegacy,
        categoryContext,
        comment,
        photoUrls,
        createdAt,
      ];

  Map<String, dynamic> toMap() {
    return {
      'service_id': serviceId,
      'client_id': clientId,
      'client_name': clientName,
      'abcd_score': abcdScore,
      'total_score': rating,
      'is_verified_purchase': isVerifiedPurchase,
      'is_legacy': isLegacy,
      'category_context': categoryContext,
      'comment': comment,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    final abcdMap = (map['abcd_score'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        );

    // Legacy migration logic: if abcd_score is missing, it's a legacy review
    final bool isLegacy = abcdMap == null || map['is_legacy'] == true;
    final Map<String, int> effectiveAbcd = abcdMap ??
        {
          'a': (map['total_score'] ?? map['rating'] ?? 5).toInt(),
          'b': (map['total_score'] ?? map['rating'] ?? 5).toInt(),
          'c': (map['total_score'] ?? map['rating'] ?? 5).toInt(),
          'd': (map['total_score'] ?? map['rating'] ?? 5).toInt(),
        };

    return Review(
      id: docId,
      serviceId: map['service_id'] as String? ?? 'unknown',
      clientId: map['client_id'] as String? ?? (map['authorId'] as String? ?? 'unknown'),
      clientName: map['client_name'] as String? ?? 'Anonymous',
      abcdScore: effectiveAbcd,
      isVerifiedPurchase: map['is_verified_purchase'] as bool? ?? false,
      isLegacy: isLegacy,
      categoryContext: map['category_context'] as String?,
      comment: map['comment'] as String? ?? '',
      photoUrls: List<String>.from(map['photo_urls'] ?? []),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }
}
