import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/stripe_config.dart';

/// Response from createPaymentIntent Cloud Function
class PaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;
  final double amount;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
  });

  factory PaymentIntentResponse.fromMap(Map<String, dynamic> map) {
    return PaymentIntentResponse(
      clientSecret: map['clientSecret'] ?? '',
      paymentIntentId: map['paymentIntentId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}

/// Result of payment processing
class PaymentResult {
  final bool success;
  final String? bookingId;
  final String? errorMessage;
  final String? paymentIntentId;

  PaymentResult({
    required this.success,
    this.bookingId,
    this.errorMessage,
    this.paymentIntentId,
  });

  PaymentResult.success({required this.bookingId, this.paymentIntentId})
      : success = true,
        errorMessage = null;

  PaymentResult.failure(this.errorMessage)
      : success = false,
        bookingId = null,
        paymentIntentId = null;
}

/// Service for handling Stripe payment integration
class StripeService {
  // Singleton pattern
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;

  /// Initialize Stripe SDK
  /// Call this once in your app's main() function
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      Stripe.publishableKey = StripeConfig.publishableKey;
      Stripe.merchantIdentifier = StripeConfig.merchantDisplayName;

      // Initialize Stripe SDK
      await Stripe.instance.applySettings();

      _isInitialized = true;
      print('Stripe SDK initialized successfully');
    } catch (e) {
      print('Error initializing Stripe SDK: $e');
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// Create a payment intent via Cloud Function
  /// This securely creates a Stripe PaymentIntent on the backend
  Future<PaymentIntentResponse> createPaymentIntent({
    required String walkerId,
    required double amount,
    required Map<String, dynamic> bookingMetadata,
  }) async {
    if (!_isInitialized) {
      throw Exception('Stripe SDK not initialized. Call initialize() first.');
    }

    try {
      // Call Cloud Function to create payment intent
      final callable = _functions.httpsCallable('createPaymentIntent');

      final response = await callable.call({
        'walkerId': walkerId,
        'amount': amount,
        'bookingMetadata': bookingMetadata,
      });

      final data = response.data;

      if (data['success'] != true) {
        throw Exception('Failed to create payment intent');
      }

      return PaymentIntentResponse.fromMap(data);
    } catch (e) {
      print('Error creating payment intent: $e');
      throw Exception('Failed to create payment intent: $e');
    }
  }

  /// Present Stripe payment sheet to user
  /// Returns true if payment was successful
  Future<bool> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail,
  }) async {
    if (!_isInitialized) {
      throw Exception('Stripe SDK not initialized');
    }

    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: StripeConfig.merchantDisplayName,
          customerEphemeralKeySecret: null, // Not using customer for MVP
          customerId: null,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1), // Match app primary color
            ),
          ),
        ),
      );

      // Present payment sheet to user
      await Stripe.instance.presentPaymentSheet();

      // If we reach here, payment was successful
      print('Payment completed successfully');
      return true;
    } on StripeException catch (e) {
      print('Stripe error: ${e.error.localizedMessage}');

      // User cancelled payment
      if (e.error.code == FailureCode.Canceled) {
        throw Exception('Payment cancelled');
      }

      // Payment failed
      throw Exception(e.error.localizedMessage ?? 'Payment failed');
    } catch (e) {
      print('Error presenting payment sheet: $e');
      throw Exception('Payment failed: $e');
    }
  }

  /// Process complete payment flow
  /// This orchestrates creating the payment intent, presenting the sheet,
  /// and waiting for the booking to be created by the webhook
  Future<PaymentResult> processPayment({
    required Map<String, dynamic> bookingData,
    required String walkerName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return PaymentResult.failure('User not authenticated');
      }

      // Extract booking data
      final walkerId = bookingData['walkerId'] as String;
      final amount = (bookingData['price'] as num).toDouble();
      final ownerName = bookingData['ownerName'] as String?;
      final dogName = bookingData['dogName'] as String?;
      final serviceType = bookingData['serviceType'] as String?;
      final scheduledDate = bookingData['date']?.toString();
      final time = bookingData['time'] as String?;
      final location = bookingData['location'] as String?;
      final duration = bookingData['duration'] as String?;

      // Create booking metadata for the payment intent
      final metadata = {
        'ownerName': ownerName ?? 'Unknown',
        'dogName': dogName ?? 'Unknown',
        'serviceType': serviceType ?? 'Dog Walking',
        'scheduledDate': scheduledDate ?? '',
        'time': time ?? '',
        'location': location ?? '',
        'duration': duration ?? '',
      };

      print('Creating payment intent for $amount AUD');

      // Step 1: Create payment intent
      final paymentIntentResponse = await createPaymentIntent(
        walkerId: walkerId,
        amount: amount,
        bookingMetadata: metadata,
      );

      print('Payment intent created: ${paymentIntentResponse.paymentIntentId}');

      // Step 2: Present payment sheet
      await presentPaymentSheet(
        clientSecret: paymentIntentResponse.clientSecret,
        customerEmail: user.email ?? '',
      );

      print('Payment sheet completed successfully');

      // Step 3: Wait for webhook to create booking
      final bookingId = await _waitForBookingCreation(
        paymentIntentId: paymentIntentResponse.paymentIntentId,
        timeout: const Duration(seconds: 30),
      );

      print('Booking created: $bookingId');

      return PaymentResult.success(
        bookingId: bookingId,
        paymentIntentId: paymentIntentResponse.paymentIntentId,
      );
    } catch (e) {
      print('Payment processing error: $e');
      return PaymentResult.failure(e.toString());
    }
  }

  /// Wait for booking to be created by webhook
  /// Polls Firestore for booking with the given paymentIntentId
  Future<String> _waitForBookingCreation({
    required String paymentIntentId,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final startTime = DateTime.now();
    const pollInterval = Duration(milliseconds: 500);

    print('Waiting for booking creation for payment intent: $paymentIntentId');

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        // Query bookings for one with this payment intent ID
        final querySnapshot = await _firestore
            .collection('bookings')
            .where('stripePaymentIntentId', isEqualTo: paymentIntentId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final bookingId = querySnapshot.docs.first.id;
          print('Found booking: $bookingId');
          return bookingId;
        }

        // Wait before polling again
        await Future.delayed(pollInterval);
      } catch (e) {
        print('Error polling for booking: $e');
        // Continue polling even if one attempt fails
      }
    }

    // Timeout reached
    throw Exception(
      'Booking creation timed out. Your payment was successful, '
      'but the booking is still being processed. Please check '
      '"My Bookings" in a moment.',
    );
  }

  /// Check if Stripe is initialized
  bool get isInitialized => _isInitialized;

  /// Get the current publishable key for debugging
  String get currentPublishableKey => StripeConfig.publishableKey;

  /// Check if in test mode
  bool get isTestMode => StripeConfig.isTestMode;
}
