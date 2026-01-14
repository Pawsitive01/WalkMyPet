# Stripe Platform-Specific Configuration

This guide covers Android and iOS specific configurations for Stripe integration.

## 📱 Android Configuration

The `flutter_stripe` package handles most Android configuration automatically. However, verify these settings:

### Minimum SDK Version

Ensure your `android/app/build.gradle.kts` has:

```kotlin
defaultConfig {
    minSdk = 21  // Stripe requires Android 5.0+
}
```

✅ **Current Configuration**: Using `flutter.minSdkVersion` (should be >= 21)

### Permissions

No special permissions are required for Stripe on Android. The package handles everything.

### ProGuard Rules (Release Builds)

If you encounter issues with release builds, add these ProGuard rules to `android/app/proguard-rules.pro`:

```
# Stripe
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }
```

### Testing on Android

1. Build the app:
   ```bash
   flutter build apk --debug
   ```

2. Install on device:
   ```bash
   flutter install
   ```

3. Test payment flow with Stripe test cards

## 🍎 iOS Configuration

### Minimum iOS Version

The `flutter_stripe` package requires iOS 13.0+.

Verify in `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

### Install Pods

After adding the package, install iOS dependencies:

```bash
cd ios
pod install
cd ..
```

### App Transport Security

Stripe requires HTTPS, but local development might need HTTP. If testing with local emulators, add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

⚠️ **DO NOT** disable ATS entirely in production.

### Testing on iOS Simulator

1. Build for iOS:
   ```bash
   flutter build ios --debug
   ```

2. Open in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

3. Select a simulator and run

### Testing on Physical iOS Device

1. Connect your iOS device
2. In Xcode, select your device
3. Sign the app with your Apple Developer account
4. Run the app

### Apple Pay (Future Feature)

If you plan to enable Apple Pay:

1. Add capability in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Apple Pay"

2. Configure merchant ID in Stripe Dashboard

3. Update `stripe_config.dart`:
   ```dart
   static const String merchantIdentifier = 'merchant.com.walkmypet';
   ```

## 🧪 Testing on Both Platforms

### Test Card Numbers

| Card Number          | Expected Result           | Platform      |
|---------------------|---------------------------|---------------|
| 4242 4242 4242 4242 | Success                   | Both          |
| 4000 0000 0000 9995 | Declined                  | Both          |
| 4000 0025 0000 3155 | Requires Authentication   | Both          |
| 4000 0000 0000 3220 | 3D Secure 2 Authentication| Both          |

Use these details for any test card:
- **Expiry**: Any future date (e.g., 12/34)
- **CVC**: Any 3 digits (e.g., 123)
- **ZIP/Postal Code**: Any valid format (e.g., 12345)

### Platform-Specific Behaviors

#### Android
- Uses Material Design payment sheet
- Supports Google Pay (when enabled)
- Hardware back button cancels payment

#### iOS
- Uses iOS native payment sheet
- Supports Apple Pay (when enabled)
- Swipe down to cancel

## 🔧 Troubleshooting

### Android Issues

**Issue: "Unable to find Stripe SDK"**

Solution:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Issue: Payment sheet doesn't appear**

Solution:
- Check that you've called `Stripe.instance.applySettings()`
- Verify publishable key is set
- Check Android logs: `flutter run -v`

**Issue: Release build crashes**

Solution:
- Add ProGuard rules (see above)
- Test with: `flutter build apk --release`

### iOS Issues

**Issue: "Module not found: Stripe"**

Solution:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

**Issue: Payment sheet doesn't appear**

Solution:
- Ensure iOS version is 13.0+
- Check iOS logs in Xcode console
- Verify Stripe is initialized in `main.dart`

**Issue: Bitcode error**

Solution: Stripe SDK doesn't support Bitcode. Disable it in Xcode:
- Build Settings → Build Options → Enable Bitcode → No

## 📊 Performance Optimization

### Android
- Enable R8/ProGuard for release builds (already enabled)
- Use app bundles: `flutter build appbundle`

### iOS
- Enable optimizations in release mode (default)
- Use TestFlight for beta testing

## 🔐 Security Checklist

### Android
- [ ] Obfuscation enabled (ProGuard/R8)
- [ ] Network security config set (HTTPS only)
- [ ] No API keys in manifest or strings.xml
- [ ] Certificate pinning (optional, for production)

### iOS
- [ ] App Transport Security configured
- [ ] No API keys in Info.plist
- [ ] Code signing configured
- [ ] Certificate pinning (optional, for production)

## 📱 Device Testing Recommendations

### Minimum Testing Matrix

| Platform | Version | Device Type     | Priority |
|----------|---------|-----------------|----------|
| Android  | 13      | Physical Device | High     |
| Android  | 11      | Emulator        | Medium   |
| Android  | 9       | Emulator        | Low      |
| iOS      | 17      | Physical Device | High     |
| iOS      | 15      | Simulator       | Medium   |
| iOS      | 13      | Simulator       | Low      |

### Recommended Test Scenarios

1. ✅ Successful payment
2. ✅ Declined card
3. ✅ Network timeout (airplane mode)
4. ✅ App backgrounding during payment
5. ✅ Payment cancellation
6. ✅ Multiple rapid payment attempts
7. ✅ Different card types (Visa, Mastercard, Amex)

## 🚀 Deployment Checklist

### Before Going Live

#### Android
- [ ] Switch to live Stripe keys in `stripe_config.dart`
- [ ] Build release APK/AAB
- [ ] Test on multiple devices
- [ ] Upload to Google Play Console (Internal Testing)
- [ ] Test with real cards (small amounts)
- [ ] Submit for production

#### iOS
- [ ] Switch to live Stripe keys in `stripe_config.dart`
- [ ] Build release IPA
- [ ] Test on multiple devices
- [ ] Upload to TestFlight
- [ ] Test with real cards (small amounts)
- [ ] Submit for App Store review

### Post-Launch Monitoring

1. Monitor Stripe Dashboard for:
   - Payment success rates
   - Declined payments
   - Disputed charges

2. Monitor Firebase:
   - Cloud Functions logs
   - Firestore writes
   - Error rates

3. Monitor app analytics:
   - Payment completion rates
   - Drop-off points
   - User feedback

## 📞 Support Resources

### Flutter Stripe Package
- GitHub: https://github.com/flutter-stripe/flutter_stripe
- Pub.dev: https://pub.dev/packages/flutter_stripe
- Issues: https://github.com/flutter-stripe/flutter_stripe/issues

### Platform-Specific
- Android Docs: https://stripe.com/docs/mobile/android
- iOS Docs: https://stripe.com/docs/mobile/ios
- Flutter Integration: https://stripe.com/docs/payments/accept-a-payment?platform=flutter

## ✅ Configuration Complete

Your platform-specific Stripe configuration is complete! The `flutter_stripe` package handles most of the heavy lifting automatically.

**Key Points:**
- ✅ Android works out of the box (minSdk 21+)
- ✅ iOS requires iOS 13.0+ and pod install
- ✅ No special permissions needed
- ✅ Test thoroughly on both platforms before production

For the full setup process, see `STRIPE_SETUP.md`.
