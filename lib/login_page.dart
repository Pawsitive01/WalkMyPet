import 'dart:ui';
import 'package:flutter/material.dart';

// Modern Design System (shared with detail_page)
class DesignSystem {
  static const double displayLarge = 40.0;
  static const double h1 = 32.0;
  static const double h2 = 24.0;
  static const double h3 = 20.0;
  static const double body = 16.0;
  static const double caption = 14.0;
  static const double small = 12.0;

  static const double space1 = 8.0;
  static const double space2 = 16.0;
  static const double space3 = 24.0;
  static const double space4 = 32.0;
  static const double space5 = 40.0;
  static const double space6 = 48.0;

  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  static List<BoxShadow> shadowSubtle(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowCard(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowElevated(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowFloat(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.16),
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
  ];
}

class LoginPage extends StatefulWidget {
  final String personName;
  final bool isWalker;
  final String? personImage;
  final double? rating;

  const LoginPage({
    super.key,
    required this.personName,
    required this.isWalker,
    this.personImage,
    this.rating,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for content
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOut,
    );

    // Slide animation for form
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeAnimationController.forward();
        _slideAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Color get _brandColor => widget.isWalker
      ? const Color(0xFF6366F1)
      : const Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(DesignSystem.space1),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.95 * 255).round()),
            shape: BoxShape.circle,
            boxShadow: DesignSystem.shadowCard(Colors.black),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isWalker
                ? [
                    const Color(0xFF5B5FF1),
                    const Color(0xFF7B5CF6),
                    const Color(0xFFA855F7),
                  ]
                : [
                    const Color(0xFFEC4899),
                    const Color(0xFFDB2777),
                    const Color(0xFFBE185D),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignSystem.space3),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero Context Section
                      _buildHeroContext(isDark),

                      const SizedBox(height: DesignSystem.space4),

                      // Social Login Buttons
                      _buildSocialLoginSection(),

                      const SizedBox(height: DesignSystem.space3),

                      // Divider
                      _buildDivider(),

                      const SizedBox(height: DesignSystem.space3),

                      // Form Card
                      _buildFormCard(isDark),

                      const SizedBox(height: DesignSystem.space3),

                      // Guest Continue
                      _buildGuestButton(),

                      const SizedBox(height: DesignSystem.space3),

                      // Trust Indicators
                      _buildTrustIndicators(),
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

  Widget _buildHeroContext(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: Colors.white.withAlpha((0.3 * 255).round()),
          width: 1.5,
        ),
        boxShadow: DesignSystem.shadowElevated(Colors.black),
      ),
      child: Column(
        children: [
          Text(
            _isSignUp ? 'Create Account to Book' : 'Sign in to Book',
            style: const TextStyle(
              fontSize: DesignSystem.caption,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignSystem.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isWalker
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: DesignSystem.shadowCard(Colors.black),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignSystem.space2),
              // Name and Rating
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.personName,
                      style: const TextStyle(
                        fontSize: DesignSystem.h3,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.rating ?? 4.9} • ${widget.isWalker ? "Walker" : "Owner"}',
                          style: TextStyle(
                            fontSize: DesignSystem.small,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha((0.9 * 255).round()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        // Apple Sign In
        _buildSocialButton(
          icon: Icons.apple_rounded,
          label: 'Continue with Apple',
          backgroundColor: Colors.black,
          onTap: () {
            _showComingSoonSnackbar('Apple Sign In');
          },
        ),
        const SizedBox(height: DesignSystem.space2),
        // Google Sign In
        _buildSocialButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          onTap: () {
            _showComingSoonSnackbar('Google Sign In');
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(vertical: DesignSystem.space2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
            boxShadow: DesignSystem.shadowCard(Colors.black),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: textColor),
              const SizedBox(width: DesignSystem.space2),
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(0),
                  Colors.white.withAlpha((0.3 * 255).round()),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.space2),
          child: Text(
            'or sign in with email',
            style: TextStyle(
              fontSize: DesignSystem.small,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha((0.85 * 255).round()),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha((0.3 * 255).round()),
                  Colors.white.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(DesignSystem.space4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1E293B).withAlpha((0.95 * 255).round()),
                      const Color(0xFF0F172A).withAlpha((0.90 * 255).round()),
                    ]
                  : [
                      Colors.white.withAlpha((0.95 * 255).round()),
                      Colors.white.withAlpha((0.90 * 255).round()),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            border: Border.all(
              color: Colors.white.withAlpha((0.2 * 255).round()),
              width: 1.5,
            ),
            boxShadow: DesignSystem.shadowFloat(Colors.black),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back',
                  style: TextStyle(
                    fontSize: DesignSystem.h2,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignSystem.space1),
                Text(
                  _isSignUp
                      ? 'Sign up to complete your booking'
                      : 'Enter your credentials to continue',
                  style: TextStyle(
                    fontSize: DesignSystem.caption,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: DesignSystem.space4),

                // Email Field
                _buildPremiumTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: DesignSystem.space3),

                // Password Field
                _buildPremiumTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  isDark: isDark,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Forgot Password
                if (!_isSignUp) ...[
                  const SizedBox(height: DesignSystem.space2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showComingSoonSnackbar('Password Reset');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: DesignSystem.caption,
                          fontWeight: FontWeight.w700,
                          color: _brandColor,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: DesignSystem.space4),

                // Submit Button
                _buildPremiumButton(
                  label: _isLoading
                      ? 'Loading...'
                      : (_isSignUp ? 'Create Account' : 'Sign In'),
                  onPressed: _isLoading ? null : _handleSubmit,
                  isDark: isDark,
                ),

                const SizedBox(height: DesignSystem.space3),

                // Toggle Sign Up/Sign In
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: DesignSystem.caption,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      children: [
                        TextSpan(
                          text: _isSignUp
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                        ),
                        TextSpan(
                          text: _isSignUp ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _brandColor,
                          ),
                        ),
                      ],
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

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: DesignSystem.body,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: DesignSystem.caption,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: _brandColor,
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withAlpha((0.6 * 255).round())
            : const Color(0xFFF8FAFC).withAlpha((0.8 * 255).round()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withAlpha((0.1 * 255).round())
                : Colors.black.withAlpha((0.1 * 255).round()),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withAlpha((0.1 * 255).round())
                : Colors.black.withAlpha((0.1 * 255).round()),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          borderSide: BorderSide(
            color: _brandColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.space2,
          vertical: DesignSystem.space2,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPremiumButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignSystem.space2 + 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isWalker
                  ? [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ]
                  : [
                      const Color(0xFFEC4899),
                      const Color(0xFFDB2777),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: _brandColor.withAlpha((0.4 * 255).round()),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: DesignSystem.space2),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return TextButton.icon(
      onPressed: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proceeding as guest...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF10B981),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      icon: Icon(
        Icons.person_outline_rounded,
        color: Colors.white.withAlpha((0.95 * 255).round()),
        size: 20,
      ),
      label: Text(
        'Continue as Guest',
        style: TextStyle(
          fontSize: DesignSystem.caption,
          fontWeight: FontWeight.w700,
          color: Colors.white.withAlpha((0.95 * 255).round()),
          letterSpacing: 0.3,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.space3,
          vertical: DesignSystem.space2,
        ),
        backgroundColor: Colors.white.withAlpha((0.15 * 255).round()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          side: BorderSide(
            color: Colors.white.withAlpha((0.3 * 255).round()),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_rounded,
          size: 14,
          color: Colors.white.withAlpha((0.7 * 255).round()),
        ),
        const SizedBox(width: DesignSystem.space1),
        Text(
          'Secure',
          style: TextStyle(
            fontSize: DesignSystem.small,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha((0.7 * 255).round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.space2),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.5 * 255).round()),
              shape: BoxShape.circle,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            _showComingSoonSnackbar('Terms & Conditions');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Terms',
            style: TextStyle(
              fontSize: DesignSystem.small,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha((0.7 * 255).round()),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.space2),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.5 * 255).round()),
              shape: BoxShape.circle,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            _showComingSoonSnackbar('Privacy Policy');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Privacy',
            style: TextStyle(
              fontSize: DesignSystem.small,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha((0.7 * 255).round()),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network request
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignUp
                  ? '✓ Account created! Proceeding to booking...'
                  : '✓ Logged in! Proceeding to booking...',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _brandColor,
      ),
    );
  }
}
