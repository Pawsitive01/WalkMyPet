import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/design_system.dart';

class ActiveWalksPage extends StatefulWidget {
  const ActiveWalksPage({super.key});

  @override
  State<ActiveWalksPage> createState() => _ActiveWalksPageState();
}

class _ActiveWalksPageState extends State<ActiveWalksPage> {
  // Using a stream controller instead of setState to prevent flickering
  final StreamController<DateTime> _timeController = StreamController<DateTime>.broadcast();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timeController.close();
    super.dispose();
  }

  void _startCountdownTimer() {
    // Add initial value
    _timeController.add(DateTime.now());

    // Update time every second via stream (no setState needed)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _timeController.add(DateTime.now());
      }
    });
  }

  Duration _calculateCountdown(Booking booking) {
    final now = DateTime.now();
    final scheduledDateTime = _parseScheduledDateTime(booking);
    final difference = scheduledDateTime.difference(now);
    return difference.isNegative ? Duration.zero : difference;
  }

  DateTime _parseScheduledDateTime(Booking booking) {
    try {
      // Parse time string (e.g., "2:30 PM" or "14:30")
      final timeStr = booking.time.trim();
      DateTime scheduledDate = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
      );

      // Handle various time formats
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        final format = DateFormat('h:mm a');
        final parsedTime = format.parse(timeStr);
        scheduledDate = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      } else if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        scheduledDate = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          hour,
          minute,
        );
      }

      return scheduledDate;
    } catch (e) {
      // Fallback to date only
      return booking.date;
    }
  }

  bool _canStartWalk(Duration countdown) {
    // Allow starting walk if scheduled time is within 10 minutes
    // or if the scheduled time has already passed (countdown is 0 or negative)
    final totalMinutes = countdown.inMinutes;
    return totalMinutes <= 10;
  }

  String _formatCountdown(Duration countdown) {
    if (countdown.inDays > 0) {
      return '${countdown.inDays}d ${countdown.inHours % 24}h';
    } else if (countdown.inHours > 0) {
      return '${countdown.inHours}h ${countdown.inMinutes % 60}m';
    } else if (countdown.inMinutes > 0) {
      return '${countdown.inMinutes}m ${countdown.inSeconds % 60}s';
    } else if (countdown.inSeconds > 0) {
      return '${countdown.inSeconds}s';
    } else {
      return 'Ready to start!';
    }
  }

  Future<void> _startWalk(Booking booking) async {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildStartWalkDialog(booking),
    );

    if (confirm == true && mounted) {
      // Future enhancement: Navigate to walk tracking screen or update booking status
      // Currently showing a success message to confirm walk started
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started walk for ${booking.dogName}'),
          backgroundColor: DesignSystem.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          ),
        ),
      );
    }
  }

  Widget _buildStartWalkDialog(Booking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? DesignSystem.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignSystem.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: DesignSystem.successGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: DesignSystem.space2),
            Text(
              'Start Walk?',
              style: TextStyle(
                fontSize: DesignSystem.h3,
                fontWeight: FontWeight.w800,
                color: DesignSystem.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: DesignSystem.space1),
            Text(
              'Begin the walk with ${booking.dogName}?',
              style: TextStyle(
                fontSize: DesignSystem.body,
                color: DesignSystem.getTextSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignSystem.space3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: DesignSystem.getBorderColor(isDark, opacity: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: DesignSystem.getTextSecondary(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.space2),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: DesignSystem.successGradient,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                      boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Start Walk',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: DesignSystem.body,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(isDark),
      body: _buildBody(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: Material(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: DesignSystem.getTextPrimary(isDark),
                size: 18,
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: DesignSystem.successGradient,
              borderRadius: BorderRadius.circular(DesignSystem.radiusCompact),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Active Walks',
            style: TextStyle(
              fontSize: DesignSystem.h2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: DesignSystem.getTextPrimary(isDark),
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        'Please log in to view active walks',
        Icons.login_rounded,
        isDark,
      );
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfWeek = startOfToday.add(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('walkerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: DesignSystem.success,
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            'Error loading walks',
            Icons.error_outline_rounded,
            isDark,
          );
        }

        // Filter bookings by date range in-app to avoid needing composite index
        final allBookings = snapshot.data?.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList() ?? [];

        final bookings = allBookings.where((booking) {
          final bookingDate = DateTime(
            booking.date.year,
            booking.date.month,
            booking.date.day,
          );
          return bookingDate.isAfter(startOfToday.subtract(const Duration(days: 1))) &&
                 bookingDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

        // Sort by date and time
        bookings.sort((a, b) {
          final dateTimeA = _parseScheduledDateTime(a);
          final dateTimeB = _parseScheduledDateTime(b);
          return dateTimeA.compareTo(dateTimeB);
        });

        if (bookings.isEmpty) {
          return _buildEmptyState(
            'No active walks scheduled',
            Icons.event_busy_rounded,
            isDark,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh is handled by StreamBuilder automatically
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: DesignSystem.success,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.space2,
              vertical: DesignSystem.space2,
            ),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              // Wrap each card with StreamBuilder to prevent full screen rebuilds
              return StreamBuilder<DateTime>(
                stream: _timeController.stream,
                initialData: DateTime.now(),
                builder: (context, snapshot) {
                  final countdown = _calculateCountdown(booking);
                  final canStart = _canStartWalk(countdown);
                  return _buildWalkCard(booking, countdown, canStart, isDark);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWalkCard(
    Booking booking,
    Duration countdown,
    bool canStart,
    bool isDark,
  ) {
    final dateStr = DateFormat('EEE, MMM dd').format(booking.date);
    final isUrgent = countdown.inMinutes <= 5 && countdown.inMinutes > 0;
    final isReady = countdown.inSeconds == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.space2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: canStart
              ? (isReady ? DesignSystem.success : DesignSystem.warning)
              : DesignSystem.getBorderColor(isDark, opacity: 0.1),
          width: canStart ? 2 : 1,
        ),
        boxShadow: canStart
            ? DesignSystem.shadowGlow(
                isReady ? DesignSystem.success : DesignSystem.warning
              )
            : DesignSystem.shadowCard(Colors.black),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignSystem.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with countdown
            Row(
              children: [
                // Countdown circle
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: isReady
                        ? DesignSystem.successGradient
                        : (isUrgent
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              )
                            : DesignSystem.walkerGradient),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                    boxShadow: DesignSystem.shadowGlow(
                      isReady
                          ? DesignSystem.success
                          : (isUrgent ? DesignSystem.warning : DesignSystem.walkerPrimary)
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReady
                            ? Icons.play_circle_filled_rounded
                            : (isUrgent
                                ? Icons.access_time_filled_rounded
                                : Icons.schedule_rounded),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        countdown.inDays > 0
                            ? '${countdown.inDays}d'
                            : (countdown.inHours > 0
                                ? '${countdown.inHours}h'
                                : '${countdown.inMinutes}m'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignSystem.space2),
                // Pet and owner info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: DesignSystem.ownerPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusTiny),
                            ),
                            child: const Icon(
                              Icons.pets,
                              size: 16,
                              color: DesignSystem.ownerPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.dogName,
                              style: TextStyle(
                                fontSize: DesignSystem.subheading,
                                fontWeight: FontWeight.w700,
                                color: DesignSystem.getTextPrimary(isDark),
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${booking.ownerName}',
                        style: TextStyle(
                          fontSize: DesignSystem.caption,
                          fontWeight: FontWeight.w500,
                          color: DesignSystem.getTextSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: DesignSystem.small,
                          fontWeight: FontWeight.w600,
                          color: DesignSystem.getTextTertiary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                // Price
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DesignSystem.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusCompact),
                  ),
                  child: Text(
                    '\$${booking.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: DesignSystem.subheading,
                      fontWeight: FontWeight.w900,
                      color: DesignSystem.success,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignSystem.space2),

            // Countdown text
            Container(
              padding: const EdgeInsets.all(DesignSystem.space1_5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(DesignSystem.radiusCompact),
              ),
              child: Row(
                children: [
                  Icon(
                    isReady
                        ? Icons.play_circle_outline_rounded
                        : Icons.timer_outlined,
                    size: 18,
                    color: isReady
                        ? DesignSystem.success
                        : (isUrgent
                            ? DesignSystem.warning
                            : DesignSystem.getTextSecondary(isDark)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isReady
                        ? 'Ready to start!'
                        : 'Starts in ${_formatCountdown(countdown)}',
                    style: TextStyle(
                      fontSize: DesignSystem.caption,
                      fontWeight: FontWeight.w700,
                      color: isReady
                          ? DesignSystem.success
                          : (isUrgent
                              ? DesignSystem.warning
                              : DesignSystem.getTextSecondary(isDark)),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignSystem.space1_5),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    DesignSystem.getBorderColor(isDark, opacity: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: DesignSystem.space1_5),

            // Details
            Row(
              children: [
                _buildInfoPill(
                  Icons.access_time_rounded,
                  booking.time,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildInfoPill(
                  Icons.timer_rounded,
                  '${booking.duration}m',
                  isDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoPill(
                    Icons.location_on_rounded,
                    booking.location,
                    isDark,
                    flex: true,
                  ),
                ),
              ],
            ),

            // Start Walk Button (only show if within time window)
            if (canStart) ...[
              const SizedBox(height: DesignSystem.space2),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: DesignSystem.successGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                  boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _startWalk(booking),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isReady ? 'Start Walk Now' : 'Start Walk',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: DesignSystem.body,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(
    IconData icon,
    String label,
    bool isDark, {
    bool flex = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.space1_5,
        vertical: DesignSystem.space1,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(DesignSystem.radiusCompact),
      ),
      child: Row(
        mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: DesignSystem.getTextTertiary(isDark),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: DesignSystem.small,
                fontWeight: FontWeight.w600,
                color: DesignSystem.getTextSecondary(isDark),
              ),
              overflow: flex ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignSystem.space3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignSystem.walkerPrimary.withValues(alpha: 0.1),
                  DesignSystem.walkerSecondary.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: DesignSystem.walkerPrimary,
            ),
          ),
          const SizedBox(height: DesignSystem.space3),
          Text(
            message,
            style: TextStyle(
              fontSize: DesignSystem.body,
              fontWeight: FontWeight.w600,
              color: DesignSystem.getTextSecondary(isDark),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignSystem.space1),
          Text(
            'Confirmed walks will appear here',
            style: TextStyle(
              fontSize: DesignSystem.caption,
              fontWeight: FontWeight.w500,
              color: DesignSystem.getTextTertiary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
