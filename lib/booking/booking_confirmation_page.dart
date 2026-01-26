import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/booking_service.dart';
import 'package:walkmypet/services/message_service.dart';
import 'package:walkmypet/design_system.dart';
import 'package:walkmypet/walker/scheduled_walks_page.dart';
import 'package:walkmypet/messaging/chat_page.dart';

class BookingConfirmationPage extends StatefulWidget {
  final String bookingId;

  const BookingConfirmationPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  final BookingService _bookingService = BookingService();
  final MessageService _messageService = MessageService();
  bool _isProcessing = false;

  Future<void> _messageOwner(Booking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(
        'Please log in to send messages',
        const Color(0xFFEF4444),
        Icons.error_outline_rounded,
      );
      return;
    }

    try {
      final conversationId = await _messageService.getOrCreateConversation(
        userId1: user.uid,
        userName1: booking.walkerName,
        userPhoto1: user.photoURL ?? '',
        userId2: booking.ownerId,
        userName2: booking.ownerName,
        userPhoto2: '', // Owner photo not available in booking
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversationId,
              otherUserId: booking.ownerId,
              otherUserName: booking.ownerName,
              otherUserPhoto: '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Failed to open chat: $e',
          const Color(0xFFEF4444),
          Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _confirmBooking(Booking booking) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmDialog(
      title: 'Confirm Booking',
      message: 'Are you sure you want to accept this booking for ${booking.dogName}?\n\nDate: ${DateFormat('MMM dd, yyyy').format(booking.date)}\nTime: ${booking.time}',
      confirmText: 'Yes, Accept',
      confirmColor: DesignSystem.success,
      confirmIcon: Icons.check_circle_rounded,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _bookingService.confirmBooking(widget.bookingId);

      if (mounted) {
        _showSnackBar(
          'Booking confirmed! The owner has been notified.',
          DesignSystem.success,
          Icons.check_circle_rounded,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Navigate to Scheduled Walks page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduledWalksPage(),
            ),
            (route) => route.isFirst, // Keep only the first route
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error confirming booking: $e',
          const Color(0xFFEF4444),
          Icons.error_outline_rounded,
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmDialog(
      title: 'Decline Booking',
      message: 'Are you sure you want to decline this booking?\n\nThe owner will be notified and this action cannot be undone.',
      confirmText: 'Yes, Decline',
      confirmColor: const Color(0xFFEF4444),
      confirmIcon: Icons.cancel_rounded,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _bookingService.cancelBooking(
        widget.bookingId,
        cancelledBy: booking.walkerName,
      );

      if (mounted) {
        _showSnackBar(
          'Booking declined. The owner has been notified.',
          const Color(0xFFEF4444),
          Icons.cancel_rounded,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error declining booking: $e',
          const Color(0xFFEF4444),
          Icons.error_outline_rounded,
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData confirmIcon,
    required bool isDark,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                confirmIcon,
                color: confirmColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: confirmColor.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(confirmIcon, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignSystem.getTextPrimary(isDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Request',
          style: TextStyle(
            fontSize: DesignSystem.h2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
      ),
      body: StreamBuilder<Booking?>(
        stream: _bookingService.getBookingStream(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: DesignSystem.walkerPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading booking details...',
                    style: TextStyle(
                      color: DesignSystem.getTextSecondary(isDark),
                      fontSize: DesignSystem.body,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading booking: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: DesignSystem.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Trigger rebuild
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final booking = snapshot.data;
          if (booking == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 64,
                    color: DesignSystem.getTextTertiary(isDark),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: DesignSystem.getTextPrimary(isDark),
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildBookingDetails(booking, isDark);
        },
      ),
    );
  }

  Widget _buildBookingDetails(Booking booking, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignSystem.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge with real-time updates
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: booking.status != BookingStatus.pending
                ? Container(
                    key: ValueKey(booking.status),
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSystem.space2,
                      vertical: DesignSystem.space1,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                      border: Border.all(
                        color: _getStatusColor(booking.status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(booking.status),
                          size: 16,
                          color: _getStatusColor(booking.status),
                        ),
                        SizedBox(width: DesignSystem.space1),
                        Text(
                          _getStatusText(booking.status),
                          style: TextStyle(
                            fontSize: DesignSystem.body,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(booking.status),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (booking.status != BookingStatus.pending) SizedBox(height: DesignSystem.space3),

          // Owner Info Card
          _buildInfoCard(
            title: 'Pet Owner',
            icon: Icons.person_rounded,
            color: DesignSystem.ownerPrimary,
            isDark: isDark,
            children: [
              _buildInfoRow(Icons.person, booking.ownerName, isDark),
              _buildInfoRow(Icons.pets, booking.dogName, isDark),
              SizedBox(height: DesignSystem.space1),
              // Message Owner Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _messageOwner(booking),
                  icon: const Icon(Icons.message_rounded, size: 18),
                  label: const Text('Message Owner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignSystem.ownerPrimary,
                    side: BorderSide(
                      color: DesignSystem.ownerPrimary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                    ),
                    padding: EdgeInsets.symmetric(vertical: DesignSystem.space1_5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),

          // Booking Details Card
          _buildInfoCard(
            title: 'Booking Details',
            icon: Icons.calendar_today_rounded,
            color: DesignSystem.walkerPrimary,
            isDark: isDark,
            children: [
              _buildInfoRow(
                Icons.calendar_today_rounded,
                DateFormat('EEEE, MMM dd, yyyy').format(booking.date),
                isDark,
              ),
              _buildInfoRow(Icons.access_time_rounded, booking.time, isDark),
              _buildInfoRow(
                Icons.timer_rounded,
                '${booking.duration} minutes',
                isDark,
              ),
              _buildInfoRow(
                Icons.location_on_rounded,
                booking.location,
                isDark,
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),

          // Services Card
          if (booking.services != null && booking.services!.isNotEmpty)
            _buildInfoCard(
              title: 'Services',
              icon: Icons.star_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              children: booking.services!
                  .map((service) => Padding(
                        padding: EdgeInsets.only(bottom: DesignSystem.space1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: const Color(0xFFF59E0B),
                            ),
                            SizedBox(width: DesignSystem.space1),
                            Text(
                              service,
                              style: TextStyle(
                                fontSize: DesignSystem.body,
                                color: DesignSystem.getTextPrimary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          if (booking.services != null && booking.services!.isNotEmpty)
            SizedBox(height: DesignSystem.space2),

          // Notes Card
          if (booking.notes != null && booking.notes!.isNotEmpty)
            _buildInfoCard(
              title: 'Special Notes',
              icon: Icons.notes_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              children: [
                Text(
                  booking.notes!,
                  style: TextStyle(
                    fontSize: DesignSystem.body,
                    color: DesignSystem.getTextSecondary(isDark),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          if (booking.notes != null && booking.notes!.isNotEmpty)
            SizedBox(height: DesignSystem.space2),

          // Price Card
          Container(
            padding: EdgeInsets.all(DesignSystem.space3),
            decoration: BoxDecoration(
              gradient: DesignSystem.successGradient,
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: DesignSystem.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: DesignSystem.space0_5),
                    Text(
                      '\$${booking.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: DesignSystem.h1,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(DesignSystem.space2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignSystem.space3),

          // Action Buttons (only show for pending bookings)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: booking.status == BookingStatus.pending && !_isProcessing
                ? Row(
                    key: const ValueKey('action_buttons'),
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _rejectBooking(booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_rounded, size: 20),
                                SizedBox(width: DesignSystem.space1),
                                Text(
                                  'Decline',
                                  style: TextStyle(
                                    fontSize: DesignSystem.body,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: DesignSystem.space2),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _confirmBooking(booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DesignSystem.success,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: DesignSystem.success.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 20),
                                SizedBox(width: DesignSystem.space1),
                                Text(
                                  'Accept',
                                  style: TextStyle(
                                    fontSize: DesignSystem.body,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _isProcessing
                    ? Center(
                        key: const ValueKey('processing'),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: DesignSystem.walkerPrimary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                color: DesignSystem.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark),
        ),
        boxShadow: DesignSystem.shadowCard(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignSystem.space1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              SizedBox(width: DesignSystem.space1_5),
              Text(
                title,
                style: TextStyle(
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                  color: DesignSystem.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignSystem.space1),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: DesignSystem.getTextTertiary(isDark),
          ),
          SizedBox(width: DesignSystem.space1),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: DesignSystem.body,
                color: DesignSystem.getTextPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return DesignSystem.success;
      case BookingStatus.cancelled:
        return const Color(0xFFEF4444);
      case BookingStatus.completed:
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.completed:
        return Icons.done_all_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      default:
        return 'Pending';
    }
  }
}
