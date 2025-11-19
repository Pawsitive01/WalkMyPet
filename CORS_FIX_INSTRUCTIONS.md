# Fix CORS Error for Firebase Storage on Web

## The Problem
Your image uploaded successfully, but the browser can't display it due to CORS (Cross-Origin Resource Sharing) policy.

**Error:** `HTTP request failed, statusCode: 0`

This happens because Firebase Storage needs to be configured to allow your web app to access the images.

## Solution: Configure CORS

You need to apply CORS configuration to your Firebase Storage bucket. Here are multiple ways to do it:

---

## Option 1: Using Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/project/walkmypet-dff4e/storage)
2. Click on **Storage** in the left sidebar
3. Click the **three dots** (⋮) menu at the top right
4. Select **Edit CORS configuration**
5. Paste this configuration:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```

6. Click **Save**

---

## Option 2: Using Google Cloud Console

1. Go to [Google Cloud Storage Browser](https://console.cloud.google.com/storage/browser?project=walkmypet-dff4e)
2. Find your bucket: `walkmypet-dff4e.firebasestorage.app`
3. Click on the bucket name
4. Go to the **Configuration** tab
5. Scroll to **CORS configuration**
6. Click **Edit**
7. Add this configuration:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```

8. Click **Save**

---

## Option 3: Using gsutil Command (Terminal)

If you have gsutil installed and authenticated:

```bash
cd /home/user/WalkMyPet

# Make sure you're authenticated
gcloud auth login

# Apply CORS configuration
gsutil cors set cors.json gs://walkmypet-dff4e.firebasestorage.app
```

The `cors.json` file has already been created in your project root.

---

## Option 4: Temporary Fix - Test on Mobile/Desktop

CORS is only an issue on **web browsers**. Your images will work fine on:
- ✅ Mobile apps (iOS/Android)
- ✅ Desktop apps (Linux/Windows/Mac)

To test without fixing CORS:
```bash
# Run on mobile emulator
flutter run -d <device-id>

# Or build for desktop
flutter run -d linux
```

---

## Verify CORS is Fixed

After applying the CORS configuration:

1. **Clear browser cache** (Ctrl+Shift+R or Cmd+Shift+R)
2. **Restart your Flutter web app**
3. **Upload a new image**
4. The image should display correctly!

---

## What the CORS Config Does

```json
{
  "origin": ["*"],           // Allows all origins (for development)
  "method": ["GET", "HEAD"], // Allows reading images
  "maxAgeSeconds": 3600      // Cache CORS response for 1 hour
}
```

### For Production (More Secure)

Replace `"*"` with your actual domain:

```json
{
  "origin": ["https://yourdomain.com"],
  "method": ["GET", "HEAD"],
  "maxAgeSeconds": 3600
}
```

---

## Expected Result

After fixing CORS, you should see:
```
✅ UI updated with new image immediately!
✅ Image URL saved to Firestore
[Image displays successfully in the circle]
```

No more "HTTP request failed, statusCode: 0" error!

---

## Need Help?

If you continue to have issues:
1. Make sure you're using the correct bucket name: `walkmypet-dff4e.firebasestorage.app`
2. Wait a few minutes after applying CORS (can take time to propagate)
3. Clear browser cache completely
4. Try in an incognito/private window

---

**Quick Test:** After fixing CORS, refresh your app and the image should load!
