import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/withdrawal_request_model.dart';
import 'stripe_connect_service.dart';

/// Service for handling withdrawal requests
class WithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StripeConnectService _stripeConnect = StripeConnectService();

  /// Minimum withdrawal amount in AUD
  static const double minimumWithdrawalAmount = 20.0;

  /// Processing fee for withdrawals in AUD
  static const double processingFee = 2.50;

  /// Request a withdrawal
  /// Creates a new withdrawal request in Firestore
  Future<String> requestWithdrawal({
    required String walkerId,
    required double amount,
    required String accountName,
    required String accountNumber,
    required String bsb,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Verify the user is requesting withdrawal for themselves
    if (user.uid != walkerId) {
      throw Exception('Cannot request withdrawal for another user');
    }

    // Validate amount
    if (amount < minimumWithdrawalAmount) {
      throw Exception(
        'Minimum withdrawal amount is \$${minimumWithdrawalAmount.toStringAsFixed(2)}',
      );
    }

    // Validate bank details
    _validateBankDetails(
      accountName: accountName,
      accountNumber: accountNumber,
      bsb: bsb,
    );

    // Get walker profile to get name and check available balance
    final walkerDoc = await _firestore.collection('walkers').doc(walkerId).get();

    if (!walkerDoc.exists) {
      throw Exception('Walker profile not found');
    }

    final walkerData = walkerDoc.data()!;
    final walkerName = walkerData['name'] ?? 'Unknown';
    final walletBalance = (walkerData['walletBalance'] ?? 0.0).toDouble();

    // Check if walker has sufficient balance
    if (amount > walletBalance) {
      throw Exception(
        'Insufficient balance. Available: \$${walletBalance.toStringAsFixed(2)}',
      );
    }

    // Check for pending withdrawal requests
    final pendingWithdrawals = await getPendingWithdrawalAmount(walkerId);
    final availableBalance = walletBalance - pendingWithdrawals;

    if (amount > availableBalance) {
      throw Exception(
        'Insufficient balance after pending withdrawals. Available: \$${availableBalance.toStringAsFixed(2)}',
      );
    }

    try {
      // Create withdrawal request document
      final withdrawalRef = _firestore.collection('withdrawal_requests').doc();

      final withdrawalRequest = WithdrawalRequest(
        id: withdrawalRef.id,
        walkerId: walkerId,
        walkerName: walkerName,
        amount: amount,
        status: WithdrawalStatus.pending,
        bankAccountName: accountName,
        bankAccountNumber: accountNumber,
        bankBSB: bsb.replaceAll('-', ''), // Store without formatting
        notes: notes,
        createdAt: DateTime.now(),
      );

      await withdrawalRef.set(withdrawalRequest.toFirestore());

      // Withdrawal request created
      return withdrawalRef.id;
    } catch (e) {
      throw Exception('Failed to create withdrawal request: $e');
    }
  }

  /// Get stream of walker's withdrawal requests
  /// Ordered by creation date, most recent first
  Stream<List<WithdrawalRequest>> getWalkerWithdrawals(String walkerId) {
    return _firestore
        .collection('withdrawal_requests')
        .where('walkerId', isEqualTo: walkerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalRequest.fromFirestore(doc))
            .toList());
  }

  /// Get a single withdrawal request by ID
  Future<WithdrawalRequest?> getWithdrawal(String withdrawalId) async {
    try {
      final doc =
          await _firestore.collection('withdrawal_requests').doc(withdrawalId).get();

      if (!doc.exists) {
        return null;
      }

      return WithdrawalRequest.fromFirestore(doc);
    } catch (e) {
      // Error handled silently
      return null;
    }
  }

  /// Cancel a pending withdrawal request
  /// Only walker who created it can cancel, and only if status is pending/approved
  Future<void> cancelWithdrawal(String withdrawalId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final withdrawal = await getWithdrawal(withdrawalId);

      if (withdrawal == null) {
        throw Exception('Withdrawal request not found');
      }

      // Verify user owns this withdrawal
      if (withdrawal.walkerId != user.uid) {
        throw Exception('Cannot cancel another user\'s withdrawal');
      }

      // Check if cancellation is allowed
      if (!withdrawal.canBeCancelled) {
        throw Exception(
          'Cannot cancel withdrawal with status: ${withdrawal.statusDisplayText}',
        );
      }

      // Update status to cancelled
      await _firestore.collection('withdrawal_requests').doc(withdrawalId).update({
        'status': WithdrawalStatus.cancelled.toShortString(),
        'processedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception('Failed to cancel withdrawal: $e');
    }
  }

  /// Get total amount of pending withdrawal requests for a walker
  /// Used to calculate available balance for new withdrawals
  Future<double> getPendingWithdrawalAmount(String walkerId) async {
    try {
      final pendingWithdrawals = await _firestore
          .collection('withdrawal_requests')
          .where('walkerId', isEqualTo: walkerId)
          .where('status', whereIn: [
            WithdrawalStatus.pending.toShortString(),
            WithdrawalStatus.approved.toShortString(),
            WithdrawalStatus.processing.toShortString(),
          ])
          .get();

      double total = 0.0;
      for (final doc in pendingWithdrawals.docs) {
        final amount = (doc.data()['amount'] ?? 0.0).toDouble();
        total += amount;
      }

      return total;
    } catch (e) {
      // Error handled silently
      return 0.0;
    }
  }

  /// Get available balance for withdrawals
  /// This is wallet balance minus pending withdrawal amounts
  Future<double> getAvailableBalance(String walkerId) async {
    try {
      // Get wallet balance
      final walkerDoc = await _firestore.collection('walkers').doc(walkerId).get();

      if (!walkerDoc.exists) {
        return 0.0;
      }

      final walletBalance = (walkerDoc.data()?['walletBalance'] ?? 0.0).toDouble();

      // Subtract pending withdrawal amounts
      final pendingAmount = await getPendingWithdrawalAmount(walkerId);

      return walletBalance - pendingAmount;
    } catch (e) {
      // Error handled silently
      return 0.0;
    }
  }

  /// Validate bank account details
  /// Throws exception if validation fails
  void _validateBankDetails({
    required String accountName,
    required String accountNumber,
    required String bsb,
  }) {
    // Validate account name
    if (accountName.trim().isEmpty) {
      throw Exception('Account name is required');
    }

    if (accountName.trim().length < 2) {
      throw Exception('Account name must be at least 2 characters');
    }

    // Validate BSB
    final bsbCleaned = bsb.replaceAll('-', '').replaceAll(' ', '');
    if (bsbCleaned.length != 6) {
      throw Exception('BSB must be 6 digits');
    }

    if (!RegExp(r'^\d{6}$').hasMatch(bsbCleaned)) {
      throw Exception('BSB must contain only digits');
    }

    // Validate account number
    final accountCleaned = accountNumber.replaceAll(' ', '');
    if (accountCleaned.length < 6 || accountCleaned.length > 9) {
      throw Exception('Account number must be 6-9 digits');
    }

    if (!RegExp(r'^\d+$').hasMatch(accountCleaned)) {
      throw Exception('Account number must contain only digits');
    }
  }

  /// Format BSB for display (XXX-XXX)
  static String formatBSB(String bsb) {
    final cleaned = bsb.replaceAll('-', '').replaceAll(' ', '');
    if (cleaned.length == 6) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
    }
    return bsb;
  }

  /// Validate BSB format (returns true if valid)
  static bool isValidBSB(String bsb) {
    final cleaned = bsb.replaceAll('-', '').replaceAll(' ', '');
    return cleaned.length == 6 && RegExp(r'^\d{6}$').hasMatch(cleaned);
  }

  /// Validate account number format (returns true if valid)
  static bool isValidAccountNumber(String accountNumber) {
    final cleaned = accountNumber.replaceAll(' ', '');
    return cleaned.length >= 6 &&
        cleaned.length <= 9 &&
        RegExp(r'^\d+$').hasMatch(cleaned);
  }

  /// Check if walker has Stripe Connect account set up and ready for payouts
  Future<bool> hasStripeAccountSetup(String walkerId) async {
    try {
      final walkerDoc = await _firestore.collection('walkers').doc(walkerId).get();
      if (!walkerDoc.exists) return false;

      final walkerData = walkerDoc.data();
      return walkerData?['stripePayoutsEnabled'] == true;
    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Request withdrawal with automatic Stripe payout
  /// This creates the withdrawal request and immediately processes it via Stripe
  Future<String> requestWithdrawalWithStripePayout({
    required String walkerId,
    required double amount,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Verify the user is requesting withdrawal for themselves
    if (user.uid != walkerId) {
      throw Exception('Cannot request withdrawal for another user');
    }

    // Validate amount
    if (amount < minimumWithdrawalAmount) {
      throw Exception(
        'Minimum withdrawal amount is \$${minimumWithdrawalAmount.toStringAsFixed(2)}',
      );
    }

    // Check if Stripe account is set up
    final stripeResult = await _stripeConnect.getAccountStatus();
    if (!stripeResult.success || !stripeResult.payoutsEnabled) {
      throw Exception(
        'Please set up your Stripe account before requesting a withdrawal. '
        'Go to Wallet > Set up payouts to connect your bank account.',
      );
    }

    // Get walker profile to check balance
    final walkerDoc = await _firestore.collection('walkers').doc(walkerId).get();

    if (!walkerDoc.exists) {
      throw Exception('Walker profile not found');
    }

    final walkerData = walkerDoc.data()!;
    final walkerName = walkerData['name'] ?? 'Unknown';
    final walletBalance = (walkerData['walletBalance'] ?? 0.0).toDouble();

    // Check if walker has sufficient balance
    if (amount > walletBalance) {
      throw Exception(
        'Insufficient balance. Available: \$${walletBalance.toStringAsFixed(2)}',
      );
    }

    // Check for pending withdrawal requests
    final pendingWithdrawals = await getPendingWithdrawalAmount(walkerId);
    final availableBalance = walletBalance - pendingWithdrawals;

    if (amount > availableBalance) {
      throw Exception(
        'Insufficient balance after pending withdrawals. Available: \$${availableBalance.toStringAsFixed(2)}',
      );
    }

    try {
      // Create withdrawal request document
      final withdrawalRef = _firestore.collection('withdrawal_requests').doc();

      final withdrawalRequest = WithdrawalRequest(
        id: withdrawalRef.id,
        walkerId: walkerId,
        walkerName: walkerName,
        amount: amount,
        status: WithdrawalStatus.pending,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await withdrawalRef.set(withdrawalRequest.toFirestore());

      // Withdrawal request created

      // Immediately process via Stripe
      final payoutResult = await _stripeConnect.processWithdrawalPayout(withdrawalRef.id);

      if (!payoutResult.success) {
        // Payout failed - update withdrawal status
        await withdrawalRef.update({
          'status': WithdrawalStatus.rejected.toShortString(),
          'rejectionReason': payoutResult.errorMessage ?? 'Stripe payout failed',
          'processedAt': FieldValue.serverTimestamp(),
        });
        throw Exception(payoutResult.errorMessage ?? 'Failed to process payout');
      }

      // Withdrawal processed via Stripe
      return withdrawalRef.id;
    } catch (e) {
      throw Exception('Failed to process withdrawal: $e');
    }
  }

  //
  // ADMIN FUNCTIONS
  // These would be called by admin users or Cloud Functions
  // For MVP, admin will manually update Firestore
  //

  /// Approve withdrawal request (admin function)
  /// For MVP, this would be done manually in Firebase Console
  Future<void> approveWithdrawal(String withdrawalId, String adminUserId) async {
    await _firestore.collection('withdrawal_requests').doc(withdrawalId).update({
      'status': WithdrawalStatus.approved.toShortString(),
      'processedBy': adminUserId,
    });
  }

  /// Mark withdrawal as processing (admin function)
  Future<void> markWithdrawalProcessing(
    String withdrawalId,
    String adminUserId,
  ) async {
    await _firestore.collection('withdrawal_requests').doc(withdrawalId).update({
      'status': WithdrawalStatus.processing.toShortString(),
      'processedBy': adminUserId,
    });
  }

  /// Reject withdrawal request (admin function)
  Future<void> rejectWithdrawal(
    String withdrawalId,
    String adminUserId,
    String reason,
  ) async {
    await _firestore.collection('withdrawal_requests').doc(withdrawalId).update({
      'status': WithdrawalStatus.rejected.toShortString(),
      'processedBy': adminUserId,
      'rejectionReason': reason,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
}
