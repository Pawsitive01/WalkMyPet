# Stripe Payment Integration Setup Guide

This guide will help you complete the Stripe payment integration for WalkMyPet.

## 📋 Prerequisites

- Firebase project created and configured
- Stripe account (sign up at https://stripe.com)
- Firebase CLI installed (`npm install -g firebase-tools`)
- Flutter environment set up

## 🔑 Step 1: Get Your Stripe API Keys

1. Log in to your Stripe Dashboard: https://dashboard.stripe.com
2. Navigate to **Developers** → **API keys**
3. You'll need:
   - **Publishable key** (starts with `pk_test_` or `pk_live_`)
   - **Secret key** (starts with `sk_test_` or `sk_live_`)

### Development vs Production

- **Test Mode**: Use `pk_test_` and `sk_test_` keys for development
- **Live Mode**: Use `pk_live_` and `sk_live_` keys for production

⚠️ **Currently configured with LIVE keys** - Consider switching to test keys for development.

## ⚙️ Step 2: Configure Firebase Cloud Functions

### 2.1 Set Stripe Secret Key

```bash
cd /home/user/WalkMyPet
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY_HERE"
```

### 2.2 Verify Configuration

```bash
firebase functions:config:get
```

You should see:
```json
{
  "stripe": {
    "secret_key": "sk_test_..."
  }
}
```

### 2.3 Update Local Development Config (Optional)

For local testing with Firebase emulators:

```bash
cd functions
firebase functions:config:get > .runtimeconfig.json
```

## 🚀 Step 3: Deploy Cloud Functions

```bash
cd /home/user/WalkMyPet
firebase deploy --only functions
```

This will deploy:
- `createPaymentIntent` - Creates Stripe payment intents
- `handleStripeWebhook` - Processes Stripe webhook events

After deployment, note the function URLs:
```
https://australia-southeast1-YOUR_PROJECT_ID.cloudfunctions.net/createPaymentIntent
https://australia-southeast1-YOUR_PROJECT_ID.cloudfunctions.net/handleStripeWebhook
```

## 🔗 Step 4: Configure Stripe Webhook

### 4.1 Register Webhook Endpoint

1. Go to Stripe Dashboard: https://dashboard.stripe.com/webhooks
2. Click **Add endpoint**
3. Enter your webhook URL:
   ```
   https://australia-southeast1-YOUR_PROJECT_ID.cloudfunctions.net/handleStripeWebhook
   ```
4. Select events to listen for:
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
5. Click **Add endpoint**

### 4.2 Get Webhook Signing Secret

1. Click on your newly created webhook endpoint
2. Find the **Signing secret** (starts with `whsec_`)
3. Click **Reveal** to see the full secret

### 4.3 Configure Webhook Secret in Firebase

```bash
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET_HERE"
```

### 4.4 Redeploy Functions

```bash
firebase deploy --only functions
```

## 📱 Step 5: Update Flutter App Configuration (Optional)

### Switch to Test Mode for Development

Edit `lib/config/stripe_config.dart`:

```dart
static const String publishableKey = 'pk_test_YOUR_TEST_KEY_HERE';
```

**Current configuration:**
```dart
static const String publishableKey = 'pk_live_51ShuhgDlJWxucYHsDR2d7jNmYS6AlEVJFojf1bpLYDPyfBEwZEDsDE116FJQocnWfi8dtoQ7sKhIFN8w0gYfeoZX00up5rq3BC';
```

## ✅ Step 6: Test the Integration

### 6.1 Test Cards (Test Mode Only)

Use these test card numbers in Stripe test mode:

| Card Number          | Description                |
|---------------------|----------------------------|
| 4242 4242 4242 4242 | Successful payment         |
| 4000 0000 0000 9995 | Card declined              |
| 4000 0025 0000 3155 | Requires authentication    |

- **Expiry**: Any future date (e.g., 12/34)
- **CVC**: Any 3 digits (e.g., 123)
- **ZIP**: Any 5 digits (e.g., 12345)

### 6.2 Test Payment Flow

1. Open the WalkMyPet app
2. Select a walker and create a booking
3. Proceed to checkout
4. Select Stripe as payment method
5. Complete payment using test card
6. Verify:
   - Payment succeeds in app
   - Booking is created in Firestore
   - Walker receives notification
   - Webhook logs appear in Firebase Functions logs

### 6.3 Monitor Logs

```bash
# Watch Cloud Functions logs
firebase functions:log --only handleStripeWebhook

# Or view in Firebase Console
# https://console.firebase.google.com/project/YOUR_PROJECT/functions/logs
```

### 6.4 Verify Webhook Events

1. Go to Stripe Dashboard → **Developers** → **Webhooks**
2. Click on your webhook endpoint
3. Check the **Recent events** section
4. Look for successful `payment_intent.succeeded` events

## 🔍 Verification Checklist

- [ ] Stripe secret key configured in Firebase
- [ ] Stripe webhook secret configured in Firebase
- [ ] Cloud Functions deployed successfully
- [ ] Webhook endpoint registered in Stripe Dashboard
- [ ] Webhook is receiving events (check Stripe Dashboard)
- [ ] Test payment completes successfully
- [ ] Booking is created after payment
- [ ] Walker receives notification
- [ ] Transaction record created in Firestore
- [ ] Platform fee (15%) calculated correctly

## 🐛 Troubleshooting

### Issue: "Stripe is not configured"

**Solution:** Make sure you've set the secret key:
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"
firebase deploy --only functions
```

### Issue: Webhook not receiving events

**Possible causes:**
1. Webhook URL is incorrect
2. Webhook secret not configured
3. Functions not deployed
4. Firewall blocking webhook calls

**Solution:**
- Verify webhook URL in Stripe Dashboard
- Check Firebase Functions logs for errors
- Ensure functions are deployed: `firebase deploy --only functions`

### Issue: Payment succeeds but booking not created

**Possible causes:**
1. Webhook signature verification failing
2. Missing metadata in payment intent
3. Firestore permissions issue

**Solution:**
- Check Firebase Functions logs: `firebase functions:log`
- Verify webhook secret is correct
- Check Firestore security rules

### Issue: "Payment intent creation failed"

**Possible causes:**
1. Invalid Stripe secret key
2. Authentication issues
3. Network/API errors

**Solution:**
- Verify secret key in Firebase config
- Check Firebase Functions logs for detailed error
- Ensure user is authenticated

## 🔐 Security Best Practices

1. **Never commit secret keys** to version control
2. **Use test keys** for development
3. **Verify webhook signatures** (already implemented)
4. **Validate amounts server-side** (already implemented)
5. **Use HTTPS only** for webhook endpoints
6. **Monitor for suspicious activity** in Stripe Dashboard

## 📊 Payment Flow Architecture

```
1. User creates booking in Flutter app
   ↓
2. Flutter calls StripeService.processPayment()
   ↓
3. StripeService calls createPaymentIntent Cloud Function
   ↓
4. Cloud Function creates PaymentIntent with Stripe API
   ↓
5. Cloud Function returns client_secret to Flutter
   ↓
6. Flutter displays Stripe payment sheet
   ↓
7. User enters card details and confirms
   ↓
8. Stripe processes payment
   ↓
9. Stripe sends webhook to handleStripeWebhook
   ↓
10. Webhook creates booking in Firestore
    ↓
11. Flutter polls Firestore for booking
    ↓
12. User sees booking confirmation
```

## 💰 Pricing & Fees

### Stripe Fees
- **2.9% + $0.30 AUD** per successful card charge
- No setup fees, monthly fees, or hidden costs

### Platform Fee (WalkMyPet)
- **15%** of booking price goes to platform
- **85%** goes to walker's wallet balance
- Calculated automatically in webhook handler

### Example Calculation
For a $100 booking:
- Gross amount: $100.00
- Platform fee (15%): $15.00
- Walker earnings: $85.00
- Stripe fee: ~$3.20
- Net to platform: ~$11.80
- Net to walker: $85.00

## 📞 Support

### Stripe Support
- Documentation: https://stripe.com/docs
- Support: https://support.stripe.com

### Firebase Support
- Documentation: https://firebase.google.com/docs
- Community: https://firebase.google.com/community

## 🎉 You're All Set!

Your Stripe integration is now fully configured and ready to process payments. Test thoroughly in test mode before switching to live mode.

For any issues, check the troubleshooting section above or review the Cloud Functions logs.
