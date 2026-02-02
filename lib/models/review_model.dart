import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String serviceId;
  final String clientId;
  final String clientName; // Denormalized for display
  final double rating; // 1.0 to 5.0
  final String comment; // Max 360 chars
  final List<String> photoUrls; // Max 3 photos
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.photoUrls,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, serviceId, clientId, rating, comment, photoUrls, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'service_id': serviceId,
      'client_id': clientId,
      'client_name': clientName,
      'rating': rating,
      'comment': comment,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    return Review(
      id: docId,
      serviceId: map['service_id'] as String,
      clientId: map['client_id'] as String,
      clientName: map['client_name'] as String? ?? 'Anonymous',
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String,
      photoUrls: List<String>.from(map['photo_urls'] ?? []),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
