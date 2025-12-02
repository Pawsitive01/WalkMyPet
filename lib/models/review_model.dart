import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String reviewerId; // User who wrote the review
  final String reviewerName;
  final String reviewerPhotoUrl;
  final String reviewedUserId; // User being reviewed (walker or owner)
  final String reviewedUserName;
  final String reviewerType; // 'owner' or 'walker'
  final String reviewedUserType; // 'owner' or 'walker'
  final double rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? dogName; // Pet involved in the booking

  Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhotoUrl,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.reviewerType,
    required this.reviewedUserType,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.dogName,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      reviewerPhotoUrl: data['reviewerPhotoUrl'] ?? '',
      reviewedUserId: data['reviewedUserId'] ?? '',
      reviewedUserName: data['reviewedUserName'] ?? '',
      reviewerType: data['reviewerType'] ?? '',
      reviewedUserType: data['reviewedUserType'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      dogName: data['dogName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'reviewedUserId': reviewedUserId,
      'reviewedUserName': reviewedUserName,
      'reviewerType': reviewerType,
      'reviewedUserType': reviewedUserType,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'dogName': dogName,
    };
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerPhotoUrl,
    String? reviewedUserId,
    String? reviewedUserName,
    String? reviewerType,
    String? reviewedUserType,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? dogName,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl ?? this.reviewerPhotoUrl,
      reviewedUserId: reviewedUserId ?? this.reviewedUserId,
      reviewedUserName: reviewedUserName ?? this.reviewedUserName,
      reviewerType: reviewerType ?? this.reviewerType,
      reviewedUserType: reviewedUserType ?? this.reviewedUserType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dogName: dogName ?? this.dogName,
    );
  }
}
