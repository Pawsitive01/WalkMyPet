import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a withdrawal request
enum WithdrawalStatus {
  pending, // Request created, awaiting admin approval
  approved, // Admin approved, ready for processing
  processing, // Payment being processed
  completed, // Withdrawal completed, funds transferred
  rejected, // Admin rejected the request
  cancelled, // Walker cancelled the request
}

/// Extension to convert WithdrawalStatus to/from string
extension WithdrawalStatusExtension on WithdrawalStatus {
  String toShortString() {
    return toString().split('.').last;
  }

  static WithdrawalStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return WithdrawalStatus.pending;
      case 'approved':
        return WithdrawalStatus.approved;
      case 'processing':
        return WithdrawalStatus.processing;
      case 'completed':
        return WithdrawalStatus.completed;
      case 'rejected':
        return WithdrawalStatus.rejected;
      case 'cancelled':
        return WithdrawalStatus.cancelled;
      default:
        return WithdrawalStatus.pending;
    }
  }
}

/// Model representing a withdrawal request from a walker
class WithdrawalRequest {
  final String id;
  final String walkerId;
  final String walkerName;
  final double amount;
  final WithdrawalStatus status;

  // Bank account details (for Australian bank transfers)
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankBSB;

  // Alternative: PayPal email (for future PayPal withdrawals)
  final String? paypalEmail;

  // Additional information
  final String? notes; // Walker's notes
  final String? adminNotes; // Admin's processing notes
  final String? rejectionReason; // Reason if rejected

  // Timestamps
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy; // Admin user ID who processed

  WithdrawalRequest({
    required this.id,
    required this.walkerId,
    required this.walkerName,
    required this.amount,
    required this.status,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankBSB,
    this.paypalEmail,
    this.notes,
    this.adminNotes,
    this.rejectionReason,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
  });

  /// Create WithdrawalRequest from Firestore document
  factory WithdrawalRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WithdrawalRequest(
      id: doc.id,
      walkerId: data['walkerId'] ?? '',
      walkerName: data['walkerName'] ?? 'Unknown',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: WithdrawalStatusExtension.fromString(
        data['status'] ?? 'pending',
      ),
      bankAccountName: data['bankAccountName'],
      bankAccountNumber: data['bankAccountNumber'],
      bankBSB: data['bankBSB'],
      paypalEmail: data['paypalEmail'],
      notes: data['notes'],
      adminNotes: data['adminNotes'],
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      processedBy: data['processedBy'],
    );
  }

  /// Convert WithdrawalRequest to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'walkerId': walkerId,
      'walkerName': walkerName,
      'amount': amount,
      'status': status.toShortString(),
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'bankBSB': bankBSB,
      'paypalEmail': paypalEmail,
      'notes': notes,
      'adminNotes': adminNotes,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processedBy': processedBy,
    };
  }

  /// Create a copy with updated fields
  WithdrawalRequest copyWith({
    String? id,
    String? walkerId,
    String? walkerName,
    double? amount,
    WithdrawalStatus? status,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankBSB,
    String? paypalEmail,
    String? notes,
    String? adminNotes,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? processedAt,
    String? processedBy,
  }) {
    return WithdrawalRequest(
      id: id ?? this.id,
      walkerId: walkerId ?? this.walkerId,
      walkerName: walkerName ?? this.walkerName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankBSB: bankBSB ?? this.bankBSB,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
    );
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.processing:
        return 'Processing';
      case WithdrawalStatus.completed:
        return 'Completed';
      case WithdrawalStatus.rejected:
        return 'Rejected';
      case WithdrawalStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if withdrawal can be cancelled by walker
  bool get canBeCancelled {
    return status == WithdrawalStatus.pending ||
        status == WithdrawalStatus.approved;
  }

  /// Format bank account details for display (masked)
  String get maskedBankAccount {
    if (bankAccountNumber == null || bankAccountNumber!.isEmpty) {
      return 'Not provided';
    }

    // Show only last 4 digits
    if (bankAccountNumber!.length <= 4) {
      return '****';
    }

    final lastFour = bankAccountNumber!.substring(bankAccountNumber!.length - 4);
    return '****$lastFour';
  }

  /// Format BSB for display
  String get formattedBSB {
    if (bankBSB == null || bankBSB!.isEmpty) {
      return 'Not provided';
    }

    // Format as XXX-XXX
    if (bankBSB!.length == 6) {
      return '${bankBSB!.substring(0, 3)}-${bankBSB!.substring(3)}';
    }

    return bankBSB!;
  }

  @override
  String toString() {
    return 'WithdrawalRequest(id: $id, walker: $walkerName, amount: \$$amount, status: ${status.toShortString()})';
  }
}
