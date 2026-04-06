/// Stripe Configuration
///
/// This file contains the Stripe publishable key for the WalkMyPet application.
///
/// IMPORTANT SECURITY NOTES:
/// - This file should contain ONLY the publishable key (pk_test_... or pk_live_...)
/// - NEVER put secret keys (sk_test_... or sk_live_...) in this file
/// - Secret keys must only be stored in Firebase Cloud Functions environment
///
/// SETUP INSTRUCTIONS:
/// 1. Get your Stripe publishable key from https://dashboard.stripe.com/apikeys
/// 2. For development: Use test key (pk_test_...)
/// 3. For production: Use live key (pk_live_...)
/// 4. Replace the placeholder below with your actual key
library;

class StripeConfig {
  /// Stripe publishable key
  ///
  static const String publishableKey = 'pk_live_51ShuhgDlJWxucYHsDR2d7jNmYS6AlEVJFojf1bpLYDPyfBEwZEDsDE116FJQocnWfi8dtoQ7sKhIFN8w0gYfeoZX00up5rq3BC';

  /// Whether we're in test mode
  /// This is automatically determined by the key prefix
  static bool get isTestMode => publishableKey.startsWith('pk_test_');

  /// Merchant display name shown in payment UI
  static const String merchantDisplayName = 'WalkMyPet';

  /// Merchant country code (for Apple Pay / Google Pay)
  static const String merchantCountryCode = 'AU';

  /// Currency code
  static const String currencyCode = 'AUD';
}
