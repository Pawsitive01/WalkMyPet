# WalkMyPet 🐾

A Flutter mobile application that connects pet owners with trusted pet walkers. Book walks, track your pet's activity, and make secure payments through the app.

## Features

- 👤 **User Profiles** - Separate profiles for pet owners and walkers
- 🗓️ **Booking System** - Schedule walks with your preferred walker
- 💳 **Stripe Payments** - Secure payment processing with Stripe
- 📍 **GPS Tracking** - Real-time walk tracking with Google Maps
- 🔔 **Push Notifications** - Stay updated on booking status
- ⭐ **Reviews & Ratings** - Rate your experience
- 💰 **Wallet System** - Walkers can track earnings and request withdrawals

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Cloud Functions, Authentication, Cloud Messaging)
- **Payments**: Stripe
- **Maps**: Google Maps API
- **State Management**: Provider
- **Platform**: Android & iOS

## Getting Started

### Prerequisites

- Flutter SDK (>=3.9.0)
- Firebase account
- Stripe account
- Android Studio / Xcode
- Node.js (for Cloud Functions)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd WalkMyPet
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Install Firebase Functions dependencies:
   ```bash
   cd functions
   npm install
   cd ..
   ```

4. Configure Firebase:
   - Add your `google-services.json` (Android)
   - Add your `GoogleService-Info.plist` (iOS)

5. Set up Stripe (see Stripe Integration section below)

### Running the App

```bash
flutter run
```

## 💳 Stripe Integration

This app includes a complete Stripe payment integration for processing bookings.

### Quick Setup

**Option 1: Automated Setup (Recommended)**
```bash
./setup-stripe.sh
```

**Option 2: Manual Setup**
See [`STRIPE_QUICKSTART.md`](./STRIPE_QUICKSTART.md) for a 10-minute setup guide.

### Documentation

| Document | Description |
|----------|-------------|
| [`STRIPE_QUICKSTART.md`](./STRIPE_QUICKSTART.md) | Get started in 10 minutes |
| [`STRIPE_SETUP.md`](./STRIPE_SETUP.md) | Complete setup instructions |
| [`STRIPE_PLATFORM_CONFIG.md`](./STRIPE_PLATFORM_CONFIG.md) | Android/iOS configuration |
| [`STRIPE_TESTING_GUIDE.md`](./STRIPE_TESTING_GUIDE.md) | Comprehensive testing guide |

### Payment Flow

1. Pet owner creates a booking
2. Proceeds to checkout and selects Stripe
3. Enters payment details in Stripe payment sheet
4. Payment processed securely through Stripe
5. Cloud Function creates booking in Firestore
6. Walker receives notification
7. Platform takes 15% fee, walker receives 85%

### Test Cards

For testing in Stripe test mode:

| Card Number          | Result    |
|---------------------|-----------|
| 4242 4242 4242 4242 | ✅ Success |
| 4000 0000 0000 9995 | ❌ Declined |
| 4000 0025 0000 3155 | 🔐 Auth Required |

## Project Structure

```
WalkMyPet/
├── lib/
│   ├── booking/          # Booking and checkout pages
│   ├── config/           # App configuration (Stripe, Firebase)
│   ├── models/           # Data models
│   ├── owner/            # Pet owner features
│   ├── profile/          # User profiles
│   ├── services/         # Business logic services
│   ├── walker/           # Pet walker features
│   └── main.dart         # App entry point
├── functions/            # Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts     # Notification functions
│   │   └── payments.ts  # Stripe payment functions
│   └── package.json
├── android/              # Android app
├── ios/                  # iOS app
└── assets/              # Images and resources
```

## Firebase Cloud Functions

The app includes several Cloud Functions:

### Notification Functions
- `onBookingCreated` - Notifies walker of new booking
- `onBookingStatusUpdated` - Notifies owner of booking updates
- `onReviewCreated` - Notifies user of new review
- `onMessageCreated` - Notifies user of new message

### Payment Functions
- `createPaymentIntent` - Creates Stripe payment intent
- `handleStripeWebhook` - Processes Stripe webhook events

### Deploying Functions

```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

## Configuration

### Stripe Keys

Edit `lib/config/stripe_config.dart`:

```dart
static const String publishableKey = 'pk_test_YOUR_KEY'; // Development
static const String publishableKey = 'pk_live_YOUR_KEY'; // Production
```

Configure secrets:
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"
```

### Google Maps

Add your Google Maps API key in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`

## Development

### Run with Firebase Emulators

```bash
firebase emulators:start
```

### Build for Production

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Testing

### Run Flutter Tests
```bash
flutter test
```

### Payment Testing
See [`STRIPE_TESTING_GUIDE.md`](./STRIPE_TESTING_GUIDE.md) for comprehensive payment testing scenarios.

## Platform Fee

The app takes a 15% platform fee on all bookings:
- Walker receives: 85% of booking price
- Platform receives: 15% of booking price
- Stripe fee: 2.9% + $0.30 AUD (deducted separately)

## Security

- ✅ Secret keys stored in Firebase Functions config (not in code)
- ✅ Webhook signature verification
- ✅ Server-side amount validation
- ✅ Authentication required for payments
- ✅ Firestore security rules
- ✅ HTTPS only

## Troubleshooting

### Payment Issues

```bash
# Check Firebase Functions logs
firebase functions:log --only handleStripeWebhook

# Verify configuration
firebase functions:config:get

# Test webhook
# Go to Stripe Dashboard → Webhooks → Send test webhook
```

### Common Issues

1. **"Stripe is not configured"**
   - Set secret key: `firebase functions:config:set stripe.secret_key="sk_..."`
   - Redeploy: `firebase deploy --only functions`

2. **Webhook not receiving events**
   - Verify webhook URL in Stripe Dashboard
   - Check webhook secret is configured
   - Ensure functions are deployed

3. **Payment succeeds but no booking**
   - Check Cloud Functions logs for errors
   - Verify webhook signature
   - Check Firestore permissions

## Support

- **Stripe**: https://stripe.com/docs
- **Firebase**: https://firebase.google.com/docs
- **Flutter**: https://docs.flutter.dev/

## License

[Add your license here]

## Contributors

[Add contributors here]

---

Made with ❤️ by the WalkMyPet team
