# Push Notifications Setup Guide

This guide explains how to set up and use push notifications in the WalkMyPet app.

## Overview

The app uses Firebase Cloud Messaging (FCM) to send push notifications to walkers when owners book them. Walkers can then confirm or reject the booking directly from the notification.

## Architecture

### Components

1. **NotificationService** (`lib/services/notification_service.dart`)
   - Handles FCM token management
   - Manages notification permissions
   - Handles foreground and background messages
   - Routes notifications to appropriate screens

2. **Cloud Functions** (`functions/src/index.ts`)
   - `onBookingCreated`: Triggers when a new booking is created (status: pending)
   - `onBookingStatusUpdated`: Triggers when booking status changes

3. **BookingConfirmationPage** (`lib/booking/booking_confirmation_page.dart`)
   - UI for walkers to view and confirm/reject bookings
   - Shows complete booking details including owner info, date, time, location, services, and price

## Setup Instructions

### 1. Firebase Console Setup

#### Enable Firebase Cloud Messaging

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Project Settings** > **Cloud Messaging**
4. Note down your:
   - Server Key
   - Sender ID

#### Android Configuration

1. Add your Android SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Copy the SHA-1 fingerprint from the output
3. In Firebase Console: **Project Settings** > **Add fingerprint**

#### iOS Configuration

1. Upload your APNs certificate or key:
   - Go to **Project Settings** > **Cloud Messaging** > **iOS app configuration**
   - Upload your APNs Authentication Key (.p8 file) OR
   - Upload your APNs Certificate (.p12 file)

2. Add capabilities to your Xcode project:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select the Runner target
   - Go to **Signing & Capabilities**
   - Click **+ Capability** and add:
     - **Push Notifications**
     - **Background Modes** (enable "Remote notifications")

### 2. Deploy Cloud Functions

```bash
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy to Firebase
firebase deploy --only functions
```

### 3. Test the Notification Flow

1. **Install the app** on two devices:
   - Device A: Log in as a pet owner
   - Device B: Log in as a walker

2. **Create a booking** from Device A:
   - Browse walkers
   - Select a walker
   - Fill out booking details
   - Proceed to checkout and pay

3. **Receive notification** on Device B:
   - Walker should receive a push notification
   - Tap the notification to open the booking confirmation page

4. **Confirm or reject** the booking on Device B:
   - Review the booking details
   - Tap "Confirm" or "Reject"

5. **Receive status update** on Device A:
   - Owner should receive a notification about the walker's decision

## How It Works

### Booking Creation Flow

```
1. Owner creates booking (status: pending)
   ↓
2. Booking saved to Firestore
   ↓
3. Cloud Function `onBookingCreated` triggers
   ↓
4. Function fetches walker's FCM token from Firestore
   ↓
5. Function sends push notification to walker
   ↓
6. Walker receives notification and taps it
   ↓
7. App opens BookingConfirmationPage
   ↓
8. Walker confirms/rejects booking
   ↓
9. Cloud Function `onBookingStatusUpdated` triggers
   ↓
10. Function sends status update notification to owner
```

### Notification Payload

**Booking Request (to Walker)**:
```json
{
  "notification": {
    "title": "🐾 New Booking Request!",
    "body": "{ownerName} wants to book you for {dogName} on {date} at {time}"
  },
  "data": {
    "type": "booking_request",
    "bookingId": "abc123",
    "ownerId": "user123",
    "ownerName": "John Doe",
    "dogName": "Buddy",
    "date": "Dec 25, 2023",
    "time": "2:00 PM",
    "price": "45.00",
    "status": "pending"
  }
}
```

**Status Update (to Owner)**:
```json
{
  "notification": {
    "title": "✅ Booking Confirmed!",
    "body": "{walkerName} has confirmed your booking for {dogName}"
  },
  "data": {
    "type": "booking_status_update",
    "bookingId": "abc123",
    "walkerId": "walker123",
    "walkerName": "Jane Smith",
    "status": "confirmed"
  }
}
```

## FCM Token Management

### When Tokens Are Saved

- User logs in → Token saved to Firestore
- Token refreshes → Updated in Firestore
- User logs out → Token removed from Firestore

### Token Storage Location

```
Firestore Collection: users
Document ID: {userId}
Fields:
  - fcmToken: string
  - fcmTokenUpdatedAt: timestamp
```

## Notification Channels (Android)

The app uses two notification channels:

1. **booking_requests**
   - Name: "Booking Requests"
   - Importance: High
   - Sound: Default
   - Vibration: Yes

2. **booking_updates**
   - Name: "Booking Updates"
   - Importance: High
   - Sound: Default

## Foreground vs Background Notifications

### Foreground (App is open)
- Notification appears as a SnackBar
- User can tap "View" to navigate to the relevant screen

### Background (App is closed/minimized)
- System notification appears in the notification tray
- Tapping opens the app and navigates to the relevant screen

## Troubleshooting

### Notifications Not Received

1. **Check FCM token**:
   ```dart
   // In your app
   final token = await NotificationService().getToken();
   print('FCM Token: $token');
   ```

2. **Verify token in Firestore**:
   - Open Firebase Console
   - Go to Firestore Database
   - Check `users/{userId}/fcmToken`

3. **Check Cloud Function logs**:
   ```bash
   firebase functions:log
   ```

4. **Verify notification permissions**:
   - iOS: Settings > WalkMyPet > Notifications
   - Android: Settings > Apps > WalkMyPet > Notifications

### Cloud Functions Not Triggering

1. **Check function deployment**:
   ```bash
   firebase functions:list
   ```

2. **View function logs**:
   ```bash
   firebase functions:log --only onBookingCreated
   ```

3. **Test manually**:
   ```bash
   firebase functions:shell
   ```

### iOS Specific Issues

1. **APNs not configured**:
   - Ensure you've uploaded your APNs certificate/key in Firebase Console

2. **Capabilities missing**:
   - Check that Push Notifications and Background Modes are enabled in Xcode

3. **Development vs Production**:
   - FCM uses different APNs environments for debug vs release builds
   - Test with both debug and release builds

### Android Specific Issues

1. **SHA-1 fingerprint**:
   - Ensure you've added the correct SHA-1 fingerprint in Firebase Console

2. **Google Services**:
   - Verify `google-services.json` is in `android/app/`

## Testing with Firebase Console

You can send test notifications directly from Firebase Console:

1. Go to **Cloud Messaging** in Firebase Console
2. Click **Send your first message**
3. Enter notification title and text
4. Click **Send test message**
5. Enter the FCM token from your device
6. Click **Test**

## Best Practices

1. **Handle errors gracefully**: The app should work without notifications if users deny permission
2. **Don't spam**: Only send notifications for important events
3. **Clear messaging**: Make notification text clear and actionable
4. **Deep linking**: Always navigate to the relevant screen when notification is tapped
5. **Token refresh**: Listen for token refresh events and update Firestore
6. **Cleanup**: Remove tokens when users log out

## Future Enhancements

- [ ] Add notification preferences for users
- [ ] Implement rich notifications with images
- [ ] Add notification history in the app
- [ ] Support for notification categories/topics
- [ ] Schedule notifications for booking reminders
- [ ] Add sound customization options

## Support

For issues or questions, please open an issue on the GitHub repository.
