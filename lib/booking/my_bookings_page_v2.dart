import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/booking_service.dart';
import 'package:walkmypet/services/review_service.dart';
import 'package:walkmypet/widgets/review_dialog.dart';
import 'package:walkmypet/design_system.dart';

/// MyBookingsPageV2 - Premium Booking Management Experience
///
/// A modern, elegant booking management page designed with world-class
/// consumer app standards (Instagram, TikTok, Snapchat level polish).
///
/// Key Features:
/// - Collapsible calendar with smooth animations
/// - Segmented tab control for booking categories
/// - Status-aware visual hierarchy
/// - Elegant card design with subtle micro-interactions
/// - Friendly empty states with reassuring copy

class MyBookingsPageV2 extends StatefulWidget {
  const MyBookingsPageV2({super.key});

  @override
  State<MyBookingsPageV2> createState() => _MyBookingsPageV2State();
}

class _MyBookingsPageV2State extends State<MyBookingsPageV2>
    with TickerProviderStateMixin {
  // Services
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();

  // State
  Map<DateTime, List<Booking>> _bookingsByDate = {};
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarExpanded = false;

  // Animation Controllers
  late AnimationController _pageAnimationController;
  late AnimationController _calendarAnimationController;
  late AnimationController _tabAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _calendarHeightAnimation;
  late Animation<double> _calendarOpacityAnimation;
  late Animation<double> _chevronRotationAnimation;

  // Tab categories
  final List<BookingCategory> _categories = [
    BookingCategory(
      label: 'Pending',
      status: BookingStatus.pending,
      color: const Color(0xFFF59E0B),
      icon: Icons.schedule_rounded,
      emptyTitle: 'No Pending Bookings',
      emptySubtitle: 'Your upcoming requests will appear here once you book a service.',
    ),
    BookingCategory(
      label: 'Confirmed',
      status: BookingStatus.confirmed,
      color: const Color(0xFF6366F1),
      icon: Icons.check_circle_rounded,
      emptyTitle: 'No Confirmed Bookings',
      emptySubtitle: 'Confirmed walks and services will show up here.',
    ),
    BookingCategory(
      label: 'Completed',
      status: BookingStatus.completed,
      color: const Color(0xFF10B981),
      icon: Icons.verified_rounded,
      emptyTitle: 'No Completed Bookings',
      emptySubtitle: 'Your finished services will be saved here for reference.',
    ),
    BookingCategory(
      label: 'Cancelled',
      status: BookingStatus.cancelled,
      color: const Color(0xFFEF4444),
      icon: Icons.cancel_rounded,
      emptyTitle: 'No Cancelled Bookings',
      emptySubtitle: 'Cancelled bookings will appear here.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBookings();
  }

  void _initAnimations() {
    // Page entrance animation
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: DesignSystem.animationHero,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Calendar expand/collapse animation
    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: DesignSystem.animationMedium,
    );

    _calendarHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _calendarAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _calendarOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _calendarAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _chevronRotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _calendarAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Tab switch animation
    _tabAnimationController = AnimationController(
      vsync: this,
      duration: DesignSystem.animationFast,
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _calendarAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      _bookingService.getOwnerBookings(user.uid).listen(
        (bookings) {
          if (mounted) {
            setState(() {
              _bookingsByDate = _groupBookingsByDate(bookings);
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar('Unable to load bookings', DesignSystem.error);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Unable to load bookings', DesignSystem.error);
      }
    }
  }

  Map<DateTime, List<Booking>> _groupBookingsByDate(List<Booking> bookings) {
    Map<DateTime, List<Booking>> grouped = {};
    for (var booking in bookings) {
      final date = DateTime(booking.date.year, booking.date.month, booking.date.day);
      grouped.putIfAbsent(date, () => []).add(booking);
    }
    return grouped;
  }

  List<Booking> _getBookingsForCategory(BookingStatus status) {
    var allBookings = _bookingsByDate.values.expand((list) => list).toList();

    // Filter by selected date if calendar date is selected
    if (_selectedDay != null && _isCalendarExpanded) {
      final normalizedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      allBookings = _bookingsByDate[normalizedDay] ?? [];
    }

    // Filter by status
    allBookings = allBookings.where((b) => b.status == status).toList();

    // Sort by date (most recent first for completed/cancelled, upcoming first for pending/confirmed)
    if (status == BookingStatus.completed || status == BookingStatus.cancelled) {
      allBookings.sort((a, b) => b.date.compareTo(a.date));
    } else {
      allBookings.sort((a, b) => a.date.compareTo(b.date));
    }

    return allBookings;
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _bookingsByDate[normalizedDay] ?? [];
  }

  int _getCountForCategory(BookingStatus status) {
    return _bookingsByDate.values
        .expand((list) => list)
        .where((b) => b.status == status)
        .length;
  }

  void _toggleCalendar() {
    HapticFeedback.lightImpact();
    setState(() => _isCalendarExpanded = !_isCalendarExpanded);

    if (_isCalendarExpanded) {
      _calendarAnimationController.forward();
    } else {
      _calendarAnimationController.reverse();
      _selectedDay = null;
    }
  }

  void _onTabChanged(int index) {
    if (index == _selectedTabIndex) return;

    HapticFeedback.selectionClick();
    setState(() => _selectedTabIndex = index);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == DesignSystem.error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        ),
        margin: const EdgeInsets.all(DesignSystem.space2),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isDark)
            : RefreshIndicator(
                onRefresh: _loadBookings,
                color: DesignSystem.ownerPrimary,
                backgroundColor: DesignSystem.getSurface(isDark),
                child: AnimatedBuilder(
                  animation: _pageAnimationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(isDark)),
                      SliverToBoxAdapter(child: _buildCalendarSection(isDark)),
                      SliverToBoxAdapter(child: _buildTabBar(isDark)),
                      SliverToBoxAdapter(child: _buildQuickStats(isDark)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          DesignSystem.space2_5,
                          DesignSystem.space2,
                          DesignSystem.space2_5,
                          DesignSystem.space4,
                        ),
                        sliver: _buildBookingsList(isDark),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: 0.5 + (0.5 * value),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignSystem.ownerPrimary.withValues(alpha: 0.15),
                    DesignSystem.walkerPrimary.withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.ownerPrimary),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignSystem.space3),
          Text(
            'Loading your bookings...',
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.space2_5,
        DesignSystem.space2,
        DesignSystem.space2_5,
        DesignSystem.space2,
      ),
      child: Row(
        children: [
          // Back button
          _BackButton(
            isDark: isDark,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: DesignSystem.space2),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bookings',
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.h2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your pet care services',
                  style: TextStyle(
                    color: DesignSystem.getTextTertiary(isDark),
                    fontSize: DesignSystem.caption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(bool isDark) {
    return Column(
      children: [
        // Calendar toggle button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.space2_5),
          child: _CalendarToggleButton(
            isDark: isDark,
            isExpanded: _isCalendarExpanded,
            selectedDay: _selectedDay,
            rotationAnimation: _chevronRotationAnimation,
            onTap: _toggleCalendar,
          ),
        ),
        // Animated calendar
        AnimatedBuilder(
          animation: _calendarAnimationController,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                heightFactor: _calendarHeightAnimation.value,
                child: Opacity(
                  opacity: _calendarOpacityAnimation.value,
                  child: child,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSystem.space2_5,
              DesignSystem.space2,
              DesignSystem.space2_5,
              DesignSystem.space1,
            ),
            child: _buildCalendarCard(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.08),
        ),
        boxShadow: DesignSystem.shadowCard(Colors.black),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          eventLoader: _getBookingsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selectedDay, focusedDay) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedDay = isSameDay(_selectedDay, selectedDay) ? null : selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              gradient: DesignSystem.ownerGradient,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              gradient: DesignSystem.walkerGradient,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: DesignSystem.success,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerSize: 6,
            markerMargin: const EdgeInsets.symmetric(horizontal: 1),
            weekendTextStyle: TextStyle(
              color: DesignSystem.ownerPrimary,
              fontWeight: FontWeight.w600,
            ),
            defaultTextStyle: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontWeight: FontWeight.w500,
            ),
            todayTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            cellMargin: const EdgeInsets.all(4),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: DesignSystem.subheading,
              fontWeight: FontWeight.w700,
            ),
            leftChevronIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignSystem.getSurface2(isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: DesignSystem.getTextPrimary(isDark),
                size: 20,
              ),
            ),
            rightChevronIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignSystem.getSurface2(isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: DesignSystem.getTextPrimary(isDark),
                size: 20,
              ),
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: DesignSystem.getTextTertiary(isDark),
              fontWeight: FontWeight.w600,
              fontSize: DesignSystem.small,
            ),
            weekendStyle: TextStyle(
              color: DesignSystem.ownerPrimary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: DesignSystem.small,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(
        DesignSystem.space2_5,
        DesignSystem.space2,
        DesignSystem.space2_5,
        DesignSystem.space1_5,
      ),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.06),
        ),
        boxShadow: DesignSystem.shadowSubtle(Colors.black),
      ),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final category = _categories[index];
          final isSelected = _selectedTabIndex == index;
          final count = _getCountForCategory(category.status);

          return Expanded(
            child: _TabItem(
              label: category.label,
              count: count,
              color: category.color,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => _onTabChanged(index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    final category = _categories[_selectedTabIndex];
    final bookings = _getBookingsForCategory(category.status);
    final count = bookings.length;

    // Calculate some stats for the selected category
    String subtitle;
    if (_selectedDay != null && _isCalendarExpanded) {
      subtitle = 'on ${DateFormat('MMM d').format(_selectedDay!)}';
    } else {
      subtitle = count == 0 ? 'None scheduled' : '$count total';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.space2_5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.color.withValues(alpha: 0.15),
                  category.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 20,
            ),
          ),
          const SizedBox(width: DesignSystem.space1_5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${category.label} Bookings',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: DesignSystem.getTextTertiary(isDark),
                  fontSize: DesignSystem.small,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_selectedDay != null && _isCalendarExpanded)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedDay = null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: category.color,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear date',
                      style: TextStyle(
                        color: category.color,
                        fontSize: DesignSystem.small,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(bool isDark) {
    final category = _categories[_selectedTabIndex];
    final bookings = _getBookingsForCategory(category.status);

    if (bookings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(isDark, category),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == bookings.length - 1 ? 0 : DesignSystem.space2,
            ),
            child: _BookingCard(
              booking: booking,
              isDark: isDark,
              onReviewTap: () => _showReviewDialog(booking),
              reviewService: _reviewService,
            ),
          );
        },
        childCount: bookings.length,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, BookingCategory category) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignSystem.space5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated empty state icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    category.color.withValues(alpha: 0.12),
                    category.color.withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        category.color.withValues(alpha: 0.2),
                        category.color.withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 32,
                    color: category.color.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignSystem.space3),
            Text(
              category.emptyTitle,
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.h3,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignSystem.space1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignSystem.space4),
              child: Text(
                category.emptySubtitle,
                style: TextStyle(
                  color: DesignSystem.getTextTertiary(isDark),
                  fontSize: DesignSystem.bodySmall,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (category.status == BookingStatus.pending) ...[
              const SizedBox(height: DesignSystem.space4),
              // CTA to book a service
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: DesignSystem.ownerGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  boxShadow: DesignSystem.shadowGlow(DesignSystem.ownerPrimary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Book a Service',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewDialog(Booking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please log in to leave a review', DesignSystem.error);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewDialog(
        bookingId: booking.id,
        walkerId: booking.walkerId,
        walkerName: booking.walkerName,
        dogName: booking.dogName,
      ),
    );

    if (result == true && mounted) {
      _showSnackBar('Review submitted successfully!', DesignSystem.success);
      setState(() {});
    }
  }
}

// =============================================================================
// SUPPORTING WIDGETS
// =============================================================================

/// Booking category data model
class BookingCategory {
  final String label;
  final BookingStatus status;
  final Color color;
  final IconData icon;
  final String emptyTitle;
  final String emptySubtitle;

  const BookingCategory({
    required this.label,
    required this.status,
    required this.color,
    required this.icon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });
}

/// Elegant back button with press effect
class _BackButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const _BackButton({
    required this.isDark,
    required this.onPressed,
  });

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: DesignSystem.animationQuick,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _isPressed
              ? DesignSystem.getSurface2(widget.isDark)
              : DesignSystem.getSurface(widget.isDark),
          shape: BoxShape.circle,
          border: Border.all(
            color: DesignSystem.getBorderColor(widget.isDark, opacity: 0.08),
          ),
          boxShadow: _isPressed ? null : DesignSystem.shadowSubtle(Colors.black),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: DesignSystem.getTextPrimary(widget.isDark),
          size: 20,
        ),
      ),
    );
  }
}

/// Calendar toggle button with date display
class _CalendarToggleButton extends StatefulWidget {
  final bool isDark;
  final bool isExpanded;
  final DateTime? selectedDay;
  final Animation<double> rotationAnimation;
  final VoidCallback onTap;

  const _CalendarToggleButton({
    required this.isDark,
    required this.isExpanded,
    required this.selectedDay,
    required this.rotationAnimation,
    required this.onTap,
  });

  @override
  State<_CalendarToggleButton> createState() => _CalendarToggleButtonState();
}

class _CalendarToggleButtonState extends State<_CalendarToggleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasSelectedDate = widget.selectedDay != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: DesignSystem.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.space2,
          vertical: DesignSystem.space1_5,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? DesignSystem.getSurface2(widget.isDark)
              : DesignSystem.getSurface(widget.isDark),
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          border: Border.all(
            color: widget.isExpanded
                ? DesignSystem.ownerPrimary.withValues(alpha: 0.3)
                : DesignSystem.getBorderColor(widget.isDark, opacity: 0.08),
            width: widget.isExpanded ? 1.5 : 1,
          ),
          boxShadow: _isPressed ? null : DesignSystem.shadowSubtle(Colors.black),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: widget.isExpanded
                    ? DesignSystem.ownerGradient
                    : LinearGradient(
                        colors: [
                          DesignSystem.ownerPrimary.withValues(alpha: 0.15),
                          DesignSystem.ownerPrimary.withValues(alpha: 0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(DesignSystem.radiusTiny),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: widget.isExpanded ? Colors.white : DesignSystem.ownerPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: DesignSystem.space1_5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelectedDate
                        ? DateFormat('EEEE, MMM d').format(widget.selectedDay!)
                        : 'Filter by Date',
                    style: TextStyle(
                      color: DesignSystem.getTextPrimary(widget.isDark),
                      fontSize: DesignSystem.bodySmall,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.isExpanded ? 'Tap to collapse' : 'Tap to expand calendar',
                    style: TextStyle(
                      color: DesignSystem.getTextTertiary(widget.isDark),
                      fontSize: DesignSystem.small,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            RotationTransition(
              turns: widget.rotationAnimation,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: DesignSystem.getTextTertiary(widget.isDark),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab item with count badge
class _TabItem extends StatefulWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: DesignSystem.animationFast,
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: widget.isSelected
              ? LinearGradient(
                  colors: [
                    widget.color,
                    widget.color.withValues(alpha: 0.85),
                  ],
                )
              : null,
          color: widget.isSelected
              ? null
              : _isPressed
                  ? DesignSystem.getSurface2(widget.isDark)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.white
                      : DesignSystem.getTextSecondary(widget.isDark),
                  fontSize: DesignSystem.small,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : widget.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
                  ),
                  child: Text(
                    widget.count.toString(),
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : widget.color,
                      fontSize: DesignSystem.tiny,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Elegant booking card with status-aware styling
class _BookingCard extends StatefulWidget {
  final Booking booking;
  final bool isDark;
  final VoidCallback onReviewTap;
  final ReviewService reviewService;

  const _BookingCard({
    required this.booking,
    required this.isDark,
    required this.onReviewTap,
    required this.reviewService,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _isPressed = false;

  Color get _statusColor {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return const Color(0xFFF59E0B);
      case BookingStatus.confirmed:
        return const Color(0xFF6366F1);
      case BookingStatus.awaitingConfirmation:
        return const Color(0xFF3B82F6);
      case BookingStatus.completed:
        return const Color(0xFF10B981);
      case BookingStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  IconData get _statusIcon {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return Icons.schedule_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.awaitingConfirmation:
        return Icons.hourglass_bottom_rounded;
      case BookingStatus.completed:
        return Icons.verified_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String get _statusLabel {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.awaitingConfirmation:
        return 'Awaiting';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getServiceColor(String service) {
    switch (service.toLowerCase()) {
      case 'walking':
        return DesignSystem.success;
      case 'grooming':
        return DesignSystem.ownerPrimary;
      case 'sitting':
        return DesignSystem.walkerPrimary;
      case 'training':
        return DesignSystem.warning;
      case 'feeding':
        return DesignSystem.walkerSecondary;
      default:
        return DesignSystem.walkerPrimary;
    }
  }

  IconData _getServiceIcon(String service) {
    switch (service.toLowerCase()) {
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'grooming':
        return Icons.content_cut_rounded;
      case 'sitting':
        return Icons.home_rounded;
      case 'training':
        return Icons.school_rounded;
      case 'feeding':
        return Icons.restaurant_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        // Could navigate to booking details
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: DesignSystem.animationQuick,
        child: AnimatedContainer(
        duration: DesignSystem.animationQuick,
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(widget.isDark),
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          border: Border.all(
            color: _statusColor.withValues(alpha: 0.15),
          ),
          boxShadow: _isPressed
              ? null
              : DesignSystem.shadowCard(Colors.black),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor,
                      _statusColor.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DesignSystem.space2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Walker name + Status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Walker info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.booking.walkerName,
                                    style: TextStyle(
                                      color: DesignSystem.getTextPrimary(widget.isDark),
                                      fontSize: DesignSystem.subheading,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (widget.booking.isRecurring) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: DesignSystem.walkerGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.repeat_rounded,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Recurring',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.pets_rounded,
                                    color: DesignSystem.ownerPrimary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.booking.dogName,
                                    style: TextStyle(
                                      color: DesignSystem.getTextSecondary(widget.isDark),
                                      fontSize: DesignSystem.caption,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _statusColor.withValues(alpha: 0.15),
                                _statusColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(
                              color: _statusColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon,
                                color: _statusColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _statusLabel,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontSize: DesignSystem.small,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignSystem.space2),
                    // Booking details in a compact grid
                    Container(
                      padding: const EdgeInsets.all(DesignSystem.space1_5),
                      decoration: BoxDecoration(
                        color: DesignSystem.getSurface2(widget.isDark).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          _DetailChip(
                            icon: Icons.calendar_today_rounded,
                            label: DateFormat('MMM d').format(widget.booking.date),
                            color: DesignSystem.walkerPrimary,
                            isDark: widget.isDark,
                          ),
                          const SizedBox(width: DesignSystem.space1),
                          _DetailChip(
                            icon: Icons.access_time_rounded,
                            label: widget.booking.time,
                            color: DesignSystem.ownerPrimary,
                            isDark: widget.isDark,
                          ),
                          const SizedBox(width: DesignSystem.space1),
                          _DetailChip(
                            icon: Icons.timer_outlined,
                            label: '${widget.booking.duration}m',
                            color: DesignSystem.walkerSecondary,
                            isDark: widget.isDark,
                          ),
                        ],
                      ),
                    ),
                    // Location
                    const SizedBox(height: DesignSystem.space1_5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: DesignSystem.success,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.booking.location,
                            style: TextStyle(
                              color: DesignSystem.getTextSecondary(widget.isDark),
                              fontSize: DesignSystem.caption,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Services
                    if (widget.booking.services != null &&
                        widget.booking.services!.isNotEmpty) ...[
                      const SizedBox(height: DesignSystem.space1_5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.booking.services!.map((service) {
                          final color = _getServiceColor(service);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.12),
                                  color.withValues(alpha: 0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getServiceIcon(service),
                                  color: color,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  service,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: DesignSystem.small,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // Notes
                    if (widget.booking.notes != null &&
                        widget.booking.notes!.isNotEmpty) ...[
                      const SizedBox(height: DesignSystem.space1_5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            color: DesignSystem.getTextTertiary(widget.isDark),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.booking.notes!,
                              style: TextStyle(
                                color: DesignSystem.getTextTertiary(widget.isDark),
                                fontSize: DesignSystem.small,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: DesignSystem.space2),
                    // Footer: Price + Action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _statusColor.withValues(alpha: 0.12),
                                _statusColor.withValues(alpha: 0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                color: _statusColor,
                                size: 18,
                              ),
                              Text(
                                widget.booking.price.toStringAsFixed(2),
                                style: TextStyle(
                                  color: _statusColor,
                                  fontSize: DesignSystem.h3,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action button (Review for completed)
                        if (widget.booking.status == BookingStatus.completed)
                          FutureBuilder<bool>(
                            future: widget.reviewService.hasUserReviewedBooking(
                              widget.booking.id,
                              FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                            builder: (context, snapshot) {
                              final hasReviewed = snapshot.data ?? false;
                              return _ReviewButton(
                                hasReviewed: hasReviewed,
                                isDark: widget.isDark,
                                onTap: hasReviewed ? null : widget.onReviewTap,
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Compact detail chip for booking info
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(isDark),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.small,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Review button with state handling
class _ReviewButton extends StatefulWidget {
  final bool hasReviewed;
  final bool isDark;
  final VoidCallback? onTap;

  const _ReviewButton({
    required this.hasReviewed,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_ReviewButton> createState() => _ReviewButtonState();
}

class _ReviewButtonState extends State<_ReviewButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.hasReviewed && widget.onTap != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled
          ? () {
              HapticFeedback.mediumImpact();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: DesignSystem.animationQuick,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: widget.hasReviewed
              ? null
              : LinearGradient(
                  colors: _isPressed
                      ? [
                          DesignSystem.rating.withValues(alpha: 0.8),
                          DesignSystem.rating.withValues(alpha: 0.6),
                        ]
                      : [DesignSystem.rating, DesignSystem.rating.withValues(alpha: 0.85)],
                ),
          color: widget.hasReviewed
              ? DesignSystem.getSurface2(widget.isDark)
              : null,
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          boxShadow: widget.hasReviewed || _isPressed
              ? null
              : [
                  BoxShadow(
                    color: DesignSystem.rating.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.hasReviewed ? Icons.check_circle_rounded : Icons.star_rounded,
              color: widget.hasReviewed
                  ? DesignSystem.getTextTertiary(widget.isDark)
                  : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              widget.hasReviewed ? 'Reviewed' : 'Review',
              style: TextStyle(
                color: widget.hasReviewed
                    ? DesignSystem.getTextTertiary(widget.isDark)
                    : Colors.white,
                fontSize: DesignSystem.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
