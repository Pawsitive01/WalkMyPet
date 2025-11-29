import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:walkmypet/booking/booking_confirmation_page.dart';
import 'package:walkmypet/booking/my_bookings_page_redesigned.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Navigation key to navigate from notification handlers
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }

      // Get the FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      // Show a snackbar or dialog for foreground notifications
      _showForegroundNotification(message);
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Message data: ${message.data}');

    final data = message.data;
    final type = data['type'];

    // Navigate based on notification type
    if (type == 'booking_request' && navigatorKey.currentContext != null) {
      final bookingId = data['bookingId'];
      // Navigate to booking confirmation page
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => BookingConfirmationPage(bookingId: bookingId),
        ),
      );
    } else if (type == 'booking_status_update' && navigatorKey.currentContext != null) {
      // Navigate to my bookings page
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const MyBookingsPageRedesigned(),
        ),
      );
    }
  }

  /// Show foreground notification as a snackbar
  void _showForegroundNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'Notification',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(notification.body ?? ''),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _handleNotificationTap(message),
        ),
      ),
    );
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firestore for a user
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': Timestamp.now(),
        });
        debugPrint('FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token from Firestore (on logout)
  Future<void> removeTokenFromFirestore(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      debugPrint('FCM token removed for user: $userId');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Get FCM token for a specific user (for sending notifications)
  Future<String?> getUserToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Create a notification for a user in Firestore
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': Timestamp.now(),
        'data': data,
      });
      debugPrint('Notification created for user: $userId');
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Create a booking request notification for a walker
  Future<void> notifyWalkerOfBookingRequest({
    required String walkerId,
    required String bookingId,
    required String ownerName,
    required String dogName,
  }) async {
    await createNotification(
      userId: walkerId,
      title: 'New Booking Request',
      message: '$ownerName wants to book a walk for $dogName',
      type: 'bookingRequest',
      bookingId: bookingId,
    );
  }

  /// Create a booking confirmation notification
  Future<void> notifyBookingConfirmed({
    required String ownerId,
    required String bookingId,
    required String walkerName,
  }) async {
    await createNotification(
      userId: ownerId,
      title: 'Booking Confirmed',
      message: '$walkerName has confirmed your booking',
      type: 'bookingConfirmed',
      bookingId: bookingId,
    );
  }

  /// Create a booking cancellation notification
  Future<void> notifyBookingCancelled({
    required String userId,
    required String bookingId,
    required String cancelledBy,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Booking Cancelled',
      message: 'Your booking has been cancelled by $cancelledBy',
      type: 'bookingCancelled',
      bookingId: bookingId,
    );
  }

  /// Create a booking completion notification
  Future<void> notifyBookingCompleted({
    required String userId,
    required String bookingId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Walk Completed',
      message: 'Your walk has been completed successfully',
      type: 'bookingCompleted',
      bookingId: bookingId,
    );
  }
}
