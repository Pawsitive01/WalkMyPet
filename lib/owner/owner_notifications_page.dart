import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:walkmypet/models/notification_model.dart';
import 'package:walkmypet/booking/my_bookings_page_redesigned.dart';

class OwnerNotificationsPage extends StatefulWidget {
  const OwnerNotificationsPage({super.key});

  @override
  State<OwnerNotificationsPage> createState() => _OwnerNotificationsPageState();
}

class _OwnerNotificationsPageState extends State<OwnerNotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      appBar: _buildAppBar(isDark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(isDark),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: Material(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF000000),
                size: 18,
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: Material(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _markAllAsRead(isDark),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      color: isDark ? Colors.white : const Color(0xFF000000),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState('Please log in to view notifications', isDark);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? Colors.white : const Color(0xFFEC4899),
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading notifications: ${snapshot.error}');
          return _buildErrorState(
            'Error loading notifications',
            'Please check your connection and try again.\n\nIf the issue persists, the app may need to configure a Firestore index.',
            isDark,
          );
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyState('No notifications yet', isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = AppNotification.fromFirestore(notifications[index]);
            return _buildNotificationCard(notification, isDark);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification, bool isDark) {
    final isUnread = !notification.isRead;
    final timeAgo = _getTimeAgo(notification.createdAt);

    Color iconColor;
    IconData iconData;
    List<Color> gradientColors;

    switch (notification.type) {
      case NotificationType.bookingRequest:
        iconData = Icons.event_rounded;
        iconColor = const Color(0xFFEC4899);
        gradientColors = [const Color(0xFFEC4899), const Color(0xFFF472B6)];
        break;
      case NotificationType.bookingConfirmed:
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
        break;
      case NotificationType.bookingCancelled:
        iconData = Icons.cancel_rounded;
        iconColor = const Color(0xFFEF4444);
        gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
        break;
      case NotificationType.bookingCompleted:
        iconData = Icons.task_alt_rounded;
        iconColor = const Color(0xFF10B981);
        gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
        break;
      case NotificationType.message:
        iconData = Icons.message_rounded;
        iconColor = const Color(0xFFEC4899);
        gradientColors = [const Color(0xFFEC4899), const Color(0xFFDB2777)];
        break;
      default:
        iconData = Icons.info_rounded;
        iconColor = const Color(0xFFEC4899);
        gradientColors = [const Color(0xFFEC4899), const Color(0xFFF472B6)];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread
              ? iconColor.withValues(alpha: 0.3)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!),
          width: isUnread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? iconColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: isUnread ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    iconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: iconColor.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[600] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEC4899).withValues(alpha: 0.1),
                  const Color(0xFFF472B6).withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see booking updates and important\nmessages here',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[700] : Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.1),
                    const Color(0xFFDC2626).withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: isDark ? Colors.red[400] : Colors.red[500],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  Future<void> _markAllAsRead(bool isDark) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    HapticFeedback.mediumImpact();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'All notifications marked as read',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Failed to mark notifications as read',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true});
    }

    // Navigate based on type - owners can view their bookings
    if (notification.bookingId != null) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyBookingsPageRedesigned(),
          ),
        );
      }
    }
  }
}
