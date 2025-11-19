import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/auth_service.dart';
import 'package:walkmypet/services/image_upload_service.dart';

class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key});

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  AppUser? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;

  // Edit controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dogNameController = TextEditingController();
  final TextEditingController _dogBreedController = TextEditingController();
  final TextEditingController _dogAgeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dogNameController.dispose();
    _dogBreedController.dispose();
    _dogAgeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print('📥 Loading profile for user: ${user.uid}');
      final profile = await _userService.getUser(user.uid);

      if (profile != null) {
        print('✅ Profile loaded successfully');
        print('   Display Name: ${profile.displayName}');
        print('   Photo URL: ${profile.photoURL ?? "No photo"}');
        print('   Photo URL length: ${profile.photoURL?.length ?? 0}');
      } else {
        print('⚠️ Profile is null');
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });

        if (profile != null) {
          final data = profile.toFirestore();
          _nameController.text = data['displayName'] ?? '';
          _dogNameController.text = data['dogName'] ?? '';
          _dogBreedController.text = data['dogBreed'] ?? '';
          _dogAgeController.text = data['dogAge'] ?? '';
          _locationController.text = data['location'] ?? '';
        }
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _userService.updateUser(user.uid, {
        'displayName': _nameController.text.trim(),
        'dogName': _dogNameController.text.trim(),
        'dogBreed': _dogBreedController.text.trim(),
        'dogAge': _dogAgeController.text.trim(),
        'location': _locationController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Profile updated successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  Future<void> _showImageSourceBottomSheet() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Photo Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                if (!_imageUploadService.isDesktop)
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Color(0xFFEC4899)),
                    title: const Text('Camera'),
                    onTap: () {
                      Navigator.pop(context);
                      _handleImageUpload(fromCamera: true);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFFEC4899)),
                  title: Text(_imageUploadService.isDesktop ? 'Choose File' : 'Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleImageUpload(fromCamera: false);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleImageUpload({required bool fromCamera}) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Pick image - returns Map with bytes for cross-platform compatibility
      Map<String, dynamic>? imageData;
      if (fromCamera) {
        imageData = await _imageUploadService.pickImageFromCamera();
      } else {
        imageData = await _imageUploadService.pickImageFromGallery();
      }

      if (imageData == null) {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
        return;
      }

      // Upload to Firebase Storage using Uint8List bytes
      final downloadUrl = await _imageUploadService.uploadProfileImage(imageData);

      // Update user profile in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('💾 Saving image URL to Firestore...');
        print('   URL: $downloadUrl');

        // Update UI immediately with new image URL (don't wait for Firestore)
        if (mounted && _userProfile != null) {
          setState(() {
            // Create updated user profile with new photo URL
            _userProfile = AppUser(
              id: _userProfile!.id,
              email: _userProfile!.email,
              displayName: _userProfile!.displayName,
              photoURL: downloadUrl, // NEW IMAGE URL
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
          });
          print('✅ UI updated with new image immediately!');
        }

        // Save to Firestore in background
        await _userService.updateUser(user.uid, {
          'photoURL': downloadUrl,
        });

        print('✅ Image URL saved to Firestore');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Profile photo updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                _loadProfile();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFFEC4899),
                                  backgroundImage: _userProfile?.photoURL != null && _userProfile!.photoURL!.isNotEmpty
                                      ? NetworkImage(_userProfile!.photoURL!)
                                      : null,
                                  onBackgroundImageError: _userProfile?.photoURL != null
                                      ? (exception, stackTrace) {
                                          print('Error loading profile image: $exception');
                                        }
                                      : null,
                                  child: _userProfile?.photoURL == null || _userProfile!.photoURL!.isEmpty
                                      ? (_isUploadingImage
                                          ? const SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.person, size: 50, color: Colors.white))
                                      : _isUploadingImage
                                          ? Container(
                                              color: Colors.black54,
                                              child: const SizedBox(
                                                width: 30,
                                                height: 30,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                            )
                                          : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploadingImage ? null : _showImageSourceBottomSheet,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEC4899),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userProfile?.displayName ?? 'Pet Owner',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userProfile?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile Information Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pets_rounded, color: Color(0xFFEC4899)),
                            const SizedBox(width: 8),
                            Text(
                              'Dog Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (_isEditing) ...[
                          _buildEditField('Your Name', _nameController, Icons.person),
                          const SizedBox(height: 16),
                          _buildEditField('Dog Name', _dogNameController, Icons.pets),
                          const SizedBox(height: 16),
                          _buildEditField('Breed', _dogBreedController, Icons.category),
                          const SizedBox(height: 16),
                          _buildEditField('Age (years)', _dogAgeController, Icons.cake, TextInputType.number),
                          const SizedBox(height: 16),
                          _buildEditField('Location', _locationController, Icons.location_on),
                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEC4899),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildInfoRow('Dog Name', _userProfile?.toFirestore()['dogName'] ?? 'Not set', Icons.pets),
                          const SizedBox(height: 16),
                          _buildInfoRow('Breed', _userProfile?.toFirestore()['dogBreed'] ?? 'Not set', Icons.category),
                          const SizedBox(height: 16),
                          _buildInfoRow('Age', '${_userProfile?.toFirestore()['dogAge'] ?? 'Not set'} years', Icons.cake),
                          const SizedBox(height: 16),
                          _buildInfoRow('Location', _userProfile?.toFirestore()['location'] ?? 'Not set', Icons.location_on),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notifications Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // TODO: Navigate to notifications page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifications coming soon!')),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_rounded,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'View your booking updates',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign Out Button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton(
                      onPressed: _handleSignOut,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEC4899).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFEC4899)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, [TextInputType? keyboardType]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFEC4899)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
        ),
      ),
    );
  }
}
