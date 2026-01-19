import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:walkmypet/booking/booking_confirmation_page.dart';
import 'package:walkmypet/booking/my_bookings_page_v3.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

class NotificationService {
  late final FirebaseMessaging _messaging;
  late final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService() {
    _messaging = FirebaseMessaging.instance;
    _firestore = FirebaseFirestore.instance;
    // Initialize timezone database
    tz.initializeTimeZones();
  }

  // Navigation key to navigate from notification handlers
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize local notifications and create Android channels
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Create Android notification channels
    await _createAndroidChannels();
  }

  /// Create Android notification channels
  Future<void> _createAndroidChannels() async {
    // Booking requests channel
    const AndroidNotificationChannel bookingRequestsChannel =
        AndroidNotificationChannel(
      'booking_requests',
      'Booking Requests',
      description: 'Notifications for new booking requests',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Booking updates channel
    const AndroidNotificationChannel bookingUpdatesChannel =
        AndroidNotificationChannel(
      'booking_updates',
      'Booking Updates',
      description: 'Notifications for booking status updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Messages channel
    const AndroidNotificationChannel messagesChannel =
        AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Reviews channel
    const AndroidNotificationChannel reviewsChannel =
        AndroidNotificationChannel(
      'reviews',
      'Reviews',
      description: 'Notifications for new reviews',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Walk reminders channel
    const AndroidNotificationChannel walkRemindersChannel =
        AndroidNotificationChannel(
      'walk_reminders',
      'Walk Reminders',
      description: 'Notifications to remind you about upcoming walks',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Create all channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bookingRequestsChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bookingUpdatesChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messagesChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reviewsChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(walkRemindersChannel);

    debugPrint('Android notification channels created');
  }

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Initialize local notifications and create Android channels
      await _initializeLocalNotifications();

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
          builder: (context) => const MyBookingsPageV3(),
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

  /// Helper method to get the correct collection for a user
  Future<String?> _getUserCollection(String userId) async {
    // Check walkers collection first
    var doc = await _firestore.collection('walkers').doc(userId).get();
    if (doc.exists) {
      return 'walkers';
    }

    // Check owners collection
    doc = await _firestore.collection('owners').doc(userId).get();
    if (doc.exists) {
      return 'owners';
    }

    // Fallback to users collection for backward compatibility
    doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return 'users';
    }

    return null;
  }

  /// Save FCM token to Firestore for a user
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        String? collection = await _getUserCollection(userId);
        if (collection != null) {
          await _firestore.collection(collection).doc(userId).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': Timestamp.now(),
          });
          debugPrint('FCM token saved for user: $userId in collection: $collection');
        } else {
          debugPrint('User not found in any collection: $userId');
        }
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token from Firestore (on logout)
  Future<void> removeTokenFromFirestore(String userId) async {
    try {
      String? collection = await _getUserCollection(userId);
      if (collection != null) {
        await _firestore.collection(collection).doc(userId).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
        debugPrint('FCM token removed for user: $userId from collection: $collection');
      }
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Get FCM token for a specific user (for sending notifications)
  Future<String?> getUserToken(String userId) async {
    try {
      String? collection = await _getUserCollection(userId);
      if (collection != null) {
        final doc = await _firestore.collection(collection).doc(userId).get();
        if (doc.exists) {
          final data = doc.data();
          return data?['fcmToken'] as String?;
        }
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

  /// Create a review received notification
  Future<void> notifyReviewReceived({
    required String reviewedUserId,
    required String reviewerName,
    required double rating,
    required String? comment,
  }) async {
    final stars = '⭐' * rating.round();
    await createNotification(
      userId: reviewedUserId,
      title: 'New Review Received!',
      message: '$reviewerName left you a $rating-star review $stars',
      type: 'reviewReceived',
      data: {
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
      },
    );
  }

  /// Notify owner to confirm walk completion
  Future<void> notifyOwnerToConfirmCompletion({
    required String ownerId,
    required String bookingId,
    required String walkerName,
    required String dogName,
    required double amount,
  }) async {
    await createNotification(
      userId: ownerId,
      title: 'Walk Completed - Confirm Now',
      message:
          '$walkerName has completed the walk with $dogName. Please confirm to release payment of \$${amount.toStringAsFixed(2)}.',
      type: 'completionConfirmation',
      bookingId: bookingId,
      data: {
        'walkerName': walkerName,
        'dogName': dogName,
        'amount': amount,
      },
    );
  }

  /// Notify walker of payment received
  Future<void> notifyWalkerPaymentReceived({
    required String walkerId,
    required String bookingId,
    required double amount,
    required String dogName,
  }) async {
    await createNotification(
      userId: walkerId,
      title: 'Payment Received!',
      message:
          'You received \$${amount.toStringAsFixed(2)} for your walk with $dogName. View your earnings in your wallet.',
      type: 'paymentReceived',
      bookingId: bookingId,
      data: {
        'amount': amount,
        'dogName': dogName,
      },
    );
  }

  /// Parse time string (e.g., "10:00 AM") and combine with date
  DateTime _parseTimeWithDate(DateTime date, String timeString) {
    try {
      // Remove any extra spaces
      final cleanTime = timeString.trim();

      // Parse time formats like "10:00 AM" or "14:30"
      final timeParts = cleanTime.split(' ');
      String time = timeParts[0];
      String? period = timeParts.length > 1 ? timeParts[1].toUpperCase() : null;

      final hourMinute = time.split(':');
      int hour = int.parse(hourMinute[0]);
      int minute = hourMinute.length > 1 ? int.parse(hourMinute[1]) : 0;

      // Handle AM/PM
      if (period != null) {
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return date;
    }
  }

  /// Schedule a notification for 10 minutes before a walk
  Future<void> scheduleWalkReminder({
    required String bookingId,
    required DateTime walkDate,
    required String walkTime,
    required String dogName,
    required String ownerName,
    required String location,
  }) async {
    try {
      // Parse the walk time
      final walkDateTime = _parseTimeWithDate(walkDate, walkTime);

      // Schedule notification 10 minutes before
      final notificationTime = walkDateTime.subtract(const Duration(minutes: 10));

      // Only schedule if the notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        // Convert to TZ DateTime
        final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

        // Create notification details
        const androidDetails = AndroidNotificationDetails(
          'walk_reminders',
          'Walk Reminders',
          channelDescription: 'Notifications to remind you about upcoming walks',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Use booking ID hash as notification ID for easy cancellation
        final notificationId = bookingId.hashCode;

        await _localNotifications.zonedSchedule(
          notificationId,
          'Walk Starting Soon! 🐕',
          'Your walk with $dogName is starting in 10 minutes at $location',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: bookingId,
        );

        debugPrint('Scheduled walk reminder for $notificationTime (ID: $notificationId)');

        // Also create a notification document in Firestore for screen notification
        await _firestore.collection('scheduled_notifications').doc(bookingId).set({
          'bookingId': bookingId,
          'notificationTime': Timestamp.fromDate(notificationTime),
          'walkTime': Timestamp.fromDate(walkDateTime),
          'dogName': dogName,
          'ownerName': ownerName,
          'location': location,
          'createdAt': Timestamp.now(),
        });
      } else {
        debugPrint('Walk time is too soon, skipping notification scheduling');
      }
    } catch (e) {
      debugPrint('Error scheduling walk reminder: $e');
    }
  }

  /// Cancel a scheduled walk reminder
  Future<void> cancelWalkReminder(String bookingId) async {
    try {
      final notificationId = bookingId.hashCode;
      await _localNotifications.cancel(notificationId);

      // Remove from Firestore
      await _firestore.collection('scheduled_notifications').doc(bookingId).delete();

      debugPrint('Cancelled walk reminder (ID: $notificationId)');
    } catch (e) {
      debugPrint('Error cancelling walk reminder: $e');
    }
  }
}
