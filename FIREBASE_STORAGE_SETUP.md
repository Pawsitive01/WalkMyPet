# Firebase Storage Setup Guide

Your image upload is failing because Firebase Storage needs to be enabled and configured. Follow these steps:

## Option 1: Enable Firebase Storage in Production (Recommended)

### Step 1: Enable Storage in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **walkmypet-dff4e**
3. Click **Storage** in the left sidebar
4. Click **Get Started**
5. Choose your storage location (select closest to Australia, e.g., `asia-southeast1` or `australia-southeast1`)
6. Click **Done**

### Step 2: Update Storage Rules

1. In Firebase Console > Storage, click **Rules** tab
2. Replace the rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images
    match /profile_images/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
      allow delete: if request.auth != null;
    }

    // Pet images
    match /pet_images/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
      allow delete: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

### Step 3: Test Image Upload

1. Restart your Flutter app
2. Log in as a user
3. Try uploading a pet image
4. Check the console logs for upload progress
5. Verify the image appears in Firebase Console > Storage

---

## Option 2: Use Firebase Emulators for Local Development

If you want to test locally without using production Firebase:

### Step 1: Enable Emulators

Edit `lib/services/firebase_emulator_config.dart`:

```dart
static const bool _useEmulators = true; // Change to true
```

### Step 2: Start Emulators

```bash
firebase emulators:start
```

### Step 3: Run Your App

```bash
flutter run -d linux
```

The app will now use local emulators for Auth, Firestore, and Storage.

---

## Troubleshooting

### Error: "Permission denied"

**Solution:** Make sure Storage rules allow authenticated users to upload:
- Check Firebase Console > Storage > Rules
- Verify `allow write: if request.auth != null`

### Error: "Network error"

**Solution:** Check your internet connection and Firebase project status

### Error: "File too large"

**Solution:** Images must be under 5MB. The app automatically compresses to 1080px.

### Error: "Unauthorized"

**Solution:** Make sure user is logged in:
```dart
FirebaseAuth.instance.currentUser != null
```

---

## Verify Setup

Check the Flutter console logs when uploading:

```
✅ Good logs:
Starting upload for user: abc123
File path: /path/to/image.jpg
File size: 245678 bytes
Upload progress: 50.00%
Upload progress: 100.00%
Upload completed successfully
Download URL: https://firebasestorage.googleapis.com/...

❌ Bad logs:
Firebase error: unauthorized
Error uploading image: Permission denied
```

---

## Quick Test

1. **Enable Storage** in Firebase Console
2. **Update Rules** to allow authenticated uploads
3. **Restart app**
4. **Try uploading** a pet image
5. **Check logs** for success/error messages

Need help? Check Firebase Console > Storage for uploaded files!
