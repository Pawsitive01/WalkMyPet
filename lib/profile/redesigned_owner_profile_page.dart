import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/auth_service.dart';
import 'package:walkmypet/services/image_upload_service.dart';
import 'package:walkmypet/booking/my_bookings_page.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;

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
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  late AnimationController _animationController;

  // Edit controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _petBreedController = TextEditingController();
  final TextEditingController _petAgeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _suburbController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();

  // Australian states and territories
  final List<String> _australianStates = [
    'New South Wales',
    'Victoria',
    'Queensland',
    'Western Australia',
    'South Australia',
    'Tasmania',
    'Australian Capital Territory',
    'Northern Territory',
  ];

  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadProfile();
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

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await _userService.getUser(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });

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
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        _loadProfile();
        // Refresh AuthProvider to keep state in sync
        Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
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

      print('💾 Saving image URL to Firestore...');
      print('   URL: $imageUrl');

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
        print('✅ UI updated with new image immediately!');
      }

      // Update user profile with new profile photo URL (not pet image)
      await _userService.updateUser(user.uid, {
        'photoURL': imageUrl,
      });

      print('✅ Image URL saved to Firestore');

      if (mounted) {
        _showSuccessSnackBar('Profile photo updated successfully');
        Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : canPop
              ? CustomScrollView(
                  slivers: [
                    _buildPinkSliverAppBar(isDark),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildProfileHeader(isDark),
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
                      const SizedBox(height: 32),
                      if (_isEditing) _buildEditForm(isDark) else _buildInfoCards(isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
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
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            _showErrorSnackBar('Notifications coming soon!');
          },
        ),
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
                          ? Image.network(
                              profilePhotoUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFFEC4899),
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading profile image: $error');
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
              MaterialPageRoute(builder: (context) => const MyBookingsPage()),
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
          _buildLocationDropdown(isDark),
          const SizedBox(height: 16),
          _buildTextField('City', _cityController, Icons.location_city, isDark),
          const SizedBox(height: 16),
          _buildTextField('Suburb (Optional)', _suburbController, Icons.home, isDark),
          const SizedBox(height: 16),
          _buildTextField('Postcode', _postcodeController, Icons.pin, isDark, TextInputType.number),
          const SizedBox(height: 24),
          _buildSaveButton(isDark),
        ],
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

  Widget _buildLocationDropdown(bool isDark) {
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
      child: DropdownButtonFormField<String>(
        initialValue: _selectedState,
        decoration: InputDecoration(
          labelText: 'State',
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: const Icon(Icons.location_on_outlined, size: 22, color: Color(0xFFEC4899)),
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
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
        items: _australianStates.map((state) {
          return DropdownMenuItem<String>(
            value: state,
            child: Text(state),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedState = value;
          });
        },
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
