import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new review
  Future<String> createReview(Review review) async {
    try {
      final docRef = await _firestore.collection('reviews').add(review.toFirestore());

      // Update the user's rating and review count
      await _updateUserRating(review.reviewedUserId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Get all reviews for a specific user
  Future<List<Review>> getReviewsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  // Get reviews for a specific user as a stream
  Stream<List<Review>> getReviewsForUserStream(String userId) {
    return _firestore
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  // Check if a user has already reviewed a specific booking
  Future<bool> hasUserReviewedBooking(String bookingId, String reviewerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check review status: $e');
    }
  }

  // Get review for a specific booking by a specific reviewer
  Future<Review?> getReviewForBooking(String bookingId, String reviewerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Review.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get review: $e');
    }
  }

  // Update an existing review
  Future<void> updateReview(String reviewId, {double? rating, String? comment}) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;

      await _firestore.collection('reviews').doc(reviewId).update(updateData);

      // Re-calculate the user's rating
      final review = await _firestore.collection('reviews').doc(reviewId).get();
      if (review.exists) {
        final reviewData = Review.fromFirestore(review);
        await _updateUserRating(reviewData.reviewedUserId);
      }
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      final review = await _firestore.collection('reviews').doc(reviewId).get();
      if (review.exists) {
        final reviewData = Review.fromFirestore(review);
        await _firestore.collection('reviews').doc(reviewId).delete();

        // Re-calculate the user's rating
        await _updateUserRating(reviewData.reviewedUserId);
      }
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Calculate and update user's average rating
  Future<void> _updateUserRating(String userId) async {
    try {
      final reviews = await getReviewsForUser(userId);

      if (reviews.isEmpty) {
        // No reviews yet - set default rating
        await _firestore.collection('users').doc(userId).update({
          'rating': 5.0,
          'reviews': 0,
        });
        return;
      }

      // Calculate average rating
      final totalRating = reviews.fold<double>(0, (total, review) => total + review.rating);
      final averageRating = totalRating / reviews.length;

      await _firestore.collection('users').doc(userId).update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'reviews': reviews.length,
      });
    } catch (e) {
      throw Exception('Failed to update user rating: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserReviewStats(String userId) async {
    try {
      final reviews = await getReviewsForUser(userId);

      if (reviews.isEmpty) {
        return {
          'averageRating': 5.0,
          'totalReviews': 0,
          'ratingBreakdown': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      final totalRating = reviews.fold<double>(0, (total, review) => total + review.rating);
      final averageRating = totalRating / reviews.length;

      // Calculate rating breakdown
      final ratingBreakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var review in reviews) {
        final ratingKey = review.rating.round();
        ratingBreakdown[ratingKey] = (ratingBreakdown[ratingKey] ?? 0) + 1;
      }

      return {
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'totalReviews': reviews.length,
        'ratingBreakdown': ratingBreakdown,
      };
    } catch (e) {
      throw Exception('Failed to get user review stats: $e');
    }
  }
}
