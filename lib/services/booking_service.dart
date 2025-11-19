import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new booking
  Future<String> createBooking(Booking booking) async {
    try {
      final docRef = await _firestore.collection('bookings').add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create booking: $e';
    }
  }

  /// Get booking by ID
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

  /// Get all bookings for an owner
  Stream<List<Booking>> getOwnerBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  /// Get all bookings for a walker
  Stream<List<Booking>> getWalkerBookings(String walkerId) {
    return _firestore
        .collection('bookings')
        .where('walkerId', isEqualTo: walkerId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
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
  Future<void> cancelBooking(String bookingId) async {
    try {
      await updateBooking(bookingId, {
        'status': BookingStatus.cancelled.toString().split('.').last,
      });
    } catch (e) {
      throw 'Failed to cancel booking: $e';
    }
  }

  /// Confirm booking
  Future<void> confirmBooking(String bookingId) async {
    try {
      await updateBooking(bookingId, {
        'status': BookingStatus.confirmed.toString().split('.').last,
      });
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
