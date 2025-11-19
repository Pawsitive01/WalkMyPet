import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/image_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/profile/redesigned_owner_profile_page.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;

class OwnerOnboardingPage extends StatefulWidget {
  const OwnerOnboardingPage({super.key});

  @override
  State<OwnerOnboardingPage> createState() => _OwnerOnboardingPageState();
}

class _OwnerOnboardingPageState extends State<OwnerOnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final UserService _userService = UserService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  int _currentStep = 0;
  final int _totalSteps = 8;

  // Form data
  String ownerName = '';
  String dogName = '';
  String dogBreed = '';
  int? dogAge;
  String dogSize = '';
  String dogTemperament = '';
  String locationState = '';
  String locationCity = '';
  String locationSuburb = '';
  String locationPostcode = '';
  String bio = '';
  Map<String, dynamic>? _profileImage;
  String? _profileImageUrl;
  Map<String, dynamic>? _petImage;
  String? _petImageUrl;

  bool _isLoading = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _loadSavedProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _userService.getUser(user.uid);
      if (userDoc == null) return;

      final data = userDoc.toFirestore();
      final progress = data['onboardingProgress'] as Map<String, dynamic>?;

      if (progress != null && mounted) {
        setState(() {
          _currentStep = progress['currentStep'] ?? 0;
          ownerName = progress['ownerName'] ?? '';
          dogName = progress['dogName'] ?? '';
          dogBreed = progress['dogBreed'] ?? '';
          dogAge = progress['dogAge'];
          locationState = progress['locationState'] ?? '';
          locationCity = progress['locationCity'] ?? '';
          locationSuburb = progress['locationSuburb'] ?? '';
          locationPostcode = progress['locationPostcode'] ?? '';
          bio = progress['bio'] ?? '';
        });
        _updateProgress();
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    // Auto-save progress to Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _userService.updateUser(user.uid, {
        'onboardingProgress': {
          'currentStep': _currentStep,
          'ownerName': ownerName,
          'dogName': dogName,
          'dogBreed': dogBreed,
          'dogAge': dogAge,
          'dogSize': dogSize,
          'dogTemperament': dogTemperament,
          'locationState': locationState,
          'locationCity': locationCity,
          'locationSuburb': locationSuburb,
          'locationPostcode': locationPostcode,
          'bio': bio,
        },
      });
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _updateProgress();
      _saveProgress();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _updateProgress();
    }
  }

  void _updateProgress() {
    final newProgress = (_currentStep + 1) / _totalSteps;
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: newProgress,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward(from: 0.0);
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Upload profile image if selected
      if (_profileImage != null) {
        try {
          _profileImageUrl = await _imageUploadService.uploadProfileImage(_profileImage!);
        } catch (e) {
          print('Error uploading profile image: $e');
          // Continue without profile image if upload fails
        }
      }

      // Upload pet image if selected
      if (_petImage != null) {
        try {
          _petImageUrl = await _imageUploadService.uploadProfileImage(_petImage!);
        } catch (e) {
          print('Error uploading pet image: $e');
          // Continue without pet image if upload fails
        }
      }

      // Save complete profile to Firebase
      await _userService.updateUser(user.uid, {
        'displayName': ownerName,
        'dogName': dogName,
        'dogBreed': dogBreed,
        'dogAge': dogAge.toString(),
        'dogSize': dogSize,
        'dogTemperament': dogTemperament,
        'locationState': locationState,
        'locationCity': locationCity,
        'locationSuburb': locationSuburb,
        'locationPostcode': locationPostcode,
        'location': '$locationCity, $locationState', // Keep for backward compatibility
        'bio': bio,
        'photoURL': _profileImageUrl,
        'petImageURL': _petImageUrl,
        'onboardingComplete': true,
      });

      // Refresh AuthProvider to update the state
      if (mounted) {
        await Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Welcome to WalkMyPet, $ownerName!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          // Navigate to profile page and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RedesignedOwnerProfilePage()),
            (route) => route.isFirst, // Keep only the first route (home page)
          );
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF0F172A), size: 20),
                  onPressed: _previousStep,
                ),
              )
            : null,
        actions: [
          if (_currentStep < _totalSteps - 1)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: TextButton(
                onPressed: _nextStep,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEC4899),
              Color(0xFFF472B6),
              Color(0xFFDB2777),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              _buildProgressBar(),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildWelcomeStep(),
                    _buildOwnerNameStep(),
                    _buildDogNameStep(),
                    _buildDogBreedStep(),
                    _buildDogAgeStep(),
                    _buildLocationStep(),
                    _buildProfileImageStep(),
                    _buildSummaryStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
    VoidCallback? onContinue,
    bool showContinueButton = true,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Content
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: child,
          ),

          if (showContinueButton) ...[
            const SizedBox(height: 40),

            // Continue Button
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildContinueButton(onContinue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueButton(VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed ?? _nextStep,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Continue',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEC4899),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFEC4899),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return _buildStepContainer(
      title: 'Welcome to\nWalkMyPet! 🐾',
      subtitle: 'Let\'s set up your profile so you can find the perfect walker for your furry friend.',
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This will only take 2 minutes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You can skip any question and come back later',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerNameStep() {
    return _buildStepContainer(
      title: 'What\'s your name?',
      subtitle: 'This helps walkers know who they\'re working with.',
      child: _buildModernTextField(
        value: ownerName,
        hint: 'Enter your full name',
        icon: Icons.person_rounded,
        onChanged: (value) {
          setState(() {
            ownerName = value;
          });
        },
      ),
      onContinue: ownerName.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildDogNameStep() {
    return _buildStepContainer(
      title: 'What\'s your dog\'s name?',
      subtitle: 'Let\'s get to know your furry friend!',
      child: _buildModernTextField(
        value: dogName,
        hint: 'e.g., Max, Bella, Charlie',
        icon: Icons.pets_rounded,
        onChanged: (value) {
          setState(() {
            dogName = value;
          });
        },
      ),
      onContinue: dogName.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildDogBreedStep() {
    return _buildStepContainer(
      title: 'What breed is ${dogName.isNotEmpty ? dogName : 'your dog'}?',
      subtitle: 'This helps us match you with experienced walkers.',
      child: _buildModernTextField(
        value: dogBreed,
        hint: 'e.g., Golden Retriever, Mixed Breed',
        icon: Icons.category_rounded,
        onChanged: (value) {
          setState(() {
            dogBreed = value;
          });
        },
      ),
      onContinue: dogBreed.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildDogAgeStep() {
    return _buildStepContainer(
      title: 'How old is ${dogName.isNotEmpty ? dogName : 'your dog'}?',
      subtitle: 'Age helps us understand their energy level and needs.',
      child: Column(
        children: [
          _buildModernTextField(
            value: dogAge?.toString() ?? '',
            hint: 'Enter age in years',
            icon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                dogAge = int.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 24),
          _buildAgeQuickSelect(),
        ],
      ),
      onContinue: dogAge != null ? _nextStep : null,
    );
  }

  Widget _buildAgeQuickSelect() {
    final ages = [1, 2, 3, 4, 5, 6, 7, 8];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ages.map((age) {
        final isSelected = dogAge == age;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                dogAge = age;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Text(
                '$age ${age == 1 ? 'year' : 'years'}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFFEC4899) : Colors.white,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationStep() {
    final List<String> australianStates = [
      'New South Wales',
      'Victoria',
      'Queensland',
      'Western Australia',
      'South Australia',
      'Tasmania',
      'Australian Capital Territory',
      'Northern Territory',
    ];

    return _buildStepContainer(
      title: 'Where are you located?',
      subtitle: 'This helps us find walkers in your area.',
      showContinueButton: false,
      child: Column(
        children: [
          // State Dropdown
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              initialValue: locationState.isEmpty ? null : locationState,
              decoration: InputDecoration(
                hintText: 'Select State',
                hintStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              items: australianStates.map((state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  locationState = value ?? '';
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // City
          _buildModernTextField(
            value: locationCity,
            hint: 'City (e.g., Adelaide, Sydney)',
            icon: Icons.location_city_rounded,
            onChanged: (value) {
              setState(() {
                locationCity = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Suburb
          _buildModernTextField(
            value: locationSuburb,
            hint: 'Suburb (Optional)',
            icon: Icons.home_rounded,
            onChanged: (value) {
              setState(() {
                locationSuburb = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Postcode
          _buildModernTextField(
            value: locationPostcode,
            hint: 'Postcode',
            icon: Icons.pin_rounded,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                locationPostcode = value;
              });
            },
          ),
          const SizedBox(height: 40),
          _buildContinueButton(
            (locationState.isNotEmpty && locationCity.isNotEmpty && locationPostcode.isNotEmpty)
                ? _nextStep
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageStep() {
    return _buildStepContainer(
      title: 'Add your photo',
      subtitle: 'Help walkers recognize you and your furry friend!',
      showContinueButton: false,
      child: Column(
        children: [
          // Profile Image Preview
          GestureDetector(
            onTap: () => _showImageSourceDialog(),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
                image: _profileImage != null
                    ? DecorationImage(
                        image: MemoryImage(_profileImage!['bytes'] as Uint8List),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          size: 60,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 32),

          // Camera and Gallery Buttons
          Row(
            children: [
              Expanded(
                child: _buildImageSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImageFromCamera(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImageSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImageFromGallery(),
                ),
              ),
            ],
          ),

          if (_profileImage != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _profileImage = null;
                  _profileImageUrl = null;
                });
              },
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              label: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Continue Button (can skip this step)
          _buildContinueButton(_nextStep),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFEC4899)),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFEC4899)),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _imageUploadService.pickImageFromCamera();
      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _imageUploadService.pickImageFromGallery();
      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildSummaryStep() {
    return _buildStepContainer(
      title: 'Look good?',
      subtitle: 'Review your information before we create your profile.',
      showContinueButton: false,
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 32),
          _buildContinueButton(_isLoading ? null : _completeOnboarding),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName.isNotEmpty ? ownerName : 'Not provided',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationCity.isNotEmpty || locationState.isNotEmpty
                          ? '${locationSuburb.isNotEmpty ? '$locationSuburb, ' : ''}$locationCity${locationState.isNotEmpty ? ', $locationState' : ''}'
                          : 'Location not set',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _buildSummaryRow(
            icon: Icons.pets,
            label: 'Dog Name',
            value: dogName.isNotEmpty ? dogName : 'Not provided',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.category,
            label: 'Breed',
            value: dogBreed.isNotEmpty ? dogBreed : 'Not provided',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.cake,
            label: 'Age',
            value: dogAge != null ? '$dogAge years old' : 'Not provided',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEC4899).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFEC4899),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required String value,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[400],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
