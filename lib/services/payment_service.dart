import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/models/transaction_model.dart';

class PaymentBreakdown {
  final double grossAmount;
  final double platformFee;
  final double platformFeePercent;
  final double walkerEarnings;

  PaymentBreakdown({
    required this.grossAmount,
    required this.platformFee,
    required this.platformFeePercent,
    required this.walkerEarnings,
  });
}

class PaymentService {
  late final FirebaseFirestore _firestore;

  // Platform commission rate (15%)
  static const double platformFeePercent = 0.15;

  PaymentService() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Calculate payment breakdown
  PaymentBreakdown calculatePaymentBreakdown(double bookingPrice) {
    final platformFee = bookingPrice * platformFeePercent;
    final walkerEarnings = bookingPrice - platformFee;

    return PaymentBreakdown(
      grossAmount: bookingPrice,
      platformFee: platformFee,
      platformFeePercent: platformFeePercent,
      walkerEarnings: walkerEarnings,
    );
  }

  /// Process payment after owner confirms completion
  Future<Transaction> processBookingPayment({
    required String bookingId,
    required String walkerId,
    required String ownerId,
  }) async {
    // Use Firestore transaction for atomic operations
    return await _firestore.runTransaction((transaction) async {
      // 1. Get booking
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      final bookingSnap = await transaction.get(bookingRef);

      if (!bookingSnap.exists) {
        throw 'Booking not found';
      }

      final booking = Booking.fromFirestore(bookingSnap);

      // 2. Validate status
      if (booking.status != BookingStatus.awaitingConfirmation) {
        throw 'Booking is not awaiting confirmation';
      }

      if (booking.paymentProcessed == true) {
        throw 'Payment already processed';
      }

      // 3. Calculate payment breakdown
      final breakdown = calculatePaymentBreakdown(booking.price);

      // 4. Create transaction record
      final txnRef = _firestore.collection('transactions').doc();
      final txn = Transaction(
        id: txnRef.id,
        userId: walkerId,
        bookingId: bookingId,
        type: TransactionType.earning,
        status: TransactionStatus.completed,
        amount: breakdown.walkerEarnings,
        grossAmount: breakdown.grossAmount,
        platformFee: breakdown.platformFee,
        platformFeePercent: breakdown.platformFeePercent,
        ownerId: ownerId,
        ownerName: booking.ownerName,
        dogName: booking.dogName,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      transaction.set(txnRef, txn.toFirestore());

      // 5. Update walker balance
      final walkerRef = _firestore.collection('walkers').doc(walkerId);
      final walkerSnap = await transaction.get(walkerRef);

      if (!walkerSnap.exists) {
        throw 'Walker not found';
      }

      final walkerData = walkerSnap.data()!;
      final currentBalance = (walkerData['walletBalance'] ?? 0.0).toDouble();
      final totalEarnings = (walkerData['totalEarnings'] ?? 0.0).toDouble();
      final pendingEarnings = (walkerData['pendingEarnings'] ?? 0.0).toDouble();
      final totalTxns = (walkerData['totalTransactions'] ?? 0) as int;

      transaction.update(walkerRef, {
        'walletBalance': currentBalance + breakdown.walkerEarnings,
        'totalEarnings': totalEarnings + breakdown.walkerEarnings,
        'pendingEarnings': pendingEarnings - breakdown.walkerEarnings,
        'lastPaymentAt': Timestamp.fromDate(DateTime.now()),
        'totalTransactions': totalTxns + 1,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // 6. Update booking status
      transaction.update(bookingRef, {
        'status': BookingStatus.completed.toString().split('.').last,
        'confirmedByOwnerAt': Timestamp.fromDate(DateTime.now()),
        'paymentProcessed': true,
        'transactionId': txnRef.id,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return txn;
    });
  }

  /// Get walker's transaction history
  Stream<List<Transaction>> getWalkerTransactions(String walkerId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: walkerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList());
  }

  /// Get single transaction
  Future<Transaction?> getTransaction(String transactionId) async {
    final doc =
        await _firestore.collection('transactions').doc(transactionId).get();
    return doc.exists ? Transaction.fromFirestore(doc) : null;
  }

  /// Calculate pending earnings for a walker (walks awaiting confirmation)
  Future<double> calculatePendingEarnings(String walkerId) async {
    final bookings = await _firestore
        .collection('bookings')
        .where('walkerId', isEqualTo: walkerId)
        .where('status', isEqualTo: 'awaitingConfirmation')
        .get();

    double pending = 0.0;
    for (var doc in bookings.docs) {
      final booking = Booking.fromFirestore(doc);
      final breakdown = calculatePaymentBreakdown(booking.price);
      pending += breakdown.walkerEarnings;
    }

    return pending;
  }

  /// Process withdrawal completion (admin or Cloud Function triggered)
  /// This decrements the walker's wallet balance and creates a withdrawal transaction
  Future<Transaction> processWithdrawal({
    required String withdrawalId,
    required String walkerId,
    required double amount,
  }) async {
    // Use Firestore transaction for atomic operations
    return await _firestore.runTransaction((transaction) async {
      // 1. Get withdrawal request
      final withdrawalRef =
          _firestore.collection('withdrawal_requests').doc(withdrawalId);
      final withdrawalSnap = await transaction.get(withdrawalRef);

      if (!withdrawalSnap.exists) {
        throw 'Withdrawal request not found';
      }

      final withdrawalData = withdrawalSnap.data()!;
      final status = withdrawalData['status'];

      // 2. Validate status (should be processing)
      if (status != 'processing' && status != 'approved') {
        throw 'Withdrawal is not in a processable state';
      }

      // 3. Get walker profile
      final walkerRef = _firestore.collection('walkers').doc(walkerId);
      final walkerSnap = await transaction.get(walkerRef);

      if (!walkerSnap.exists) {
        throw 'Walker not found';
      }

      final walkerData = walkerSnap.data()!;
      final walkerName = walkerData['name'] ?? 'Unknown';
      final currentBalance = (walkerData['walletBalance'] ?? 0.0).toDouble();
      final totalTxns = (walkerData['totalTransactions'] ?? 0) as int;

      // 4. Validate sufficient balance
      if (currentBalance < amount) {
        throw 'Insufficient balance for withdrawal';
      }

      // 5. Create withdrawal transaction record
      final txnRef = _firestore.collection('transactions').doc();
      final txn = Transaction(
        id: txnRef.id,
        userId: walkerId,
        bookingId: '', // No booking associated with withdrawal
        type: TransactionType.withdrawal,
        status: TransactionStatus.completed,
        amount: -amount, // Negative amount for withdrawal
        grossAmount: amount,
        platformFee: 0.0, // No platform fee on withdrawals
        platformFeePercent: 0.0,
        withdrawalRequestId: withdrawalId,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          'walkerName': walkerName,
          'type': 'bank_transfer',
        },
      );

      transaction.set(txnRef, txn.toFirestore());

      // 6. Update walker balance
      transaction.update(walkerRef, {
        'walletBalance': currentBalance - amount,
        'lastPaymentAt': Timestamp.fromDate(DateTime.now()),
        'totalTransactions': totalTxns + 1,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // 7. Update withdrawal request status
      transaction.update(withdrawalRef, {
        'status': 'completed',
        'processedAt': Timestamp.fromDate(DateTime.now()),
      });

      return txn;
    });
  }

  /// Get available balance for withdrawals
  /// This is the wallet balance minus pending withdrawal amounts
  /// Returns a stream so UI updates in real-time
  Stream<double> getAvailableBalance(String walkerId) {
    return _firestore.collection('walkers').doc(walkerId).snapshots().asyncMap(
      (walkerSnap) async {
        if (!walkerSnap.exists) {
          return 0.0;
        }

        final walletBalance =
            (walkerSnap.data()?['walletBalance'] ?? 0.0).toDouble();

        // Get pending withdrawal amounts
        final pendingWithdrawals = await _firestore
            .collection('withdrawal_requests')
            .where('walkerId', isEqualTo: walkerId)
            .where('status', whereIn: ['pending', 'approved', 'processing']).get();

        double pendingAmount = 0.0;
        for (final doc in pendingWithdrawals.docs) {
          final amount = (doc.data()['amount'] ?? 0.0).toDouble();
          pendingAmount += amount;
        }

        return walletBalance - pendingAmount;
      },
    );
  }

  /// Get wallet balance (simple, non-stream version)
  Future<double> getWalletBalance(String walkerId) async {
    final walkerDoc = await _firestore.collection('walkers').doc(walkerId).get();
    if (!walkerDoc.exists) {
      return 0.0;
    }
    return (walkerDoc.data()?['walletBalance'] ?? 0.0).toDouble();
  }

  /// Get total earnings
  Future<double> getTotalEarnings(String walkerId) async {
    final walkerDoc = await _firestore.collection('walkers').doc(walkerId).get();
    if (!walkerDoc.exists) {
      return 0.0;
    }
    return (walkerDoc.data()?['totalEarnings'] ?? 0.0).toDouble();
  }

  /// Get pending earnings
  Future<double> getPendingEarnings(String walkerId) async {
    final walkerDoc = await _firestore.collection('walkers').doc(walkerId).get();
    if (!walkerDoc.exists) {
      return 0.0;
    }
    return (walkerDoc.data()?['pendingEarnings'] ?? 0.0).toDouble();
  }
}
