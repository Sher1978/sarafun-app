import 'package:equatable/equatable.dart';

enum DealStatus { pending, completed, cancelled }

class Deal extends Equatable {
  final String id;
  final String clientId;
  final String masterId;
  final String serviceId;
  final num amountStars;
  final num commissionTotal;
  final Map<String, dynamic> commissionDistribution;
  final int rating;
  final DealStatus status;
  final DateTime createdAt;

  const Deal({
    required this.id,
    required this.clientId,
    required this.masterId,
    required this.serviceId,
    required this.amountStars,
    required this.commissionTotal,
    required this.commissionDistribution,
    this.rating = 0,
    this.status = DealStatus.pending,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        clientId,
        masterId,
        serviceId,
        amountStars,
        commissionTotal,
        commissionDistribution,
        rating,
        status,
        createdAt,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'masterId': masterId,
      'serviceId': serviceId,
      'amountStars': amountStars,
      'commissionTotal': commissionTotal,
      'commissionDistribution': commissionDistribution,
      'rating': rating,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Deal.fromMap(Map<String, dynamic> map) {
    return Deal(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      masterId: map['masterId'] as String,
      serviceId: map['serviceId'] as String? ?? '',
      amountStars: (map['amountStars'] as num? ?? 0),
      commissionTotal: (map['commissionTotal'] as num? ?? 0),
      commissionDistribution: Map<String, dynamic>.from(map['commissionDistribution'] ?? {}),
      rating: map['rating'] as int? ?? 0,
      status: DealStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => DealStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
