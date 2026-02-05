import 'package:equatable/equatable.dart';

enum TransactionType { referralBonus, cashback, payment, withdrawal, directBonus, openerBonus, topup }

class Transaction extends Equatable {
  final String id;
  final String userId;
  final num amount;
  final TransactionType type;
  final String note;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, amount, type, note, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num? ?? 0),
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      note: map['note'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
