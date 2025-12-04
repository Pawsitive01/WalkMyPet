import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/models/recurring_booking_model.dart';
import 'package:walkmypet/services/recurring_booking_service.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/design_system.dart';

class RecurringBookingPage extends StatefulWidget {
  final Walker walker;
  final Map<String, dynamic> bookingData; // Data from regular booking page

  const RecurringBookingPage({
    super.key,
    required this.walker,
    required this.bookingData,
  });

  @override
  State<RecurringBookingPage> createState() => _RecurringBookingPageState();
}

class _RecurringBookingPageState extends State<RecurringBookingPage>
    with SingleTickerProviderStateMixin {
  final _recurringBookingService = RecurringBookingService();
  final _userService = UserService();

  RecurrenceType _recurrenceType = RecurrenceType.weekly;
  Set<int> _selectedDays = <int>{}; // 1=Monday, 7=Sunday
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasEndDate = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<DateTime> _previewDates = [];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    if (_startDate == null ||
        (_recurrenceType != RecurrenceType.daily && _selectedDays.isEmpty)) {
      setState(() => _previewDates = []);
      return;
    }

    final dates = _recurringBookingService.previewBookingDates(
      recurrenceType: _recurrenceType,
      daysOfWeek: _recurrenceType == RecurrenceType.daily
          ? [1, 2, 3, 4, 5, 6, 7]
          : _selectedDays.toList(),
      startDate: _startDate!,
      endDate: _hasEndDate ? _endDate : null,
      previewDays: 90,
    );

    setState(() => _previewDates = dates.take(10).toList());
  }

  Future<void> _createRecurringBooking() async {
    if (_startDate == null) {
      _showSnackBar(
        'Please select a start date',
        const Color(0xFFF59E0B),
        Icons.warning_rounded,
      );
      return;
    }

    if (_recurrenceType != RecurrenceType.daily && _selectedDays.isEmpty) {
      _showSnackBar(
        'Please select at least one day',
        const Color(0xFFF59E0B),
        Icons.warning_rounded,
      );
      return;
    }

    if (_hasEndDate && _endDate != null && _endDate!.isBefore(_startDate!)) {
      _showSnackBar(
        'End date must be after start date',
        const Color(0xFFEF4444),
        Icons.error_outline_rounded,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final ownerProfile = await _userService.getUser(user.uid);
      if (ownerProfile == null) throw 'Owner profile not found';

      final recurringBooking = RecurringBooking(
        id: '',
        ownerId: user.uid,
        walkerId: widget.walker.name,
        ownerName: ownerProfile.displayName ?? 'Unknown',
        walkerName: widget.walker.name,
        dogName: widget.bookingData['dogName'] ?? 'My Dog',
        time: widget.bookingData['time'] ?? '',
        duration: widget.bookingData['duration'] ?? 60,
        location: widget.bookingData['location'] ?? '',
        pricePerBooking: widget.bookingData['price'] ?? 0.0,
        notes: widget.bookingData['notes'],
        recurrenceType: _recurrenceType,
        daysOfWeek: _recurrenceType == RecurrenceType.daily
            ? [1, 2, 3, 4, 5, 6, 7]
            : _selectedDays.toList()..sort(),
        startDate: _startDate!,
        endDate: _hasEndDate ? _endDate : null,
        services: List<String>.from(widget.bookingData['services'] ?? []),
        serviceDetails: Map<String, dynamic>.from(
          widget.bookingData['serviceDetails'] ?? {},
        ),
        createdAt: DateTime.now(),
      );

      await _recurringBookingService.createRecurringBooking(recurringBooking);

      if (mounted) {
        _showSnackBar(
          'Recurring booking created successfully!',
          DesignSystem.success,
          Icons.check_circle_rounded,
        );

        // Navigate back to home or bookings page
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error: $e',
          const Color(0xFFEF4444),
          Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) {
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
      appBar: AppBar(
        title: Text(
          'Recurring Booking',
          style: TextStyle(
            fontSize: DesignSystem.h2,
            fontWeight: FontWeight.w800,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
        backgroundColor: DesignSystem.getBackground(isDark),
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(DesignSystem.space2),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(isDark),
                    SizedBox(height: DesignSystem.space3),
                    _buildFrequencySelector(isDark),
                    SizedBox(height: DesignSystem.space3),
                    if (_recurrenceType != RecurrenceType.daily) ...[
                      _buildDaySelector(isDark),
                      SizedBox(height: DesignSystem.space3),
                    ],
                    _buildDateRangeSelector(isDark),
                    SizedBox(height: DesignSystem.space3),
                    _buildPreviewSection(isDark),
                    SizedBox(height: DesignSystem.space3),
                    _buildCreateButton(isDark),
                    SizedBox(height: DesignSystem.space5),
                  ],
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
          Container(
            padding: EdgeInsets.all(DesignSystem.space3),
            decoration: BoxDecoration(
              color: DesignSystem.walkerPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.walkerPrimary),
            ),
          ),
          SizedBox(height: DesignSystem.space4),
          Text(
            'Creating recurring booking...',
            style: TextStyle(
              fontSize: DesignSystem.h3,
              fontWeight: FontWeight.w700,
              color: DesignSystem.getTextPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignSystem.walkerPrimary.withValues(alpha: 0.1),
            DesignSystem.walkerSecondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.walkerPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: DesignSystem.walkerPrimary,
            size: 24,
          ),
          SizedBox(width: DesignSystem.space1_5),
          Expanded(
            child: Text(
              'Set up a recurring schedule for automatic bookings',
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark),
          width: 1,
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
              Text(
                'Frequency',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFrequencyOption(
                isDark: isDark,
                label: 'Daily',
                icon: Icons.today_rounded,
                type: RecurrenceType.daily,
              ),
              _buildFrequencyOption(
                isDark: isDark,
                label: 'Weekly',
                icon: Icons.calendar_view_week_rounded,
                type: RecurrenceType.weekly,
              ),
              _buildFrequencyOption(
                isDark: isDark,
                label: 'Custom',
                icon: Icons.tune_rounded,
                type: RecurrenceType.custom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption({
    required bool isDark,
    required String label,
    required IconData icon,
    required RecurrenceType type,
  }) {
    final isSelected = _recurrenceType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _recurrenceType = type;
          if (type == RecurrenceType.daily) {
            _selectedDays = {1, 2, 3, 4, 5, 6, 7};
          }
        });
        _updatePreview();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: DesignSystem.space2,
          vertical: DesignSystem.space1_5,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? DesignSystem.walkerGradient : null,
          color: isSelected ? null : DesignSystem.getSurface2(isDark),
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          border: Border.all(
            color: isSelected
                ? DesignSystem.walkerPrimary
                : DesignSystem.getBorderColor(isDark, opacity: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : DesignSystem.getTextPrimary(isDark),
              size: 20,
            ),
            SizedBox(width: DesignSystem.space1),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark),
          width: 1,
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
                  gradient: DesignSystem.walkerGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignSystem.space1_5),
              Text(
                'Select Days',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDayButton(isDark, 1, 'Mon'),
              _buildDayButton(isDark, 2, 'Tue'),
              _buildDayButton(isDark, 3, 'Wed'),
              _buildDayButton(isDark, 4, 'Thu'),
              _buildDayButton(isDark, 5, 'Fri'),
              _buildDayButton(isDark, 6, 'Sat'),
              _buildDayButton(isDark, 7, 'Sun'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(bool isDark, int dayNumber, String dayLabel) {
    final isSelected = _selectedDays.contains(dayNumber);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(dayNumber);
          } else {
            _selectedDays.add(dayNumber);
          }
        });
        _updatePreview();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isSelected ? DesignSystem.walkerGradient : null,
          color: isSelected ? null : DesignSystem.getSurface2(isDark),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? DesignSystem.walkerPrimary
                : DesignSystem.getBorderColor(isDark, opacity: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? DesignSystem.shadowGlow(DesignSystem.walkerPrimary)
              : null,
        ),
        child: Center(
          child: Text(
            dayLabel,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : DesignSystem.getTextPrimary(isDark),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark),
          width: 1,
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
                  gradient: DesignSystem.walkerGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignSystem.space1_5),
              Text(
                'Date Range',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),
          _buildDateButton(
            isDark: isDark,
            label: 'Start Date',
            date: _startDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
                _updatePreview();
              }
            },
          ),
          SizedBox(height: DesignSystem.space1_5),
          SwitchListTile(
            title: Text(
              'Set end date',
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _hasEndDate ? 'Recurring until end date' : 'Ongoing',
              style: TextStyle(
                color: DesignSystem.getTextSecondary(isDark),
                fontSize: DesignSystem.small,
              ),
            ),
            value: _hasEndDate,
            activeTrackColor: DesignSystem.walkerPrimary,
            onChanged: (value) {
              setState(() {
                _hasEndDate = value;
                if (value && _endDate == null) {
                  _endDate = DateTime.now().add(const Duration(days: 90));
                }
              });
              _updatePreview();
            },
          ),
          if (_hasEndDate) ...[
            SizedBox(height: DesignSystem.space1_5),
            _buildDateButton(
              isDark: isDark,
              label: 'End Date',
              date: _endDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ??
                      (_startDate?.add(const Duration(days: 90)) ??
                          DateTime.now().add(const Duration(days: 90))),
                  firstDate: _startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                  _updatePreview();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required bool isDark,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
      child: Container(
        padding: EdgeInsets.all(DesignSystem.space2),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface2(isDark),
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          border: Border.all(
            color: DesignSystem.getBorderColor(isDark, opacity: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: DesignSystem.getTextSecondary(isDark),
                    fontSize: DesignSystem.small,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: DesignSystem.space0_5),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Select date',
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today_rounded,
              color: DesignSystem.walkerPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
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
              Icon(
                Icons.visibility_rounded,
                color: DesignSystem.walkerPrimary,
                size: 20,
              ),
              SizedBox(width: DesignSystem.space1),
              Text(
                'Preview (Next 10 walks)',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _updatePreview,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: DesignSystem.walkerPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space2),
          if (_previewDates.isEmpty)
            Text(
              'Select frequency and days to preview',
              style: TextStyle(
                color: DesignSystem.getTextSecondary(isDark),
                fontSize: DesignSystem.body,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...List.generate(_previewDates.length, (index) {
              final date = _previewDates[index];
              return Padding(
                padding: EdgeInsets.only(bottom: DesignSystem.space1),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DesignSystem.walkerPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: DesignSystem.space1),
                    Text(
                      DateFormat('EEE, MMM dd, yyyy').format(date),
                      style: TextStyle(
                        color: DesignSystem.getTextPrimary(isDark),
                        fontSize: DesignSystem.body,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (_previewDates.length >= 10) ...[
            SizedBox(height: DesignSystem.space1),
            Text(
              'And more...',
              style: TextStyle(
                color: DesignSystem.getTextSecondary(isDark),
                fontSize: DesignSystem.small,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateButton(bool isDark) {
    final isValid = _startDate != null &&
        (_recurrenceType == RecurrenceType.daily || _selectedDays.isNotEmpty);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isValid ? _createRecurringBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          elevation: isValid ? 8 : 0,
          shadowColor: DesignSystem.success.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 20,
            ),
            SizedBox(width: DesignSystem.space1_5),
            Text(
              'Create Recurring Booking',
              style: TextStyle(
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
