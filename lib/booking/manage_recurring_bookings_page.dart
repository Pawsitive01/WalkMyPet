import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:walkmypet/models/recurring_booking_model.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/recurring_booking_service.dart';
import 'package:walkmypet/design_system.dart';

class ManageRecurringBookingsPage extends StatefulWidget {
  const ManageRecurringBookingsPage({super.key});

  @override
  State<ManageRecurringBookingsPage> createState() =>
      _ManageRecurringBookingsPageState();
}

class _ManageRecurringBookingsPageState
    extends State<ManageRecurringBookingsPage> {
  final _recurringBookingService = RecurringBookingService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recurring Bookings'),
        ),
        body: const Center(
          child: Text('Please log in to view recurring bookings'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Recurring Bookings',
          style: TextStyle(
            fontSize: DesignSystem.h2,
            fontWeight: FontWeight.w800,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
        backgroundColor: DesignSystem.getBackground(isDark),
        elevation: 0,
      ),
      body: StreamBuilder<List<RecurringBooking>>(
        stream: _recurringBookingService.getOwnerRecurringBookings(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDark);
          }

          if (snapshot.hasError) {
            return _buildErrorState(isDark, snapshot.error.toString());
          }

          final recurringBookings = snapshot.data ?? [];

          if (recurringBookings.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(DesignSystem.space2),
            itemCount: recurringBookings.length,
            itemBuilder: (context, index) {
              return _buildRecurringBookingCard(
                isDark,
                recurringBookings[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              DesignSystem.walkerPrimary,
            ),
          ),
          SizedBox(height: DesignSystem.space2),
          Text(
            'Loading recurring bookings...',
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: const Color(0xFFEF4444),
          ),
          SizedBox(height: DesignSystem.space2),
          Text(
            'Error loading bookings',
            style: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: DesignSystem.h3,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: DesignSystem.space1),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat_rounded,
            size: 80,
            color: DesignSystem.getTextTertiary(isDark),
          ),
          SizedBox(height: DesignSystem.space2),
          Text(
            'No Recurring Bookings',
            style: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: DesignSystem.h3,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: DesignSystem.space1),
          Text(
            'Set up recurring walks to save time',
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringBookingCard(bool isDark, RecurringBooking booking) {
    return Card(
      margin: EdgeInsets.only(bottom: DesignSystem.space2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        side: BorderSide(
          color: DesignSystem.getBorderColor(isDark),
          width: 1,
        ),
      ),
      color: DesignSystem.getSurface(isDark),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(DesignSystem.space1_5),
                    decoration: BoxDecoration(
                      gradient: booking.isActive
                          ? DesignSystem.walkerGradient
                          : LinearGradient(
                              colors: [Colors.grey, Colors.grey.shade700],
                            ),
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusSmall),
                    ),
                    child: Icon(
                      booking.isActive
                          ? Icons.repeat_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: DesignSystem.space1_5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${booking.walkerName} - ${booking.dogName}',
                          style: TextStyle(
                            color: DesignSystem.getTextPrimary(isDark),
                            fontSize: DesignSystem.h3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: DesignSystem.space0_5),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: DesignSystem.getTextSecondary(isDark),
                            ),
                            SizedBox(width: DesignSystem.space0_5),
                            Text(
                              booking.getRecurrenceDescription(),
                              style: TextStyle(
                                color: DesignSystem.getTextSecondary(isDark),
                                fontSize: DesignSystem.small,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSystem.space1_5,
                      vertical: DesignSystem.space0_5,
                    ),
                    decoration: BoxDecoration(
                      color: booking.isActive
                          ? DesignSystem.success.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusTiny),
                    ),
                    child: Text(
                      booking.isActive ? 'Active' : 'Paused',
                      style: TextStyle(
                        color: booking.isActive
                            ? DesignSystem.success
                            : Colors.grey,
                        fontSize: DesignSystem.tiny,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignSystem.space2),
              Container(
                padding: EdgeInsets.all(DesignSystem.space1_5),
                decoration: BoxDecoration(
                  color: DesignSystem.getSurface2(isDark),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      isDark,
                      Icons.today_rounded,
                      'Start Date',
                      DateFormat('MMM dd, yyyy').format(booking.startDate),
                    ),
                    if (booking.endDate != null) ...[
                      SizedBox(height: DesignSystem.space1),
                      _buildInfoRow(
                        isDark,
                        Icons.event_rounded,
                        'End Date',
                        DateFormat('MMM dd, yyyy').format(booking.endDate!),
                      ),
                    ],
                    SizedBox(height: DesignSystem.space1),
                    _buildInfoRow(
                      isDark,
                      Icons.access_time_rounded,
                      'Duration',
                      '${booking.duration} min',
                    ),
                    SizedBox(height: DesignSystem.space1),
                    _buildInfoRow(
                      isDark,
                      Icons.attach_money_rounded,
                      'Price per walk',
                      '\$${booking.pricePerBooking.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              SizedBox(height: DesignSystem.space2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewUpcomingWalks(booking),
                      icon: Icon(Icons.calendar_view_week_rounded, size: 16),
                      label: Text('View Walks'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignSystem.walkerPrimary,
                        side: BorderSide(
                          color: DesignSystem.walkerPrimary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignSystem.radiusSmall),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DesignSystem.space1),
                  if (booking.isActive)
                    IconButton(
                      onPressed: () => _cancelRecurringBooking(booking),
                      icon: Icon(Icons.cancel_rounded),
                      color: const Color(0xFFEF4444),
                      tooltip: 'Cancel',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      bool isDark, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: DesignSystem.getTextTertiary(isDark),
        ),
        SizedBox(width: DesignSystem.space1),
        Text(
          '$label: ',
          style: TextStyle(
            color: DesignSystem.getTextSecondary(isDark),
            fontSize: DesignSystem.small,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: DesignSystem.getTextPrimary(isDark),
            fontSize: DesignSystem.small,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(RecurringBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingDetailsSheet(booking),
    );
  }

  Widget _buildBookingDetailsSheet(RecurringBooking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignSystem.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignSystem.getTextTertiary(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: DesignSystem.space3),
          Text(
            'Recurring Booking Details',
            style: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: DesignSystem.h2,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: DesignSystem.space3),
          _buildDetailRow(isDark, 'Walker', booking.walkerName),
          _buildDetailRow(isDark, 'Pet', booking.dogName),
          _buildDetailRow(
              isDark, 'Pattern', booking.getRecurrenceDescription()),
          _buildDetailRow(isDark, 'Location', booking.location),
          _buildDetailRow(isDark, 'Time', booking.time),
          _buildDetailRow(isDark, 'Duration', '${booking.duration} minutes'),
          _buildDetailRow(
              isDark, 'Price', '\$${booking.pricePerBooking.toStringAsFixed(2)}'),
          _buildDetailRow(isDark, 'Services', booking.services.join(', ')),
          if (booking.notes != null && booking.notes!.isNotEmpty)
            _buildDetailRow(isDark, 'Notes', booking.notes!),
          SizedBox(height: DesignSystem.space3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.walkerPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(bool isDark, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignSystem.space1_5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: DesignSystem.getTextSecondary(isDark),
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewUpcomingWalks(RecurringBooking booking) async {
    final bookings =
        await _recurringBookingService.getBookingsForRecurringPattern(booking.id);

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(DesignSystem.space3),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(isDark),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignSystem.radiusLarge),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignSystem.getTextTertiary(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: DesignSystem.space3),
            Text(
              'Upcoming Walks',
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.h2,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: DesignSystem.space2),
            Expanded(
              child: bookings.isEmpty
                  ? Center(
                      child: Text(
                        'No upcoming walks',
                        style: TextStyle(
                          color: DesignSystem.getTextSecondary(isDark),
                          fontSize: DesignSystem.body,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _buildWalkItem(isDark, booking);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkItem(bool isDark, Booking booking) {
    final statusColor = _getStatusColor(booking.status);

    return Container(
      margin: EdgeInsets.only(bottom: DesignSystem.space1_5),
      padding: EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface2(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM dd, yyyy').format(booking.date),
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: DesignSystem.space0_5),
                Text(
                  booking.time,
                  style: TextStyle(
                    color: DesignSystem.getTextSecondary(isDark),
                    fontSize: DesignSystem.small,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignSystem.space1_5,
              vertical: DesignSystem.space0_5,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignSystem.radiusTiny),
            ),
            child: Text(
              booking.status.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: DesignSystem.tiny,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (booking.status == BookingStatus.pending) ...[
            SizedBox(width: DesignSystem.space1),
            IconButton(
              onPressed: () => _cancelSingleWalk(booking),
              icon: Icon(Icons.cancel_rounded),
              color: const Color(0xFFEF4444),
              iconSize: 20,
              tooltip: 'Cancel this walk',
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFF59E0B);
      case BookingStatus.confirmed:
        return const Color(0xFF10B981);
      case BookingStatus.completed:
        return const Color(0xFF6366F1);
      case BookingStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  Future<void> _cancelRecurringBooking(RecurringBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recurring Booking?'),
        content: const Text(
          'This will cancel all future pending walks in this series. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _recurringBookingService.cancelRecurringBooking(booking.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Recurring booking cancelled'),
              ],
            ),
            backgroundColor: DesignSystem.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _cancelSingleWalk(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel This Walk?'),
        content: Text(
          'Cancel walk on ${DateFormat('MMM dd, yyyy').format(booking.date)} at ${booking.time}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _recurringBookingService.cancelSingleOccurrence(booking.id);

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Walk cancelled'),
              ],
            ),
            backgroundColor: DesignSystem.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
