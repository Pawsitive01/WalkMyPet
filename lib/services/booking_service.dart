import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Create a new booking
  Future<String> createBooking(Booking booking) async {
    try {
      final docRef = await _firestore.collection('bookings').add(booking.toFirestore());
      final bookingId = docRef.id;

      // Send notification to walker about new booking request
      await _notificationService.notifyWalkerOfBookingRequest(
        walkerId: booking.walkerId,
        bookingId: bookingId,
        ownerName: booking.ownerName,
        dogName: booking.dogName,
      );

      // Create in-app notification for walker
      await _notificationService.createNotification(
        userId: booking.walkerId,
        title: 'New Booking Request',
        message: '${booking.ownerName} wants to book a walk for ${booking.dogName}',
        type: 'bookingRequest',
        bookingId: bookingId,
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
      final cancelledByName = cancelledBy ?? 'Walker';
      await _notificationService.notifyBookingCancelled(
        userId: booking.ownerId,
        bookingId: bookingId,
        cancelledBy: cancelledByName,
      );

      // Create in-app notification
      await _notificationService.createNotification(
        userId: booking.ownerId,
        title: 'Booking Cancelled',
        message: 'Your booking for ${booking.dogName} has been cancelled by $cancelledByName',
        type: 'bookingCancelled',
        bookingId: bookingId,
      );
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
      await _notificationService.notifyBookingConfirmed(
        ownerId: booking.ownerId,
        bookingId: bookingId,
        walkerName: booking.walkerName,
      );

      // Create in-app notification
      await _notificationService.createNotification(
        userId: booking.ownerId,
        title: 'Booking Confirmed!',
        message: '${booking.walkerName} has confirmed your booking for ${booking.dogName}',
        type: 'bookingConfirmed',
        bookingId: bookingId,
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

  /// Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      throw 'Failed to delete booking: $e';
    }
  }
}
