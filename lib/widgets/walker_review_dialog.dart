import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/models/review_model.dart';
import 'package:walkmypet/services/review_service.dart';
import 'package:walkmypet/services/user_service.dart';

/// Dialog for walkers to review pet owners after a completed walk
class WalkerReviewDialog extends StatefulWidget {
  final String bookingId;
  final String ownerId;
  final String ownerName;
  final String? dogName;

  const WalkerReviewDialog({
    super.key,
    required this.bookingId,
    required this.ownerId,
    required this.ownerName,
    this.dogName,
  });

  @override
  State<WalkerReviewDialog> createState() => _WalkerReviewDialogState();
}

class _WalkerReviewDialogState extends State<WalkerReviewDialog> {
  final ReviewService _reviewService = ReviewService();
  final UserService _userService = UserService();
  final TextEditingController _commentController = TextEditingController();

  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Please log in to submit a review');
      return;
    }

    if (_rating < 1) {
      _showError('Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current user's profile (walker profile)
      final userProfile = await _userService.getUser(user.uid);

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final review = Review(
        id: '',
        bookingId: widget.bookingId,
        reviewerId: user.uid,
        reviewerName: userProfile.displayName ?? 'Unknown',
        reviewerPhotoUrl: userProfile.photoURL ?? '',
        reviewedUserId: widget.ownerId,
        reviewedUserName: widget.ownerName,
        reviewerType: 'walker',
        reviewedUserType: 'owner',
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
        dogName: widget.dogName,
      );

      await _reviewService.createReview(review);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Failed to submit review: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).round()),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate the Pet Owner',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How was ${widget.ownerName}?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),

                if (widget.dogName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 16,
                          color: Color(0xFFEC4899),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Walked ${widget.dogName!}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Star Rating
                Text(
                  'How was your experience?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Star selector
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _rating >= starValue
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 48,
                              color: _rating >= starValue
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.grey[700] : Colors.grey[300]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 8),

                // Rating text
                Center(
                  child: Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _getRatingColor(_rating),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Comment field
                Text(
                  'Tell us more (optional)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Was ${widget.ownerName} on time? Were the pet instructions clear?',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha((0.1 * 255).round())
                            : Colors.black.withAlpha((0.1 * 255).round()),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha((0.1 * 255).round())
                            : Colors.black.withAlpha((0.1 * 255).round()),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF6366F1).withAlpha((0.4 * 255).round()),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Excellent!';
    if (rating >= 4) return 'Great!';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return const Color(0xFF10B981);
    if (rating >= 3) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }
}
