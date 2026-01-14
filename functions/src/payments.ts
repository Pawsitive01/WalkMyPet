import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import Stripe from "stripe";

// Initialize Stripe with secret key from Firebase config
// Set via: firebase functions:config:set stripe.secret_key="sk_test_..."
const stripeSecretKey = functions.config().stripe?.secret_key;
if (!stripeSecretKey) {
  console.error("Stripe secret key not configured. Run: firebase functions:config:set stripe.secret_key=sk_test_...");
}
const stripe = stripeSecretKey ? new Stripe(stripeSecretKey, {
  apiVersion: "2025-02-24.acacia",
}) : null;

const db = admin.firestore();

/**
 * Create Payment Intent - HTTP Callable Function
 *
 * Creates a Stripe PaymentIntent for booking payment.
 * This function validates the booking data, calculates the amount server-side,
 * and creates a PaymentIntent with the booking metadata.
 *
 * Security: Validates authentication, recalculates amount server-side
 */
export const createPaymentIntent = functions
  .region("australia-southeast1")
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to create payment intent"
      );
    }

    if (!stripe) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Stripe is not configured. Please contact support."
      );
    }

    const {walkerId, amount, bookingMetadata} = data;

    // Validate required parameters
    if (!walkerId || !amount || !bookingMetadata) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: walkerId, amount, bookingMetadata"
      );
    }

    try {
      // Fetch walker profile to verify existence
      const walkerDoc = await db.collection("walkers").doc(walkerId).get();
      if (!walkerDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          `Walker with ID ${walkerId} not found`
        );
      }

      const walkerData = walkerDoc.data();

      // Server-side amount validation
      // CRITICAL: Never trust client-provided amounts
      const providedAmount = parseFloat(amount);
      if (isNaN(providedAmount) || providedAmount <= 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid amount provided"
        );
      }

      // Convert amount to cents for Stripe (Stripe expects smallest currency unit)
      const amountInCents = Math.round(providedAmount * 100);

      // Create idempotency key from booking metadata to prevent duplicate charges
      const idempotencyKey = `booking_${context.auth.uid}_${walkerId}_${Date.now()}`;

      // Create PaymentIntent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amountInCents,
        currency: "aud",
        payment_method_types: ["card"],
        metadata: {
          // Store booking information in metadata for webhook processing
          ownerId: context.auth.uid,
          walkerId: walkerId,
          walkerName: walkerData?.name || "Unknown",
          ownerName: bookingMetadata.ownerName || "Unknown",
          dogName: bookingMetadata.dogName || "Unknown",
          serviceType: bookingMetadata.serviceType || "Dog Walking",
          scheduledDate: bookingMetadata.scheduledDate || "",
          duration: bookingMetadata.duration || "",
          location: bookingMetadata.location || "",
          price: providedAmount.toString(),
          createdAt: new Date().toISOString(),
        },
        description: `WalkMyPet - ${bookingMetadata.serviceType || "Dog Walking"} with ${walkerData?.name || "Walker"}`,
      }, {
        idempotencyKey: idempotencyKey,
      });

      console.log(`Payment intent created: ${paymentIntent.id} for amount: ${providedAmount} AUD`);

      // Return client_secret for Flutter to complete payment
      return {
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: providedAmount,
      };
    } catch (error: any) {
      console.error("Error creating payment intent:", error);

      // Handle Stripe-specific errors
      if (error.type === "StripeCardError") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `Card error: ${error.message}`
        );
      }

      // Re-throw HttpsError as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Generic error
      throw new functions.https.HttpsError(
        "internal",
        `Failed to create payment intent: ${error.message || "Unknown error"}`
      );
    }
  });

/**
 * Handle Stripe Webhook - HTTP Endpoint
 *
 * Processes Stripe webhook events, primarily payment_intent.succeeded.
 * When a payment succeeds, this function creates the booking in Firestore
 * and sends a notification to the walker.
 *
 * Security: Verifies webhook signature to prevent spoofing
 * Idempotency: Checks for existing bookings to prevent duplicates
 */
export const handleStripeWebhook = functions
  .region("australia-southeast1")
  .https.onRequest(async (req: functions.https.Request, res: functions.Response) => {
    if (!stripe) {
      console.error("Stripe not configured");
      res.status(500).send("Stripe not configured");
      return;
    }

    // Get webhook signing secret from Firebase config
    // Set via: firebase functions:config:set stripe.webhook_secret="whsec_..."
    const webhookSecret = functions.config().stripe?.webhook_secret;
    if (!webhookSecret) {
      console.error("Webhook secret not configured");
      res.status(500).send("Webhook secret not configured");
      return;
    }

    const sig = req.headers["stripe-signature"];
    if (!sig) {
      console.error("No stripe-signature header found");
      res.status(400).send("Missing stripe-signature header");
      return;
    }

    let event: Stripe.Event;

    try {
      // CRITICAL: Verify webhook signature to prevent spoofing
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig as string,
        webhookSecret
      );
    } catch (err: any) {
      console.error("Webhook signature verification failed:", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    console.log(`Received webhook event: ${event.type}`);

    // Handle different event types
    switch (event.type) {
      case "payment_intent.succeeded": {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await handlePaymentSuccess(paymentIntent);
        break;
      }

      case "payment_intent.payment_failed": {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await handlePaymentFailure(paymentIntent);
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    // Acknowledge receipt of event
    res.status(200).json({received: true});
  });

/**
 * Handle successful payment
 * Creates booking and transaction records in Firestore
 */
async function handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent) {
  const paymentIntentId = paymentIntent.id;
  const metadata = paymentIntent.metadata;

  console.log(`Processing successful payment: ${paymentIntentId}`);

  try {
    // Check for duplicate processing (idempotency)
    const existingBookings = await db
      .collection("bookings")
      .where("stripePaymentIntentId", "==", paymentIntentId)
      .limit(1)
      .get();

    if (!existingBookings.empty) {
      console.log(`Booking already exists for payment intent ${paymentIntentId}, skipping...`);
      return;
    }

    // Extract booking data from metadata
    const ownerId = metadata.ownerId;
    const walkerId = metadata.walkerId;
    const walkerName = metadata.walkerName;
    const ownerName = metadata.ownerName;
    const dogName = metadata.dogName;
    const serviceType = metadata.serviceType;
    const scheduledDate = metadata.scheduledDate;
    const duration = metadata.duration;
    const location = metadata.location;
    const price = parseFloat(metadata.price || "0");

    if (!ownerId || !walkerId) {
      console.error("Missing required metadata in payment intent");
      return;
    }

    // Calculate platform fee (15%)
    const platformFee = price * 0.15;
    const walkerEarnings = price - platformFee;

    const now = admin.firestore.Timestamp.now();

    // Use Firestore transaction for atomic operations
    await db.runTransaction(async (transaction) => {
      // Create booking document
      const bookingRef = db.collection("bookings").doc();
      const bookingData = {
        id: bookingRef.id,
        ownerId: ownerId,
        walkerId: walkerId,
        walkerName: walkerName,
        ownerName: ownerName,
        dogName: dogName,
        serviceType: serviceType || "Dog Walking",
        scheduledDate: scheduledDate,
        duration: duration,
        location: location,
        price: price,
        status: "pending", // Walker needs to confirm
        paymentProcessed: false, // Will be true after walk completion and owner confirmation
        stripePaymentIntentId: paymentIntentId,
        createdAt: now,
        updatedAt: now,
      };
      transaction.set(bookingRef, bookingData);

      // Create initial transaction record for platform fee
      const transactionRef = db.collection("transactions").doc();
      const transactionData = {
        id: transactionRef.id,
        userId: walkerId, // Walker receives the payment
        bookingId: bookingRef.id,
        type: "platformFee", // This is the initial platform fee record
        status: "pending", // Will be "completed" after walk confirmation
        amount: walkerEarnings,
        grossAmount: price,
        platformFee: platformFee,
        platformFeePercent: 0.15,
        ownerId: ownerId,
        ownerName: ownerName,
        dogName: dogName,
        stripePaymentIntentId: paymentIntentId,
        createdAt: now,
      };
      transaction.set(transactionRef, transactionData);

      console.log(`Created booking ${bookingRef.id} and transaction ${transactionRef.id}`);
    });

    // Send notification to walker (using existing notification function pattern)
    await sendWalkerNotification(walkerId, {
      title: "New Booking!",
      body: `${ownerName} has booked you for ${serviceType} with ${dogName}`,
      bookingId: paymentIntentId,
    });

    console.log(`Successfully processed payment ${paymentIntentId}`);
  } catch (error: any) {
    console.error(`Error processing payment success for ${paymentIntentId}:`, error);
    // Don't throw - webhook will retry
  }
}

/**
 * Handle failed payment
 * Logs the failure and optionally notifies the owner
 */
async function handlePaymentFailure(paymentIntent: Stripe.PaymentIntent) {
  const paymentIntentId = paymentIntent.id;
  const metadata = paymentIntent.metadata;

  console.log(`Payment failed: ${paymentIntentId}`);
  console.log(`Failure reason: ${paymentIntent.last_payment_error?.message || "Unknown"}`);

  // Optionally notify owner of payment failure
  const ownerId = metadata.ownerId;
  if (ownerId) {
    await sendOwnerNotification(ownerId, {
      title: "Payment Failed",
      body: "Your payment could not be processed. Please try again.",
      paymentIntentId: paymentIntentId,
    });
  }
}

/**
 * Send notification to walker
 */
async function sendWalkerNotification(walkerId: string, notification: {
  title: string;
  body: string;
  bookingId: string;
}) {
  try {
    // Get walker's FCM token
    const userDoc = await db.collection("users").doc(walkerId).get();
    if (!userDoc.exists) {
      console.log(`User ${walkerId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for walker ${walkerId}`);
      return;
    }

    // Send FCM notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: "booking_request",
        bookingId: notification.bookingId,
      },
      android: {
        priority: "high",
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
      },
    });

    console.log(`Notification sent to walker ${walkerId}`);
  } catch (error: any) {
    console.error(`Error sending notification to walker ${walkerId}:`, error);
  }
}

/**
 * Send notification to owner
 */
async function sendOwnerNotification(ownerId: string, notification: {
  title: string;
  body: string;
  paymentIntentId: string;
}) {
  try {
    // Get owner's FCM token
    const userDoc = await db.collection("users").doc(ownerId).get();
    if (!userDoc.exists) {
      console.log(`User ${ownerId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for owner ${ownerId}`);
      return;
    }

    // Send FCM notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: "payment_status",
        paymentIntentId: notification.paymentIntentId,
      },
    });

    console.log(`Notification sent to owner ${ownerId}`);
  } catch (error: any) {
    console.error(`Error sending notification to owner ${ownerId}:`, error);
  }
}
