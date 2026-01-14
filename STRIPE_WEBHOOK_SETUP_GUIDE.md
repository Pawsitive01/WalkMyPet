# Stripe Webhook Setup Guide

Complete step-by-step guide to set up Stripe webhooks for WalkMyPet.

## 📋 Prerequisites

Before setting up the webhook, you need:
- ✅ Stripe account (test mode or live mode)
- ✅ Firebase Cloud Functions deployed
- ✅ Your webhook endpoint URL

## 🚀 Step 1: Deploy Cloud Functions First

You need to deploy your Cloud Functions to get the webhook URL.

### Deploy Commands:

```bash
cd /home/user/WalkMyPet

# Build the functions
cd functions
npm run build

# Deploy to Firebase
cd ..
firebase deploy --only functions
```

### Get Your Webhook URL

After deployment, you'll see output like:

```
✔  functions[createPaymentIntent(australia-southeast1)] Successful create operation.
✔  functions[handleStripeWebhook(australia-southeast1)] Successful create operation.

Function URL (handleStripeWebhook(australia-southeast1)):
https://australia-southeast1-YOUR_PROJECT_ID.cloudfunctions.net/handleStripeWebhook
```

**Copy this URL!** You'll need it in the next step.

### If You Don't See the URL:

```bash
firebase functions:list
```

Or construct it manually:
```
https://australia-southeast1-YOUR_PROJECT_ID.cloudfunctions.net/handleStripeWebhook
```

---

## 🔗 Step 2: Access Stripe Dashboard

### For Test Mode (Development):
1. Go to: https://dashboard.stripe.com/test/webhooks
2. Make sure you're in **TEST MODE** (toggle in top-right corner should say "Test mode")

### For Live Mode (Production):
1. Go to: https://dashboard.stripe.com/webhooks
2. Make sure you're in **LIVE MODE**

**Important:** Use Test Mode for development and testing!

---

## ➕ Step 3: Create Webhook Endpoint

### 3.1. Click "Add endpoint" Button

On the Webhooks page, click the blue **"Add endpoint"** button in the top-right corner.

### 3.2. Enter Endpoint URL

In the form that appears:

**Endpoint URL:**
```
https://australia-southeast1-YOUR_PROJECT_ID.cloudfunctions.net/handleStripeWebhook
```

Replace `YOUR_PROJECT_ID` with your actual Firebase project ID.

**Example:**
```
https://australia-southeast1-walkmypet-prod.cloudfunctions.net/handleStripeWebhook
```

### 3.3. Add Description (Optional)

**Description:** WalkMyPet Production Webhook

This helps you identify the webhook later.

---

## 📡 Step 4: Select Events to Listen To

### Method 1: Select Specific Events (Recommended)

Click on **"Select events"** and choose:

#### Required Events:
- ✅ **payment_intent.succeeded** - When payment succeeds
- ✅ **payment_intent.payment_failed** - When payment fails

#### How to Find These Events:

1. In the event selection dialog, use the search box
2. Type "payment_intent"
3. Check the boxes for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`

### Method 2: Listen to All Events (Not Recommended)

You can select "Listen to all events" but this will send unnecessary webhooks and use more bandwidth.

**Recommended:** Only select the 2 events listed above.

---

## 🔐 Step 5: Get Webhook Signing Secret

### 5.1. Add the Endpoint

After selecting events, click **"Add endpoint"** at the bottom of the form.

### 5.2. View Endpoint Details

You'll be redirected to the webhook endpoint details page.

### 5.3. Reveal Signing Secret

1. Scroll down to the **"Signing secret"** section
2. Click **"Reveal"** or **"Click to reveal"**
3. You'll see a secret that starts with `whsec_`

**Example:**
```
whsec_1234567890abcdefghijklmnopqrstuvwxyz1234567890
```

### 5.4. Copy the Secret

Click the **copy icon** or manually select and copy the entire secret.

**⚠️ Important:** Keep this secret secure! Never commit it to version control.

---

## ⚙️ Step 6: Configure Webhook Secret in Firebase

### 6.1. Set the Secret

Open your terminal and run:

```bash
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET_HERE"
```

**Example:**
```bash
firebase functions:config:set stripe.webhook_secret="whsec_1234567890abcdefghijklmnopqrstuvwxyz1234567890"
```

### 6.2. Verify Configuration

```bash
firebase functions:config:get
```

You should see:
```json
{
  "stripe": {
    "secret_key": "sk_test_...",
    "webhook_secret": "whsec_..."
  }
}
```

### 6.3. Redeploy Functions

**Critical:** You must redeploy after setting the webhook secret!

```bash
firebase deploy --only functions
```

---

## ✅ Step 7: Test the Webhook

### 7.1. Send Test Webhook

In the Stripe Dashboard, on your webhook endpoint page:

1. Scroll down to **"Send test webhook"** section
2. Click **"Send test webhook"** button
3. Select event: **payment_intent.succeeded**
4. Click **"Send test webhook"**

### 7.2. Check Response

You should see:
- ✅ **Response code: 200** (success)
- ✅ Response body: `{"received":true}`

If you see an error:
- ❌ **500 error:** Check if webhook secret is configured
- ❌ **404 error:** Check if webhook URL is correct
- ❌ **Timeout:** Check if Cloud Functions are deployed

### 7.3. View Logs

Check Firebase Functions logs to see the webhook processing:

```bash
firebase functions:log --only handleStripeWebhook
```

You should see:
```
Received webhook event: payment_intent.succeeded
Processing successful payment: pi_test_...
```

---

## 🧪 Step 8: Test End-to-End Payment Flow

### 8.1. Make a Test Payment in Your App

1. Open the WalkMyPet app
2. Select a walker and create a booking
3. Proceed to checkout
4. Use test card: **4242 4242 4242 4242**
5. Expiry: **12/34**, CVC: **123**
6. Complete payment

### 8.2. Monitor Webhook Delivery

In Stripe Dashboard → Webhooks → Your endpoint:

1. Look at **"Recent events"** section
2. You should see a new `payment_intent.succeeded` event
3. Click on it to see details
4. Check that response code is **200**

### 8.3. Verify Booking Creation

Check your Firestore database:

```bash
# In Firebase Console
Go to Firestore Database → bookings collection
```

You should see a new booking document with:
- ✅ `stripePaymentIntentId` matching the payment intent
- ✅ `status: "pending"`
- ✅ `paymentProcessed: false`
- ✅ All booking details

### 8.4. Check Walker Notification

The walker should receive a push notification about the new booking.

---

## 🔍 Troubleshooting

### Issue 1: "Webhook signature verification failed"

**Cause:** Webhook secret is incorrect or not configured.

**Solution:**
```bash
# Check current config
firebase functions:config:get

# Reset webhook secret
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"

# Redeploy
firebase deploy --only functions
```

### Issue 2: Webhook returns 500 error

**Cause:** Error in Cloud Function code or missing configuration.

**Solution:**
```bash
# Check logs for errors
firebase functions:log --only handleStripeWebhook

# Common fixes:
# 1. Ensure stripe.secret_key is set
firebase functions:config:set stripe.secret_key="sk_test_..."

# 2. Ensure stripe.webhook_secret is set
firebase functions:config:set stripe.webhook_secret="whsec_..."

# 3. Redeploy
firebase deploy --only functions
```

### Issue 3: Webhook returns 404 error

**Cause:** Webhook URL is incorrect or function not deployed.

**Solution:**
```bash
# List deployed functions
firebase functions:list

# Verify handleStripeWebhook is listed
# If not, deploy:
firebase deploy --only functions

# Get correct URL
firebase functions:list | grep handleStripeWebhook
```

### Issue 4: Payment succeeds but no booking created

**Cause:** Webhook not receiving events or processing fails.

**Solution:**
1. Check Stripe Dashboard → Webhooks → Recent events
2. Verify events are being sent (status 200)
3. Check Firebase Functions logs:
   ```bash
   firebase functions:log --only handleStripeWebhook
   ```
4. Look for errors in booking creation

### Issue 5: Duplicate bookings created

**Cause:** Webhook receiving duplicate events or idempotency check failing.

**Solution:**
- This shouldn't happen with the implemented idempotency check
- Check Firestore for bookings with same `stripePaymentIntentId`
- Review logs to see if webhook is being called multiple times

---

## 📊 Monitoring Webhook Health

### Check Webhook Status

In Stripe Dashboard:

1. Go to **Webhooks**
2. Click on your endpoint
3. Monitor:
   - ✅ Success rate (should be >95%)
   - ✅ Response time (should be <5s)
   - ✅ Recent events

### Set Up Alerts

In Stripe Dashboard:

1. Go to **Webhooks** → Your endpoint
2. Click **"⋮"** (three dots) → **"Configure alerts"**
3. Enable alerts for:
   - Webhook endpoint failures
   - High error rates

### Monitor Firebase Functions

```bash
# Watch logs in real-time
firebase functions:log --only handleStripeWebhook --follow

# Check function metrics in Firebase Console
# Go to: Functions → handleStripeWebhook → Usage tab
```

---

## 🔄 Webhook Lifecycle

### How Webhooks Work:

```
1. Payment succeeds in Stripe
   ↓
2. Stripe sends webhook event to your URL
   ↓
3. Your Cloud Function verifies signature
   ↓
4. Function checks for duplicate (idempotency)
   ↓
5. Function creates booking in Firestore
   ↓
6. Function creates transaction record
   ↓
7. Function sends notification to walker
   ↓
8. Function returns 200 response to Stripe
```

### Webhook Retries:

If your endpoint fails (non-200 response), Stripe will:
- ✅ Retry the webhook automatically
- ✅ Use exponential backoff (1h, 2h, 4h, etc.)
- ✅ Retry for up to 3 days
- ⚠️ Mark endpoint as disabled if failures persist

---

## 🔐 Security Best Practices

### ✅ DO:
- Always verify webhook signatures
- Use HTTPS only (Firebase Functions enforce this)
- Keep webhook secret secure
- Monitor webhook failures
- Implement idempotency checks
- Log all webhook events

### ❌ DON'T:
- Don't skip signature verification
- Don't expose webhook secret in code
- Don't process webhooks without checking duplicates
- Don't return 200 if processing fails
- Don't log sensitive payment information

---

## 🎯 Quick Reference

### Important URLs:

| Purpose | URL |
|---------|-----|
| Test Mode Webhooks | https://dashboard.stripe.com/test/webhooks |
| Live Mode Webhooks | https://dashboard.stripe.com/webhooks |
| Test API Keys | https://dashboard.stripe.com/test/apikeys |
| Live API Keys | https://dashboard.stripe.com/apikeys |
| Webhook Events Docs | https://stripe.com/docs/api/events/types |

### Required Events:

```
payment_intent.succeeded
payment_intent.payment_failed
```

### Webhook URL Format:

```
https://australia-southeast1-PROJECT_ID.cloudfunctions.net/handleStripeWebhook
```

### Configuration Commands:

```bash
# Set secret key
firebase functions:config:set stripe.secret_key="sk_test_..."

# Set webhook secret
firebase functions:config:set stripe.webhook_secret="whsec_..."

# Get config
firebase functions:config:get

# Deploy
firebase deploy --only functions

# View logs
firebase functions:log --only handleStripeWebhook
```

---

## ✅ Checklist

Before going live, verify:

- [ ] Cloud Functions deployed successfully
- [ ] Webhook endpoint created in Stripe
- [ ] Events selected: `payment_intent.succeeded` and `payment_intent.payment_failed`
- [ ] Webhook secret copied from Stripe
- [ ] Webhook secret configured in Firebase
- [ ] Functions redeployed after configuration
- [ ] Test webhook sent successfully (200 response)
- [ ] End-to-end payment tested in app
- [ ] Booking created in Firestore after payment
- [ ] Walker received notification
- [ ] Logs show successful webhook processing
- [ ] No duplicate bookings created

---

## 🎉 You're Done!

Your Stripe webhook is now configured and ready to process payments!

### Next Steps:

1. **Test thoroughly** with test cards
2. **Monitor webhook health** in Stripe Dashboard
3. **Check Firebase Functions logs** regularly
4. **Set up alerts** for webhook failures
5. **Switch to live mode** when ready for production

### Need Help?

- **Stripe Webhooks Docs:** https://stripe.com/docs/webhooks
- **Firebase Functions Docs:** https://firebase.google.com/docs/functions
- **Testing Guide:** See `STRIPE_TESTING_GUIDE.md`

---

**Happy Processing! 💳✨**
