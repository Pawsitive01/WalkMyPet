# Stripe Payment Integration Testing Guide

This comprehensive guide will help you test the Stripe payment integration thoroughly before going live.

## 🧪 Testing Environment Setup

### 1. Prerequisites

- [ ] Firebase project configured with test environment
- [ ] Stripe test mode keys configured
- [ ] Cloud Functions deployed
- [ ] Webhook configured and receiving events
- [ ] App built and installed on test device/emulator

### 2. Verify Test Mode

Check that you're using **TEST** keys:

```dart
// lib/config/stripe_config.dart
static const String publishableKey = 'pk_test_...';  // Should start with pk_test_
```

Cloud Functions:
```bash
firebase functions:config:get
# Should show: "secret_key": "sk_test_..."
```

### 3. Enable Test Mode Indicator

Add this to your checkout page to remind you that you're in test mode:

```dart
if (StripeConfig.isTestMode) {
  Container(
    color: Colors.orange,
    padding: EdgeInsets.all(8),
    child: Text('TEST MODE - Using test cards only'),
  ),
}
```

## 🎯 Test Scenarios

### Basic Payment Flow Tests

#### ✅ Test 1: Successful Payment

**Steps:**
1. Open app and browse walkers
2. Select a walker and create a booking
3. Proceed to checkout
4. Select Stripe as payment method
5. Enter test card: `4242 4242 4242 4242`
6. Enter expiry: `12/34`, CVC: `123`, ZIP: `12345`
7. Tap "Pay Now"

**Expected Results:**
- ✅ Payment sheet appears with correct amount
- ✅ Payment processes successfully
- ✅ Success message displayed
- ✅ Booking appears in "My Bookings"
- ✅ Walker receives notification
- ✅ Booking status is "pending" (awaiting walker confirmation)

**Verify in Dashboards:**
- Stripe Dashboard: Payment intent succeeded
- Firebase Console: Booking document created
- Firebase Console: Transaction document created
- Cloud Functions logs: Webhook processed successfully

---

#### ❌ Test 2: Declined Card

**Steps:**
1. Create a new booking
2. Use declined card: `4000 0000 0000 9995`
3. Attempt payment

**Expected Results:**
- ✅ Payment fails with error message
- ✅ No booking created
- ✅ User can try again with different card
- ✅ No charge in Stripe Dashboard

---

#### ❌ Test 3: Insufficient Funds

**Steps:**
1. Create a new booking
2. Use insufficient funds card: `4000 0000 0000 9987`
3. Attempt payment

**Expected Results:**
- ✅ Payment fails with "Insufficient funds" message
- ✅ No booking created
- ✅ User can retry

---

#### 🔐 Test 4: 3D Secure Authentication

**Steps:**
1. Create a new booking
2. Use 3DS card: `4000 0025 0000 3155`
3. Attempt payment
4. Complete authentication challenge

**Expected Results:**
- ✅ Authentication modal appears
- ✅ After completing auth, payment succeeds
- ✅ Booking created successfully

---

#### 🚫 Test 5: User Cancels Payment

**Steps:**
1. Create a new booking
2. Open payment sheet
3. Tap "Cancel" or swipe down (iOS) / back button (Android)

**Expected Results:**
- ✅ Payment sheet closes
- ✅ User returns to checkout page
- ✅ No booking created
- ✅ No charge made
- ✅ User can try again

---

### Edge Case Tests

#### 🔄 Test 6: Network Interruption

**Steps:**
1. Start payment process
2. Enable airplane mode during payment
3. Complete card details
4. Tap Pay

**Expected Results:**
- ✅ Error message about network connectivity
- ✅ No duplicate charges
- ✅ User can retry when network returns

---

#### 📱 Test 7: App Backgrounding

**Steps:**
1. Start payment process
2. Enter card details
3. Switch to another app (don't close payment sheet)
4. Return to WalkMyPet app
5. Complete payment

**Expected Results:**
- ✅ Payment sheet still active
- ✅ Can complete payment normally
- ✅ No data loss

---

#### ⚡ Test 8: Rapid Multiple Payments

**Steps:**
1. Create booking
2. Attempt payment with card `4242 4242 4242 4242`
3. Immediately create another booking
4. Attempt payment again

**Expected Results:**
- ✅ Both payments process independently
- ✅ Two separate bookings created
- ✅ No duplicate charges
- ✅ Idempotency keys working correctly

---

#### ⏱️ Test 9: Payment Timeout

**Steps:**
1. Start payment process
2. Wait 5+ minutes without completing
3. Try to complete payment

**Expected Results:**
- ✅ Payment intent may expire
- ✅ Error message displayed
- ✅ User can create new payment intent

---

#### 💰 Test 10: Various Payment Amounts

Test with different booking prices:

| Amount | Card Number          | Expected Result |
|--------|---------------------|-----------------|
| $10    | 4242 4242 4242 4242 | Success         |
| $100   | 4242 4242 4242 4242 | Success         |
| $500   | 4242 4242 4242 4242 | Success         |
| $1000  | 4242 4242 4242 4242 | Success         |

**Expected Results:**
- ✅ All amounts process correctly
- ✅ Platform fee (15%) calculated accurately
- ✅ Walker earnings correct (85%)

---

### Platform-Specific Tests

#### 📱 Android Specific

**Test 11: Hardware Back Button**
- Open payment sheet
- Press hardware back button
- Should cancel payment gracefully

**Test 12: Screen Rotation**
- Start payment
- Rotate device
- Complete payment
- Should handle orientation change

**Test 13: Different Android Versions**
- Test on Android 9, 11, 13, 14
- Verify consistent behavior

---

#### 🍎 iOS Specific

**Test 14: Swipe to Dismiss**
- Open payment sheet
- Swipe down to dismiss
- Should cancel payment gracefully

**Test 15: Face ID / Touch ID**
- Use card requiring authentication
- Complete Face ID / Touch ID
- Payment should complete

**Test 16: Different iOS Versions**
- Test on iOS 13, 15, 17
- Verify consistent behavior

---

### Webhook Tests

#### 🪝 Test 17: Webhook Delivery

**Steps:**
1. Make a test payment
2. Check Stripe Dashboard → Webhooks
3. Verify event received

**Expected Results:**
- ✅ `payment_intent.succeeded` event received
- ✅ Response code: 200
- ✅ Booking created in Firestore

---

#### 🪝 Test 18: Webhook Retry

**Steps:**
1. Temporarily cause webhook to fail (invalid data)
2. Make a payment
3. Fix the issue
4. Wait for Stripe to retry

**Expected Results:**
- ✅ Stripe retries webhook
- ✅ Eventually succeeds after fix

---

#### 🪝 Test 19: Duplicate Webhook Prevention

**Steps:**
1. Make a payment
2. Manually resend webhook from Stripe Dashboard
3. Check Firestore

**Expected Results:**
- ✅ Only one booking created
- ✅ Idempotency check prevents duplicates

---

### Data Integrity Tests

#### 💾 Test 20: Booking Data Accuracy

**Verify all booking fields:**
```
✅ ownerId - correct user ID
✅ walkerId - correct walker ID
✅ ownerName - correct owner name
✅ walkerName - correct walker name
✅ dogName - correct dog name
✅ serviceType - matches selection
✅ scheduledDate - matches selection
✅ time - matches selection
✅ location - matches selection
✅ duration - matches selection
✅ price - matches checkout amount
✅ status - set to "pending"
✅ stripePaymentIntentId - matches Stripe
✅ createdAt - timestamp exists
```

---

#### 💰 Test 21: Transaction Record

**Verify transaction fields:**
```
✅ userId - walker ID
✅ bookingId - matches booking
✅ type - "platformFee"
✅ status - "pending"
✅ amount - walker earnings (85%)
✅ grossAmount - full price
✅ platformFee - 15% of price
✅ platformFeePercent - 0.15
✅ stripePaymentIntentId - matches
```

---

#### 🔔 Test 22: Notifications

**Steps:**
1. Complete a payment
2. Check walker's device for notification

**Expected Results:**
- ✅ Walker receives push notification
- ✅ Notification shows booking details
- ✅ Tapping notification opens booking

---

### Security Tests

#### 🔒 Test 23: Unauthenticated User

**Steps:**
1. Log out of app
2. Try to access checkout

**Expected Results:**
- ✅ Redirected to login
- ✅ Cannot create payment intent
- ✅ No security bypass

---

#### 🔒 Test 24: Invalid Payment Intent

**Steps:**
1. Modify payment intent ID in client
2. Try to complete payment

**Expected Results:**
- ✅ Payment fails
- ✅ Error handled gracefully
- ✅ No booking created

---

#### 🔒 Test 25: Amount Manipulation

**Attempt to modify amount:**
1. Start checkout with $100 booking
2. Try to modify amount in client
3. Complete payment

**Expected Results:**
- ✅ Server-side amount validation
- ✅ Payment fails if amounts don't match
- ✅ Cannot cheat the system

---

## 🎴 Test Cards Reference

### Basic Cards

| Card Number          | Type       | Result    |
|---------------------|------------|-----------|
| 4242 4242 4242 4242 | Visa       | Success   |
| 5555 5555 5555 4444 | Mastercard | Success   |
| 3782 822463 10005   | Amex       | Success   |
| 6011 1111 1111 1117 | Discover   | Success   |

### Decline Cards

| Card Number          | Decline Code           |
|---------------------|------------------------|
| 4000 0000 0000 9995 | Generic decline        |
| 4000 0000 0000 9987 | Insufficient funds     |
| 4000 0000 0000 9979 | Stolen card            |
| 4000 0000 0000 0069 | Expired card           |
| 4000 0000 0000 0127 | Incorrect CVC          |
| 4000 0000 0000 0002 | Card declined          |

### Special Cards

| Card Number          | Behavior                    |
|---------------------|-----------------------------|
| 4000 0025 0000 3155 | Requires authentication     |
| 4000 0000 0000 3220 | 3D Secure 2 authentication  |
| 4000 0000 0000 3063 | Always requires auth        |

### Geographic Cards

| Card Number          | Country   |
|---------------------|-----------|
| 4000 0036 0000 0006 | AU        |
| 4000 0084 0000 0008 | US        |
| 4000 0008 2600 0006 | GB        |

## 📊 Monitoring & Logs

### Real-Time Monitoring

#### Stripe Dashboard
```
https://dashboard.stripe.com/test/payments
```
Monitor:
- Payment attempts
- Success/failure rates
- Webhook deliveries
- Dispute/refund activity

#### Firebase Console
```
https://console.firebase.google.com
```
Monitor:
- Cloud Functions logs
- Firestore writes
- Authentication events

#### Cloud Functions Logs
```bash
# Watch logs in real-time
firebase functions:log --only handleStripeWebhook

# Or specific function
firebase functions:log --only createPaymentIntent
```

### Log Analysis

Look for these success indicators:

```
✅ "Payment intent created: pi_xxx"
✅ "Received webhook event: payment_intent.succeeded"
✅ "Created booking xxx and transaction xxx"
✅ "Notification sent to walker xxx"
```

Look for these error indicators:

```
❌ "Stripe secret key not configured"
❌ "Webhook signature verification failed"
❌ "Error creating payment intent"
❌ "Error processing payment success"
```

## ✅ Testing Checklist

### Before Each Testing Session
- [ ] Verify test mode enabled
- [ ] Clear app data/cache
- [ ] Check Firebase Functions are deployed
- [ ] Verify webhook is active
- [ ] Have test cards ready

### After Each Test
- [ ] Check Stripe Dashboard for payment
- [ ] Verify booking created in Firestore
- [ ] Check Cloud Functions logs
- [ ] Verify notifications sent
- [ ] Document any issues

### Before Production Launch
- [ ] All 25 test scenarios passed
- [ ] Tested on multiple devices
- [ ] Tested on both Android and iOS
- [ ] Verified webhook reliability
- [ ] Tested with real money (small amounts)
- [ ] Security audit completed
- [ ] Error handling verified
- [ ] Performance acceptable

## 🐛 Common Issues & Solutions

### Issue: Payment succeeds but booking not created

**Diagnosis:**
```bash
firebase functions:log --only handleStripeWebhook
```

**Common causes:**
- Webhook secret incorrect
- Webhook signature verification failing
- Firestore permissions issue

**Solution:**
1. Verify webhook secret matches Stripe Dashboard
2. Check Cloud Functions logs for errors
3. Redeploy functions if needed

---

### Issue: Payment sheet doesn't appear

**Diagnosis:**
- Check Flutter console for errors
- Verify Stripe initialization in main.dart

**Solution:**
```dart
// Ensure this runs before showing payment sheet
await stripeService.initialize();
```

---

### Issue: Webhook not receiving events

**Diagnosis:**
- Check Stripe Dashboard → Webhooks
- Look for failed delivery attempts

**Solution:**
1. Verify webhook URL is correct
2. Check Cloud Functions are deployed
3. Test webhook with "Send test webhook" in Stripe

---

## 📞 Getting Help

### Stripe Support
- Test mode support: support@stripe.com
- Documentation: https://stripe.com/docs
- Community: https://stackoverflow.com/questions/tagged/stripe-payments

### Firebase Support
- Documentation: https://firebase.google.com/docs
- Community: https://stackoverflow.com/questions/tagged/firebase

## 🎉 Testing Complete!

Once all tests pass, you're ready to switch to live mode:

1. Replace test keys with live keys
2. Test with real cards (small amounts)
3. Monitor closely for first few transactions
4. Set up automated monitoring/alerts

**Remember:**
- Start with small transactions
- Monitor dashboard closely
- Have support ready for users
- Keep testing in parallel test environment

Good luck with your launch! 🚀
