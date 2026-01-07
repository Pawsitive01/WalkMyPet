import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/auth_service.dart';
import 'package:walkmypet/services/image_upload_service.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;
import 'package:walkmypet/widgets/location_picker.dart';
import 'package:walkmypet/onboarding/walker_onboarding_page.dart';
import 'package:walkmypet/walker/scheduled_walks_page.dart';
import 'package:walkmypet/walker/walker_notifications_page.dart';
import 'package:walkmypet/walker/active_walks_page.dart';
import 'package:walkmypet/screens/pages/wallet/wallet_screen.dart';

class RedesignedWalkerProfilePage extends StatefulWidget {
  const RedesignedWalkerProfilePage({super.key});

  @override
  State<RedesignedWalkerProfilePage> createState() => _RedesignedWalkerProfilePageState();
}

class _RedesignedWalkerProfilePageState extends State<RedesignedWalkerProfilePage>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  AppUser? _userProfile;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Stream<AppUser?>? _userProfileStream;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  double? _selectedLatitude;
  double? _selectedLongitude;

  // Services editing
  List<String> _selectedServices = [];
  Map<String, int> _servicePrices = {};

  final List<Map<String, dynamic>> _availableServices = [
    {
      'name': 'Walking',
      'icon': Icons.directions_walk_rounded,
      'description': 'Daily dog walks',
      'gradient': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    },
    {
      'name': 'Sitting',
      'icon': Icons.home_work_rounded,
      'description': 'Pet sitting at home',
      'gradient': [Color(0xFF10B981), Color(0xFF059669)],
    },
    {
      'name': 'Grooming',
      'icon': Icons.cleaning_services_rounded,
      'description': 'Basic grooming services',
      'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
    },
    {
      'name': 'Training',
      'icon': Icons.school_rounded,
      'description': 'Basic obedience training',
      'gradient': [Color(0xFFEC4899), Color(0xFFDB2777)],
    },
  ];

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _initializeStream();
    _animationController.forward();
  }

  void _initializeStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userProfileStream = _userService.userStream(user.uid);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await _userService.updateUser(user.uid, {
        'displayName': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'hourlyRate': int.tryParse(_hourlyRateController.text) ?? 25,
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        _showSuccessSnackBar('Profile updated successfully');
        try {
          await Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
        } catch (e) {
          debugPrint('AuthProvider not available: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Failed to update profile');
      }
    }
  }

  Future<void> _handleImageUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Show bottom sheet to choose image source
      final imageSource = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildImageSourceBottomSheet(),
      );

      if (imageSource == null) return;

      Map<String, dynamic>? imageData;
      if (imageSource == 'camera') {
        imageData = await _imageUploadService.pickImageFromCamera();
      } else {
        imageData = await _imageUploadService.pickImageFromGallery();
      }

      if (imageData == null) return;

      setState(() => _isUploadingImage = true);

      // Upload image to Firebase Storage
      final imageUrl = await _imageUploadService.uploadProfileImage(imageData);

      // Update user profile with new profile photo URL
      await _userService.updateUser(user.uid, {
        'photoURL': imageUrl,
      });

      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showSuccessSnackBar('Profile photo updated successfully');
        try {
          await Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
        } catch (e) {
          debugPrint('AuthProvider not available: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showErrorSnackBar('Failed to upload image: ${e.toString()}');
      }
    }
  }

  Widget _buildImageSourceBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = _imageUploadService.isDesktop;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Profile Photo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          // Only show camera option on mobile
          if (!isDesktop) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
              ),
              title: Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1F2937))),
              subtitle: Text('Use your camera', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey[600])),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            const SizedBox(height: 8),
          ],
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.photo_library, color: Color(0xFF6366F1)),
            ),
            title: Text(isDesktop ? 'Choose Photo' : 'Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1F2937))),
            subtitle: Text(isDesktop ? 'Select an image file' : 'Select from your photos', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey[600])),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildSignOutDialog(),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error signing out');
        }
      }
    }
  }

  void _showAccountBalance() {
    // Navigate to full wallet screen instead of showing dialog
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalletScreen(walkerId: user.uid),
        ),
      );
    }
  }

  void _showNotificationsPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WalkerNotificationsPage(),
      ),
    );
  }

  void _navigateToScheduledWalks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduledWalksPage(),
      ),
    );
  }

  void _navigateToActiveWalks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActiveWalksPage(),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _updateControllersWithProfile(AppUser? profile) {
    if (profile != null && !_isEditing) {
      _nameController.text = profile.displayName ?? '';
      _locationController.text = profile.location ?? '';
      _bioController.text = profile.bio ?? '';
      _hourlyRateController.text = (profile.hourlyRate ?? 25).toString();
      _selectedLatitude = profile.latitude;
      _selectedLongitude = profile.longitude;

      // Load services
      if (profile.services != null) {
        _selectedServices = List<String>.from(profile.services!);
      }
      if (profile.servicePrices != null) {
        _servicePrices = Map<String, int>.from(profile.servicePrices!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: StreamBuilder<AppUser?>(
        stream: _userProfileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            );
          }

          _userProfile = snapshot.data;
          _updateControllersWithProfile(_userProfile);

          return _buildBody(isDark, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildNotificationIcon(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Icon(
        Icons.notifications_none_rounded,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
        size: 22,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading notification count: ${snapshot.error}');
        }
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              size: 22,
            ),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }


  Widget _buildBody(bool isDark, bool isSmallScreen) {
    final bool needsOnboarding = _userProfile?.onboardingComplete != true;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildWalkerHeader(isDark),
                  const SizedBox(height: 20),
                  _buildProfileHeader(isDark, isSmallScreen),
                  if (needsOnboarding) ...[
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildCompleteSetupBanner(isDark),
                  ],
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  _buildStatsRow(isDark, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  if (_isEditing)
                    _buildEditForm(isDark, isSmallScreen)
                  else
                    _buildInfoCards(isDark, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkerHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.elliptical(60, 30),
          bottomRight: Radius.elliptical(60, 30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.directions_walk_rounded, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Walker Profile',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome, ${_userProfile?.displayName?.split(' ')[0] ?? 'Walker'}!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: _buildNotificationIcon(true),
                      onPressed: _showNotificationsPanel,
                      tooltip: 'Notifications',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Menu',
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      offset: const Offset(0, 50),
                      onSelected: (value) {
                        HapticFeedback.selectionClick();
                        if (value == 'edit') {
                          setState(() => _isEditing = !_isEditing);
                        } else if (value == 'active') {
                          _navigateToActiveWalks();
                        } else if (value == 'scheduled') {
                          _navigateToScheduledWalks();
                        } else if (value == 'balance') {
                          _showAccountBalance();
                        } else if (value == 'logout') {
                          _handleSignOut();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                                size: 20,
                                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isEditing ? 'Cancel Edit' : 'Edit Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'active',
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_walk_rounded,
                                size: 20,
                                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Active Walks',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'scheduled',
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Scheduled Walks',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'balance',
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 20,
                                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Account Balance',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                              SizedBox(width: 12),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, bool isSmallScreen) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _handleImageUpload,
              child: Hero(
                tag: 'profile-image',
                child: Container(
                  width: isSmallScreen ? 100 : 120,
                  height: isSmallScreen ? 100 : 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.1),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _isUploadingImage
                        ? Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF6366F1),
                              ),
                            ),
                          )
                        : _userProfile?.photoURL != null
                            ? Image.network(
                                _userProfile!.photoURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(isSmallScreen),
                              )
                            : _buildDefaultAvatar(isSmallScreen),
                  ),
                ),
              ),
            ),
            if (!_isUploadingImage)
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleImageUpload,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 7 : 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: isSmallScreen ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (_userProfile?.hasPoliceClearance == true)
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          _userProfile?.displayName ?? 'Pet Walker',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _userProfile?.email ?? '',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (!_isEditing)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isEditing = true);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 7 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.1),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: isSmallScreen ? 14 : 16,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompleteSetupBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WalkerOnboardingPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Finish setting up to unlock all features',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.15),
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: isSmallScreen ? 48 : 60,
        color: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
            ? [
                const Color(0xFF1E1E1E),
                const Color(0xFF252525),
              ]
            : [
                Colors.white,
                const Color(0xFFFAFAFA),
              ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            isDark,
            Icons.star_rounded,
            '${_userProfile?.rating ?? 5.0}',
            'Rating',
            const Color(0xFFFBBF24),
            isSmallScreen,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          _buildStatItem(
            isDark,
            Icons.directions_walk_rounded,
            '${_userProfile?.completedWalks ?? 0}',
            'Walks',
            const Color(0xFF6366F1),
            isSmallScreen,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          _buildStatItem(
            isDark,
            Icons.calendar_month_rounded,
            '0', // Placeholder - will be updated dynamically
            'Scheduled',
            const Color(0xFFEC4899),
            isSmallScreen,
            onTap: _navigateToScheduledWalks,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    bool isDark,
    IconData icon,
    String value,
    String label,
    Color color,
    bool isSmallScreen, {
    VoidCallback? onTap,
  }) {
    Widget child = Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16,
        horizontal: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.15 : 0.08),
            color.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: isSmallScreen ? 20 : 24, color: Colors.white),
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (onTap != null) {
      child = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: child,
      );
    }

    return Expanded(child: child);
  }

  Widget _buildInfoCards(bool isDark, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.location_on_outlined,
            title: 'Location',
            isSmallScreen: isSmallScreen,
            items: [
              _InfoItem('', _userProfile?.location ?? 'Not set'),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.attach_money_rounded,
            title: 'Rate & Experience',
            isSmallScreen: isSmallScreen,
            items: [
              _InfoItem('Hourly Rate', '\$${_userProfile?.hourlyRate ?? 25}/hr'),
              _InfoItem('Phone', _userProfile?.phoneNumber ?? 'Not set'),
            ],
          ),
          if (_userProfile?.services != null && _userProfile!.services!.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildServicesCard(isDark, _userProfile!.services!, isSmallScreen),
          ],
          if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildBioCard(isDark, _userProfile!.bio!, isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required bool isSmallScreen,
    required List<_InfoItem> items,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 18 : 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ...items.map((item) => _buildInfoRow(isDark, item, isSmallScreen)),
        ],
      ),
    );
  }

  Widget _buildServicesCard(bool isDark, List services, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
            ? [
                const Color(0xFF1E1E1E),
                const Color(0xFF252525),
              ]
            : [
                Colors.white,
                const Color(0xFFFAFAFA),
              ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category_outlined,
                  size: isSmallScreen ? 18 : 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Services',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Edit button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEditServicesDialog(isDark, isSmallScreen),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: services.map((service) {
              // Get gradient for this service
              final serviceData = _availableServices.firstWhere(
                (s) => s['name'] == service,
                orElse: () => _availableServices[0],
              );
              final gradient = serviceData['gradient'] as List<Color>;
              final icon = serviceData['icon'] as IconData;

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 14,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradient[0].withValues(alpha: isDark ? 0.2 : 0.15),
                      gradient[1].withValues(alpha: isDark ? 0.15 : 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gradient[0].withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        size: isSmallScreen ? 12 : 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      service.toString(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: gradient[0],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(bool isDark, String bio, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
            ? [
                const Color(0xFF1E1E1E),
                const Color(0xFF252525),
              ]
            : [
                Colors.white,
                const Color(0xFFFAFAFA),
              ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outlined,
                  size: isSmallScreen ? 18 : 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About',
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text(
            bio,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, _InfoItem item, bool isSmallScreen) {
    if (item.label.isEmpty) {
      return Text(
        item.value,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isDark, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          _buildTextField(
            'Your Name',
            _nameController,
            Icons.person_outline,
            isDark,
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          // Map Picker for Location
          _buildLocationPicker(isDark, isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            'Hourly Rate (\$)',
            _hourlyRateController,
            Icons.attach_money,
            isDark,
            isSmallScreen,
            TextInputType.number,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            'Bio',
            _bioController,
            Icons.info_outlined,
            isDark,
            isSmallScreen,
            TextInputType.multiline,
            4,
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          _buildSaveButton(isDark, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildLocationPicker(bool isDark, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<LocationPickerResult>(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPicker(
                initialLatitude: _selectedLatitude,
                initialLongitude: _selectedLongitude,
              ),
            ),
          );

          if (result != null) {
            setState(() {
              _selectedLatitude = result.latitude;
              _selectedLongitude = result.longitude;
              _locationController.text = result.address;
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 14 : 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: isSmallScreen ? 10 : 12),
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _locationController.text.isNotEmpty
                      ? Icons.map_rounded
                      : Icons.add_location_alt_rounded,
                  size: isSmallScreen ? 18 : 20,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _locationController.text.isNotEmpty
                          ? _locationController.text
                          : 'Tap to select location',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w500,
                        color: _locationController.text.isNotEmpty
                            ? (isDark ? Colors.white : const Color(0xFF1F2937))
                            : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark,
    bool isSmallScreen, [
    TextInputType? keyboardType,
    int maxLines = 1,
  ]) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: isSmallScreen ? 15 : 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: isSmallScreen ? 18 : 20, color: Colors.white),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
        ),
        child: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Future<void> _showEditServicesDialog(bool isDark, bool isSmallScreen) async {
    // Create copies for editing
    List<String> tempSelectedServices = List.from(_selectedServices);
    Map<String, int> tempServicePrices = Map.from(_servicePrices);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Edit Services',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Services Selection
                        Text(
                          'Select Services',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose the services you offer',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._availableServices.map((service) {
                          final isSelected =
                              tempSelectedServices.contains(service['name']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelectedServices
                                          .remove(service['name']);
                                      tempServicePrices.remove(service['name']);
                                    } else {
                                      tempSelectedServices
                                          .add(service['name'] as String);
                                      tempServicePrices[service['name'] as String] = 25;
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                            .withValues(alpha: 0.1)
                                        : isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : const Color(0xFFE5E7EB),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? LinearGradient(
                                                  colors: service['gradient']
                                                      as List<Color>,
                                                )
                                              : null,
                                          color: isSelected
                                              ? null
                                              : isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.1)
                                                  : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          service['icon'] as IconData,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF6366F1),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              service['name'] as String,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              service['description'] as String,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white60
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF10B981),
                                          size: 26,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Pricing Section
                        if (tempSelectedServices.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Set Your Rates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set hourly rates for each service',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),

                          ...tempSelectedServices.map((serviceName) {
                            final serviceData = _availableServices.firstWhere(
                              (s) => s['name'] == serviceName,
                              orElse: () => _availableServices[0],
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: serviceData['gradient']
                                              as List<Color>,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        serviceData['icon'] as IconData,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        serviceName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 70,
                                      child: TextFormField(
                                        initialValue: tempServicePrices[serviceName]
                                                ?.toString() ??
                                            '25',
                                        onChanged: (value) {
                                          if (value.isEmpty) {
                                            tempServicePrices[serviceName] = 0;
                                          } else {
                                            tempServicePrices[serviceName] =
                                                int.tryParse(value) ?? 0;
                                          }
                                        },
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1F2937),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '25',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF6366F1),
                                              width: 2,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: const Color(0xFF6366F1)
                                                  .withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF6366F1),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '/hr',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                // Save Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: tempSelectedServices.isEmpty
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);

                              // Update state
                              setState(() {
                                _selectedServices = tempSelectedServices;
                                _servicePrices = tempServicePrices;
                              });

                              // Save to Firebase
                              await _saveServicesToFirebase();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Save Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveServicesToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Calculate average rate
      final rates = _servicePrices.values.toList();
      final avgRate = rates.isNotEmpty
          ? rates.reduce((a, b) => a + b) / rates.length
          : 25.0;

      await _userService.updateUser(user.uid, {
        'services': _selectedServices,
        'servicePrices': _servicePrices,
        'hourlyRate': avgRate.round(),
      });

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessSnackBar('Services updated successfully');
        try {
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .refreshUserProfile();
        } catch (e) {
          debugPrint('AuthProvider not available: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Failed to update services');
      }
    }
  }

  Widget _buildSignOutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFEF4444),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to sign out? You\'ll need to log in again to access your account.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, false);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}