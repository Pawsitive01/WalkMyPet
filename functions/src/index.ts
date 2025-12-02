import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Cloud Function that triggers when a new booking is created
 * Sends a push notification to the walker to confirm the booking
 */
export const onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const booking = snapshot.data();
    const bookingId = context.params.bookingId;

    // Only send notification for pending bookings
    if (booking.status !== "pending") {
      console.log(`Booking ${bookingId} status is not pending, skipping notification`);
      return null;
    }

    try {
      // Get walker's FCM token from users collection
      // Note: walkerId in the booking is the walker's name, we need to find the user by name
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("displayName", "==", booking.walkerName)
        .where("userType", "==", "petWalker")
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        console.log(`Walker ${booking.walkerName} not found in users collection`);
        return null;
      }

      const walkerDoc = usersSnapshot.docs[0];
      const walkerData = walkerDoc.data();
      const fcmToken = walkerData.fcmToken;

      if (!fcmToken) {
        console.log(`Walker ${booking.walkerName} does not have an FCM token`);
        return null;
      }

      // Format the date and time
      const bookingDate = booking.date.toDate();
      const formattedDate = bookingDate.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      });

      // Prepare notification payload
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: "🐾 New Booking Request!",
          body: `${booking.ownerName} wants to book you for ${booking.dogName} on ${formattedDate} at ${booking.time}`,
        },
        data: {
          bookingId: bookingId,
          type: "booking_request",
          ownerId: booking.ownerId,
          ownerName: booking.ownerName,
          dogName: booking.dogName,
          date: formattedDate,
          time: booking.time,
          price: booking.price.toString(),
          status: booking.status,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "booking_requests",
            priority: "high",
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log(`Notification sent successfully to walker ${booking.walkerName}:`, response);

      // Update the booking to mark that notification was sent
      await snapshot.ref.update({
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return response;
    } catch (error) {
      console.error("Error sending booking notification:", error);
      return null;
    }
  });

/**
 * Cloud Function that triggers when a booking status is updated
 * Sends a notification to the owner when walker confirms or rejects
 */
export const onBookingStatusUpdated = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    // Check if status changed
    if (before.status === after.status) {
      return null;
    }

    try {
      // Get owner's FCM token
      const ownerDoc = await admin.firestore()
        .collection("users")
        .doc(after.ownerId)
        .get();

      if (!ownerDoc.exists) {
        console.log(`Owner ${after.ownerId} not found`);
        return null;
      }

      const ownerData = ownerDoc.data();
      const fcmToken = ownerData?.fcmToken;

      if (!fcmToken) {
        console.log(`Owner ${after.ownerId} does not have an FCM token`);
        return null;
      }

      let title = "";
      let body = "";

      // Prepare notification based on new status
      switch (after.status) {
        case "confirmed":
          title = "✅ Booking Confirmed!";
          body = `${after.walkerName} has confirmed your booking for ${after.dogName}`;
          break;
        case "cancelled":
          title = "❌ Booking Cancelled";
          body = `${after.walkerName} has cancelled your booking for ${after.dogName}`;
          break;
        case "completed":
          title = "🎉 Walk Completed!";
          body = `${after.walkerName} completed the walk with ${after.dogName}`;
          break;
        default:
          return null;
      }

      // Prepare notification payload
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          bookingId: bookingId,
          type: "booking_status_update",
          walkerId: after.walkerId,
          walkerName: after.walkerName,
          status: after.status,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "booking_updates",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log(`Status update notification sent to owner ${after.ownerId}:`, response);

      return response;
    } catch (error) {
      console.error("Error sending status update notification:", error);
      return null;
    }
  });

/**
 * Cloud Function that triggers when a new review is created
 * Sends a notification to the user being reviewed
 */
export const onReviewCreated = functions.firestore
  .document("reviews/{reviewId}")
  .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const review = snapshot.data();
    const reviewId = context.params.reviewId;

    try {
      // Get the FCM token for the user being reviewed
      const reviewedUserDoc = await admin.firestore()
        .collection("users")
        .doc(review.reviewedUserId)
        .get();

      if (!reviewedUserDoc.exists) {
        console.log(`User ${review.reviewedUserId} not found`);
        return null;
      }

      const reviewedUserData = reviewedUserDoc.data();
      const fcmToken = reviewedUserData?.fcmToken;

      if (!fcmToken) {
        console.log(`User ${review.reviewedUserId} does not have an FCM token`);
        return null;
      }

      // Format the rating with stars
      const stars = "⭐".repeat(Math.round(review.rating));
      const commentPreview = review.comment
        ? (review.comment.length > 50 ? review.comment.substring(0, 50) + "..." : review.comment)
        : "No comment provided";

      // Prepare notification payload
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: "⭐ New Review Received!",
          body: `${review.reviewerName} left you a ${review.rating}-star review ${stars}`,
        },
        data: {
          reviewId: reviewId,
          type: "review_received",
          reviewerId: review.reviewerId,
          reviewerName: review.reviewerName,
          rating: review.rating.toString(),
          comment: review.comment || "",
          commentPreview: commentPreview,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "reviews",
            priority: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log(`Review notification sent to user ${review.reviewedUserId}:`, response);

      return response;
    } catch (error) {
      console.error("Error sending review notification:", error);
      return null;
    }
  });
