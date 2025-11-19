import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Background Image with Overlay
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.15 : 0.08,
              child: Image.asset(
                'assets/images/walker2.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Hero Section
                  _buildHeroSection(isDark),
                  const SizedBox(height: 24),

                  // Why WalkMyPet
                  _buildSection(
                    isDark: isDark,
                    title: 'Why WalkMyPet?',
                    icon: Icons.pets_rounded,
                    iconColor: const Color(0xFF6366F1),
                    content:
                        'Dogs are wonderful family members, but busy schedules can make it challenging to give them the exercise and attention they deserve. WalkMyPet connects caring pet owners with trusted local dog walkers across Australia, making it simple to ensure your furry friend gets the walks they need, when they need them.\n\nWhether you\'re working long hours, traveling, or just need an extra hand, we\'ve made it easy for you to find reliable walkers in your neighborhood and give your best friend the exercise and care they deserve.',
                  ),
                  const SizedBox(height: 20),

                  // For Pet Owners
                  _buildSection(
                    isDark: isDark,
                    title: 'For Pet Owners',
                    icon: Icons.home_rounded,
                    iconColor: const Color(0xFFEC4899),
                    content: 'Finding the perfect walker is simple:',
                    children: [
                      _buildFeatureItem(isDark, 'Browse Local Walkers',
                          'See available walkers in your suburb with their profiles, rates, and reviews'),
                      _buildFeatureItem(isDark, 'Book with Confidence',
                          'Choose your preferred date, time, and duration'),
                      _buildFeatureItem(isDark, 'Secure Payment',
                          'Pay safely through the app after your walk is completed'),
                      _buildFeatureItem(isDark, 'Rate & Review',
                          'Share your experience to help other pet owners'),
                      const SizedBox(height: 12),
                      Text(
                        'Your dog\'s safety and happiness are our priority. All walkers display their rates, availability, and reviews so you can make the best choice for your pet.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // For Dog Walkers
                  _buildSection(
                    isDark: isDark,
                    title: 'For Dog Walkers',
                    icon: Icons.directions_walk_rounded,
                    iconColor: const Color(0xFF10B981),
                    content: 'Turn your love for dogs into flexible income:',
                    children: [
                      _buildFeatureItem(isDark, 'Create Your Profile',
                          'Showcase your experience, set your rates, and define your availability'),
                      _buildFeatureItem(isDark, 'Accept Walk Requests',
                          'Choose walks that fit your schedule and location'),
                      _buildFeatureItem(isDark, 'Walk & Earn',
                          'Complete walks and receive secure payments directly to your account'),
                      _buildFeatureItem(isDark, 'Build Your Reputation',
                          'Earn positive reviews and grow your client base'),
                      const SizedBox(height: 12),
                      Text(
                        'Work on your own terms. Set your own rates, choose your hours, and work in your local area. Whether you\'re looking for extra income or a flexible side hustle, WalkMyPet makes it easy to connect with pet owners who need your services.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grooming Services
                  _buildSection(
                    isDark: isDark,
                    title: 'Grooming Services',
                    icon: Icons.cleaning_services_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    content: 'Professional grooming services for your furry friend:',
                    children: [
                      _buildFeatureItem(isDark, 'Full Grooming Package',
                          'Bath, haircut, nail trimming, and ear cleaning'),
                      _buildFeatureItem(isDark, 'Basic Bath & Brush',
                          'Keep your pet clean and fresh'),
                      _buildFeatureItem(isDark, 'Nail & Paw Care',
                          'Professional nail trimming and paw pad treatment'),
                      _buildFeatureItem(isDark, 'Experienced Groomers',
                          'Certified professionals who love what they do'),
                      const SizedBox(height: 12),
                      Text(
                        'Our groomers are trained to handle all breeds and temperaments with care and patience.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Pet Sitting Services
                  _buildSection(
                    isDark: isDark,
                    title: 'Pet Sitting Services',
                    icon: Icons.home_work_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    content: 'Reliable pet sitting when you need to be away:',
                    children: [
                      _buildFeatureItem(isDark, 'In-Home Care',
                          'Your pet stays comfortable in their familiar environment'),
                      _buildFeatureItem(isDark, 'Daily Updates',
                          'Photos and messages so you know your pet is happy'),
                      _buildFeatureItem(isDark, 'Flexible Duration',
                          'Hourly, daily, or overnight sitting available'),
                      _buildFeatureItem(isDark, 'Feeding & Medication',
                          'Following your pet\'s specific routine and needs'),
                      const SizedBox(height: 12),
                      Text(
                        'Travel with peace of mind knowing your pet is in caring, experienced hands.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Our Mission
                  _buildSection(
                    isDark: isDark,
                    title: 'Our Mission',
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFEF4444),
                    content:
                        'At WalkMyPet, we believe every dog deserves daily exercise and every owner deserves peace of mind. We\'re building a trusted community where pets get the care they need and walkers earn doing what they love.',
                  ),
                  const SizedBox(height: 20),

                  // Contact Section
                  _buildContactSection(isDark),
                  const SizedBox(height: 20),

                  // Version Info
                  _buildVersionInfo(isDark),
                  const SizedBox(height: 20),

                  // Legal Links
                  _buildLegalLinks(isDark),
                  const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha((0.3 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha((0.3 * 255).round()),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.pets,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'About WalkMyPet',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Connecting paws with caring hands across Australia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha((0.9 * 255).round()),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    List<Widget>? children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha((0.1 * 255).round())
              : Colors.black.withAlpha((0.05 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withAlpha((0.2 * 255).round()),
                      iconColor.withAlpha((0.1 * 255).round()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              letterSpacing: 0.2,
            ),
          ),
          if (children != null) ...[
            const SizedBox(height: 16),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(bool isDark, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha((0.3 * 255).round()),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
                      const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_support_rounded,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Get in Touch',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Have questions? We\'re here to help!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            isDark: isDark,
            icon: Icons.email_rounded,
            label: 'Email',
            value: 'walkmypet.pawsitive@gmail.com',
            onTap: () => _launchEmail('walkmypet.pawsitive@gmail.com'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha((0.05 * 255).round())
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Business Hours',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHoursItem(isDark, 'Monday - Friday', '9:00 AM - 6:00 PM AEST'),
                _buildHoursItem(isDark, 'Saturday', '10:00 AM - 4:00 PM AEST'),
                _buildHoursItem(isDark, 'Sunday', 'Closed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha((0.05 * 255).round())
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha((0.1 * 255).round())
                : Colors.black.withAlpha((0.05 * 255).round()),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursItem(bool isDark, String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha((0.1 * 255).round())
              : Colors.black.withAlpha((0.05 * 255).round()),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Version',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '1.0.0 (MVP)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Last Updated',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'November 2024',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLinks(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withAlpha((0.5 * 255).round())
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Legal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLegalLink(isDark, 'Terms of Service'),
              _buildDivider(isDark),
              _buildLegalLink(isDark, 'Privacy Policy'),
              _buildDivider(isDark),
              _buildLegalLink(isDark, 'Cancellation Policy'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(bool isDark, String text) {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text coming soon!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6366F1),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 16,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
    );
  }

  void _launchEmail(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email: $email'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6366F1),
        action: SnackBarAction(
          label: 'Copy',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
