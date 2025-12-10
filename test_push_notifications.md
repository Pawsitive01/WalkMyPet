# Push Notification Testing Guide for WalkMyPet

## Current Status: ✅ IMPLEMENTED & READY TO TEST

The push notification system has been properly implemented. Here's what's been verified:

### ✅ What's Working:

1. **Flutter Dependencies**
   - `firebase_messaging: ^16.0.4` is installed and configured
   - All dependencies resolve without errors

2. **Notification Service**
   - ✅ `NotificationService` class properly implemented (`lib/services/notification_service.dart`)
   - ✅ FCM token management (get, save, remove)
   - ✅ Foreground and background message handlers
   - ✅ Deep linking to booking confirmation pages
   - ✅ Navigation system integrated with `navigatorKey`

3. **Auth Integration**
   - ✅ NotificationService initialized on user login (`lib/providers/auth_provider.dart:39`)
   - ✅ FCM token saved to Firestore on login (`lib/providers/auth_provider.dart:40`)
   - ✅ FCM token removed on logout (`lib/providers/auth_provider.dart:75`)

4. **Android Configuration**
   - ✅ `google-services.json` present
   - ✅ `POST_NOTIFICATIONS` permission added for Android 13+
   - ✅ Internet and location permissions configured

5. **Cloud Functions**
   - ✅ 4 Cloud Functions implemented:
     - `onBookingCreated` - Notifies walker of new booking
     - `onBookingStatusUpdated` - Notifies owner of booking status changes
     - `onReviewCreated` - Notifies user of new review
     - `onMessageCreated` - Notifies user of new messages
   - ✅ Functions compile successfully (TypeScript)
   - ⚠️ **NOT YET DEPLOYED** (requires Firebase authentication)

6. **Code Quality**
   - ✅ No Flutter analysis errors
   - ✅ All type definitions correct
   - ✅ Proper error handling in place

---

## 🔍 What Was Fixed Today:

### Fixed Issue #1: Missing POST_NOTIFICATIONS Permission
**Problem:** Android 13+ requires explicit `POST_NOTIFICATIONS` permission
**Solution:** Added to `android/app/src/main/AndroidManifest.xml:7`

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## 📋 How to Test Push Notifications

### Method 1: Test with Two Devices (Recommended)

1. **Setup Device 1 (Pet Walker)**
   ```bash
   flutter run -d <device-1-id>
   ```
   - Register as a Pet Walker
   - Complete onboarding
   - Stay logged in

2. **Setup Device 2 (Pet Owner)**
   ```bash
   flutter run -d <device-2-id>
   ```
   - Register as a Pet Owner
   - Find the walker from Device 1
   - Book a walk

3. **Expected Result:**
   - Device 1 (Walker) should receive a push notification: "🐾 New Booking Request!"
   - Tap notification → Opens `BookingConfirmationPage`
   - Confirm or reject booking
   - Device 2 (Owner) receives confirmation/rejection notification

### Method 2: Test with Firebase Console (Manual Notification)

1. **Get FCM Token**
   - Run the app
   - Login as a user
   - Check debug console for: `FCM Token: xxxxx`

2. **Send Test Notification**
   - Go to Firebase Console → Cloud Messaging
   - Click "Send your first message"
   - Enter title and body
   - Click "Send test message"
   - Paste the FCM token
   - Click "Test"

3. **Expected Behaviors:**
   - **Foreground:** SnackBar appears with "View" button
   - **Background:** System notification appears in status bar
   - **Tap:** App opens and navigates to appropriate page

### Method 3: Test with curl (Advanced)

First, get your Firebase Server Key from Firebase Console → Project Settings → Cloud Messaging → Server key

```bash
# Get FCM token from the app's debug logs

# Send notification
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test from curl"
    },
    "data": {
      "type": "booking_request",
      "bookingId": "test123"
    },
    "priority": "high"
  }'
```

---

## 🚀 Deploying Cloud Functions

To enable automatic notifications, deploy the Cloud Functions:

```bash
# Login to Firebase (if not already logged in)
firebase login

# Deploy Cloud Functions
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

**Expected Output:**
```
✔  Deploy complete!

Functions:
  onBookingCreated(...)
  onBookingStatusUpdated(...)
  onReviewCreated(...)
  onMessageCreated(...)
```

---

## 🐛 Troubleshooting

### Issue: "User hasn't granted notification permission"
**Solution:**
- iOS: Settings → WalkMyPet → Notifications → Allow
- Android: Settings → Apps → WalkMyPet → Notifications → Allow

### Issue: "No FCM token"
**Check:**
1. Is `google-services.json` correctly placed?
2. Is Firebase initialized? (Check logs for "Firebase initialized")
3. Is the app connected to the internet?
4. Try uninstalling and reinstalling the app

### Issue: "Notifications not showing in foreground"
**Expected:** Foreground notifications show as SnackBar, not system notifications
**Check:** Look for the purple SnackBar at the bottom of the screen

### Issue: "Cloud Functions not triggering"
**Check:**
1. Are functions deployed? Run `firebase deploy --only functions`
2. Check Firebase Console → Functions for errors
3. Check Firestore: Does the user have `fcmToken` field?
4. Check Cloud Functions logs: Firebase Console → Functions → Logs

### Issue: "Deep linking not working"
**Check:**
1. Is `navigatorKey` set in `main.dart`? (✅ Verified: line 175)
2. Does notification data include correct `type` field?
3. Check debug logs for "Notification tapped: ..."

---

## 📊 Notification Flow Diagram

```
┌─────────────────────────────────────────┐
│    Owner Creates Booking                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Firestore: bookings/{id}               │
│  status: "pending"                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Cloud Function: onBookingCreated()     │
│  1. Get walker's FCM token              │
│  2. Build notification payload          │
│  3. Send via Firebase Cloud Messaging   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Walker's Device Receives Notification  │
│  • Background: System notification      │
│  • Foreground: SnackBar with "View"     │
└──────────────┬──────────────────────────┘
               │ (Tap)
               ▼
┌─────────────────────────────────────────┐
│  Navigate to BookingConfirmationPage    │
│  Walker reviews and confirms/rejects    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Firestore: Update booking status       │
│  status: "confirmed" / "cancelled"      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Cloud Function: onBookingStatusUpdated │
│  1. Get owner's FCM token               │
│  2. Send confirmation notification      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Owner's Device Receives Update         │
│  "✅ Booking Confirmed!" or             │
│  "❌ Booking Cancelled"                 │
└─────────────────────────────────────────┘
```

---

## 🔒 Security Notes

1. **FCM Tokens are User-Specific**
   - Each device gets a unique token
   - Tokens are refreshed periodically
   - Old tokens are automatically cleaned up on logout

2. **Cloud Functions Use Admin SDK**
   - Server-side validation
   - Users cannot spoof notifications
   - Tokens stored securely in Firestore

3. **Notification Permissions**
   - Requested on first launch
   - Users can revoke in system settings
   - App handles gracefully if denied

---

## 📝 Next Steps to Production

1. ✅ Code implementation complete
2. ⚠️ **Deploy Cloud Functions** (requires Firebase CLI auth)
3. ⚠️ **Test on real devices** (emulator has FCM limitations)
4. ⚠️ **Set up iOS APNs** (if supporting iOS)
5. ✅ Android notification channels configured
6. ⚠️ **Monitor notification delivery** (Firebase Console → Cloud Messaging → Reports)

---

## 📞 Support

- Check logs: `flutter run` and watch for FCM-related messages
- Firebase Console Logs: Project → Functions → Logs
- Notification delivery reports: Firebase Console → Cloud Messaging

---

## Summary

✅ **Push notifications are fully implemented and ready to test!**

The system includes:
- Complete FCM integration
- Token management
- 4 Cloud Functions for automatic notifications
- Deep linking to relevant screens
- Foreground and background message handling
- Proper Android 13+ permissions

**To test:** Run the app on a physical device, create a booking, and verify notifications are received!
