import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  earning,
  withdrawal,
  refund,
  platformFee,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class Transaction {
  final String id;
  final String userId; // Walker ID who receives payment
  final String bookingId; // Reference to booking
  final TransactionType type;
  final TransactionStatus status;
  final double amount; // Amount walker receives
  final double grossAmount; // Original booking price
  final double platformFee; // Commission amount
  final double platformFeePercent; // Commission percentage (0.15 = 15%)
  final String? ownerId; // Who paid
  final String? ownerName;
  final String? dogName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata; // Additional info

  // Stripe integration fields
  final String? stripePaymentIntentId; // Link to Stripe payment
  final String? withdrawalRequestId; // Link to withdrawal request

  Transaction({
    required this.id,
    required this.userId,
    required this.bookingId,
    required this.type,
    required this.status,
    required this.amount,
    required this.grossAmount,
    required this.platformFee,
    required this.platformFeePercent,
    this.ownerId,
    this.ownerName,
    this.dogName,
    required this.createdAt,
    this.completedAt,
    this.metadata,
    this.stripePaymentIntentId,
    this.withdrawalRequestId,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.earning,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${data['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      grossAmount: (data['grossAmount'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      platformFeePercent: (data['platformFeePercent'] ?? 0.15).toDouble(),
      ownerId: data['ownerId'],
      ownerName: data['ownerName'],
      dogName: data['dogName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      stripePaymentIntentId: data['stripePaymentIntentId'],
      withdrawalRequestId: data['withdrawalRequestId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookingId': bookingId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amount': amount,
      'grossAmount': grossAmount,
      'platformFee': platformFee,
      'platformFeePercent': platformFeePercent,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'dogName': dogName,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
      'stripePaymentIntentId': stripePaymentIntentId,
      'withdrawalRequestId': withdrawalRequestId,
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? bookingId,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    double? grossAmount,
    double? platformFee,
    double? platformFeePercent,
    String? ownerId,
    String? ownerName,
    String? dogName,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    String? stripePaymentIntentId,
    String? withdrawalRequestId,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      grossAmount: grossAmount ?? this.grossAmount,
      platformFee: platformFee ?? this.platformFee,
      platformFeePercent: platformFeePercent ?? this.platformFeePercent,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      dogName: dogName ?? this.dogName,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      withdrawalRequestId: withdrawalRequestId ?? this.withdrawalRequestId,
    );
  }
}
