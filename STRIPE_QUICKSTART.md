# Stripe Integration Quick Start

Get your Stripe payment integration up and running in 10 minutes.

## 🚀 Quick Setup (10 minutes)

### Step 1: Get Stripe Keys (2 minutes)

1. Sign up at https://stripe.com (if you haven't already)
2. Go to https://dashboard.stripe.com/test/apikeys
3. Copy your **Publishable key** (`pk_live_...`)
4. Copy your **Secret key** (`sk_live_...`)

### Step 2: Run Setup Script (3 minutes)

```bash
cd /home/user/WalkMyPet
./setup-stripe.sh
```

The script will:
- ✅ Configure Stripe secret key
- ✅ Build Cloud Functions
- ✅ Deploy to Firebase
- ✅ Show you the webhook URL

### Step 3: Configure Webhook (2 minutes)

1. Go to https://dashboard.stripe.com/test/webhooks
2. Click **"Add endpoint"**
3. Paste the webhook URL from Step 2
4. Select events:
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
5. Click **"Add endpoint"**
6. Copy the **Signing secret** (`whsec_...`)
7. Run: `firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"`
8. Redeploy: `firebase deploy --only functions`

### Step 4: Test Payment (3 minutes)

1. Open WalkMyPet app
2. Select a walker
3. Create a booking
4. At checkout, select Stripe
5. Use test card: **4242 4242 4242 4242**
6. Expiry: **12/34**, CVC: **123**, ZIP: **12345**
7. Complete payment ✨

**Expected Result:**
- ✅ Payment succeeds
- ✅ Booking created
- ✅ Walker receives notification

## 📚 Full Documentation

- **Setup Guide**: [`STRIPE_SETUP.md`](./STRIPE_SETUP.md) - Complete setup instructions
- **Platform Config**: [`STRIPE_PLATFORM_CONFIG.md`](./STRIPE_PLATFORM_CONFIG.md) - Android/iOS configuration
- **Testing Guide**: [`STRIPE_TESTING_GUIDE.md`](./STRIPE_TESTING_GUIDE.md) - Comprehensive testing scenarios

## 🔍 Quick Verification

### Is it working?

Run these checks:

```bash
# 1. Check Firebase config
firebase functions:config:get

# Should show:
# {
#   "stripe": {
#     "secret_key": "sk_test_...",
#     "webhook_secret": "whsec_..."
#   }
# }

# 2. Check if functions are deployed
firebase functions:list

# Should show:
# - createPaymentIntent
# - handleStripeWebhook

# 3. Watch webhook events
firebase functions:log --only handleStripeWebhook
```

### Test the Flow

1. **Create booking** → Should reach checkout page ✅
2. **Select Stripe** → Payment sheet appears ✅
3. **Enter card details** → Validates correctly ✅
4. **Complete payment** → Success message ✅
5. **Check bookings** → Booking appears ✅
6. **Walker notification** → Walker receives push ✅

## ⚠️ Current Configuration Status

### ✅ Already Done
- ✅ Stripe SDK installed (`flutter_stripe: ^11.3.0`)
- ✅ Stripe service implemented
- ✅ Payment UI created
- ✅ Cloud Functions written
- ✅ Webhook handler implemented
- ✅ Transaction management
- ✅ Platform fee calculation (15%)
- ✅ Error handling
- ✅ Idempotency protection

### ⚠️ You Need To Do
- [ ] Configure Stripe secret key
- [ ] Configure webhook secret
- [ ] Deploy Cloud Functions
- [ ] Register webhook in Stripe
- [ ] Test end-to-end
- [ ] Switch to live keys for production

## 🎯 Current Setup

**App Configuration:**
- Publishable Key: `pk_live_51Sh...` (⚠️ **Live key** - consider test key for dev)
- Location: `lib/config/stripe_config.dart:22`
- Currency: AUD
- Merchant: WalkMyPet

**Backend:**
- Region: `australia-southeast1`
- Functions: `createPaymentIntent`, `handleStripeWebhook`
- Platform Fee: 15%

## 🔄 Development vs Production

### Use Test Keys for Development

Edit `lib/config/stripe_config.dart`:

```dart
// DEVELOPMENT
static const String publishableKey = 'pk_test_YOUR_TEST_KEY';

// PRODUCTION (when ready)
static const String publishableKey = 'pk_live_YOUR_LIVE_KEY';
```

And in Firebase:

```bash
# DEVELOPMENT
firebase functions:config:set stripe.secret_key="sk_test_YOUR_TEST_KEY"

# PRODUCTION (when ready)
firebase functions:config:set stripe.secret_key="sk_live_YOUR_LIVE_KEY"
```

## 💳 Test Cards

| Card               | Result  |
|-------------------|---------|
| 4242 4242 4242 4242 | ✅ Success |
| 4000 0000 0000 9995 | ❌ Declined |
| 4000 0025 0000 3155 | 🔐 Requires Auth |

## 🐛 Troubleshooting

### "Stripe is not configured"

```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"
firebase deploy --only functions
```

### Webhook not working

1. Check webhook URL is correct
2. Verify webhook secret: `firebase functions:config:get`
3. Check logs: `firebase functions:log --only handleStripeWebhook`

### Payment succeeds but no booking

Check logs:
```bash
firebase functions:log --only handleStripeWebhook
```

Look for errors in booking creation.

## 📊 Architecture Overview

```
Flutter App
    ↓
StripeService.processPayment()
    ↓
createPaymentIntent (Cloud Function)
    ↓
Stripe API (creates PaymentIntent)
    ↓
Payment Sheet (user pays)
    ↓
Stripe Webhook → handleStripeWebhook
    ↓
Create Booking + Transaction in Firestore
    ↓
Send Notification to Walker
    ↓
App polls for booking
    ↓
Success! 🎉
```

## 🎯 What Each File Does

| File | Purpose |
|------|---------|
| `lib/config/stripe_config.dart` | Stripe keys and settings |
| `lib/services/stripe_service.dart` | Flutter payment logic |
| `lib/services/payment_service.dart` | Transaction management |
| `functions/src/payments.ts` | Backend payment handling |
| `lib/booking/checkout_page.dart` | Payment UI |

## ✅ Pre-Launch Checklist

Before going live:

- [ ] All tests passing
- [ ] Webhook reliably receiving events
- [ ] Tested on real devices
- [ ] Error handling verified
- [ ] Switched to live Stripe keys
- [ ] Tested with real card (small amount)
- [ ] Monitoring set up
- [ ] Support process ready

## 💰 Fees & Pricing

**Stripe Fees:**
- 2.9% + $0.30 AUD per transaction

**Platform Fee:**
- 15% of booking price

**Example ($100 booking):**
- Customer pays: $100.00
- Stripe fee: ~$3.20
- Platform fee: $15.00
- Walker receives: $85.00

## 🎉 You're Ready!

Follow the 4 steps above, and you'll be accepting payments in 10 minutes.

**Need help?** Check the full documentation:
- [`STRIPE_SETUP.md`](./STRIPE_SETUP.md)
- [`STRIPE_TESTING_GUIDE.md`](./STRIPE_TESTING_GUIDE.md)

**Ready to test?** Use card `4242 4242 4242 4242` with any future expiry.

Good luck! 🚀
