# 🔥 Firebase Setup Guide for WalkMyPet

Complete guide to configure Firebase Authentication and Firestore for your WalkMyPet application.

---

## 📋 Prerequisites

- [x] Firebase project created
- [x] `google-services.json` added to `android/app/`
- [x] `GoogleService-Info.plist` added to `ios/Runner/`
- [ ] Google Sign-In enabled in Firebase Console
- [ ] Firestore database created
- [ ] Firestore security rules configured

---

## 🔐 Part 1: Enable Google Sign-In in Firebase Console

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **walkmypet-dff4e**

### Step 2: Enable Google Sign-In
1. In the left sidebar, click **Build** → **Authentication**
2. Click on the **Sign-in method** tab
3. Click **Add new provider**
4. Select **Google**
5. Toggle **Enable** to ON
6. Set **Project support email** (your email)
7. Click **Save**

### Step 3: Configure OAuth Consent Screen (if needed)
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to **APIs & Services** → **OAuth consent screen**
4. Fill in required fields:
   - App name: **WalkMyPet**
   - User support email: (your email)
   - Developer contact: (your email)
5. Click **Save and Continue**

### Step 4: Get SHA-1 Certificate Fingerprint (Android)

**For Debug Build:**
```bash
cd android
./gradlew signingReport
```

**Or using keytool:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For Release Build:**
```bash
keytool -list -v -keystore /path/to/your/release-key.keystore
```

Copy the **SHA-1** fingerprint.

### Step 5: Add SHA-1 to Firebase
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps**
3. Click on your Android app
4. Scroll to **SHA certificate fingerprints**
5. Click **Add fingerprint**
6. Paste your SHA-1
7. Click **Save**

### Step 6: Download Updated google-services.json
1. After adding SHA-1, download the updated `google-services.json`
2. Replace the file in `android/app/google-services.json`

**The new file should have oauth_client entries like:**
```json
{
  "oauth_client": [
    {
      "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
      "client_type": 3
    }
  ]
}
```

---

## 📊 Part 2: Set Up Firestore Database

### Step 1: Create Firestore Database
1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (we'll add security rules later)
4. Choose a location (closest to your users)
5. Click **Enable**

### Step 2: Create Firestore Security Rules

In the Firebase Console, go to **Firestore Database** → **Rules** and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function to check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      // Anyone can read user profiles (needed for walker/owner listings)
      allow read: if true;

      // Only authenticated users can create their own profile
      allow create: if isAuthenticated() && isOwner(userId);

      // Only the user can update their own profile
      allow update: if isAuthenticated() && isOwner(userId);

      // Only the user can delete their own profile
      allow delete: if isAuthenticated() && isOwner(userId);
    }

    // Bookings collection (future feature)
    match /bookings/{bookingId} {
      // Users can read their own bookings
      allow read: if isAuthenticated() && (
        resource.data.ownerId == request.auth.uid ||
        resource.data.walkerId == request.auth.uid
      );

      // Users can create bookings
      allow create: if isAuthenticated();

      // Only booking participants can update
      allow update: if isAuthenticated() && (
        resource.data.ownerId == request.auth.uid ||
        resource.data.walkerId == request.auth.uid
      );

      // Only booking participants can delete
      allow delete: if isAuthenticated() && (
        resource.data.ownerId == request.auth.uid ||
        resource.data.walkerId == request.auth.uid
      );
    }
  }
}
```

Click **Publish** to apply the rules.

---

## 🧪 Part 3: Test the Integration

### Test Account Creation (Email/Password)

1. Run the app: `flutter run`
2. Navigate to **Register** tab
3. Click **Pet Owner** or **Pet Walker**
4. Fill in email and password
5. Click **Create Account**

**Expected Result:**
- ✅ Success notification appears
- ✅ User is redirected back
- ✅ Check Firestore Console → users collection → new document with user's UID

### Test Google Sign-In

1. Click **Continue with Google**
2. Select a Google account
3. Approve permissions

**Expected Result:**
- ✅ Success notification appears
- ✅ User is redirected back
- ✅ Check Firestore Console → users collection → new document with Google user data

### Verify Data in Firestore

Go to Firebase Console → Firestore Database → users collection

You should see documents like:
```
users/
  {userId}/
    - email: "user@example.com"
    - displayName: "John Doe"
    - photoURL: "https://..." (if Google Sign-In)
    - userType: "petOwner" or "petWalker"
    - createdAt: Timestamp
    - updatedAt: Timestamp (if updated)
```

---

## 🐛 Troubleshooting

### Google Sign-In Shows "Error 10"
**Cause:** SHA-1 fingerprint not configured

**Solution:**
1. Generate SHA-1 as shown in Step 4
2. Add it to Firebase as shown in Step 5
3. Download updated `google-services.json`
4. Run `flutter clean && flutter pub get`
5. Rebuild the app

### "No user from sign in result"
**Cause:** OAuth client not configured

**Solution:**
1. Verify `google-services.json` has `oauth_client` array with entries
2. Re-download from Firebase Console if empty
3. Ensure Google Sign-In is enabled in Authentication methods

### "User cancelled the sign-in"
**Cause:** User closed Google Sign-In popup

**Solution:** This is normal behavior, no action needed

### "Failed to create user profile"
**Cause:** Firestore security rules too restrictive or network error

**Solution:**
1. Check Firestore rules allow user creation
2. Verify internet connection
3. Check Firebase Console → Firestore → Logs for errors

### Email/Password Sign-Up Fails
**Cause:** Weak password or email already in use

**Solution:**
1. Use password with at least 6 characters
2. Use different email if already registered
3. Check Firebase Console → Authentication → Users to see existing accounts

---

## 📱 Platform-Specific Setup

### Android Configuration (already done)

File: `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Already added
}
```

File: `android/build.gradle.kts`
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0") // ✅ Already added
    }
}
```

### iOS Configuration (additional steps)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add GoogleService-Info.plist to Runner target:
   - Right-click on Runner → Add Files to "Runner"
   - Select `ios/Runner/GoogleService-Info.plist`
   - Check "Copy items if needed"
   - Click **Add**

3. Update `ios/Runner/Info.plist`:
```xml
<!-- Get the REVERSED_CLIENT_ID from GoogleService-Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value from `GoogleService-Info.plist`.

---

## ✅ Verification Checklist

Before deploying to production:

- [ ] Google Sign-In enabled in Firebase Console
- [ ] SHA-1 fingerprint added (debug AND release)
- [ ] Updated `google-services.json` with oauth_client
- [ ] Firestore database created
- [ ] Firestore security rules configured
- [ ] Test email/password sign-up works
- [ ] Test Google Sign-In works
- [ ] Verify user data appears in Firestore
- [ ] Test sign-in with existing account
- [ ] Test error handling (wrong password, etc.)

---

## 🔒 Security Best Practices

1. **Never commit sensitive keys** to version control
2. **Use environment-specific configs** (dev, staging, prod)
3. **Enable App Check** for production (prevents API abuse)
4. **Set up billing alerts** in Google Cloud Console
5. **Review Firestore security rules** regularly
6. **Enable 2FA** on your Firebase account
7. **Rotate API keys** periodically

---

## 📚 Additional Resources

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

## 🎯 Next Steps

After Firebase is fully configured:

1. **Test thoroughly** with multiple accounts
2. **Add profile completion** flow (add pet details, bio, etc.)
3. **Implement booking system** using Firestore
4. **Add real-time updates** with Firestore snapshots
5. **Set up Cloud Functions** for server-side logic
6. **Add push notifications** via Firebase Cloud Messaging

---

**Your Firebase backend is ready! 🚀**
