import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/models/transaction_model.dart';
import 'package:walkmypet/services/notification_service.dart';
import 'package:walkmypet/services/payment_service.dart';

class BookingService {
  late final FirebaseFirestore _firestore;
  late final NotificationService _notificationService;
  late final PaymentService _paymentService;

  BookingService() {
    _firestore = FirebaseFirestore.instance;
    _notificationService = NotificationService();
    _paymentService = PaymentService();
  }

  /// Create a new booking
  Future<String> createBooking(Booking booking) async {
    try {
      final docRef = await _firestore.collection('bookings').add(booking.toFirestore());
      final bookingId = docRef.id;

      // Send notification to walker about new booking request
      // This method already creates the notification, no need to call createNotification separately
      await _notificationService.notifyWalkerOfBookingRequest(
        walkerId: booking.walkerId,
        bookingId: bookingId,
        ownerName: booking.ownerName,
        dogName: booking.dogName,
      );

      return bookingId;
    } catch (e) {
      throw 'Failed to create booking: $e';
    }
  }

  /// Get booking by ID (one-time read)
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch booking: $e';
    }
  }

  /// Get booking by ID (real-time stream)
  Stream<Booking?> getBookingStream(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots().map((doc) {
      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get all bookings for an owner
  Stream<List<Booking>> getOwnerBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        // Removed .orderBy() to avoid requiring composite index
        // We'll sort in the app instead
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
          // Sort by date in the app
          bookings.sort((a, b) => a.date.compareTo(b.date));
          return bookings;
        });
  }

  /// Get all bookings for a walker
  Stream<List<Booking>> getWalkerBookings(String walkerId) {
    return _firestore
        .collection('bookings')
        .where('walkerId', isEqualTo: walkerId)
        // Removed .orderBy() to avoid requiring composite index
        // We'll sort in the app instead
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
          // Sort by date in the app
          bookings.sort((a, b) => a.date.compareTo(b.date));
          return bookings;
        });
  }

  /// Get bookings for a specific date range
  Future<List<Booking>> getBookingsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
    {bool isOwner = true}
  ) async {
    try {
      final field = isOwner ? 'ownerId' : 'walkerId';
      final querySnapshot = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to fetch bookings: $e';
    }
  }

  /// Update booking
  Future<void> updateBooking(String bookingId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('bookings').doc(bookingId).update(updates);
    } catch (e) {
      throw 'Failed to update booking: $e';
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId, {String? cancelledBy}) async {
    try {
      // Get booking details first
      final booking = await getBooking(bookingId);
      if (booking == null) throw 'Booking not found';

      // Update booking status
      await updateBooking(bookingId, {
        'status': BookingStatus.cancelled.toString().split('.').last,
      });

      // Send notification to the other party
      // This method already creates the notification, no need to call createNotification separately
      final cancelledByName = cancelledBy ?? 'Walker';
      await _notificationService.notifyBookingCancelled(
        userId: booking.ownerId,
        bookingId: bookingId,
        cancelledBy: cancelledByName,
      );

      // Cancel any scheduled walk reminder
      await _notificationService.cancelWalkReminder(bookingId);
    } catch (e) {
      throw 'Failed to cancel booking: $e';
    }
  }

  /// Confirm booking
  Future<void> confirmBooking(String bookingId) async {
    try {
      // Get booking details first
      final booking = await getBooking(bookingId);
      if (booking == null) throw 'Booking not found';

      // Update booking status
      await updateBooking(bookingId, {
        'status': BookingStatus.confirmed.toString().split('.').last,
      });

      // Send notification to owner
      // This method already creates the notification, no need to call createNotification separately
      await _notificationService.notifyBookingConfirmed(
        ownerId: booking.ownerId,
        bookingId: bookingId,
        walkerName: booking.walkerName,
      );

      // Schedule a reminder notification for 10 minutes before the walk
      await _notificationService.scheduleWalkReminder(
        bookingId: bookingId,
        walkDate: booking.date,
        walkTime: booking.time,
        dogName: booking.dogName,
        ownerName: booking.ownerName,
        location: booking.location,
      );
    } catch (e) {
      throw 'Failed to confirm booking: $e';
    }
  }

  /// Complete booking
  Future<void> completeBooking(String bookingId) async {
    try {
      await updateBooking(bookingId, {
        'status': BookingStatus.completed.toString().split('.').last,
      });
    } catch (e) {
      throw 'Failed to complete booking: $e';
    }
  }

  /// Walker marks walk as complete
  Future<void> markWalkComplete(String bookingId, String walkerId) async {
    try {
      // Get booking
      final booking = await getBooking(bookingId);
      if (booking == null) throw 'Booking not found';

      // Validate walker
      if (booking.walkerId != walkerId) {
        throw 'Only the assigned walker can complete this walk';
      }

      // Validate status
      if (booking.status != BookingStatus.confirmed) {
        throw 'Booking must be confirmed to complete';
      }

      // Update status to awaitingConfirmation
      await updateBooking(bookingId, {
        'status': BookingStatus.awaitingConfirmation.toString().split('.').last,
        'completedByWalkerAt': Timestamp.fromDate(DateTime.now()),
      });

      // Calculate pending earnings
      final breakdown = _paymentService.calculatePaymentBreakdown(booking.price);

      // Update walker's pending earnings
      final walkerRef = _firestore.collection('walkers').doc(walkerId);
      final walkerDoc = await walkerRef.get();
      if (walkerDoc.exists) {
        final currentPending =
            (walkerDoc.data()?['pendingEarnings'] ?? 0.0).toDouble();
        await walkerRef.update({
          'pendingEarnings': currentPending + breakdown.walkerEarnings,
        });
      }

      // Notify owner
      await _notificationService.notifyOwnerToConfirmCompletion(
        ownerId: booking.ownerId,
        bookingId: bookingId,
        walkerName: booking.walkerName,
        dogName: booking.dogName,
        amount: booking.price,
      );

      // Create in-app notification
      await _notificationService.createNotification(
        userId: booking.ownerId,
        title: 'Walk Completed - Confirm Now',
        message:
            '${booking.walkerName} has completed the walk with ${booking.dogName}. Please confirm to release payment.',
        type: 'completionConfirmation',
        bookingId: bookingId,
      );
    } catch (e) {
      throw 'Failed to mark walk complete: $e';
    }
  }

  /// Owner confirms walk completion
  Future<Transaction> confirmWalkCompletion(
      String bookingId, String ownerId) async {
    try {
      // Get booking
      final booking = await getBooking(bookingId);
      if (booking == null) throw 'Booking not found';

      // Validate owner
      if (booking.ownerId != ownerId) {
        throw 'Only the booking owner can confirm completion';
      }

      // Validate status
      if (booking.status != BookingStatus.awaitingConfirmation) {
        throw 'Booking is not awaiting confirmation';
      }

      // Process payment
      final transaction = await _paymentService.processBookingPayment(
        bookingId: bookingId,
        walkerId: booking.walkerId,
        ownerId: ownerId,
      );

      // Notify walker of payment
      await _notificationService.notifyWalkerPaymentReceived(
        walkerId: booking.walkerId,
        bookingId: bookingId,
        amount: transaction.amount,
        dogName: booking.dogName,
      );

      // Create in-app notification
      await _notificationService.createNotification(
        userId: booking.walkerId,
        title: 'Payment Received!',
        message:
            'You received \$${transaction.amount.toStringAsFixed(2)} for your walk with ${booking.dogName}.',
        type: 'paymentReceived',
        bookingId: bookingId,
      );

      return transaction;
    } catch (e) {
      throw 'Failed to confirm completion: $e';
    }
  }

  /// Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      throw 'Failed to delete booking: $e';
    }
  }
}
