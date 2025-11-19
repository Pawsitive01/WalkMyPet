import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/image_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/profile/redesigned_walker_profile_page.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;

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

  final List<Map<String, dynamic>> availableServices = [
    {
      'name': 'Walking',
      'icon': Icons.directions_walk_rounded,
      'description': 'Daily dog walks',
    },
    {
      'name': 'Sitting',
      'icon': Icons.home_work_rounded,
      'description': 'Pet sitting at home',
    },
    {
      'name': 'Grooming',
      'icon': Icons.cleaning_services_rounded,
      'description': 'Basic grooming services',
    },
    {
      'name': 'Training',
      'icon': Icons.school_rounded,
      'description': 'Basic obedience training',
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
          walkerName = progress['walkerName'] ?? '';
          location = progress['location'] ?? '';
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
      print('Error loading progress: $e');
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

      // Calculate average hourly rate
      final rates = servicePrices.values.toList();
      final avgRate = rates.isNotEmpty
          ? rates.reduce((a, b) => a + b) / rates.length
          : 25.0;

      await _userService.updateUser(user.uid, {
        'displayName': walkerName,
        'location': location,
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

      // Refresh AuthProvider to update the state
      if (mounted) {
        await Provider.of<app_auth.AuthProvider>(context, listen: false).refreshUserProfile();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Welcome to WalkMyPet, $walkerName!',
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
            MaterialPageRoute(builder: (context) => const RedesignedWalkerProfilePage()),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(),
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
                    _buildWalkerNameStep(),
                    _buildLocationStep(),
                    _buildExperienceStep(),
                    _buildPoliceClearanceStep(),
                    _buildServicesStep(),
                    _buildPricingStep(),
                    _buildAvailabilityStep(),
                    _buildBioStep(),
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
                  _currentStep == _totalSteps - 1
                      ? 'Complete Setup'
                      : 'Continue',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF6366F1),
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
      title: 'Become a\nPet Walker! 🚶',
      subtitle:
          'Join our community of trusted pet walkers and start earning while doing what you love.',
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
                Icons.directions_walk_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Professional Profile Setup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll help you create a compelling profile that attracts pet owners',
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

  Widget _buildWalkerNameStep() {
    return _buildStepContainer(
      title: 'What\'s your name?',
      subtitle: 'Pet owners want to know who they\'re trusting with their pets.',
      child: _buildModernTextField(
        value: walkerName,
        hint: 'Enter your full name',
        icon: Icons.person_rounded,
        onChanged: (value) {
          setState(() {
            walkerName = value;
          });
        },
      ),
      onContinue: walkerName.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildLocationStep() {
    return _buildStepContainer(
      title: 'Where do you operate?',
      subtitle: 'This helps us connect you with nearby pet owners.',
      child: _buildModernTextField(
        value: location,
        hint: 'e.g., Adelaide, Australia',
        icon: Icons.location_on_rounded,
        onChanged: (value) {
          setState(() {
            location = value;
          });
        },
      ),
      onContinue: location.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildExperienceStep() {
    return _buildStepContainer(
      title: 'Your experience?',
      subtitle: 'How many years have you been working with dogs?',
      child: Column(
        children: [
          _buildModernTextField(
            value: yearsOfExperience > 0 ? yearsOfExperience.toString() : '',
            hint: 'Years of experience',
            icon: Icons.star_rounded,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                yearsOfExperience = int.tryParse(value) ?? 0;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildExperienceQuickSelect(),
        ],
      ),
      onContinue: yearsOfExperience > 0 ? _nextStep : null,
    );
  }

  Widget _buildExperienceQuickSelect() {
    final experiences = [
      {'value': 1, 'label': '< 1 year'},
      {'value': 2, 'label': '1-2 years'},
      {'value': 3, 'label': '3-5 years'},
      {'value': 5, 'label': '5+ years'},
      {'value': 10, 'label': '10+ years'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: experiences.map((exp) {
        final isSelected = yearsOfExperience == exp['value'];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                yearsOfExperience = exp['value'] as int;
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
                exp['label'] as String,
                style: TextStyle(
                  fontSize: 15,
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

  Widget _buildPoliceClearanceStep() {
    return _buildStepContainer(
      title: 'Police clearance?',
      subtitle: 'Do you have a valid police clearance certificate?',
      child: Column(
        children: [
          _buildSelectionCard(
            icon: Icons.shield_rounded,
            title: 'Yes, I have clearance',
            subtitle: 'Verified background check',
            isSelected: hasPoliceClearance == true,
            onTap: () {
              setState(() {
                hasPoliceClearance = true;
              });
            },
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            icon: Icons.info_outline_rounded,
            title: 'Not yet',
            subtitle: 'I can get one later',
            isSelected: hasPoliceClearance == false && _currentStep == 4,
            onTap: () {
              setState(() {
                hasPoliceClearance = false;
              });
            },
            color: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    return _buildStepContainer(
      title: 'Services you offer',
      subtitle: 'Select all services you can provide (choose at least one)',
      child: Column(
        children: availableServices.map((service) {
          final isSelected = selectedServices.contains(service['name']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          service['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'] as String,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              service['description'] as String,
                              style: TextStyle(
                                fontSize: 13,
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
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 28,
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

  Widget _buildPricingStep() {
    return _buildStepContainer(
      title: 'Set your rates',
      subtitle: 'What are your hourly rates for each service?',
      showContinueButton: false,
      child: Column(
        children: [
          ...selectedServices.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPriceInput(service),
            );
          }),
          const SizedBox(height: 24),
          _buildContinueButton(_nextStep),
        ],
      ),
    );
  }

  Widget _buildPriceInput(String service) {
    final iconMap = {
      'Walking': Icons.directions_walk_rounded,
      'Sitting': Icons.home_work_rounded,
      'Grooming': Icons.cleaning_services_rounded,
      'Training': Icons.school_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconMap[service] ?? Icons.star_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '\$',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(
                text: servicePrices[service]?.toString() ?? '25',
              )..selection = TextSelection.collapsed(
                  offset: servicePrices[service]?.toString().length ?? 2),
              onChanged: (value) {
                setState(() {
                  servicePrices[service] = int.tryParse(value) ?? 25;
                });
              },
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '/hr',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStep() {
    return _buildStepContainer(
      title: 'Your availability',
      subtitle: 'Which days are you typically available?',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: daysOfWeek.map((day) {
          final isSelected = availability.contains(day);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? const Color(0xFF6366F1) : Colors.white,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
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

  Widget _buildBioStep() {
    return _buildStepContainer(
      title: 'Tell us about yourself',
      subtitle: 'Share your experience and why you love working with dogs.',
      child: Container(
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
          controller: TextEditingController(text: bio)
            ..selection = TextSelection.collapsed(offset: bio.length),
          onChanged: (value) {
            setState(() {
              bio = value;
            });
          },
          maxLines: 6,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText:
                'e.g., I\'ve been a dog lover my entire life and have 5 years of professional experience...',
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ),
      onContinue: bio.isNotEmpty ? _nextStep : null,
    );
  }

  Widget _buildProfileImageStep() {
    return _buildStepContainer(
      title: 'Add your photo',
      subtitle: 'Show pet owners the friendly face behind the service!',
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
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1)),
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
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1)),
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
      title: 'Review your profile',
      subtitle: 'Make sure everything looks perfect before we publish!',
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
    final rates = servicePrices.values.toList();
    final avgRate = rates.isNotEmpty
        ? rates.reduce((a, b) => a + b) / rates.length
        : 25.0;

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
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
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
                      walkerName.isNotEmpty ? walkerName : 'Not provided',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.isNotEmpty ? location : 'Location not set',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFBBF24),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${avgRate.round()}/hr average',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const Spacer(),
                if (hasPoliceClearance)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Police Check',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _buildSummaryRow(
            icon: Icons.work_rounded,
            label: 'Experience',
            value: yearsOfExperience > 0
                ? '$yearsOfExperience years'
                : 'Not provided',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.category_rounded,
            label: 'Services',
            value: selectedServices.isNotEmpty
                ? selectedServices.join(', ')
                : 'None selected',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Available',
            value: availability.isNotEmpty
                ? '${availability.length} days/week'
                : 'Not set',
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'About',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
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
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
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
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
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
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
