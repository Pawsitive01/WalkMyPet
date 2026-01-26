import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/booking_service.dart';
import 'package:walkmypet/services/review_service.dart';
import 'package:walkmypet/services/message_service.dart';
import 'package:walkmypet/widgets/review_dialog.dart';
import 'package:walkmypet/messaging/chat_page.dart';
import 'package:walkmypet/design_system.dart';

/// OwnerBookingDetailPage - Premium Booking Detail Experience for Pet Owners
///
/// A world-class booking detail page designed with Instagram/TikTok-level polish.
/// Shows comprehensive booking information with elegant visual hierarchy,
/// smooth animations, and intuitive action buttons.
///
/// Key Features:
/// - Hero header with status-aware gradient
/// - Walker profile section with quick actions
/// - Detailed booking information cards
/// - Timeline visualization for booking status
/// - Quick action buttons (Message, Call, Cancel, Review)
/// - Smooth entrance animations

class OwnerBookingDetailPage extends StatefulWidget {
  final Booking booking;
  final String? walkerPhotoUrl;
  final String? walkerPhone;

  const OwnerBookingDetailPage({
    super.key,
    required this.booking,
    this.walkerPhotoUrl,
    this.walkerPhone,
  });

  @override
  State<OwnerBookingDetailPage> createState() => _OwnerBookingDetailPageState();
}

class _OwnerBookingDetailPageState extends State<OwnerBookingDetailPage>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();
  final MessageService _messageService = MessageService();

  late AnimationController _pageAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
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

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Pulse animation for status indicator
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pageAnimationController.forward();

    // Only pulse for active statuses
    if (widget.booking.status == BookingStatus.pending ||
        widget.booking.status == BookingStatus.confirmed) {
      _pulseAnimationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return DesignSystem.warning;
      case BookingStatus.confirmed:
        return DesignSystem.walkerPrimary;
      case BookingStatus.awaitingConfirmation:
        return DesignSystem.info;
      case BookingStatus.completed:
        return DesignSystem.success;
      case BookingStatus.cancelled:
        return DesignSystem.error;
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
        return 'Pending Confirmation';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.awaitingConfirmation:
        return 'Awaiting Confirmation';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get _statusDescription {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return 'Waiting for ${widget.booking.walkerName} to confirm your booking request.';
      case BookingStatus.confirmed:
        return 'Your booking is confirmed! ${widget.booking.walkerName} will arrive at the scheduled time.';
      case BookingStatus.awaitingConfirmation:
        return 'Please confirm the booking completion to release payment.';
      case BookingStatus.completed:
        return 'This booking has been successfully completed. Thank you for using WalkMyPet!';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero header
              SliverToBoxAdapter(
                child: _buildHeroHeader(isDark),
              ),
              // Animated content
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _pageAnimationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.space2_5,
                      DesignSystem.space3,
                      DesignSystem.space2_5,
                      120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWalkerCard(isDark),
                        const SizedBox(height: DesignSystem.space3),
                        _buildStatusCard(isDark),
                        const SizedBox(height: DesignSystem.space3),
                        _buildBookingDetailsCard(isDark),
                        const SizedBox(height: DesignSystem.space3),
                        if (widget.booking.services != null &&
                            widget.booking.services!.isNotEmpty)
                          _buildServicesCard(isDark),
                        if (widget.booking.services != null &&
                            widget.booking.services!.isNotEmpty)
                          const SizedBox(height: DesignSystem.space3),
                        _buildPricingCard(isDark),
                        if (widget.booking.notes != null &&
                            widget.booking.notes!.isNotEmpty) ...[
                          const SizedBox(height: DesignSystem.space3),
                          _buildNotesCard(isDark),
                        ],
                        const SizedBox(height: DesignSystem.space3),
                        _buildTimelineCard(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Fixed app bar
          _buildAppBar(isDark),
          // Bottom action bar
          _buildBottomActionBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _statusColor,
            _statusColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignSystem.space2_5,
                60,
                DesignSystem.space2_5,
                DesignSystem.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _statusIcon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: DesignSystem.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: DesignSystem.h2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Booking #${widget.booking.id.substring(0, 8).toUpperCase()}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: DesignSystem.caption,
                                fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignSystem.space2,
            vertical: DesignSystem.space1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              _GlassButton(
                icon: Icons.more_horiz_rounded,
                onTap: () => _showOptionsSheet(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalkerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.08),
        ),
        boxShadow: DesignSystem.shadowCard(Colors.black),
      ),
      child: Row(
        children: [
          // Walker avatar
          Hero(
            tag: 'walker_${widget.booking.walkerId}',
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: DesignSystem.walkerGradient,
                border: Border.all(
                  color: DesignSystem.walkerPrimary.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: DesignSystem.shadowGlow(DesignSystem.walkerPrimary),
              ),
              child: ClipOval(
                child: widget.walkerPhotoUrl != null &&
                        widget.walkerPhotoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.walkerPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          ),
          const SizedBox(width: DesignSystem.space2),
          // Walker info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.walkerName,
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.h3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: DesignSystem.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Walker',
                      style: TextStyle(
                        color: DesignSystem.success,
                        fontSize: DesignSystem.small,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Walking ${widget.booking.dogName}',
                  style: TextStyle(
                    color: DesignSystem.getTextSecondary(isDark),
                    fontSize: DesignSystem.caption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Quick action buttons
          Column(
            children: [
              _QuickActionButton(
                icon: Icons.message_rounded,
                color: DesignSystem.walkerPrimary,
                isDark: isDark,
                onTap: () => _startConversation(),
              ),
              const SizedBox(height: DesignSystem.space1),
              _QuickActionButton(
                icon: Icons.phone_rounded,
                color: DesignSystem.success,
                isDark: isDark,
                onTap: () => _callWalker(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _statusColor.withValues(alpha: 0.15),
            _statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: _statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignSystem.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Update',
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: DesignSystem.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusDescription,
                  style: TextStyle(
                    color: DesignSystem.getTextSecondary(isDark),
                    fontSize: DesignSystem.bodySmall,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Booking Details',
      icon: Icons.calendar_month_rounded,
      iconColor: DesignSystem.walkerPrimary,
      child: Column(
        children: [
          _DetailRow(
            isDark: isDark,
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: DateFormat('EEEE, MMMM d, yyyy').format(widget.booking.date),
            color: DesignSystem.walkerPrimary,
          ),
          const SizedBox(height: DesignSystem.space2),
          _DetailRow(
            isDark: isDark,
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: widget.booking.time,
            color: DesignSystem.ownerPrimary,
          ),
          const SizedBox(height: DesignSystem.space2),
          _DetailRow(
            isDark: isDark,
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: _formatDuration(widget.booking.duration),
            color: DesignSystem.walkerSecondary,
          ),
          const SizedBox(height: DesignSystem.space2),
          _DetailRow(
            isDark: isDark,
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: widget.booking.location,
            color: DesignSystem.success,
            isExpandable: true,
          ),
          const SizedBox(height: DesignSystem.space2),
          _DetailRow(
            isDark: isDark,
            icon: Icons.pets_rounded,
            label: 'Pet',
            value: widget.booking.dogName,
            color: DesignSystem.ownerPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Services Included',
      icon: Icons.star_rounded,
      iconColor: DesignSystem.rating,
      child: Wrap(
        spacing: DesignSystem.space1_5,
        runSpacing: DesignSystem.space1_5,
        children: widget.booking.services!.map((service) {
          final color = _getServiceColor(service);
          final icon = _getServiceIcon(service);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.space2,
              vertical: DesignSystem.space1_5,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  service,
                  style: TextStyle(
                    color: color,
                    fontSize: DesignSystem.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingCard(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Payment Summary',
      icon: Icons.receipt_long_rounded,
      iconColor: DesignSystem.success,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Total',
                style: TextStyle(
                  color: DesignSystem.getTextSecondary(isDark),
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${widget.booking.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.space2),
          Container(
            height: 1,
            color: DesignSystem.getBorderColor(isDark, opacity: 0.1),
          ),
          const SizedBox(height: DesignSystem.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.subheading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.space2,
                  vertical: DesignSystem.space1,
                ),
                decoration: BoxDecoration(
                  gradient: DesignSystem.successGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                  boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
                ),
                child: Text(
                  '\$${widget.booking.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignSystem.h3,
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

  Widget _buildNotesCard(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Special Instructions',
      icon: Icons.notes_rounded,
      iconColor: DesignSystem.info,
      child: Text(
        widget.booking.notes!,
        style: TextStyle(
          color: DesignSystem.getTextSecondary(isDark),
          fontSize: DesignSystem.body,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTimelineCard(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Booking Timeline',
      icon: Icons.timeline_rounded,
      iconColor: DesignSystem.walkerSecondary,
      child: Column(
        children: [
          _TimelineItem(
            isDark: isDark,
            title: 'Booking Created',
            subtitle: DateFormat('MMM d, yyyy • h:mm a').format(widget.booking.createdAt),
            icon: Icons.add_circle_outline_rounded,
            color: DesignSystem.walkerPrimary,
            isCompleted: true,
            isFirst: true,
          ),
          if (widget.booking.status != BookingStatus.pending)
            _TimelineItem(
              isDark: isDark,
              title: widget.booking.status == BookingStatus.cancelled
                  ? 'Booking Cancelled'
                  : 'Walker Confirmed',
              subtitle: widget.booking.updatedAt != null
                  ? DateFormat('MMM d, yyyy • h:mm a').format(widget.booking.updatedAt!)
                  : 'Confirmed',
              icon: widget.booking.status == BookingStatus.cancelled
                  ? Icons.cancel_rounded
                  : Icons.check_circle_rounded,
              color: widget.booking.status == BookingStatus.cancelled
                  ? DesignSystem.error
                  : DesignSystem.success,
              isCompleted: true,
            ),
          if (widget.booking.status == BookingStatus.completed)
            _TimelineItem(
              isDark: isDark,
              title: 'Service Completed',
              subtitle: widget.booking.completedByWalkerAt != null
                  ? DateFormat('MMM d, yyyy • h:mm a')
                      .format(widget.booking.completedByWalkerAt!)
                  : 'Completed',
              icon: Icons.verified_rounded,
              color: DesignSystem.success,
              isCompleted: true,
              isLast: true,
            ),
          if (widget.booking.status == BookingStatus.confirmed ||
              widget.booking.status == BookingStatus.pending)
            _TimelineItem(
              isDark: isDark,
              title: 'Scheduled Walk',
              subtitle: DateFormat('MMM d, yyyy • ').format(widget.booking.date) +
                  widget.booking.time,
              icon: Icons.directions_walk_rounded,
              color: DesignSystem.walkerPrimary,
              isCompleted: false,
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(DesignSystem.space2_5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        DesignSystem.surfaceDark.withValues(alpha: 0.95),
                        DesignSystem.backgroundDark.withValues(alpha: 0.9),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                top: BorderSide(
                  color: DesignSystem.getBorderColor(isDark, opacity: 0.1),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _buildActionButton(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return _ActionButton(
          label: 'Cancel Booking',
          icon: Icons.cancel_rounded,
          color: DesignSystem.error,
          isDark: isDark,
          isLoading: _isLoading,
          onTap: () => _showCancelConfirmation(isDark),
        );
      case BookingStatus.confirmed:
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Cancel',
                icon: Icons.cancel_outlined,
                color: DesignSystem.error,
                isDark: isDark,
                isLoading: _isLoading,
                isOutlined: true,
                onTap: () => _showCancelConfirmation(isDark),
              ),
            ),
            const SizedBox(width: DesignSystem.space2),
            Expanded(
              flex: 2,
              child: _ActionButton(
                label: 'Message Walker',
                icon: Icons.message_rounded,
                color: DesignSystem.walkerPrimary,
                isDark: isDark,
                isLoading: _isLoading,
                onTap: () => _startConversation(),
              ),
            ),
          ],
        );
      case BookingStatus.awaitingConfirmation:
        return _ActionButton(
          label: 'Confirm Completion',
          icon: Icons.check_circle_rounded,
          color: DesignSystem.success,
          isDark: isDark,
          isLoading: _isLoading,
          onTap: () => _confirmCompletion(),
        );
      case BookingStatus.completed:
        return FutureBuilder<bool>(
          future: _reviewService.hasUserReviewedBooking(
            widget.booking.id,
            FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
          builder: (context, snapshot) {
            final hasReviewed = snapshot.data ?? false;
            return _ActionButton(
              label: hasReviewed ? 'Review Submitted' : 'Leave a Review',
              icon: hasReviewed ? Icons.check_circle_rounded : Icons.star_rounded,
              color: hasReviewed ? DesignSystem.getTextTertiary(isDark) : DesignSystem.rating,
              isDark: isDark,
              isLoading: _isLoading,
              isDisabled: hasReviewed,
              onTap: hasReviewed ? null : () => _showReviewDialog(),
            );
          },
        );
      case BookingStatus.cancelled:
        return _ActionButton(
          label: 'Book Again',
          icon: Icons.refresh_rounded,
          color: DesignSystem.walkerPrimary,
          isDark: isDark,
          isLoading: _isLoading,
          onTap: () => Navigator.pop(context),
        );
    }
  }

  // Helper methods
  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hr $mins min';
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

  // Actions
  Future<void> _startConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final conversationId = await _messageService.getOrCreateConversation(
        userId1: user.uid,
        userName1: user.displayName ?? 'Pet Owner',
        userPhoto1: user.photoURL ?? '',
        userId2: widget.booking.walkerId,
        userName2: widget.booking.walkerName,
        userPhoto2: widget.walkerPhotoUrl ?? '',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversationId,
              otherUserId: widget.booking.walkerId,
              otherUserName: widget.booking.walkerName,
              otherUserPhoto: widget.walkerPhotoUrl ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Unable to start conversation', DesignSystem.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callWalker() async {
    HapticFeedback.mediumImpact();
    if (widget.walkerPhone != null && widget.walkerPhone!.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: widget.walkerPhone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      _showSnackBar('Phone number not available', DesignSystem.warning);
    }
  }

  void _showCancelConfirmation(bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignSystem.space3),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(isDark),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignSystem.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignSystem.getTextTertiary(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignSystem.space3),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignSystem.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cancel_rounded,
                color: DesignSystem.error,
                size: 32,
              ),
            ),
            const SizedBox(height: DesignSystem.space2),
            Text(
              'Cancel Booking?',
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.h2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignSystem.space1),
            Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignSystem.getTextSecondary(isDark),
                fontSize: DesignSystem.body,
              ),
            ),
            const SizedBox(height: DesignSystem.space3),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Keep Booking',
                    icon: Icons.check_rounded,
                    color: DesignSystem.success,
                    isDark: isDark,
                    isOutlined: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: DesignSystem.space2),
                Expanded(
                  child: _ActionButton(
                    label: 'Cancel',
                    icon: Icons.cancel_rounded,
                    color: DesignSystem.error,
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(context);
                      await _cancelBooking();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _bookingService.cancelBooking(
        widget.booking.id,
        cancelledBy: user?.displayName ?? 'Owner',
      );
      if (mounted) {
        _showSnackBar('Booking cancelled successfully', DesignSystem.success);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Failed to cancel booking', DesignSystem.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmCompletion() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please log in to confirm', DesignSystem.error);
        return;
      }
      await _bookingService.confirmWalkCompletion(widget.booking.id, user.uid);
      if (mounted) {
        _showSnackBar('Payment released to ${widget.booking.walkerName}!', DesignSystem.success);
        // Automatically show review dialog after successful fund release
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _showReviewDialogAfterCompletion();
        }
      }
    } catch (e) {
      _showSnackBar('Failed to confirm completion', DesignSystem.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shows the review dialog automatically after confirming walk completion
  /// This is triggered after funds are released to the walker
  Future<void> _showReviewDialogAfterCompletion() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // First show a prompt asking if they'd like to leave a review
    final wantsToReview = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignSystem.space3),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(isDark),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignSystem.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignSystem.getTextTertiary(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignSystem.space3),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: DesignSystem.space2),
            Text(
              'Walk Complete!',
              style: TextStyle(
                color: DesignSystem.getTextPrimary(isDark),
                fontSize: DesignSystem.h2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignSystem.space1),
            Text(
              'Payment has been released to ${widget.booking.walkerName}.\nWould you like to leave a review?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignSystem.getTextSecondary(isDark),
                fontSize: DesignSystem.body,
                height: 1.4,
              ),
            ),
            const SizedBox(height: DesignSystem.space3),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Maybe Later',
                    icon: Icons.schedule_rounded,
                    color: DesignSystem.getTextTertiary(isDark),
                    isDark: isDark,
                    isOutlined: true,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: DesignSystem.space2),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    label: 'Leave Review',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFBBF24),
                    isDark: isDark,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );

    // If user wants to review, show the review dialog
    if (wantsToReview == true && mounted) {
      await _showReviewDialog();
    }
  }

  Future<void> _showReviewDialog() async {
    HapticFeedback.mediumImpact();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewDialog(
        bookingId: widget.booking.id,
        walkerId: widget.booking.walkerId,
        walkerName: widget.booking.walkerName,
        dogName: widget.booking.dogName,
      ),
    );

    if (result == true && mounted) {
      _showSnackBar('Review submitted successfully!', DesignSystem.success);
      setState(() {});
    }
  }

  void _showOptionsSheet(bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignSystem.space3),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(isDark),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignSystem.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignSystem.getTextTertiary(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignSystem.space3),
            _OptionTile(
              icon: Icons.share_rounded,
              label: 'Share Booking Details',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                // Implement share
              },
            ),
            _OptionTile(
              icon: Icons.help_outline_rounded,
              label: 'Get Help',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                // Implement help
              },
            ),
            _OptionTile(
              icon: Icons.report_outlined,
              label: 'Report an Issue',
              isDark: isDark,
              color: DesignSystem.error,
              onTap: () {
                Navigator.pop(context);
                // Implement report
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == DesignSystem.error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        ),
        margin: const EdgeInsets.all(DesignSystem.space2),
      ),
    );
  }
}

// =============================================================================
// SUPPORTING WIDGETS
// =============================================================================

class _GlassButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: DesignSystem.animationQuick,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: DesignSystem.animationQuick,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: _isPressed
              ? null
              : LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.15),
                    widget.color.withValues(alpha: 0.05),
                  ],
                ),
          color: _isPressed ? widget.color.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 20,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.space2_5),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.08),
        ),
        boxShadow: DesignSystem.shadowCard(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.15),
                      iconColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: DesignSystem.space1_5),
              Text(
                title,
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.subheading,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.space2_5),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isExpandable;

  const _DetailRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isExpandable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          isExpandable ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: DesignSystem.space1_5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: DesignSystem.getTextTertiary(isDark),
                  fontSize: DesignSystem.small,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isCompleted,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      )
                    : null,
                color: isCompleted ? null : DesignSystem.getSurface2(isDark),
                shape: BoxShape.circle,
                border: isCompleted
                    ? null
                    : Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 2,
                      ),
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : color,
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: isCompleted ? 0.5 : 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: DesignSystem.space2),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : DesignSystem.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isLoading;
  final bool isOutlined;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isDisabled && !widget.isLoading && widget.onTap != null;

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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: widget.isOutlined || widget.isDisabled
              ? null
              : LinearGradient(
                  colors: _isPressed
                      ? [
                          widget.color.withValues(alpha: 0.8),
                          widget.color.withValues(alpha: 0.6),
                        ]
                      : [widget.color, widget.color.withValues(alpha: 0.85)],
                ),
          color: widget.isDisabled
              ? DesignSystem.getSurface2(widget.isDark)
              : widget.isOutlined
                  ? Colors.transparent
                  : null,
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          border: widget.isOutlined
              ? Border.all(color: widget.color, width: 2)
              : null,
          boxShadow: widget.isOutlined || widget.isDisabled || _isPressed
              ? null
              : DesignSystem.shadowGlow(widget.color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.isOutlined ? widget.color : Colors.white,
                ),
              )
            else
              Icon(
                widget.icon,
                color: widget.isDisabled
                    ? DesignSystem.getTextTertiary(widget.isDark)
                    : widget.isOutlined
                        ? widget.color
                        : Colors.white,
                size: 20,
              ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.isDisabled
                    ? DesignSystem.getTextTertiary(widget.isDark)
                    : widget.isOutlined
                        ? widget.color
                        : Colors.white,
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? DesignSystem.getTextPrimary(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignSystem.space2,
            vertical: DesignSystem.space2,
          ),
          child: Row(
            children: [
              Icon(icon, color: tileColor, size: 24),
              const SizedBox(width: DesignSystem.space2),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: tileColor,
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: DesignSystem.getTextTertiary(isDark),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
