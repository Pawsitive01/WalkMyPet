import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/models/recurring_booking_model.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/booking_service.dart';
import 'package:walkmypet/services/notification_service.dart';

class RecurringBookingService {
  late final FirebaseFirestore _firestore;
  late final BookingService _bookingService;
  late final NotificationService _notificationService;

  RecurringBookingService() {
    _firestore = FirebaseFirestore.instance;
    _bookingService = BookingService();
    _notificationService = NotificationService();
  }

  /// Create a new recurring booking
  Future<String> createRecurringBooking(RecurringBooking recurringBooking) async {
    try {
      final docRef = await _firestore
          .collection('recurring_bookings')
          .add(recurringBooking.toFirestore());
      final recurringBookingId = docRef.id;

      // Generate bookings for the next 3 months (or until end date)
      await generateBookingsForRecurringPattern(recurringBookingId);

      // Send notification to walker
      await _notificationService.createNotification(
        userId: recurringBooking.walkerId,
        title: 'New Recurring Booking Request',
        message:
            '${recurringBooking.ownerName} wants to book recurring walks for ${recurringBooking.dogName}. ${recurringBooking.getRecurrenceDescription()}',
        type: 'recurringBookingRequest',
        data: {'recurringBookingId': recurringBookingId},
      );

      return recurringBookingId;
    } catch (e) {
      throw 'Failed to create recurring booking: $e';
    }
  }

  /// Generate individual bookings from a recurring pattern
  /// Generates bookings for the next 3 months or until end date
  Future<void> generateBookingsForRecurringPattern(
    String recurringBookingId, {
    DateTime? fromDate,
    int monthsAhead = 3,
  }) async {
    try {
      final recurringDoc = await _firestore
          .collection('recurring_bookings')
          .doc(recurringBookingId)
          .get();

      if (!recurringDoc.exists) throw 'Recurring booking not found';

      final recurringBooking = RecurringBooking.fromFirestore(recurringDoc);

      if (!recurringBooking.isActive) return;

      final startFrom = fromDate ?? DateTime.now();
      final endDate = recurringBooking.endDate ??
          DateTime.now().add(Duration(days: 30 * monthsAhead));

      // Calculate dates that match the recurrence pattern
      final bookingDates = _calculateBookingDates(
        recurringBooking: recurringBooking,
        startDate: startFrom,
        endDate: endDate,
      );

      // Create individual bookings
      for (final date in bookingDates) {
        // Check if booking already exists for this date
        final existingBookings = await _firestore
            .collection('bookings')
            .where('recurringBookingId', isEqualTo: recurringBookingId)
            .where('date', isEqualTo: Timestamp.fromDate(date))
            .get();

        if (existingBookings.docs.isEmpty) {
          // Create new booking
          final booking = Booking(
            id: '',
            ownerId: recurringBooking.ownerId,
            walkerId: recurringBooking.walkerId,
            ownerName: recurringBooking.ownerName,
            walkerName: recurringBooking.walkerName,
            dogName: recurringBooking.dogName,
            date: date,
            time: recurringBooking.time,
            duration: recurringBooking.duration,
            location: recurringBooking.location,
            price: recurringBooking.pricePerBooking,
            status: BookingStatus.pending,
            notes: recurringBooking.notes,
            createdAt: DateTime.now(),
            services: recurringBooking.services,
            serviceDetails: recurringBooking.serviceDetails,
            recurringBookingId: recurringBookingId,
            isRecurring: true,
          );

          await _firestore.collection('bookings').add(booking.toFirestore());
        }
      }
    } catch (e) {
      throw 'Failed to generate bookings: $e';
    }
  }

  /// Calculate dates that match the recurrence pattern
  List<DateTime> _calculateBookingDates({
    required RecurringBooking recurringBooking,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dates = <DateTime>[];
    var currentDate = _getNextValidDate(recurringBooking, startDate);

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      if (currentDate.isAfter(recurringBooking.startDate) ||
          currentDate.isAtSameMomentAs(recurringBooking.startDate)) {
        dates.add(currentDate);
      }

      // Move to next occurrence
      currentDate = _getNextValidDate(
        recurringBooking,
        currentDate.add(const Duration(days: 1)),
      );

      // Safety check to prevent infinite loops
      if (dates.length > 1000) break;
    }

    return dates;
  }

  /// Get the next valid date according to the recurrence pattern
  DateTime _getNextValidDate(RecurringBooking recurringBooking, DateTime from) {
    var checkDate = DateTime(from.year, from.month, from.day);

    switch (recurringBooking.recurrenceType) {
      case RecurrenceType.daily:
        return checkDate;

      case RecurrenceType.weekly:
      case RecurrenceType.custom:
        // Find next day that matches one of the selected days of week
        for (var i = 0; i < 7; i++) {
          final testDate = checkDate.add(Duration(days: i));
          final weekday = testDate.weekday; // ISO 8601 (1=Monday, 7=Sunday)

          if (recurringBooking.daysOfWeek.contains(weekday)) {
            return testDate;
          }
        }
        // Fallback (should never reach here)
        return checkDate;
    }
  }

  /// Get recurring booking by ID
  Future<RecurringBooking?> getRecurringBooking(String id) async {
    try {
      final doc = await _firestore
          .collection('recurring_bookings')
          .doc(id)
          .get();
      if (doc.exists) {
        return RecurringBooking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch recurring booking: $e';
    }
  }

  /// Get all recurring bookings for an owner
  Stream<List<RecurringBooking>> getOwnerRecurringBookings(String ownerId) {
    return _firestore
        .collection('recurring_bookings')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecurringBooking.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all recurring bookings for a walker
  Stream<List<RecurringBooking>> getWalkerRecurringBookings(String walkerId) {
    return _firestore
        .collection('recurring_bookings')
        .where('walkerId', isEqualTo: walkerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecurringBooking.fromFirestore(doc))
          .toList();
    });
  }

  /// Update recurring booking
  Future<void> updateRecurringBooking(
    String recurringBookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection('recurring_bookings')
          .doc(recurringBookingId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update recurring booking: $e';
    }
  }

  /// Cancel/Deactivate recurring booking
  /// This stops future bookings from being generated
  Future<void> cancelRecurringBooking(String recurringBookingId) async {
    try {
      await updateRecurringBooking(recurringBookingId, {
        'isActive': false,
      });

      // Cancel all future pending bookings in the series
      final futureBookings = await _firestore
          .collection('bookings')
          .where('recurringBookingId', isEqualTo: recurringBookingId)
          .where('status', isEqualTo: 'pending')
          .where('date', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .get();

      for (final doc in futureBookings.docs) {
        await _bookingService.cancelBooking(doc.id);
      }
    } catch (e) {
      throw 'Failed to cancel recurring booking: $e';
    }
  }

  /// Cancel a single booking in the series
  Future<void> cancelSingleOccurrence(String bookingId) async {
    try {
      await _bookingService.cancelBooking(bookingId);
    } catch (e) {
      throw 'Failed to cancel booking: $e';
    }
  }

  /// Cancel this occurrence and all future occurrences
  Future<void> cancelFromThisOccurrence(String bookingId) async {
    try {
      final booking = await _bookingService.getBooking(bookingId);
      if (booking == null || booking.recurringBookingId == null) {
        throw 'Booking not found or not part of recurring series';
      }

      // Cancel all bookings on or after this date
      final futureBookings = await _firestore
          .collection('bookings')
          .where('recurringBookingId', isEqualTo: booking.recurringBookingId)
          .where('status', isEqualTo: 'pending')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(booking.date))
          .get();

      for (final doc in futureBookings.docs) {
        await _bookingService.cancelBooking(doc.id);
      }

      // Deactivate the recurring booking
      await updateRecurringBooking(booking.recurringBookingId!, {
        'isActive': false,
      });
    } catch (e) {
      throw 'Failed to cancel from this occurrence: $e';
    }
  }

  /// Get all bookings for a recurring booking pattern
  Future<List<Booking>> getBookingsForRecurringPattern(
    String recurringBookingId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('recurringBookingId', isEqualTo: recurringBookingId)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      bookings.sort((a, b) => a.date.compareTo(b.date));
      return bookings;
    } catch (e) {
      throw 'Failed to fetch bookings: $e';
    }
  }

  /// Delete recurring booking (hard delete)
  Future<void> deleteRecurringBooking(String recurringBookingId) async {
    try {
      // Delete all associated bookings
      final bookings = await _firestore
          .collection('bookings')
          .where('recurringBookingId', isEqualTo: recurringBookingId)
          .get();

      for (final doc in bookings.docs) {
        await doc.reference.delete();
      }

      // Delete the recurring booking
      await _firestore
          .collection('recurring_bookings')
          .doc(recurringBookingId)
          .delete();
    } catch (e) {
      throw 'Failed to delete recurring booking: $e';
    }
  }

  /// Preview upcoming bookings for a recurring pattern (without creating them)
  List<DateTime> previewBookingDates({
    required RecurrenceType recurrenceType,
    required List<int> daysOfWeek,
    required DateTime startDate,
    DateTime? endDate,
    int previewDays = 90,
  }) {
    final tempRecurring = RecurringBooking(
      id: '',
      ownerId: '',
      walkerId: '',
      ownerName: '',
      walkerName: '',
      dogName: '',
      time: '',
      duration: 0,
      location: '',
      pricePerBooking: 0,
      recurrenceType: recurrenceType,
      daysOfWeek: daysOfWeek,
      startDate: startDate,
      endDate: endDate,
      services: [],
      serviceDetails: {},
      createdAt: DateTime.now(),
    );

    final previewEndDate = endDate ??
        startDate.add(Duration(days: previewDays));

    return _calculateBookingDates(
      recurringBooking: tempRecurring,
      startDate: startDate,
      endDate: previewEndDate,
    );
  }
}
