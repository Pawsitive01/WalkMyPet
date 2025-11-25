import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/services/booking_service.dart';
import 'package:walkmypet/booking/my_bookings_page_redesigned.dart';
import 'package:walkmypet/design_system.dart';
import 'package:walkmypet/booking/payment_logos.dart';

enum PaymentMethod {
  stripe,
  paypal,
  googlePay,
  applePay,
}

class CheckoutPage extends StatefulWidget {
  final Booking bookingData;
  final Walker walker;

  const CheckoutPage({
    super.key,
    required this.bookingData,
    required this.walker,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  PaymentMethod? _selectedPaymentMethod;
  bool _isProcessing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      _showSnackBar(
        'Please select a payment method',
        const Color(0xFFF59E0B),
        Icons.info_outline_rounded,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Here you would integrate actual payment processing
      // For Stripe: Use stripe_flutter package
      // For PayPal: Use paypal_flutter package
      // For Google Pay: Use pay package
      // For Apple Pay: Use pay package

      bool paymentSuccessful = await _simulatePayment(_selectedPaymentMethod!);

      if (paymentSuccessful) {
        // Create booking after successful payment
        await _bookingService.createBooking(widget.bookingData);

        if (mounted) {
          _showSnackBar(
            'Payment successful! Booking confirmed.',
            const Color(0xFF10B981),
            Icons.check_circle_rounded,
          );

          await Future.delayed(const Duration(milliseconds: 1500));

          if (mounted) {
            // Pop back to previous screens first, then navigate to My Bookings
            Navigator.of(context).pop(); // Pop checkout page
            Navigator.of(context).pop(); // Pop booking page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const MyBookingsPageRedesigned();
                },
              ),
            );
          } else {
          }
        }
      } else {
        throw 'Payment failed';
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Payment failed: $e',
          const Color(0xFFEF4444),
          Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _simulatePayment(PaymentMethod method) async {
    // This is a placeholder for actual payment processing
    // In production, you would integrate with actual payment providers
    return true;
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

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return const Color(0xFF635BFF);
      case PaymentMethod.paypal:
        return const Color(0xFF0070BA);
      case PaymentMethod.googlePay:
        return const Color(0xFF4285F4);
      case PaymentMethod.applePay:
        return const Color(0xFF000000);
    }
  }

  Widget _getPaymentMethodLogo(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return PaymentLogos.stripe(height: 28);
      case PaymentMethod.paypal:
        return PaymentLogos.paypal(height: 28);
      case PaymentMethod.googlePay:
        return PaymentLogos.googlePay(height: 28);
      case PaymentMethod.applePay:
        return PaymentLogos.applePay(height: 28);
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return 'Credit or debit card';
      case PaymentMethod.paypal:
        return 'PayPal account';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.applePay:
        return 'Apple Pay';
    }
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return 'Secure card payment processing';
      case PaymentMethod.paypal:
        return 'Pay with your PayPal balance or linked account';
      case PaymentMethod.googlePay:
        return 'Fast checkout with Google';
      case PaymentMethod.applePay:
        return 'Pay with Touch ID or Face ID';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      body: SafeArea(
        child: _isProcessing
            ? _buildProcessingState(isDark)
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

  Widget _buildProcessingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(DesignSystem.space3),
            decoration: BoxDecoration(
              color: DesignSystem.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
            ),
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.success),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: DesignSystem.space4),
          Text(
            'Processing payment...',
            style: TextStyle(
              fontSize: DesignSystem.h3,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: DesignSystem.getTextPrimary(isDark),
            ),
          ),
          SizedBox(height: DesignSystem.space1),
          Text(
            'Please wait while we confirm your payment',
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
      backgroundColor: DesignSystem.getBackground(isDark),
      leading: Container(
        margin: EdgeInsets.all(DesignSystem.space1),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(isDark),
          shape: BoxShape.circle,
          border: Border.all(
            color: DesignSystem.getBorderColor(isDark),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignSystem.getTextPrimary(isDark),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        'Checkout',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookingDetailsCard(isDark),
          SizedBox(height: DesignSystem.space4),
          _buildSectionTitle('Payment Method', isDark),
          SizedBox(height: DesignSystem.space2),
          _buildPaymentMethodsSection(isDark),
          SizedBox(height: DesignSystem.space2),
          _buildSecurityBadge(isDark),
          SizedBox(height: DesignSystem.space4),
          _buildPriceSummary(isDark),
          SizedBox(height: DesignSystem.space3),
          _buildPayButton(isDark),
          SizedBox(height: DesignSystem.space5),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: DesignSystem.h3,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: DesignSystem.getTextPrimary(isDark),
      ),
    );
  }

  Widget _buildBookingDetailsCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2),
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
          // Walker info - Compressed
          Row(
            children: [
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
                  children: [
                    Text(
                      widget.bookingData.walkerName,
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
                          Icons.pets_rounded,
                          size: 12,
                          color: DesignSystem.getTextTertiary(isDark),
                        ),
                        SizedBox(width: DesignSystem.space0_5),
                        Text(
                          widget.bookingData.dogName,
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
              if (widget.walker.hasPoliceClearance)
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
                        size: 12,
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
          ),
          SizedBox(height: DesignSystem.space2),
          Divider(
            color: DesignSystem.getBorderColor(isDark),
            height: 1,
          ),
          SizedBox(height: DesignSystem.space2),
          // Booking details - Compact grid layout
          Wrap(
            spacing: DesignSystem.space1,
            runSpacing: DesignSystem.space1,
            children: [
              _buildDetailChip(
                icon: Icons.calendar_today_rounded,
                label: DateFormat('MMM dd').format(widget.bookingData.date),
                isDark: isDark,
              ),
              _buildDetailChip(
                icon: Icons.access_time_rounded,
                label: widget.bookingData.time,
                isDark: isDark,
              ),
              _buildDetailChip(
                icon: Icons.timer_rounded,
                label: '${widget.bookingData.duration}m',
                isDark: isDark,
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space1_5),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: DesignSystem.getTextSecondary(isDark),
              ),
              SizedBox(width: DesignSystem.space0_5),
              Expanded(
                child: Text(
                  widget.bookingData.location,
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
          if (widget.bookingData.notes != null &&
              widget.bookingData.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
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
                      widget.bookingData.notes!,
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
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignSystem.space1_5,
        vertical: DesignSystem.space1,
      ),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface2(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: DesignSystem.getTextTertiary(isDark),
          ),
          SizedBox(width: DesignSystem.space0_5),
          Text(
            label,
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.small,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(bool isDark) {
    return Column(
      children: PaymentMethod.values.map((method) {
        final isSelected = _selectedPaymentMethod == method;
        final color = _getPaymentMethodColor(method);
        final name = _getPaymentMethodName(method);
        final description = _getPaymentMethodDescription(method);

        return GestureDetector(
          onTap: () {
            setState(() => _selectedPaymentMethod = method);
          },
          child: AnimatedContainer(
            duration: DesignSystem.animationFast,
            curve: DesignSystem.curveEaseOutCubic,
            margin: EdgeInsets.only(bottom: DesignSystem.space1_5),
            padding: EdgeInsets.all(DesignSystem.space2),
            decoration: BoxDecoration(
              color: DesignSystem.getSurface(isDark),
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              border: Border.all(
                color: isSelected
                    ? color
                    : DesignSystem.getBorderColor(isDark),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? DesignSystem.shadowGlow(color)
                  : DesignSystem.shadowSubtle(Colors.black),
            ),
            child: Row(
              children: [
                // Payment Logo
                Container(
                  width: 72,
                  height: 44,
                  alignment: Alignment.center,
                  child: _getPaymentMethodLogo(method),
                ),
                SizedBox(width: DesignSystem.space2),
                // Payment details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: DesignSystem.getTextPrimary(isDark),
                          fontSize: DesignSystem.bodySmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: DesignSystem.space0_5),
                      Text(
                        description,
                        style: TextStyle(
                          color: DesignSystem.getTextTertiary(isDark),
                          fontSize: DesignSystem.small,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: DesignSystem.space1),
                // Selection indicator
                AnimatedContainer(
                  duration: DesignSystem.animationFast,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : DesignSystem.getTextTertiary(isDark),
                      width: 2,
                    ),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSecurityBadge(bool isDark) {
    final selectedMethod = _selectedPaymentMethod;
    if (selectedMethod == null) return SizedBox.shrink();

    String provider = '';
    switch (selectedMethod) {
      case PaymentMethod.stripe:
        provider = 'Stripe';
        break;
      case PaymentMethod.paypal:
        provider = 'PayPal';
        break;
      case PaymentMethod.googlePay:
        provider = 'Google';
        break;
      case PaymentMethod.applePay:
        provider = 'Apple';
        break;
    }

    return Container(
      padding: EdgeInsets.all(DesignSystem.space1_5),
      decoration: BoxDecoration(
        color: DesignSystem.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        border: Border.all(
          color: DesignSystem.success.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 14,
            color: DesignSystem.success,
          ),
          SizedBox(width: DesignSystem.space1),
          Expanded(
            child: Text(
              'Secured by $provider • 256-bit encryption',
              style: TextStyle(
                color: DesignSystem.success,
                fontSize: DesignSystem.small,
                fontWeight: FontWeight.w600,
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
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: DesignSystem.space0_5),
              Text(
                '\$${widget.bookingData.price.toStringAsFixed(2)}',
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

  Widget _buildPayButton(bool isDark) {
    final isEnabled = _selectedPaymentMethod != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? _processPayment : null,
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
              Icons.lock_rounded,
              size: 20,
            ),
            SizedBox(width: DesignSystem.space1_5),
            Text(
              'Pay \$${widget.bookingData.price.toStringAsFixed(2)}',
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
}
