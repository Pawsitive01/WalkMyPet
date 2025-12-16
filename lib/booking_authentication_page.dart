import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:walkmypet/services/auth_service.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/onboarding/owner_onboarding_page.dart';
import 'package:walkmypet/onboarding/walker_onboarding_page.dart';
import 'package:walkmypet/profile/redesigned_walker_profile_page.dart';
import 'package:walkmypet/profile/redesigned_owner_profile_page.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;

class BookingAuthenticationPage extends StatefulWidget {
  final String personName;
  final bool isWalker;

  const BookingAuthenticationPage({
    super.key,
    required this.personName,
    required this.isWalker,
  });

  @override
  State<BookingAuthenticationPage> createState() => _BookingAuthenticationPageState();
}

class _BookingAuthenticationPageState extends State<BookingAuthenticationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final horizontalPadding = isSmallScreen ? 20.0 : 32.0;
    final cardMaxWidth = isSmallScreen ? double.infinity : 440.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isWalker
                ? [
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                    const Color(0xFF7C3AED),
                  ]
                : [
                    const Color(0xFFEC4899),
                    const Color(0xFFF472B6),
                    const Color(0xFFDB2777),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Brand Icon
                      _buildBrandIcon(),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Title & Subtitle
                      _buildHeader(),

                      SizedBox(height: isSmallScreen ? 32 : 40),

                      // Form Card
                      Container(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: _buildFormCard(isDark, isSmallScreen),
                      ),

                      const SizedBox(height: 32),

                      // Divider with OR
                      _buildDivider(isDark),

                      const SizedBox(height: 24),

                      // Google Sign In Button
                      Container(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: _buildGoogleSignInButton(isDark),
                      ),

                      const SizedBox(height: 16),

                      // Register as Pet Walker (only show for owner flow)
                      if (!widget.isWalker) ...[
                        Container(
                          constraints: BoxConstraints(maxWidth: cardMaxWidth),
                          child: _buildRegisterAsWalkerButton(),
                        ),
                      ],

                      // Register as Pet Owner (only show for walker flow)
                      if (widget.isWalker) ...[
                        Container(
                          constraints: BoxConstraints(maxWidth: cardMaxWidth),
                          child: _buildRegisterAsOwnerButton(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              widget.isWalker ? Icons.directions_walk_rounded : Icons.pets_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _isSignUp
              ? 'Join WalkMyPet as ${widget.isWalker ? 'a Pet Walker' : 'a Pet Owner'}'
              : 'Sign in to continue your journey',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.1,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'Email address',
              hint: 'name@example.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Password Field
            _buildPasswordField(isDark),

            const SizedBox(height: 12),

            // Forgot Password (only show on sign in)
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isWalker
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFEC4899),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),

            SizedBox(height: _isSignUp ? 24 : 32),

            // Submit Button
            _buildSubmitButton(isDark),

            const SizedBox(height: 20),

            // Toggle Sign Up/Sign In
            _buildToggleAuthMode(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          size: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.isWalker
                ? const Color(0xFF6366F1)
                : const Color(0xFFEC4899),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          Icons.lock_rounded,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.isWalker
                ? const Color(0xFF6366F1)
                : const Color(0xFFEC4899),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleSubmit,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isWalker
                  ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                  : [const Color(0xFFEC4899), const Color(0xFFF472B6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.isWalker
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFEC4899)).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Create Account' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildToggleAuthMode(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp
              ? 'Already have an account?'
              : "Don't have an account?",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = !_isSignUp;
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.isWalker
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFEC4899),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Text(
              'OR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/google_logo.png',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.g_mobiledata, size: 20),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterAsWalkerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingAuthenticationPage(
                personName: 'Pet Walker',
                isWalker: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_walk_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Register as a Pet Walker',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterAsOwnerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingAuthenticationPage(
                personName: 'Pet Owner',
                isWalker: false,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Register as a Pet Owner',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isSignUp) {

          // Sign up with email and password
          final userCredential = await _authService.signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (userCredential != null) {

            // Create user profile in Firestore
            await _userService.createUser(
              email: _emailController.text.trim(),
              userType: widget.isWalker ? UserType.petWalker : UserType.petOwner,
              displayName: widget.personName,
            );

          }
        } else {

          // Sign in with email and password
          final userCredential = await _authService.signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (userCredential != null) {

            // Verify user type matches the flow they're trying to access
            final userDoc = await _userService.getUser(userCredential.user!.uid);
            if (userDoc != null) {
              final userData = userDoc.toFirestore();
              final userType = userData['userType'] as String?;

              // Check if user type matches
              final expectedType = widget.isWalker ? 'petWalker' : 'petOwner';
              if (userType != expectedType) {
                // Wrong user type - sign them out and show error
                await _authService.signOut();
                throw Exception(
                  widget.isWalker
                    ? 'This account is registered as a Pet Owner. Please use the Pet Owner login.'
                    : 'This account is registered as a Pet Walker. Please use the Pet Walker login.'
                );
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _isSignUp
                        ? 'Account created successfully!'
                        : 'Welcome back!',
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
            // Navigate to appropriate onboarding for new sign-ups
            if (_isSignUp) {
              if (widget.isWalker) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalkerOnboardingPage(),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerOnboardingPage(),
                  ),
                );
              }
            } else {
              // For sign-in, check if user has completed onboarding
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userDoc = await _userService.getUser(user.uid);
                final needsOnboarding = userDoc?.toFirestore()['onboardingComplete'] != true;

                if (needsOnboarding) {
                  // User needs onboarding - navigate to appropriate onboarding page
                  if (widget.isWalker) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalkerOnboardingPage(),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OwnerOnboardingPage(),
                      ),
                    );
                  }
                } else {
                  // User has completed onboarding - wait for AuthProvider to fully load
                  debugPrint('⏳ Waiting for AuthProvider to update...');

                  // Wait up to 5 seconds for auth state to propagate
                  int attempts = 0;
                  while (attempts < 50) {
                    await Future.delayed(const Duration(milliseconds: 100));

                    // Check if we can access AuthProvider through context
                    try {
                      final authProvider = Provider.of<app_auth.AuthProvider?>(context, listen: false);
                      if (authProvider != null &&
                          authProvider.isAuthenticated &&
                          !authProvider.isLoading &&
                          authProvider.userProfile != null) {
                        debugPrint('✅ AuthProvider ready - authenticated');
                        break;
                      }
                    } catch (e) {
                      debugPrint('⚠️ AuthProvider not available yet: $e');
                    }

                    attempts++;
                  }

                  debugPrint('🚀 Navigating directly to profile after $attempts attempts');

                  if (mounted) {
                    // Navigate directly to profile page to avoid splash screen
                    if (widget.isWalker) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RedesignedWalkerProfilePage(),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RedesignedOwnerProfilePage(),
                        ),
                      );
                    }
                  }
                }
              } else {
                // Fallback: navigate to home page
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            }
          }
        }
      } catch (e, stackTrace) {
        // Print detailed error to console for debugging
        print('🚨 Authentication Error:');
        print('Error Type: ${e.runtimeType}');
        print('Error Message: $e');
        print('Stack Trace: $stackTrace');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Get a clean error message
          String errorMessage = e.toString();

          // Remove common prefixes
          errorMessage = errorMessage
              .replaceAll('Exception: ', '')
              .replaceAll('FirebaseAuthException: ', '')
              .replaceAll('[firebase_auth/operation-not-allowed] ', '');

          // If error message is empty or just "error", provide helpful default
          if (errorMessage.isEmpty || errorMessage.toLowerCase() == 'error') {
            errorMessage = 'Authentication failed. Please check:\n'
                '• Email/Password auth is enabled in Firebase Console\n'
                '• Your internet connection\n'
                '• Email and password are valid';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage,
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
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });


      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {

        // Check if user already exists with a different type
        final existingUser = await _userService.getUser(userCredential.user!.uid);
        if (existingUser != null) {
          final userData = existingUser.toFirestore();
          final existingType = userData['userType'] as String?;
          final expectedType = widget.isWalker ? 'petWalker' : 'petOwner';

          if (existingType != null && existingType != expectedType) {
            // User exists with wrong type - sign out and show error
            await _authService.signOut();
            throw Exception(
              widget.isWalker
                ? 'This account is registered as a Pet Owner. Please use the Pet Owner login.'
                : 'This account is registered as a Pet Walker. Please use the Pet Walker login.'
            );
          }
        }

        // Create or update user profile in Firestore
        await _userService.createUser(
          email: userCredential.user?.email ?? '',
          userType: widget.isWalker ? UserType.petWalker : UserType.petOwner,
          displayName: userCredential.user?.displayName ?? widget.personName,
          photoURL: userCredential.user?.photoURL,
        );


        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Welcome ${userCredential.user?.displayName?.split(' ')[0] ?? 'back'}!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
            // Check if user needs onboarding
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final userDoc = await _userService.getUser(user.uid);
              final needsOnboarding = userDoc?.toFirestore()['onboardingComplete'] != true;

              if (needsOnboarding) {
                if (widget.isWalker) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalkerOnboardingPage(),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OwnerOnboardingPage(),
                    ),
                  );
                }
              } else {
                // User has completed onboarding - wait for AuthProvider to fully load
                debugPrint('⏳ (Google) Waiting for AuthProvider to update...');

                // Wait up to 5 seconds for auth state to propagate
                int attempts = 0;
                while (attempts < 50) {
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Check if we can access AuthProvider through context
                  try {
                    final authProvider = Provider.of<app_auth.AuthProvider?>(context, listen: false);
                    if (authProvider != null &&
                        authProvider.isAuthenticated &&
                        !authProvider.isLoading &&
                        authProvider.userProfile != null) {
                      debugPrint('✅ (Google) AuthProvider ready - authenticated');
                      break;
                    }
                  } catch (e) {
                    debugPrint('⚠️ (Google) AuthProvider not available yet: $e');
                  }

                  attempts++;
                }

                debugPrint('🚀 (Google) Navigating directly to profile after $attempts attempts');

                if (mounted) {
                  // Navigate directly to profile page to avoid splash screen
                  if (widget.isWalker) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RedesignedWalkerProfilePage(),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RedesignedOwnerProfilePage(),
                      ),
                    );
                  }
                }
              }
            } else {
              // Fallback: wait for auth state then navigate to profile
              debugPrint('⏳ (Google Fallback) Waiting for AuthProvider...');

              int attempts = 0;
              while (attempts < 50) {
                await Future.delayed(const Duration(milliseconds: 100));

                try {
                  final authProvider = Provider.of<app_auth.AuthProvider?>(context, listen: false);
                  if (authProvider != null &&
                      authProvider.isAuthenticated &&
                      !authProvider.isLoading) {
                    debugPrint('✅ (Google Fallback) AuthProvider ready');
                    break;
                  }
                } catch (e) {
                  debugPrint('⚠️ (Google Fallback) AuthProvider not available: $e');
                }

                attempts++;
              }

              if (mounted) {
                // Navigate directly to profile page
                if (widget.isWalker) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RedesignedWalkerProfilePage(),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RedesignedOwnerProfilePage(),
                    ),
                  );
                }
              }
            }
          }
        }
      } else {
      }
    } catch (e, stackTrace) {
      // Print detailed error to console for debugging
      print('🚨 Google Sign-In Error:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: $stackTrace');

      if (mounted) {
        // More user-friendly error messages
        String errorMessage = 'Failed to sign in with Google';

        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().contains('cancelled')) {
          errorMessage = 'Sign-in cancelled';
        } else if (e.toString().contains('ERROR_INVALID_CREDENTIAL')) {
          errorMessage = 'Invalid credentials. Please try again.';
        } else if (e.toString().contains('operation-not-allowed')) {
          errorMessage = 'Google Sign-In is not enabled in Firebase Console';
        } else {
          // Show the actual error for debugging
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
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
            duration: const Duration(seconds: 4),
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

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please enter your email address first',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF6366F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Password reset email sent! Check your inbox.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
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
                    e.toString().replaceAll('Exception: ', ''),
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
