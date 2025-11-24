import 'package:flutter/material.dart';

/// Professional payment provider logo widgets
/// Designed to look authentic and match real brand guidelines
class PaymentLogos {
  /// Stripe logo with authentic styling
  static Widget stripe({double height = 24}) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.5, vertical: height * 0.25),
      decoration: BoxDecoration(
        color: const Color(0xFF635BFF),
        borderRadius: BorderRadius.circular(height * 0.2),
      ),
      child: Center(
        child: Text(
          'stripe',
          style: TextStyle(
            color: Colors.white,
            fontSize: height * 0.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  /// PayPal logo with authentic two-tone blue design
  static Widget paypal({double height = 24}) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.4, vertical: height * 0.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0070BA), Color(0xFF003087)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(height * 0.15),
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Pay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height * 0.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              TextSpan(
                text: 'Pal',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: height * 0.5,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Google Pay logo with Google colors
  static Widget googlePay({double height = 24}) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.4, vertical: height * 0.2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height * 0.15),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Google "G" multicolor
          SizedBox(
            width: height * 0.5,
            height: height * 0.5,
            child: CustomPaint(
              painter: _GoogleGPainter(),
            ),
          ),
          SizedBox(width: height * 0.15),
          Text(
            'Pay',
            style: TextStyle(
              color: const Color(0xFF5F6368),
              fontSize: height * 0.45,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ],
      ),
    );
  }

  /// Apple Pay logo with Apple styling
  static Widget applePay({double height = 24}) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.4, vertical: height * 0.2),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(height * 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Apple logo
          Icon(
            Icons.apple,
            color: Colors.white,
            size: height * 0.6,
          ),
          SizedBox(width: height * 0.1),
          Text(
            'Pay',
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.45,
              fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display',
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for Google "G" logo
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue section (top right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Red section (top left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14, // -180 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Yellow section (bottom left)
    paint.color = const Color(0xFFFBBC04);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees (from bottom)
      1.57, // 90 degrees
      true,
      paint,
    );

    // Green section (bottom right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, // 0 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // White center
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
