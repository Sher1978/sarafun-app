
import 'package:equatable/equatable.dart';

enum LeadStatus { open, converted, archived }

class Lead extends Equatable {
  final String id;
  final String clientId;
  final String masterId;
  final String serviceId;
  final LeadStatus status;
  final DateTime createdAt;

  const Lead({
    required this.id,
    required this.clientId,
    required this.masterId,
    required this.serviceId,
    this.status = LeadStatus.open,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, clientId, masterId, serviceId, status, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'masterId': masterId,
      'serviceId': serviceId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Lead.fromMap(Map<String, dynamic> map) {
    return Lead(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      masterId: map['masterId'] as String,
      serviceId: map['serviceId'] as String,
      status: LeadStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'open'),
        orElse: () => LeadStatus.open,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
