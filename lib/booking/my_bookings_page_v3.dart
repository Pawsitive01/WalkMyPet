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

/// MyBookingsPageV3 - World-Class Booking Management Experience
///
/// A premium, elegant booking management page designed with top-tier
/// consumer app standards (Instagram, TikTok, Snapchat, X level polish).
///
/// Design Principles:
/// - Clean, modern, and stylish layout that feels premium yet friendly
/// - Optimized for clarity, speed, and ease of use
/// - Trustworthy, calm, and intuitive for pet owners
/// - Elegant micro-interactions and smooth animations
/// - Status-aware visual hierarchy with subtle color accents
///
/// Key Features:
/// - Collapsed calendar by default with smooth expand animation
/// - Segmented tab control with clear category separation
/// - Elegant booking cards with modern card design
/// - Friendly empty states with reassuring copy
/// - Pull-to-refresh with haptic feedback

class MyBookingsPageV3 extends StatefulWidget {
  const MyBookingsPageV3({super.key});

  @override
  State<MyBookingsPageV3> createState() => _MyBookingsPageV3State();
}

class _MyBookingsPageV3State extends State<MyBookingsPageV3>
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
  late AnimationController _fabAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _calendarScaleAnimation;
  late Animation<double> _calendarOpacityAnimation;
  late Animation<double> _chevronRotationAnimation;
  late Animation<double> _fabScaleAnimation;

  // Scroll controller for FAB visibility
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  // Tab categories with refined styling
  final List<BookingCategory> _categories = [
    BookingCategory(
      label: 'Pending',
      shortLabel: 'Pending',
      status: BookingStatus.pending,
      color: const Color(0xFFF59E0B), // Warm amber
      lightColor: const Color(0xFFFEF3C7),
      icon: Icons.schedule_rounded,
      emptyIcon: Icons.hourglass_empty_rounded,
      emptyTitle: 'No Pending Bookings',
      emptySubtitle:
          'When you book a service, it will appear here awaiting confirmation.',
      emptyAction: 'Book a Walk',
    ),
    BookingCategory(
      label: 'Confirmed',
      shortLabel: 'Confirmed',
      status: BookingStatus.confirmed,
      color: const Color(0xFF6366F1), // Indigo
      lightColor: const Color(0xFFE0E7FF),
      icon: Icons.check_circle_rounded,
      emptyIcon: Icons.event_available_rounded,
      emptyTitle: 'No Confirmed Bookings',
      emptySubtitle: 'Confirmed walks and services will show up here.',
      emptyAction: null,
    ),
    BookingCategory(
      label: 'Completed',
      shortLabel: 'Done',
      status: BookingStatus.completed,
      color: const Color(0xFF10B981), // Emerald
      lightColor: const Color(0xFFD1FAE5),
      icon: Icons.task_alt_rounded,
      emptyIcon: Icons.sentiment_satisfied_alt_rounded,
      emptyTitle: 'No Completed Bookings',
      emptySubtitle: 'Your finished services will be saved here for reference.',
      emptyAction: null,
    ),
    BookingCategory(
      label: 'Cancelled',
      shortLabel: 'Cancelled',
      status: BookingStatus.cancelled,
      color: const Color(0xFF94A3B8), // Slate (muted, non-aggressive)
      lightColor: const Color(0xFFF1F5F9),
      icon: Icons.cancel_outlined,
      emptyIcon: Icons.block_rounded,
      emptyTitle: 'No Cancelled Bookings',
      emptySubtitle: 'Cancelled bookings will appear here.',
      emptyAction: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBookings();
    _setupScrollListener();
  }

  void _initAnimations() {
    // Page entrance animation
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Calendar expand/collapse animation
    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _calendarScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _calendarAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _calendarOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _calendarAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _chevronRotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _calendarAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // FAB animation
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _pageAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset < 100;
      if (shouldShow != _showFab) {
        setState(() => _showFab = shouldShow);
        if (_showFab) {
          _fabAnimationController.forward();
        } else {
          _fabAnimationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _calendarAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
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
            _showSnackBar('Unable to load bookings', isError: true);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Unable to load bookings', isError: true);
      }
    }
  }

  Map<DateTime, List<Booking>> _groupBookingsByDate(List<Booking> bookings) {
    Map<DateTime, List<Booking>> grouped = {};
    for (var booking in bookings) {
      final date =
          DateTime(booking.date.year, booking.date.month, booking.date.day);
      grouped.putIfAbsent(date, () => []).add(booking);
    }
    return grouped;
  }

  List<Booking> _getBookingsForCategory(BookingStatus status) {
    var allBookings = _bookingsByDate.values.expand((list) => list).toList();

    // Filter by selected date if calendar date is selected
    if (_selectedDay != null && _isCalendarExpanded) {
      final normalizedDay =
          DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
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
        backgroundColor: isError ? DesignSystem.error : DesignSystem.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        ),
        margin: const EdgeInsets.all(DesignSystem.space2),
        elevation: 0,
        duration: const Duration(seconds: 3),
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
                displacement: 60,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(isDark)),
                        SliverToBoxAdapter(
                            child: _buildCalendarSection(isDark)),
                        SliverToBoxAdapter(child: _buildTabBar(isDark)),
                        SliverToBoxAdapter(
                            child: _buildCategoryHeader(isDark)),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            8,
                            20,
                            100, // Extra bottom padding for FAB
                          ),
                          sliver: _buildBookingsList(isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant loading animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.9 + (0.1 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignSystem.ownerPrimary.withValues(alpha: 0.12),
                    DesignSystem.walkerPrimary.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating ring
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DesignSystem.ownerPrimary.withValues(alpha: 0.3),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                  // Inner indicator
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        DesignSystem.ownerPrimary,
                      ),
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Center icon
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DesignSystem.ownerPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pets_rounded,
                      color: DesignSystem.ownerPrimary,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your bookings',
            style: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Just a moment...',
            style: TextStyle(
              color: DesignSystem.getTextTertiary(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button with refined design
          _PremiumBackButton(
            isDark: isDark,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bookings',
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your pet care services',
                  style: TextStyle(
                    color: DesignSystem.getTextTertiary(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          // Quick stats indicator
          _QuickStatsIndicator(
            count: _bookingsByDate.values.expand((l) => l).length,
            isDark: isDark,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _CalendarToggle(
            isDark: isDark,
            isExpanded: _isCalendarExpanded,
            selectedDay: _selectedDay,
            rotationAnimation: _chevronRotationAnimation,
            onTap: _toggleCalendar,
            onClearDate: _selectedDay != null
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedDay = null);
                  }
                : null,
          ),
        ),
        // Animated calendar
        AnimatedBuilder(
          animation: _calendarAnimationController,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                heightFactor: _calendarAnimationController.value,
                child: Opacity(
                  opacity: _calendarOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _calendarScaleAnimation.value,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
              _selectedDay =
                  isSameDay(_selectedDay, selectedDay) ? null : selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: DesignSystem.ownerPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: DesignSystem.ownerPrimary,
              fontWeight: FontWeight.w700,
            ),
            selectedDecoration: const BoxDecoration(
              gradient: DesignSystem.ownerGradient,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            markerDecoration: BoxDecoration(
              color: DesignSystem.walkerPrimary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerSize: 5,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            weekendTextStyle: TextStyle(
              color: DesignSystem.ownerPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            defaultTextStyle: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontWeight: FontWeight.w500,
            ),
            cellMargin: const EdgeInsets.all(3),
            cellPadding: const EdgeInsets.all(0),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            leftChevronIcon: _CalendarChevron(
              icon: Icons.chevron_left_rounded,
              isDark: isDark,
            ),
            rightChevronIcon: _CalendarChevron(
              icon: Icons.chevron_right_rounded,
              isDark: isDark,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: DesignSystem.getTextTertiary(isDark),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            weekendStyle: TextStyle(
              color: DesignSystem.ownerPrimary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          daysOfWeekHeight: 32,
          rowHeight: 44,
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final category = _categories[index];
          final isSelected = _selectedTabIndex == index;
          final count = _getCountForCategory(category.status);

          return Expanded(
            child: _TabSegment(
              label: category.shortLabel,
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

  Widget _buildCategoryHeader(bool isDark) {
    final category = _categories[_selectedTabIndex];
    final bookings = _getBookingsForCategory(category.status);
    final count = bookings.length;

    String subtitle;
    if (_selectedDay != null && _isCalendarExpanded) {
      subtitle = DateFormat('EEEE, MMM d').format(_selectedDay!);
    } else {
      subtitle = count == 1 ? '1 booking' : '$count bookings';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          // Category icon with gradient background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  category.color.withValues(alpha: 0.15),
                  category.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Category title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.label} Bookings',
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: DesignSystem.getTextTertiary(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Clear date filter chip
          if (_selectedDay != null && _isCalendarExpanded)
            _ClearDateChip(
              color: category.color,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedDay = null);
              },
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
              bottom: index == bookings.length - 1 ? 0 : 12,
            ),
            child: _PremiumBookingCard(
              booking: booking,
              isDark: isDark,
              onReviewTap: () => _showReviewDialog(booking),
              reviewService: _reviewService,
              animationDelay: index * 50,
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated empty state
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      category.color.withValues(alpha: 0.12),
                      category.color.withValues(alpha: 0.02),
                    ],
                    radius: 0.8,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: category.lightColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: category.color.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      category.emptyIcon,
                      size: 36,
                      color: category.color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              category.emptyTitle,
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                category.emptySubtitle,
                style: TextStyle(
                  color: DesignSystem.getTextTertiary(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (category.emptyAction != null) ...[
              const SizedBox(height: 28),
              _PremiumActionButton(
                label: category.emptyAction!,
                icon: Icons.add_rounded,
                color: DesignSystem.ownerPrimary,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to home page to select a walker and book
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB(bool isDark) {
    // Only show FAB for pending tab as a quick action
    if (_selectedTabIndex != 0) return null;

    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: DesignSystem.ownerPrimary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            // Navigate to home page to select a walker and book
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          backgroundColor: DesignSystem.ownerPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.add_rounded,
            color: Colors.white,
          ),
          label: const Text(
            'Book a Walk',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReviewDialog(Booking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please log in to leave a review', isError: true);
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
      _showSnackBar('Review submitted successfully!');
      setState(() {});
    }
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Booking category with visual properties
class BookingCategory {
  final String label;
  final String shortLabel;
  final BookingStatus status;
  final Color color;
  final Color lightColor;
  final IconData icon;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String? emptyAction;

  const BookingCategory({
    required this.label,
    required this.shortLabel,
    required this.status,
    required this.color,
    required this.lightColor,
    required this.icon,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyAction,
  });
}

// =============================================================================
// PREMIUM WIDGETS
// =============================================================================

/// Premium back button with refined design
class _PremiumBackButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const _PremiumBackButton({
    required this.isDark,
    required this.onPressed,
  });

  @override
  State<_PremiumBackButton> createState() => _PremiumBackButtonState();
}

class _PremiumBackButtonState extends State<_PremiumBackButton> {
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
        duration: const Duration(milliseconds: 100),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _isPressed
              ? DesignSystem.getSurface2(widget.isDark)
              : DesignSystem.getSurface(widget.isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DesignSystem.getBorderColor(widget.isDark, opacity: 0.06),
          ),
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: widget.isDark ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Icon(
            Icons.arrow_back_rounded,
            color: DesignSystem.getTextPrimary(widget.isDark),
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Quick stats indicator in header
class _QuickStatsIndicator extends StatelessWidget {
  final int count;
  final bool isDark;

  const _QuickStatsIndicator({
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignSystem.ownerPrimary.withValues(alpha: 0.12),
            DesignSystem.walkerPrimary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: DesignSystem.ownerPrimary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendar toggle button
class _CalendarToggle extends StatefulWidget {
  final bool isDark;
  final bool isExpanded;
  final DateTime? selectedDay;
  final Animation<double> rotationAnimation;
  final VoidCallback onTap;
  final VoidCallback? onClearDate;

  const _CalendarToggle({
    required this.isDark,
    required this.isExpanded,
    required this.selectedDay,
    required this.rotationAnimation,
    required this.onTap,
    this.onClearDate,
  });

  @override
  State<_CalendarToggle> createState() => _CalendarToggleState();
}

class _CalendarToggleState extends State<_CalendarToggle> {
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isPressed
              ? DesignSystem.getSurface2(widget.isDark)
              : DesignSystem.getSurface(widget.isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isExpanded
                ? DesignSystem.ownerPrimary.withValues(alpha: 0.25)
                : DesignSystem.getBorderColor(widget.isDark, opacity: 0.06),
            width: widget.isExpanded ? 1.5 : 1,
          ),
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: widget.isDark ? 0.15 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Calendar icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: widget.isExpanded
                    ? DesignSystem.ownerGradient
                    : LinearGradient(
                        colors: [
                          DesignSystem.ownerPrimary.withValues(alpha: 0.12),
                          DesignSystem.ownerPrimary.withValues(alpha: 0.06),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color:
                    widget.isExpanded ? Colors.white : DesignSystem.ownerPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Text content
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isExpanded
                        ? 'Tap to collapse'
                        : 'Tap to expand calendar',
                    style: TextStyle(
                      color: DesignSystem.getTextTertiary(widget.isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            RotationTransition(
              turns: widget.rotationAnimation,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DesignSystem.getSurface2(widget.isDark)
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: DesignSystem.getTextTertiary(widget.isDark),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendar chevron navigation button
class _CalendarChevron extends StatelessWidget {
  final IconData icon;
  final bool isDark;

  const _CalendarChevron({
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface2(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: DesignSystem.getTextSecondary(isDark),
        size: 18,
      ),
    );
  }
}

/// Tab segment widget
class _TabSegment extends StatefulWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TabSegment> createState() => _TabSegmentState();
}

class _TabSegmentState extends State<_TabSegment> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
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
                      .withValues(alpha: 0.5)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isSelected
                          ? Colors.white
                          : DesignSystem.getTextSecondary(widget.isDark),
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.count.toString(),
                      style: TextStyle(
                        color: widget.isSelected ? Colors.white : widget.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clear date filter chip
class _ClearDateChip extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;

  const _ClearDateChip({
    required this.color,
    required this.onTap,
  });

  @override
  State<_ClearDateChip> createState() => _ClearDateChipState();
}

class _ClearDateChipState extends State<_ClearDateChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.color.withValues(alpha: 0.2)
              : widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close_rounded,
              color: widget.color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Clear',
              style: TextStyle(
                color: widget.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium action button for empty states
class _PremiumActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PremiumActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PremiumActionButton> createState() => _PremiumActionButtonState();
}

class _PremiumActionButtonState extends State<_PremiumActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium booking card with elegant design
class _PremiumBookingCard extends StatefulWidget {
  final Booking booking;
  final bool isDark;
  final VoidCallback onReviewTap;
  final ReviewService reviewService;
  final int animationDelay;

  const _PremiumBookingCard({
    required this.booking,
    required this.isDark,
    required this.onReviewTap,
    required this.reviewService,
    this.animationDelay = 0,
  });

  @override
  State<_PremiumBookingCard> createState() => _PremiumBookingCardState();
}

class _PremiumBookingCardState extends State<_PremiumBookingCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

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
        return const Color(0xFF94A3B8);
    }
  }

  Color get _statusLightColor {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return const Color(0xFFFEF3C7);
      case BookingStatus.confirmed:
        return const Color(0xFFE0E7FF);
      case BookingStatus.awaitingConfirmation:
        return const Color(0xFFDBEAFE);
      case BookingStatus.completed:
        return const Color(0xFFD1FAE5);
      case BookingStatus.cancelled:
        return const Color(0xFFF1F5F9);
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
        return Icons.task_alt_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
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
        return const Color(0xFF10B981);
      case 'grooming':
        return const Color(0xFFEC4899);
      case 'sitting':
        return const Color(0xFF6366F1);
      case 'training':
        return const Color(0xFFF59E0B);
      case 'feeding':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to booking details
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                color: DesignSystem.getSurface(widget.isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      DesignSystem.getBorderColor(widget.isDark, opacity: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: widget.isDark ? 0.2 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status gradient bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _statusColor,
                          _statusColor.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        _buildHeader(),
                        const SizedBox(height: 14),
                        // Details section
                        _buildDetailsSection(),
                        // Services
                        if (widget.booking.services != null &&
                            widget.booking.services!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildServicesRow(),
                        ],
                        const SizedBox(height: 14),
                        // Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Walker avatar placeholder
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignSystem.walkerPrimary.withValues(alpha: 0.15),
                DesignSystem.walkerSecondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              widget.booking.walkerName.isNotEmpty
                  ? widget.booking.walkerName[0].toUpperCase()
                  : 'W',
              style: TextStyle(
                color: DesignSystem.walkerPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Walker info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.booking.walkerName,
                      style: TextStyle(
                        color: DesignSystem.getTextPrimary(widget.isDark),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    color: DesignSystem.ownerPrimary.withValues(alpha: 0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.booking.dogName,
                    style: TextStyle(
                      color: DesignSystem.getTextSecondary(widget.isDark),
                      fontSize: 14,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusLightColor,
            borderRadius: BorderRadius.circular(10),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface2(widget.isDark).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Date and time row
          Row(
            children: [
              _InfoTile(
                icon: Icons.calendar_today_rounded,
                label: DateFormat('EEE, MMM d').format(widget.booking.date),
                color: DesignSystem.walkerPrimary,
                isDark: widget.isDark,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                icon: Icons.access_time_rounded,
                label: widget.booking.time,
                color: DesignSystem.ownerPrimary,
                isDark: widget.isDark,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                icon: Icons.timer_outlined,
                label: '${widget.booking.duration}m',
                color: DesignSystem.walkerSecondary,
                isDark: widget.isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Location row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignSystem.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: DesignSystem.success,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.booking.location,
                  style: TextStyle(
                    color: DesignSystem.getTextSecondary(widget.isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.booking.services!.map((service) {
        final color = _getServiceColor(service);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _statusColor.withValues(alpha: 0.12),
                _statusColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.booking.price.toStringAsFixed(2),
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // Action button
        if (widget.booking.status == BookingStatus.completed)
          FutureBuilder<bool>(
            future: widget.reviewService.hasUserReviewedBooking(
              widget.booking.id,
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              final hasReviewed = snapshot.data ?? false;
              return _ReviewActionButton(
                hasReviewed: hasReviewed,
                isDark: widget.isDark,
                onTap: hasReviewed ? null : widget.onReviewTap,
              );
            },
          ),
      ],
    );
  }
}

/// Info tile for booking details
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _InfoTile({
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Review action button
class _ReviewActionButton extends StatefulWidget {
  final bool hasReviewed;
  final bool isDark;
  final VoidCallback? onTap;

  const _ReviewActionButton({
    required this.hasReviewed,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_ReviewActionButton> createState() => _ReviewActionButtonState();
}

class _ReviewActionButtonState extends State<_ReviewActionButton> {
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
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: widget.hasReviewed
              ? null
              : LinearGradient(
                  colors: _isPressed
                      ? [
                          DesignSystem.rating.withValues(alpha: 0.9),
                          DesignSystem.rating.withValues(alpha: 0.7),
                        ]
                      : [
                          DesignSystem.rating,
                          DesignSystem.rating.withValues(alpha: 0.85),
                        ],
                ),
          color: widget.hasReviewed
              ? DesignSystem.getSurface2(widget.isDark)
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.hasReviewed || _isPressed
              ? null
              : [
                  BoxShadow(
                    color: DesignSystem.rating.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
