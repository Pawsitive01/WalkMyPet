import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/booking/checkout_page.dart';
import 'package:walkmypet/booking/recurring_booking_page.dart';
import 'package:walkmypet/design_system.dart';
import 'package:walkmypet/widgets/location_picker.dart';

class BookingPage extends StatefulWidget {
  final Walker walker;

  const BookingPage({super.key, required this.walker});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final Map<String, int> _serviceDurations = {};
  final Set<String> _selectedServices = {};
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final List<int> _durationOptions = [30, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: DesignSystem.animationMedium,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignSystem.curveEaseOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignSystem.curveEaseOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isFixedPriceService(String service) {
    return service.toLowerCase() == 'grooming';
  }

  double get _subtotalPrice {
    double total = 0;
    for (var service in _selectedServices) {
      final servicePrice = widget.walker.servicePrices[service] ?? widget.walker.hourlyRate;
      if (_isFixedPriceService(service)) {
        total += servicePrice;
      } else {
        final duration = _serviceDurations[service] ?? 60;
        final hours = duration / 60;
        total += servicePrice * hours;
      }
    }
    return total;
  }

  double get _transactionFee {
    final subtotal = _subtotalPrice;
    return (subtotal * 0.029) + 0.30;
  }

  double get _totalPrice {
    return _subtotalPrice + _transactionFee;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedServices.isEmpty) {
      _showSnackBar(
        'Please select at least one service',
        const Color(0xFFF59E0B),
        Icons.info_outline_rounded,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final ownerProfile = await _userService.getUser(user.uid);
      if (ownerProfile == null) throw 'Owner profile not found';

      final ownerData = ownerProfile.toFirestore();

      // Verify walker has a valid user ID
      if (widget.walker.userId == null || widget.walker.userId!.isEmpty) {
        throw 'Walker user ID is missing. Please try selecting a different walker.';
      }

      // Create service details map
      final serviceDetails = <String, dynamic>{};
      for (var service in _selectedServices) {
        serviceDetails[service] = {
          'duration': _serviceDurations[service] ?? (_isFixedPriceService(service) ? 0 : 60),
          'price': widget.walker.servicePrices[service] ?? widget.walker.hourlyRate,
        };
      }

      final booking = Booking(
        id: '',
        ownerId: user.uid,
        walkerId: widget.walker.userId!,
        ownerName: ownerProfile.displayName ?? 'Unknown',
        walkerName: widget.walker.name,
        dogName: ownerData['dogName'] ?? 'My Dog',
        date: _selectedDate,
        time: _selectedTime.format(context),
        duration: _serviceDurations.values.isNotEmpty
            ? _serviceDurations.values.reduce((a, b) => a > b ? a : b)
            : 60,
        location: _locationController.text.trim(),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        price: _totalPrice,
        status: BookingStatus.pending,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        services: _selectedServices.toList(),
        serviceDetails: serviceDetails,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to checkout page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutPage(
              bookingData: booking,
              walker: widget.walker,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error: $e',
          const Color(0xFFEF4444),
          Icons.error_outline_rounded,
        );
        setState(() => _isLoading = false);
      }
    }
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
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isDark)
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
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
                      child: _buildBody(isDark),
                    ),
                  ),
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
            padding: EdgeInsets.all(DesignSystem.space3),
            decoration: BoxDecoration(
              color: DesignSystem.walkerPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: DesignSystem.shadowGlow(DesignSystem.walkerPrimary),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.walkerPrimary),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: DesignSystem.space4),
          Text(
            'Confirming your booking...',
            style: TextStyle(
              fontSize: DesignSystem.h3,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: DesignSystem.getTextPrimary(isDark),
            ),
          ),
          SizedBox(height: DesignSystem.space1),
          Text(
            'This will only take a moment',
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: EdgeInsets.all(DesignSystem.space1),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
      title: Text(
        'Book Service',
        style: TextStyle(
          fontSize: DesignSystem.h2,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: DesignSystem.getTextPrimary(isDark),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(DesignSystem.space2),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalkerCard(isDark),
            SizedBox(height: DesignSystem.space3),
            _buildDateTimeSection(isDark),
            SizedBox(height: DesignSystem.space3),
            _buildServicesSection(isDark),
            SizedBox(height: DesignSystem.space3),
            if (_selectedServices.isNotEmpty) ...[
              _buildPriceBreakdown(isDark),
              SizedBox(height: DesignSystem.space3),
            ],
            _buildLocationSection(isDark),
            SizedBox(height: DesignSystem.space3),
            _buildNotesSection(isDark),
            SizedBox(height: DesignSystem.space3),
            _buildRecurringOption(isDark),
            SizedBox(height: DesignSystem.space3),
            _buildPriceSummary(isDark),
            SizedBox(height: DesignSystem.space3),
            _buildConfirmButton(isDark),
            SizedBox(height: DesignSystem.space5),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkerCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space1_5),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark),
          width: 1,
        ),
        boxShadow: DesignSystem.shadowCard(Colors.black),
      ),
      child: Row(
        children: [
          // Compressed avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignSystem.walkerPrimary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: widget.walker.imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: widget.walker.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: DesignSystem.walkerPrimary.withValues(alpha: 0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: DesignSystem.walkerPrimary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: DesignSystem.walkerPrimary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            color: DesignSystem.walkerPrimary,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: DesignSystem.walkerPrimary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          color: DesignSystem.walkerPrimary,
                          size: 24,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(width: DesignSystem.space1_5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.walker.name,
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: DesignSystem.space0_5),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: DesignSystem.getTextTertiary(isDark),
                    ),
                    SizedBox(width: DesignSystem.space0_5),
                    Expanded(
                      child: Text(
                        widget.walker.location,
                        style: TextStyle(
                          color: DesignSystem.getTextSecondary(isDark),
                          fontSize: DesignSystem.small,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: DesignSystem.space1),
          // Compact badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSystem.space1,
                  vertical: DesignSystem.space0_5,
                ),
                decoration: BoxDecoration(
                  color: DesignSystem.rating.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusTiny),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: DesignSystem.rating,
                      size: 12,
                    ),
                    SizedBox(width: DesignSystem.space0_5),
                    Text(
                      widget.walker.rating.toString(),
                      style: TextStyle(
                        color: DesignSystem.rating,
                        fontSize: DesignSystem.small,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.walker.hasPoliceClearance) ...[
                SizedBox(height: DesignSystem.space0_5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignSystem.space1,
                    vertical: DesignSystem.space0_5,
                  ),
                  decoration: BoxDecoration(
                    color: DesignSystem.verified.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusTiny),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: DesignSystem.verified,
                        size: 10,
                      ),
                      SizedBox(width: DesignSystem.space0_5),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: DesignSystem.verified,
                          fontSize: DesignSystem.tiny,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                      const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
                      const Color(0xFFEC4899).withAlpha((0.2 * 255).round()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Date & Time',
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
          Row(
            children: [
              Expanded(
                child: _buildDateTimeButton(
                  isDark: isDark,
                  icon: Icons.today_rounded,
                  label: 'Date',
                  value: DateFormat('MMM dd, yyyy').format(_selectedDate),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeButton(
                  isDark: isDark,
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: _selectedTime.format(context),
                  onTap: _selectTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF6366F1),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.star_rounded,
                  color: Color(0xFFEC4899),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Services',
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.walker.services.map((service) {
              final isSelected = _selectedServices.contains(service);
              final color = _getServiceColor(service);
              final icon = _getServiceIcon(service);
              final price = widget.walker.servicePrices[service] ?? widget.walker.hourlyRate;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedServices.remove(service);
                      _serviceDurations.remove(service);
                    } else {
                      _selectedServices.add(service);
                      if (!_isFixedPriceService(service)) {
                        _serviceDurations[service] = 60;
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              color,
                              color.withAlpha((0.8 * 255).round()),
                            ],
                          )
                        : null,
                    color: isSelected ? null : isDark
                        ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : color.withAlpha((0.3 * 255).round()),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withAlpha((0.4 * 255).round()),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? Colors.white : color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            service,
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
                          const SizedBox(height: 2),
                          Text(
                            '\$$price${_isFixedPriceService(service) ? '' : '/hr'}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withAlpha((0.9 * 255).round())
                                  : color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedServices.any((s) => !_isFixedPriceService(s))) ...[
            const SizedBox(height: 20),
            ..._selectedServices.where((s) => !_isFixedPriceService(s)).map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDurationSelector(service, isDark),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationSelector(String service, bool isDark) {
    final color = _getServiceColor(service);
    final duration = _serviceDurations[service] ?? 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$service Duration',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withAlpha((0.2 * 255).round()),
                    color.withAlpha((0.1 * 255).round()),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$duration min',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _durationOptions.map((mins) {
            final isSelected = duration == mins;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _serviceDurations[service] = mins;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : isDark
                          ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : color.withAlpha((0.2 * 255).round()),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  '${mins}m',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2_5),
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
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignSystem.space1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEC4899).withValues(alpha: 0.2),
                      const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFEC4899),
                  size: 20,
                ),
              ),
              SizedBox(width: DesignSystem.space1_5),
              Text(
                'Price Breakdown',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEC4899).withValues(alpha: 0.3),
                  const Color(0xFF6366F1).withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          SizedBox(height: DesignSystem.space2),

          // Selected Services
          for (var service in _selectedServices) ...[
            _buildServiceLine(service, isDark),
          ],

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(vertical: DesignSystem.space1),
            child: Container(
              height: 1,
              color: DesignSystem.getBorderColor(isDark),
            ),
          ),

          // Subtotal
          Padding(
            padding: EdgeInsets.only(bottom: DesignSystem.space1_5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    color: DesignSystem.getTextSecondary(isDark),
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${_subtotalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Transaction Fee
          Padding(
            padding: EdgeInsets.only(bottom: DesignSystem.space1_5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Fee',
                  style: TextStyle(
                    color: DesignSystem.getTextTertiary(isDark),
                    fontSize: DesignSystem.small,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${_transactionFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: DesignSystem.getTextTertiary(isDark),
                    fontSize: DesignSystem.small,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Thick Divider
          Padding(
            padding: EdgeInsets.symmetric(vertical: DesignSystem.space1),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEC4899).withValues(alpha: 0.5),
                    const Color(0xFF6366F1).withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSystem.space2,
                  vertical: DesignSystem.space1,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEC4899).withValues(alpha: 0.2),
                      const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: Text(
                  '\$${_totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.h2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceLine(String service, bool isDark) {
    final servicePrice = widget.walker.servicePrices[service] ?? widget.walker.hourlyRate;
    final isFixed = _isFixedPriceService(service);
    final duration = isFixed ? 0 : (_serviceDurations[service] ?? 60);
    final price = isFixed ? servicePrice : (servicePrice * duration / 60);

    return Padding(
      padding: EdgeInsets.only(bottom: DesignSystem.space1_5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  _getServiceIcon(service),
                  size: 16,
                  color: _getServiceColor(service),
                ),
                SizedBox(width: DesignSystem.space1),
                Expanded(
                  child: Text(
                    '$service${!isFixed ? " ($duration min)" : ""}',
                    style: TextStyle(
                      color: DesignSystem.getTextSecondary(isDark),
                      fontSize: DesignSystem.body,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: DesignSystem.body,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLocationSection(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  DesignSystem.surfaceDark,
                  DesignSystem.backgroundDark,
                ]
              : [
                  DesignSystem.surfaceLight,
                  DesignSystem.surface2Light,
                ],
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark),
          width: 1,
        ),
        boxShadow: DesignSystem.shadowCard(
          isDark ? Colors.black : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignSystem.space1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignSystem.success.withValues(alpha: 0.2),
                      DesignSystem.success.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: DesignSystem.success,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignSystem.space1_5),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: DesignSystem.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),

          // Map Picker Button
          InkWell(
            onTap: _openLocationPicker,
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            child: Container(
              padding: EdgeInsets.all(DesignSystem.space2),
              decoration: BoxDecoration(
                color: DesignSystem.getSurface2(isDark),
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                border: Border.all(
                  color: _selectedLatitude != null
                      ? DesignSystem.success.withValues(alpha: 0.3)
                      : DesignSystem.getBorderColor(isDark, opacity: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(DesignSystem.space1_5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignSystem.success.withValues(alpha: 0.15),
                          DesignSystem.success.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                    ),
                    child: Icon(
                      _selectedLatitude != null
                          ? Icons.map_rounded
                          : Icons.add_location_alt_rounded,
                      color: DesignSystem.success,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: DesignSystem.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLatitude != null
                              ? 'Location Selected'
                              : 'Select pickup location',
                          style: TextStyle(
                            color: DesignSystem.getTextPrimary(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedAddress != null) ...[
                          SizedBox(height: DesignSystem.space0_5),
                          Text(
                            _selectedAddress!,
                            style: TextStyle(
                              color: DesignSystem.getTextSecondary(isDark),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: DesignSystem.getTextTertiary(isDark),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Map Preview
          if (_selectedLatitude != null && _selectedLongitude != null) ...[
            SizedBox(height: DesignSystem.space2),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                border: Border.all(
                  color: DesignSystem.success.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Builder(
                    builder: (context) {
                      try {
                        return GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_selectedLatitude!, _selectedLongitude!),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: LatLng(_selectedLatitude!, _selectedLongitude!),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueViolet,
                              ),
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                        );
                      } catch (e) {
                        return Container(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 32,
                                  color: isDark ? Colors.white60 : Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Map preview unavailable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  // Tap overlay to open full map
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openLocationPicker,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tap to edit indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignSystem.space1_5,
                        vertical: DesignSystem.space0_5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: DesignSystem.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tap to change',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Manual entry option (optional fallback)
          SizedBox(height: DesignSystem.space1_5),
          TextButton.icon(
            onPressed: () {
              // Option to manually type address
              _showManualAddressDialog(isDark);
            },
            icon: Icon(
              Icons.edit_location_alt_outlined,
              size: 16,
              color: DesignSystem.getTextSecondary(isDark),
            ),
            label: Text(
              'Or type address manually',
              style: TextStyle(
                fontSize: 13,
                color: DesignSystem.getTextSecondary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                      const Color(0xFF8B5CF6).withAlpha((0.2 * 255).round()),
                      const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notes (Optional)',
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
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special instructions or notes...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withAlpha((0.2 * 255).round()),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withAlpha((0.2 * 255).round()),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringOption(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignSystem.walkerPrimary.withValues(alpha: 0.1),
            DesignSystem.walkerSecondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.walkerPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignSystem.space1),
                decoration: BoxDecoration(
                  gradient: DesignSystem.walkerGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignSystem.space1_5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Regular Walks?',
                      style: TextStyle(
                        color: DesignSystem.getTextPrimary(isDark),
                        fontSize: DesignSystem.h3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: DesignSystem.space0_5),
                    Text(
                      'Set up recurring bookings to save time',
                      style: TextStyle(
                        color: DesignSystem.getTextSecondary(isDark),
                        fontSize: DesignSystem.small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _selectedServices.isEmpty
                  ? null
                  : () {
                      // Prepare booking data to pass to recurring booking page
                      final bookingData = {
                        'dogName': widget.walker.name, // Will be replaced with actual dog name
                        'time': _selectedTime.format(context),
                        'duration': _serviceDurations.values.isNotEmpty
                            ? _serviceDurations.values.reduce((a, b) => a > b ? a : b)
                            : 60,
                        'location': _locationController.text.trim(),
                        'price': _totalPrice,
                        'notes': _notesController.text.trim(),
                        'services': _selectedServices.toList(),
                        'serviceDetails': <String, dynamic>{},
                      };

                      // Add service details
                      final serviceDetails = bookingData['serviceDetails'] as Map<String, dynamic>;
                      for (var service in _selectedServices) {
                        serviceDetails[service] = {
                          'duration': _serviceDurations[service] ??
                              (_isFixedPriceService(service) ? 0 : 60),
                          'price': widget.walker.servicePrices[service] ??
                              widget.walker.hourlyRate,
                        };
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecurringBookingPage(
                            walker: widget.walker,
                            bookingData: bookingData,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                'Set Up Recurring Booking',
                style: TextStyle(
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignSystem.walkerPrimary,
                side: BorderSide(
                  color: DesignSystem.walkerPrimary,
                  width: 2,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: DesignSystem.space2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        gradient: DesignSystem.walkerGradient,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        boxShadow: _selectedServices.isNotEmpty
            ? DesignSystem.shadowGlow(DesignSystem.walkerPrimary)
            : DesignSystem.shadowCard(Colors.black),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Price',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: DesignSystem.caption,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: DesignSystem.space0_5),
              Text(
                '\$${_totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: DesignSystem.h1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
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
              Icons.receipt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    final isEnabled = _selectedServices.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? _submitBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          disabledForegroundColor: isDark ? Colors.grey[600] : Colors.grey[500],
          elevation: isEnabled ? 8 : 0,
          shadowColor: DesignSystem.success.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_forward_rounded,
              size: 20,
            ),
            SizedBox(width: DesignSystem.space1_5),
            Text(
              'Proceed to Checkout',
              style: TextStyle(
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;
        _selectedAddress = result.address;
        _locationController.text = result.address;
      });
    }
  }

  void _showManualAddressDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignSystem.getSurface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        ),
        title: Text(
          'Enter Address',
          style: TextStyle(
            color: DesignSystem.getTextPrimary(isDark),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Enter pickup location',
            hintStyle: TextStyle(
              color: DesignSystem.getTextTertiary(isDark),
            ),
            prefixIcon: Icon(
              Icons.place_rounded,
              color: DesignSystem.success,
            ),
            filled: true,
            fillColor: DesignSystem.getSurface2(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: DesignSystem.getBorderColor(isDark, opacity: 0.2),
              ),
            ),
          ),
          style: TextStyle(
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedAddress = _locationController.text;
                _selectedLatitude = null;
                _selectedLongitude = null;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
