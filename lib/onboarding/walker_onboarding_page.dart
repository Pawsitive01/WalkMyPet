import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/image_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/profile/redesigned_walker_profile_page.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;
import 'package:walkmypet/widgets/location_picker.dart';

class WalkerOnboardingPage extends StatefulWidget {
  const WalkerOnboardingPage({super.key});

  @override
  State<WalkerOnboardingPage> createState() => _WalkerOnboardingPageState();
}

class _WalkerOnboardingPageState extends State<WalkerOnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final UserService _userService = UserService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  int _currentStep = 0;
  final int _totalSteps = 11;

  // Form data
  String walkerName = '';
  String location = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  String bio = '';
  int yearsOfExperience = 0;
  bool hasPoliceClearance = false;
  List<String> selectedServices = [];
  Map<String, int> servicePrices = {};
  List<String> availability = [];
  String phoneNumber = '';
  Map<String, dynamic>? _profileImage;
  String? _profileImageUrl;

  bool _isLoading = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> availableServices = [
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

  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _loadSavedProgress();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
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
          walkerName = progress['walkerName'] ?? '';
          location = progress['location'] ?? '';
          _selectedLatitude = progress['selectedLatitude']?.toDouble();
          _selectedLongitude = progress['selectedLongitude']?.toDouble();
          bio = progress['bio'] ?? '';
          yearsOfExperience = progress['yearsOfExperience'] ?? 0;
          hasPoliceClearance = progress['hasPoliceClearance'] ?? false;
          selectedServices = List<String>.from(progress['selectedServices'] ?? []);
          servicePrices = Map<String, int>.from(progress['servicePrices'] ?? {});
          availability = List<String>.from(progress['availability'] ?? []);
          phoneNumber = progress['phoneNumber'] ?? '';
        });
        _updateProgress();
      }
    } catch (e) {
        // Error handled silently
    }
  }

  Future<void> _saveProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _userService.updateUser(user.uid, {
        'onboardingProgress': {
          'currentStep': _currentStep,
          'walkerName': walkerName,
          'location': location,
          'selectedLatitude': _selectedLatitude,
          'selectedLongitude': _selectedLongitude,
          'bio': bio,
          'yearsOfExperience': yearsOfExperience,
          'hasPoliceClearance': hasPoliceClearance,
          'selectedServices': selectedServices,
          'servicePrices': servicePrices,
          'availability': availability,
          'phoneNumber': phoneNumber,
        },
      });
    } catch (e) {
        // Error handled silently
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
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
      HapticFeedback.lightImpact();
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
      if (_profileImage != null) {
        try {
          _profileImageUrl = await _imageUploadService.uploadProfileImage(_profileImage!);
        } catch (e) {
        // Error handled silently
        }
      }

      final rates = servicePrices.values.toList();
      final avgRate = rates.isNotEmpty
          ? rates.reduce((a, b) => a + b) / rates.length
          : 25.0;

      await _userService.updateUser(user.uid, {
        'displayName': walkerName,
        'location': location,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'bio': bio,
        'yearsOfExperience': yearsOfExperience,
        'hasPoliceClearance': hasPoliceClearance,
        'services': selectedServices,
        'servicePrices': servicePrices,
        'availability': availability,
        'phoneNumber': phoneNumber,
        'hourlyRate': avgRate.round(),
        'photoURL': _profileImageUrl,
        'onboardingComplete': true,
        'rating': 5.0,
        'reviews': 0,
        'completedWalks': 0,
      });

      if (mounted) {
        try {
          await Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
        } catch (e) {
          // Error handled silently
        }
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome to WalkMyPet, $walkerName!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RedesignedWalkerProfilePage()),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to save profile: ${e.toString().replaceAll('Exception: ', '')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 6),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final safePadding = MediaQuery.of(context).padding;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: _currentStep > 0
            ? Container(
                margin: EdgeInsets.only(left: 12, top: safePadding.top > 20 ? 4 : 8, bottom: 8),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  elevation: 0,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  child: InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF0F172A),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        actions: [
          if (_currentStep < _totalSteps - 1)
            Container(
              margin: EdgeInsets.only(right: 12, top: safePadding.top > 20 ? 4 : 8, bottom: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _nextStep,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildProgressBar(isSmallScreen),
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
                    _buildWelcomeStep(isSmallScreen),
                    _buildWalkerNameStep(isSmallScreen),
                    _buildLocationStep(isSmallScreen),
                    _buildExperienceStep(isSmallScreen),
                    _buildPoliceClearanceStep(isSmallScreen),
                    _buildServicesStep(isSmallScreen),
                    _buildPricingStep(isSmallScreen),
                    _buildAvailabilityStep(isSmallScreen),
                    _buildBioStep(isSmallScreen),
                    _buildProfileImageStep(isSmallScreen),
                    _buildSummaryStep(isSmallScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isSmallScreen ? 12 : 16,
      ),
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
                  letterSpacing: 0.3,
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
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
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
    required bool isSmallScreen,
    VoidCallback? onContinue,
    bool showContinueButton = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
        
        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: isSmallScreen ? 12 : 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + (isSmallScreen ? 16 : 24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 26 : 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  child,
                  if (showContinueButton) ...[
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildContinueButton(onContinue, isSmallScreen),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton(VoidCallback? onPressed, bool isSmallScreen) {
    final isEnabled = onPressed != null || _currentStep == _totalSteps - 1;
    
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? (onPressed ?? _nextStep) : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isEnabled ? null : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Continue',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 17,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Become a\nPet Walker! 🚶',
      subtitle: 'Join our community of trusted pet walkers and start earning while doing what you love.',
      isSmallScreen: isSmallScreen,
      onContinue: _nextStep, // Allow continuing from welcome page
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_walk_rounded,
                size: isSmallScreen ? 48 : 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            Text(
              'Professional Profile Setup',
              style: TextStyle(
                fontSize: isSmallScreen ? 17 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'We\'ll help you create a compelling profile that attracts pet owners',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkerNameStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'What\'s your name?',
      subtitle: 'Pet owners want to know who they\'re trusting with their pets.',
      isSmallScreen: isSmallScreen,
      child: _buildModernTextField(
        value: walkerName,
        hint: 'Enter your full name',
        icon: Icons.person_rounded,
        isSmallScreen: isSmallScreen,
        onChanged: (value) {
          setState(() {
            walkerName = value;
          });
        },
      ),
      onContinue: walkerName.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildLocationStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Where do you operate?',
      subtitle: 'This helps us connect you with nearby pet owners.',
      isSmallScreen: isSmallScreen,
      child: Column(
        children: [
          // Map Picker Button
          InkWell(
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
                  location = result.address;
                });
                // Save progress immediately after location is selected
                _saveProgress();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: location.isNotEmpty
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: location.isNotEmpty
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      location.isNotEmpty
                          ? Icons.map_rounded
                          : Icons.add_location_alt_rounded,
                      color: Colors.white,
                      size: isSmallScreen ? 22 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.isNotEmpty
                              ? 'Location Selected'
                              : 'Select your location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 15 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            location,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          SizedBox(height: 4),
                          Text(
                            'Tap to open map',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      onContinue: location.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildExperienceStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Your experience?',
      subtitle: 'How many years have you been working with dogs?',
      isSmallScreen: isSmallScreen,
      child: Column(
        children: [
          _buildModernTextField(
            value: yearsOfExperience > 0 ? yearsOfExperience.toString() : '',
            hint: 'Years of experience',
            icon: Icons.star_rounded,
            isSmallScreen: isSmallScreen,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                yearsOfExperience = int.tryParse(value) ?? 0;
              });
            },
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildExperienceQuickSelect(isSmallScreen),
        ],
      ),
      onContinue: yearsOfExperience > 0 ? _nextStep : null,
    );
  }

  Widget _buildExperienceQuickSelect(bool isSmallScreen) {
    final experiences = [
      {'value': 1, 'label': '< 1 year'},
      {'value': 2, 'label': '1-2 years'},
      {'value': 3, 'label': '3-5 years'},
      {'value': 5, 'label': '5+ years'},
      {'value': 10, 'label': '10+ years'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: experiences.map((exp) {
        final isSelected = yearsOfExperience == exp['value'];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                yearsOfExperience = exp['value'] as int;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 14 : 18,
                vertical: isSmallScreen ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                exp['label'] as String,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPoliceClearanceStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Police clearance?',
      subtitle: 'Do you have a valid police clearance certificate?',
      isSmallScreen: isSmallScreen,
      child: Column(
        children: [
          _buildSelectionCard(
            icon: Icons.shield_rounded,
            title: 'Yes, I have clearance',
            subtitle: 'Verified background check',
            isSelected: hasPoliceClearance == true,
            isSmallScreen: isSmallScreen,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                hasPoliceClearance = true;
              });
            },
            color: const Color(0xFF10B981),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildSelectionCard(
            icon: Icons.info_outline_rounded,
            title: 'Not yet',
            subtitle: 'I can get one later',
            isSelected: hasPoliceClearance == false,
            isSmallScreen: isSmallScreen,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                hasPoliceClearance = false;
              });
            },
            color: const Color(0xFF64748B),
          ),
        ],
      ),
      onContinue: _nextStep, // Always allow continuing - both options are valid
    );
  }

  Widget _buildServicesStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Services you offer',
      subtitle: 'Select all services you can provide (choose at least one)',
      isSmallScreen: isSmallScreen,
      child: Column(
        children: availableServices.map((service) {
          final isSelected = selectedServices.contains(service['name']);
          return Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      selectedServices.remove(service['name']);
                      servicePrices.remove(service['name']);
                    } else {
                      selectedServices.add(service['name'] as String);
                      servicePrices[service['name'] as String] = 25;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: service['gradient'] as List<Color>,
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          service['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'] as String,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 17,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              service['description'] as String,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF64748B)
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          size: isSmallScreen ? 24 : 28,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      onContinue: selectedServices.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildPricingStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Set your rates',
      subtitle: 'What are your hourly rates for each service?',
      isSmallScreen: isSmallScreen,
      showContinueButton: false,
      child: Column(
        children: [
          ...selectedServices.map((service) {
            return Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
              child: _buildPriceInput(service, isSmallScreen),
            );
          }),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildContinueButton(_nextStep, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildPriceInput(String service, bool isSmallScreen) {
    final iconMap = {
      'Walking': Icons.directions_walk_rounded,
      'Sitting': Icons.home_work_rounded,
      'Grooming': Icons.cleaning_services_rounded,
      'Training': Icons.school_rounded,
    };

    final gradientMap = {
      'Walking': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      'Sitting': [Color(0xFF10B981), Color(0xFF059669)],
      'Grooming': [Color(0xFFF59E0B), Color(0xFFD97706)],
      'Training': [Color(0xFFEC4899), Color(0xFFDB2777)],
    };

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientMap[service] ?? [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconMap[service] ?? Icons.star_rounded,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Text(
              service,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Text(
            '\$',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: isSmallScreen ? 70 : 80,
            child: TextFormField(
              key: ValueKey('price_$service'),
              initialValue: servicePrices[service]?.toString() ?? '25',
              onChanged: (value) {
                if (value.isEmpty) {
                  servicePrices[service] = 0;
                } else {
                  servicePrices[service] = int.tryParse(value) ?? 0;
                }
              },
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '25',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '/hr',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Your availability',
      subtitle: 'Which days are you typically available?',
      isSmallScreen: isSmallScreen,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: daysOfWeek.map((day) {
          final isSelected = availability.contains(day);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    availability.remove(day);
                  } else {
                    availability.add(day);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSmallScreen ? day.substring(0, 3) : day,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        size: isSmallScreen ? 16 : 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      onContinue: availability.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildBioStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Tell us about yourself',
      subtitle: 'Share your experience and why you love working with dogs.',
      isSmallScreen: isSmallScreen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: TextEditingController(text: bio)
            ..selection = TextSelection.collapsed(offset: bio.length),
          onChanged: (value) {
            setState(() {
              bio = value;
            });
          },
          maxLines: isSmallScreen ? 5 : 6,
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., I\'ve been a dog lover my entire life and have 5 years of professional experience...',
            hintStyle: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          ),
        ),
      ),
      onContinue: bio.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildProfileImageStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Add your photo',
      subtitle: 'Show pet owners the friendly face behind the service!',
      isSmallScreen: isSmallScreen,
      showContinueButton: false,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImageSourceDialog(),
            child: Container(
              width: isSmallScreen ? 160 : 180,
              height: isSmallScreen ? 160 : 180,
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
                          size: isSmallScreen ? 48 : 56,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 28),
          Row(
            children: [
              Expanded(
                child: _buildImageSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  isSmallScreen: isSmallScreen,
                  onTap: () => _pickImageFromCamera(),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: _buildImageSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  isSmallScreen: isSmallScreen,
                  onTap: () => _pickImageFromGallery(),
                ),
              ),
            ],
          ),
          if (_profileImage != null) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _profileImage = null;
                  _profileImageUrl = null;
                });
              },
              icon: Icon(Icons.delete_outline_rounded, color: Colors.white, size: isSmallScreen ? 18 : 20),
              label: Text(
                'Remove Photo',
                style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 14 : 15),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
            ),
          ],
          SizedBox(height: isSmallScreen ? 24 : 32),
          _buildContinueButton(_nextStep, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: isSmallScreen ? 32 : 36, color: Colors.white),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
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
              const SizedBox(height: 12),
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
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1), size: 22),
                ),
                title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Take a new photo', style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1), size: 22),
                ),
                title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose from gallery', style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 12),
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
        // Error handled silently
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
        // Error handled silently
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildSummaryStep(bool isSmallScreen) {
    return _buildStepContainer(
      title: 'Review your profile',
      subtitle: 'Make sure everything looks perfect before we publish!',
      isSmallScreen: isSmallScreen,
      showContinueButton: false,
      child: Column(
        children: [
          _buildSummaryCard(isSmallScreen),
          SizedBox(height: isSmallScreen ? 24 : 28),
          _buildContinueButton(_isLoading ? null : _completeOnboarding, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isSmallScreen) {
    final rates = servicePrices.values.toList();
    final avgRate = rates.isNotEmpty
        ? rates.reduce((a, b) => a + b) / rates.length
        : 25.0;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 26 : 30,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walkerName.isNotEmpty ? walkerName : 'Not provided',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.isNotEmpty ? location : 'Location not set',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: const Color(0xFFFBBF24),
                  size: isSmallScreen ? 20 : 22,
                ),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Text(
                  '${avgRate.round()}/hr average',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const Spacer(),
                if (hasPoliceClearance)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: const Color(0xFF10B981),
                          size: isSmallScreen ? 14 : 16,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Divider(height: 1, color: Colors.grey[200]),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildSummaryRow(
            icon: Icons.work_rounded,
            label: 'Experience',
            value: yearsOfExperience > 0 ? '$yearsOfExperience years' : 'Not provided',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 12 : 14),
          _buildSummaryRow(
            icon: Icons.category_rounded,
            label: 'Services',
            value: selectedServices.isNotEmpty ? selectedServices.join(', ') : 'None selected',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 12 : 14),
          _buildSummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Available',
            value: availability.isNotEmpty ? '${availability.length} days/week' : 'Not set',
            isSmallScreen: isSmallScreen,
          ),
          if (bio.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 16 : 20),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: isSmallScreen ? 12 : 14),
            Text(
              'About',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bio,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
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
    required bool isSmallScreen,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: isSmallScreen ? 16 : 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: isSmallScreen ? 16 : 17,
            fontWeight: FontWeight.w500,
            color: Colors.grey[400],
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
            child: Icon(
              icon,
              color: Colors.white,
              size: isSmallScreen ? 20 : 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isSmallScreen,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : null,
                  gradient: isSelected
                      ? null
                      : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : Colors.white,
                  size: isSmallScreen ? 24 : 26,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF64748B)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: isSmallScreen ? 24 : 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}