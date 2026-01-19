import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/auth_service.dart';
import 'package:walkmypet/services/image_upload_service.dart';
import 'package:walkmypet/booking/my_bookings_page_v3.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;
import 'package:walkmypet/widgets/location_picker.dart';
import 'package:walkmypet/onboarding/owner_onboarding_page.dart';
import 'package:walkmypet/owner/owner_notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RedesignedOwnerProfilePage extends StatefulWidget {
  const RedesignedOwnerProfilePage({super.key});

  @override
  State<RedesignedOwnerProfilePage> createState() => _RedesignedOwnerProfilePageState();
}

class _RedesignedOwnerProfilePageState extends State<RedesignedOwnerProfilePage>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  AppUser? _userProfile;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  late AnimationController _animationController;
  Stream<AppUser?>? _userProfileStream;

  // Edit controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _petBreedController = TextEditingController();
  final TextEditingController _petAgeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _suburbController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();

  double? _selectedLatitude;
  double? _selectedLongitude;

  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeStream();
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
    _petNameController.dispose();
    _petBreedController.dispose();
    _petAgeController.dispose();
    _cityController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  void _updateControllersWithProfile(AppUser? profile) {
    if (profile != null) {
      final data = profile.toFirestore();
      _nameController.text = data['displayName'] ?? '';
      _petNameController.text = data['dogName'] ?? '';
      _petBreedController.text = data['dogBreed'] ?? '';
      _petAgeController.text = data['dogAge'] ?? '';
      _selectedState = data['locationState'];
      _cityController.text = data['locationCity'] ?? '';
      _suburbController.text = data['locationSuburb'] ?? '';
      _postcodeController.text = data['locationPostcode'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _userService.updateUser(user.uid, {
        'displayName': _nameController.text.trim(),
        'dogName': _petNameController.text.trim(),
        'dogBreed': _petBreedController.text.trim(),
        'dogAge': _petAgeController.text.trim(),
        'locationState': _selectedState ?? '',
        'locationCity': _cityController.text.trim(),
        'locationSuburb': _suburbController.text.trim(),
        'locationPostcode': _postcodeController.text.trim(),
        'location': '${_cityController.text.trim()}, ${_selectedState ?? ''}', // Keep for backward compatibility
      });

      if (mounted) {
        setState(() => _isEditing = false);
        _showSuccessSnackBar('Profile updated successfully');
        // Refresh AuthProvider to keep state in sync
        try {
          Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
        } catch (e) {
          debugPrint('AuthProvider not available: $e');
        }
      }
    } catch (e) {
      if (mounted) {
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


      // Update UI immediately with new image URL
      if (mounted && _userProfile != null) {
        setState(() {
          _userProfile = AppUser(
            id: _userProfile!.id,
            email: _userProfile!.email,
            displayName: _userProfile!.displayName,
            photoURL: imageUrl, // NEW PROFILE PHOTO URL
            userType: _userProfile!.userType,
            createdAt: _userProfile!.createdAt,
            updatedAt: _userProfile!.updatedAt,
            dogName: _userProfile!.dogName,
            dogBreed: _userProfile!.dogBreed,
            dogAge: _userProfile!.dogAge,
            hourlyRate: _userProfile!.hourlyRate,
            bio: _userProfile!.bio,
            availability: _userProfile!.availability,
          );
          _isUploadingImage = false;
        });
      }

      // Update user profile with new profile photo URL (not pet image)
      await _userService.updateUser(user.uid, {
        'photoURL': imageUrl,
      });


      if (mounted) {
        _showSuccessSnackBar('Profile photo updated successfully');
        try {
          Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
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
    final isDesktop = _imageUploadService.isDesktop;

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Choose Pet Photo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          // Only show camera option on mobile
          if (!isDesktop) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFFEC4899)),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use your camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            const SizedBox(height: 8),
          ],
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.photo_library, color: Color(0xFFEC4899)),
            ),
            title: Text(isDesktop ? 'Choose Photo' : 'Choose from Gallery'),
            subtitle: Text(isDesktop ? 'Select an image file' : 'Select from your photos'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildSignOutDialog(),
    );

    if (confirm == true) {
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
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
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
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
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
      body: _userProfileStream == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : StreamBuilder<AppUser?>(
              stream: _userProfileStream,
              builder: (context, snapshot) {
                // Show loading only on initial waiting state without data
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading profile: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                // If no data after waiting, show error
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No profile found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeStream();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                _userProfile = snapshot.data;

                // Update controllers with new data (only when not editing)
                if (!_isEditing && _userProfile != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateControllersWithProfile(_userProfile);
                  });
                }

                final bool needsOnboarding = _userProfile?.toFirestore()['onboardingComplete'] != true;

                return canPop
                    ? CustomScrollView(
                        slivers: [
                          _buildPinkSliverAppBar(isDark),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildProfileHeader(isDark),
                                if (needsOnboarding) ...[
                                  const SizedBox(height: 16),
                                  _buildCompleteSetupBanner(isDark),
                                ],
                                const SizedBox(height: 32),
                                if (_isEditing) _buildEditForm(isDark) else _buildInfoCards(isDark),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileHeader(isDark),
                            if (needsOnboarding) ...[
                              const SizedBox(height: 16),
                              _buildCompleteSetupBanner(isDark),
                            ],
                            const SizedBox(height: 32),
                            if (_isEditing) _buildEditForm(isDark) else _buildInfoCards(isDark),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
              },
            ),
    );
  }

  Widget _buildNotificationButton() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        // Only show if there are notifications
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerNotificationsPage(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
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

  Widget _buildPinkSliverAppBar(bool isDark) {
    final canPop = Navigator.of(context).canPop();

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: [
        if (!_isEditing) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                // Navigate to home page and show walkers tab
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Book a Walk',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
        _buildNotificationButton(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          offset: const Offset(0, 50),
          onSelected: (value) {
            if (value == 'edit') {
              setState(() => _isEditing = !_isEditing);
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
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 12),
                  Text(_isEditing ? 'Cancel Edit' : 'Edit Profile'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                  SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pets, size: 60, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userProfile?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        collapseMode: CollapseMode.pin,
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final data = _userProfile?.toFirestore() ?? {};
    final profilePhotoUrl = data['photoURL'] as String?;

    return Column(
      children: [
        // Profile Photo with upload button
        Stack(
          children: [
            Hero(
              tag: 'profile-image',
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEC4899),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isUploadingImage
                      ? Container(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFEC4899)),
                          ),
                        )
                      : profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profilePhotoUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                child: const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFEC4899)),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                // Silently fall back to default avatar
                                return _buildDefaultPetAvatar(isDark);
                              },
                            )
                          : _buildDefaultPetAvatar(isDark),
                ),
              ),
            ),
            // Camera button
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleImageUpload,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Owner Name
        Text(
          _userProfile?.displayName ?? 'Pet Owner',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Pet Name
        if (data['dogName'] != null && data['dogName'].toString().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  data['dogName'].toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
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
                builder: (context) => const OwnerOnboardingPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
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

  Widget _buildDefaultPetAvatar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withValues(alpha: 0.2),
            const Color(0xFFF472B6).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.pets,
          size: 60,
          color: Color(0xFFEC4899),
        ),
      ),
    );
  }

  Widget _buildInfoCards(bool isDark) {
    final data = _userProfile?.toFirestore() ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Pet Information Card
          _buildElegantCard(
            isDark: isDark,
            icon: Icons.pets_rounded,
            iconColor: const Color(0xFFEC4899),
            title: 'Pet Information',
            children: [
              _buildInfoRow(isDark, 'Name', data['dogName'] ?? 'Not set', Icons.abc),
              const Divider(height: 24),
              _buildInfoRow(isDark, 'Breed', data['dogBreed'] ?? 'Not set', Icons.category),
              const Divider(height: 24),
              _buildInfoRow(isDark, 'Age', '${data['dogAge'] ?? 'Not set'} ${data['dogAge'] != null ? 'years' : ''}', Icons.cake),
            ],
          ),
          const SizedBox(height: 16),
          // Location Card
          _buildElegantCard(
            isDark: isDark,
            icon: Icons.location_on,
            iconColor: const Color(0xFF6366F1),
            title: 'Location',
            children: [
              _buildInfoRow(isDark, 'State', data['locationState'] ?? 'Not set', Icons.map),
              const Divider(height: 24),
              _buildInfoRow(isDark, 'City', data['locationCity'] ?? 'Not set', Icons.location_city),
              if (data['locationSuburb'] != null && data['locationSuburb'].toString().isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(isDark, 'Suburb', data['locationSuburb'], Icons.home),
              ],
              const Divider(height: 24),
              _buildInfoRow(isDark, 'Postcode', data['locationPostcode'] ?? 'Not set', Icons.pin),
            ],
          ),
          const SizedBox(height: 16),
          // My Bookings Card
          _buildMyBookingsCard(isDark),
        ],
      ),
    );
  }

  Widget _buildElegantCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyBookingsCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyBookingsPageV3()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View and manage your pet walks',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildTextField('Your Name', _nameController, Icons.person_outline, isDark),
          const SizedBox(height: 16),
          _buildTextField('Pet Name', _petNameController, Icons.pets_outlined, isDark),
          const SizedBox(height: 16),
          _buildTextField('Breed', _petBreedController, Icons.category_outlined, isDark),
          const SizedBox(height: 16),
          _buildTextField('Age (years)', _petAgeController, Icons.cake_outlined, isDark, TextInputType.number),
          const SizedBox(height: 16),
          // Map Picker for Location
          _buildLocationPicker(isDark),
          const SizedBox(height: 24),
          _buildSaveButton(isDark),
        ],
      ),
    );
  }

  Widget _buildLocationPicker(bool isDark) {
    // Combined location string for display
    final String fullLocation = [_cityController.text, _selectedState ?? '', _postcodeController.text]
        .where((s) => s.isNotEmpty)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
              // Parse the address to fill in the fields
              final addressParts = result.address.split(', ');
              if (addressParts.isNotEmpty) {
                _cityController.text = addressParts.first;
              }
              if (addressParts.length > 1) {
                _selectedState = addressParts[1];
              }
              if (addressParts.length > 2) {
                _postcodeController.text = addressParts.last;
              }
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                fullLocation.isNotEmpty
                    ? Icons.map_rounded
                    : Icons.add_location_alt_rounded,
                size: 22,
                color: const Color(0xFFEC4899),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullLocation.isNotEmpty
                          ? fullLocation
                          : 'Tap to select location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: fullLocation.isNotEmpty
                            ? (isDark ? Colors.white : const Color(0xFF1F2937))
                            : (isDark ? Colors.grey[400] : Colors.grey[400]),
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
                color: isDark ? Colors.grey[400] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, [TextInputType? keyboardType]) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(icon, size: 22, color: const Color(0xFFEC4899)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
          SizedBox(width: 12),
          Text('Sign Out'),
        ],
      ),
      content: const Text('Are you sure you want to sign out of your account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}
