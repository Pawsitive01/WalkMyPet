# 🚀 WalkMyPet Quick Reference

Essential commands and information for development.

---

## 🔧 Development Commands

### Run the App
```bash
flutter run
```

### Run on Specific Device
```bash
flutter devices                    # List all devices
flutter run -d android             # Run on Android
flutter run -d ios                 # Run on iOS
flutter run -d chrome              # Run on Chrome (web)
```

### Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### View Logs
```bash
flutter logs                       # View all logs
flutter logs | grep "📝"          # Filter for specific logs
```

### Build for Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🔑 Firebase Quick Commands

### Get SHA-1 Fingerprint (Android)
```bash
cd android
./gradlew signingReport
```

Or using keytool:
```bash
# Debug
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release
keytool -list -v -keystore /path/to/release.keystore
```

### Firebase Emulator (Local Development)
```bash
firebase emulators:start
```

---

## 📁 Important File Locations

### Firebase Configuration
```
android/app/google-services.json          # Android config
ios/Runner/GoogleService-Info.plist       # iOS config
```

### Authentication Services
```
lib/services/auth_service.dart            # Firebase Auth
lib/services/user_service.dart            # Firestore user management
```

### Auth Pages
```
lib/booking_authentication_page.dart      # Main auth UI
lib/user_type_selection_page.dart         # Register page
```

### Models
```
lib/models.dart                            # Walker, Owner, Person
lib/services/user_service.dart             # AppUser, UserType
```

---

## 🎨 Design System

### Colors

**Walker (Purple)**
```dart
Primary: #6366F1
Secondary: #8B5CF6
Tertiary: #7C3AED
```

**Owner (Pink)**
```dart
Primary: #EC4899
Secondary: #F472B6
Tertiary: #DB2777
```

**Success**
```dart
#10B981 (Emerald)
```

**Error**
```dart
#EF4444 (Red)
```

**Neutral**
```dart
Dark: #0F172A (Slate 900)
Mid: #64748B (Slate 500)
Light: #F8FAFC (Slate 50)
```

### Typography Scale
```dart
Hero:    32px / w800 / -0.8 tracking
Title:   24px / w600 / -0.5 tracking
Body:    16px / w400 / 0 tracking
Caption: 14px / w500 / 0.1 tracking
Label:   13px / w600 / 0.2 tracking
```

### Spacing (8px grid)
```dart
xs:  8px
sm:  12px
md:  16px
lg:  24px
xl:  32px
2xl: 48px
3xl: 64px
```

### Border Radius
```dart
Small:  8px   (inputs, tags)
Medium: 16px  (buttons, cards)
Large:  24px  (main containers)
Round:  999px (pills, avatars)
```

---

## 🗄️ Firestore Structure

### Collections

**users/** (Main user profiles)
```json
{
  "userId": {
    "email": "string",
    "displayName": "string",
    "photoURL": "string?",
    "userType": "petOwner" | "petWalker",
    "createdAt": "Timestamp",
    "updatedAt": "Timestamp?",

    // Pet Owner fields
    "dogName": "string?",
    "dogBreed": "string?",
    "dogAge": "string?",

    // Pet Walker fields
    "hourlyRate": "number?",
    "bio": "string?",
    "availability": "array<string>?"
  }
}
```

**bookings/** (Future implementation)
```json
{
  "bookingId": {
    "ownerId": "string",
    "walkerId": "string",
    "date": "Timestamp",
    "duration": "number",
    "status": "pending" | "confirmed" | "completed" | "cancelled",
    "price": "number",
    "createdAt": "Timestamp"
  }
}
```

---

## 🔐 Authentication Flow

### Email/Password Sign-Up
```
User fills form
  ↓
AuthService.signUpWithEmail()
  ↓
Firebase Auth creates account
  ↓
UserService.createUser()
  ↓
Firestore document created
  ↓
Success → Navigate back
```

### Google Sign-In
```
User clicks "Continue with Google"
  ↓
AuthService.signInWithGoogle()
  ↓
Google OAuth flow
  ↓
Firebase Auth credential
  ↓
UserService.createUser() (or update if exists)
  ↓
Firestore document created/updated
  ↓
Success → Navigate back
```

---

## 🐛 Debugging Tips

### Enable Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Check Firebase Connection
In your app, add temporary logging:
```dart
print('Firebase project: ${FirebaseOptions.currentPlatform.projectId}');
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
```

### View Firestore Data
```bash
# Firebase console
https://console.firebase.google.com/project/walkmypet-dff4e/firestore

# Or use Firebase CLI
firebase firestore:indexes
```

### Check Google Sign-In Config
```dart
// Add to auth_service.dart temporarily
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);
print('Google Sign-In configured: ${googleSignIn.currentUser != null}');
```

---

## 📊 Monitoring & Analytics

### Firebase Console Quick Links
```
Project: walkmypet-dff4e

Authentication: https://console.firebase.google.com/project/walkmypet-dff4e/authentication/users
Firestore: https://console.firebase.google.com/project/walkmypet-dff4e/firestore
Storage: https://console.firebase.google.com/project/walkmypet-dff4e/storage
Crashlytics: https://console.firebase.google.com/project/walkmypet-dff4e/crashlytics
```

### Useful Firestore Queries (Console)
```javascript
// All pet walkers
users where userType == "petWalker"

// All pet owners
users where userType == "petOwner"

// Recent sign-ups (last 24h)
users where createdAt > [timestamp from yesterday]
```

---

## 🧪 Testing Accounts

### Email/Password Test Accounts
```
Owner:
  Email: testowner@example.com
  Password: password123

Walker:
  Email: testwalker@example.com
  Password: password123
```

### Delete Test Accounts
```bash
# Via Firebase Console
Authentication → Users → Select user → Delete

# Or via Firebase CLI
firebase auth:delete testowner@example.com
```

---

## 📱 Navigation Mapping

### From Main Screen
```
Walker Panel → "Book Walker" → Owner Auth (pink)
Owner Panel → "Add Your Pet" → Owner Auth (pink)
```

### From Register Tab
```
Pet Owner card → Owner Auth (pink)
Pet Walker card → Walker Auth (purple)
```

### From Detail Pages
```
Walker Detail → "Book Walk" → Owner Auth (pink)
Owner Detail → "Add Your Pet" → Walker Auth (purple)
```

### Cross-Navigation (Bottom Buttons)
```
Owner Auth → "Register as Pet Walker" → Walker Auth (purple)
Walker Auth → "Register as Pet Owner" → Owner Auth (pink)
```

---

## ⚡ Performance Tips

### Optimize Firestore Reads
```dart
// Use snapshots for real-time data
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .snapshots()

// Use .get() for one-time reads
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .get()
```

### Reduce Build Size
```bash
# Remove unused imports
flutter pub run dart_code_metrics:check-unused-files lib

# Analyze bundle size
flutter build apk --analyze-size
```

### Cache Network Images
```dart
// Already implemented in existing code
CachedNetworkImage(
  imageUrl: photoURL,
  placeholder: (context, url) => CircularProgressIndicator(),
)
```

---

## 🔒 Security Checklist

### Before Production
- [ ] Update Firestore security rules (remove test mode)
- [ ] Enable App Check
- [ ] Set up rate limiting
- [ ] Add SHA-256 for release builds
- [ ] Review API keys exposure
- [ ] Enable Firebase Authentication email verification
- [ ] Set up billing alerts
- [ ] Configure backup rules
- [ ] Add error reporting (Crashlytics)
- [ ] Test all auth flows on production

---

## 📞 Support Resources

### Documentation
- Flutter: https://flutter.dev/docs
- Firebase: https://firebase.google.com/docs
- FlutterFire: https://firebase.flutter.dev

### Community
- Flutter Discord: https://discord.gg/flutter
- StackOverflow: Tag with `flutter` and `firebase`
- GitHub Issues: https://github.com/firebase/flutterfire/issues

### WalkMyPet Specific
- Firebase Setup: `FIREBASE_SETUP.md`
- Testing Guide: `TESTING_GUIDE.md`
- Quick Reference: `QUICK_REFERENCE.md` (this file)

---

## 🎯 Current MVP Features

✅ **Implemented:**
- Email/Password authentication
- Google Sign-In
- Firestore user profiles
- Role-based auth (Owner/Walker)
- Cross-navigation between roles
- Form validation
- Error handling
- Responsive design
- Dark mode support

🔜 **Coming Soon:**
- Profile completion flow
- Pet details for owners
- Walker portfolio
- Booking system
- Real-time messaging
- Reviews & ratings
- Payment integration
- Push notifications

---

## 🚨 Emergency Commands

### Reset Everything (Nuclear Option)
```bash
flutter clean
rm -rf android/.gradle
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf pubspec.lock
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Fix iOS Pods Issues
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod repo update
pod install
cd ..
flutter run
```

### Fix Android Build Issues
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

**Keep this handy for quick reference during development! 📌**
