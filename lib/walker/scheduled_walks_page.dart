import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/booking/booking_confirmation_page.dart';
import 'package:walkmypet/widgets/walker_review_dialog.dart';
import 'package:walkmypet/services/review_service.dart';

class ScheduledWalksPage extends StatefulWidget {
  const ScheduledWalksPage({super.key});

  @override
  State<ScheduledWalksPage> createState() => _ScheduledWalksPageState();
}

class _ScheduledWalksPageState extends State<ScheduledWalksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      extendBodyBehindAppBar: false,
      appBar: _buildModernAppBar(isDark),
      body: Column(
        children: [
          _buildModernTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWalksList(BookingStatus.pending, isDark),
                _buildUpcomingWalksList(isDark),
                _buildWalksList(BookingStatus.completed, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: Material(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF000000),
                size: 18,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'My Walks',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: isDark ? Colors.white : const Color(0xFF000000),
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildModernTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'New',
              0,
              isDark,
              icon: Icons.fiber_new_rounded,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Upcoming',
              1,
              isDark,
              icon: Icons.event_rounded,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'History',
              2,
              isDark,
              icon: Icons.history_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, bool isDark, {required IconData icon}) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF6366F1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : const Color(0xFF6366F1))
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? const Color(0xFF000000) : Colors.white)
                  : (isDark ? Colors.grey[600] : Colors.grey[500]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? const Color(0xFF000000) : Colors.white)
                    : (isDark ? Colors.grey[600] : Colors.grey[500]),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalksList(BookingStatus status, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState('Please log in to view walks', isDark);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('walkerId', isEqualTo: user.uid)
          .where('status', isEqualTo: status.toString().split('.').last)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? Colors.white : const Color(0xFF6366F1),
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Error loading walks', isDark);
        }

        // Map and sort bookings in-app to avoid needing composite index
        final bookings = snapshot.data?.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList() ?? [];

        // Sort by date (descending for completed, ascending for pending)
        bookings.sort((a, b) {
          if (status == BookingStatus.completed) {
            return b.date.compareTo(a.date); // descending
          } else {
            return a.date.compareTo(b.date); // ascending
          }
        });

        if (bookings.isEmpty) {
          return _buildEmptyState(
            status == BookingStatus.pending
                ? 'No new walk requests'
                : 'No walks found',
            isDark,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildModernWalkCard(booking, isDark);
          },
        );
      },
    );
  }

  Widget _buildUpcomingWalksList(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState('Please log in to view walks', isDark);
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

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
              color: isDark ? Colors.white : const Color(0xFF6366F1),
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Error loading walks', isDark);
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
          return bookingDate.isAfter(startOfToday.subtract(const Duration(days: 1)));
        }).toList();

        // Sort by date ascending
        bookings.sort((a, b) => a.date.compareTo(b.date));

        if (bookings.isEmpty) {
          return _buildEmptyState('No upcoming walks', isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildModernWalkCard(booking, isDark);
          },
        );
      },
    );
  }

  Widget _buildModernWalkCard(Booking booking, bool isDark) {
    final isNewRequest = booking.status == BookingStatus.pending;
    final dateStr = DateFormat('MMM dd').format(booking.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNewRequest
              ? const Color(0xFF6366F1)
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!),
          width: isNewRequest ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: isNewRequest ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isNewRequest
              ? () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmationPage(
                        bookingId: booking.id,
                      ),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Date Circle
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isNewRequest
                              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                              : [const Color(0xFF10B981), const Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isNewRequest ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dateStr.split(' ')[1],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr.split(' ')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Pet Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isNewRequest)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'NEW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                '\$${booking.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF000000),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  size: 16,
                                  color: Color(0xFFEC4899),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.dogName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF000000),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      booking.ownerName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (isDark ? Colors.white : Colors.grey[300]!).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Details Row
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
                // Action Button for New Requests
                if (isNewRequest) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingConfirmationPage(
                                bookingId: booking.id,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            'View & Respond',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                // Review Button for Completed Walks
                if (booking.status == BookingStatus.completed) ...[
                  const SizedBox(height: 16),
                  _buildReviewButton(booking, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String label, bool isDark, {bool flex = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              overflow: flex ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewButton(Booking booking, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: _reviewService.hasUserReviewedBooking(booking.id, user.uid),
      builder: (context, snapshot) {
        final hasReviewed = snapshot.data ?? false;

        if (hasReviewed) {
          // Already reviewed - show completed badge
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Text(
                  'Review Submitted',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // Show review button
        return Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => WalkerReviewDialog(
                    bookingId: booking.id,
                    ownerId: booking.ownerId,
                    ownerName: booking.ownerName,
                    dogName: booking.dogName,
                  ),
                );

                if (result == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          const Text('Review submitted successfully!'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  setState(() {}); // Refresh to show "Review Submitted" badge
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Rate Pet Owner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'New requests will appear here',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[700] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
