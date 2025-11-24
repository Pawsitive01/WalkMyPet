import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/booking_service.dart';

class MyBookingsPageRedesigned extends StatefulWidget {
  const MyBookingsPageRedesigned({super.key});

  @override
  State<MyBookingsPageRedesigned> createState() => _MyBookingsPageRedesignedState();
}

class _MyBookingsPageRedesignedState extends State<MyBookingsPageRedesigned>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Booking>> _bookingsByDate = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _loadBookings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ My Bookings: No user logged in');
      setState(() => _isLoading = false);
      _showSnackBar('Please log in to view bookings', const Color(0xFFF59E0B));
      return;
    }

    print('📱 My Bookings: Loading bookings for user ${user.uid}');
    setState(() => _isLoading = true);

    try {
      _bookingService.getOwnerBookings(user.uid).listen(
        (bookings) {
          print('✅ My Bookings: Received ${bookings.length} bookings from Firebase');
          if (mounted) {
            setState(() {
              _bookingsByDate = _groupBookingsByDate(bookings);
              _isLoading = false;
            });
            print('📊 My Bookings: Grouped into ${_bookingsByDate.length} dates');
          }
        },
        onError: (error) {
          print('❌ My Bookings: Stream error: $error');
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar('Error loading bookings: $error', const Color(0xFFEF4444));
          }
        },
      );
    } catch (e) {
      print('❌ My Bookings: Exception: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading bookings: $e', const Color(0xFFEF4444));
      }
    }
  }

  Map<DateTime, List<Booking>> _groupBookingsByDate(List<Booking> bookings) {
    Map<DateTime, List<Booking>> grouped = {};
    for (var booking in bookings) {
      final date = DateTime(booking.date.year, booking.date.month, booking.date.day);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(booking);
    }
    return grouped;
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    var bookings = _bookingsByDate[normalizedDay] ?? [];

    // Filter bookings based on selected filter
    if (_selectedFilter != 'All') {
      bookings = bookings.where((b) {
        switch (_selectedFilter) {
          case 'Pending':
            return b.status == BookingStatus.pending;
          case 'Confirmed':
            return b.status == BookingStatus.confirmed;
          case 'Completed':
            return b.status == BookingStatus.completed;
          case 'Cancelled':
            return b.status == BookingStatus.cancelled;
          default:
            return true;
        }
      }).toList();
    }

    return bookings;
  }

  List<Booking> _getAllFilteredBookings() {
    var allBookings = _bookingsByDate.values.expand((list) => list).toList();
    allBookings.sort((a, b) => b.date.compareTo(a.date));

    if (_selectedFilter != 'All') {
      allBookings = allBookings.where((b) {
        switch (_selectedFilter) {
          case 'Pending':
            return b.status == BookingStatus.pending;
          case 'Confirmed':
            return b.status == BookingStatus.confirmed;
          case 'Completed':
            return b.status == BookingStatus.completed;
          case 'Cancelled':
            return b.status == BookingStatus.cancelled;
          default:
            return true;
        }
      }).toList();
    }

    return allBookings;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFF59E0B);
      case BookingStatus.confirmed:
        return const Color(0xFF6366F1);
      case BookingStatus.completed:
        return const Color(0xFF10B981);
      case BookingStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.completed:
        return Icons.verified_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Gradient background
          _buildGradientBackground(),

          // Main content
          SafeArea(
            child: _isLoading
                ? _buildLoadingState(isDark)
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    color: const Color(0xFFEC4899),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        _buildSliverAppBar(isDark),
                        SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _buildFilterChips(isDark),
                              const SizedBox(height: 16),
                              _buildStatsCards(isDark),
                              const SizedBox(height: 24),
                              _buildCalendar(isDark),
                              const SizedBox(height: 24),
                              _buildBookingsList(isDark),
                              const SizedBox(height: 32),
                            ],
                          ),
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

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEC4899).withAlpha((0.05 * 255).round()),
            const Color(0xFF6366F1).withAlpha((0.05 * 255).round()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEC4899).withAlpha((0.1 * 255).round()),
                  const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withAlpha((0.3 * 255).round()),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Loading your bookings...',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withAlpha((0.9 * 255).round())
              : Colors.white.withAlpha((0.9 * 255).round()),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha((0.1 * 255).round())
                : Colors.black.withAlpha((0.05 * 255).round()),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEC4899).withAlpha((0.9 * 255).round()),
                const Color(0xFF6366F1).withAlpha((0.9 * 255).round()),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withAlpha((0.3 * 255).round()),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'My Bookings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          Color chipColor;
          switch (filter) {
            case 'Pending':
              chipColor = const Color(0xFFF59E0B);
              break;
            case 'Confirmed':
              chipColor = const Color(0xFF6366F1);
              break;
            case 'Completed':
              chipColor = const Color(0xFF10B981);
              break;
            case 'Cancelled':
              chipColor = const Color(0xFFEF4444);
              break;
            default:
              chipColor = const Color(0xFFEC4899);
          }

          return Padding(
            padding: EdgeInsets.only(right: index == filters.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            chipColor,
                            chipColor.withAlpha((0.8 * 255).round()),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : isDark
                          ? const Color(0xFF1E293B).withAlpha((0.5 * 255).round())
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? chipColor
                        : chipColor.withAlpha((0.3 * 255).round()),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: chipColor.withAlpha((0.4 * 255).round()),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final allBookings = _bookingsByDate.values.expand((list) => list).toList();
    final pending = allBookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmed = allBookings.where((b) => b.status == BookingStatus.confirmed).length;
    final completed = allBookings.where((b) => b.status == BookingStatus.completed).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              title: 'Pending',
              count: pending,
              icon: Icons.schedule_rounded,
              gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              title: 'Active',
              count: confirmed,
              icon: Icons.check_circle_rounded,
              gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              title: 'Done',
              count: completed,
              icon: Icons.verified_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String title,
    required int count,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient[0].withAlpha((0.3 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withAlpha((0.1 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha((0.1 * 255).round())
              : Colors.black.withAlpha((0.05 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(((isDark ? 0.2 : 0.05) * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getBookingsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
            ),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: const Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            color: const Color(0xFFEC4899),
            fontWeight: FontWeight.w600,
          ),
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: const Color(0xFFEC4899).withAlpha((0.8 * 255).round()),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(bool isDark) {
    final bookings = _selectedDay != null
        ? _getBookingsForDay(_selectedDay!)
        : _getAllFilteredBookings();

    if (bookings.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEC4899).withAlpha((0.2 * 255).round()),
                      const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFEC4899),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedDay != null
                    ? DateFormat('MMMM dd, yyyy').format(_selectedDay!)
                    : 'All Bookings',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bookings.map((booking) => _buildBookingCard(booking, isDark)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, bool isDark) {
    final statusColor = _getStatusColor(booking.status);
    final statusIcon = _getStatusIcon(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha((0.1 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Colored stripe on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [statusColor, statusColor.withAlpha((0.6 * 255).round())],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.walkerName,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.pets_rounded,
                                  size: 14,
                                  color: const Color(0xFFEC4899),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  booking.dogName,
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withAlpha((0.2 * 255).round()),
                              statusColor.withAlpha((0.1 * 255).round()),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.status.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: DateFormat('MMM dd, yyyy').format(booking.date),
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: booking.time,
                          color: const Color(0xFFEC4899),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.timer_rounded,
                          label: 'Duration',
                          value: '${booking.duration} min',
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: booking.location,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Services Section
                  if (booking.services != null && booking.services!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services_rounded,
                                color: const Color(0xFFEC4899),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Services',
                                style: TextStyle(
                                  color: const Color(0xFFEC4899),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: booking.services!.map((service) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getServiceColor(service).withAlpha((0.15 * 255).round()),
                                      _getServiceColor(service).withAlpha((0.05 * 255).round()),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getServiceColor(service).withAlpha((0.3 * 255).round()),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getServiceIcon(service),
                                      color: _getServiceColor(service),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      service,
                                      style: TextStyle(
                                        color: _getServiceColor(service),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withAlpha((0.2 * 255).round()),
                          statusColor.withAlpha((0.1 * 255).round()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              color: statusColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Total Price',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${booking.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.notes!,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEC4899).withAlpha((0.1 * 255).round()),
                    const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Bookings',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDay != null
                  ? 'No bookings on this day'
                  : 'You haven\'t made any bookings yet',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
