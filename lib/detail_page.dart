import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/booking_authentication_page.dart';
import 'package:walkmypet/booking/booking_page.dart';
import 'package:walkmypet/design_system.dart';
import 'package:walkmypet/widgets/reviews_list.dart';

class DetailPage extends StatefulWidget {
  final Person person;
  const DetailPage({super.key, required this.person});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  late AnimationController _statsAnimationController;
  late List<Animation<double>> _statAnimations;
  String? _selectedService; // Track selected service for walkers

  @override
  void initState() {
    super.initState();

    // Set default selected service for walkers
    if (widget.person is Walker) {
      final walker = widget.person as Walker;
      _selectedService = walker.services.isNotEmpty ? walker.services.first : null;
    }

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    // Stats cascade animation
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for each stat card
    _statAnimations = List.generate(3, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return CurvedAnimation(
        parent: _statsAnimationController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    // Start animation after build
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _statsAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  // Professional subtle shrinking animation - Instagram-level polish
  double get _headerHeight {
    const maxHeight = 240.0;
    const minHeight = 200.0; // Only 40px shrink - very subtle
    final height = maxHeight - (_scrollOffset * 0.15);
    return height.clamp(minHeight, maxHeight);
  }

  double get _imageSize {
    const maxSize = 200.0; // Larger hero image
    const minSize = 180.0; // Only 20px shrink
    final size = maxSize - (_scrollOffset * 0.08);
    return size.clamp(minSize, maxSize);
  }

  double get _imageOffset {
    // Image overlaps - half on header, half on content
    return _headerHeight - (_imageSize / 2);
  }

  double get _contentTopPadding {
    // Content starts after image + name overlay (with extra spacing)
    return _imageOffset + _imageSize + 80; // Added 80px for name overlay
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWalker = widget.person is Walker;

    return Scaffold(
      body: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Space for fixed header
              SliverToBoxAdapter(
                child: SizedBox(height: _contentTopPadding),
              ),
              
              // Content Section - Professional Card-Based Layout
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Main Content Area - Clean start
                      Padding(
                        padding: const EdgeInsets.all(DesignSystem.space3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        // Bio Section
                        _buildCompactBio(widget.person, isDark, isWalker),

                        const SizedBox(height: DesignSystem.space3),

                        // Animated Stats Row with Modern Design
                        Container(
                          padding: const EdgeInsets.all(DesignSystem.space2 + 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF1E293B),
                                      const Color(0xFF0F172A),
                                    ]
                                  : [
                                      const Color(0xFFF8FAFC),
                                      const Color(0xFFFFFFFF),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withAlpha((0.08 * 255).round())
                                  : Colors.black.withAlpha((0.05 * 255).round()),
                              width: 1,
                            ),
                            boxShadow: DesignSystem.shadowCard(Colors.black),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildAnimatedStatCard(
                                  animation: _statAnimations[0],
                                  icon: Icons.directions_walk_rounded,
                                  value: '${widget.person.completedWalks}+',
                                  label: 'Walks',
                                  color: isWalker ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: DesignSystem.space2),
                              Expanded(
                                child: _buildAnimatedStatCard(
                                  animation: _statAnimations[1],
                                  icon: Icons.star_rounded,
                                  value: widget.person.rating.toString(),
                                  label: 'Rating',
                                  color: const Color(0xFFFBBF24),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: DesignSystem.space2),
                              Expanded(
                                child: _buildAnimatedStatCard(
                                  animation: _statAnimations[2],
                                  icon: Icons.reviews_rounded,
                                  value: '${widget.person.reviews}',
                                  label: 'Reviews',
                                  color: const Color(0xFF8B5CF6),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: DesignSystem.space3),

                        // Services Section (for Walkers)
                        if (isWalker && (widget.person as Walker).services.isNotEmpty)
                          _buildServicesSection(isDark, (widget.person as Walker).services),

                        if (isWalker && (widget.person as Walker).services.isNotEmpty)
                          const SizedBox(height: DesignSystem.space3),

                        // Availability
                        _buildCompactAvailability(isDark),

                        const SizedBox(height: DesignSystem.space3),

                        // Reviews Section
                        if (widget.person.userId != null)
                          ReviewsList(
                            userId: widget.person.userId!,
                            maxReviews: 5,
                          ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Premium Header - Subtle gradient background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _headerHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWalker
                      ? [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                        ]
                      : [
                          const Color(0xFFEC4899),
                          const Color(0xFFDB2777),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Hero Image - Large, overlapping design (Instagram-style)
          Positioned(
            top: _imageOffset,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'image_${widget.person.imageUrl}',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.15 * 255).round()),
                            blurRadius: 40,
                            spreadRadius: 0,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 80,
                            spreadRadius: 0,
                            offset: const Offset(0, 25),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: _imageSize,
                          height: _imageSize,
                          child: widget.person.imageUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: widget.person.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: (widget.person is Walker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                                        .withAlpha((0.1 * 255).round()),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: widget.person is Walker ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: (widget.person is Walker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                                        .withAlpha((0.1 * 255).round()),
                                    child: Icon(
                                      widget.person is Walker ? Icons.person : Icons.pets,
                                      color: widget.person is Walker ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                                      size: _imageSize * 0.4,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: (widget.person is Walker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                                      .withAlpha((0.1 * 255).round()),
                                  child: Icon(
                                    widget.person is Walker ? Icons.person : Icons.pets,
                                    color: widget.person is Walker ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                                    size: _imageSize * 0.4,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name & Location Overlay - Always visible
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withAlpha((0.9 * 255).round()),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withAlpha((0.1 * 255).round()),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name
                        Text(
                          widget.person.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Location & Verification (for Walker)
                        if (widget.person is Walker)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (widget.person as Walker).location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if ((widget.person as Walker).hasPoliceClearance) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                              ],
                            ],
                          ),
                        // Pet Info for Owner
                        if (widget.person is Owner)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.pets_rounded,
                                    color: Color(0xFFEC4899),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${(widget.person as Owner).dogName}, ${(widget.person as Owner).dogAge}y • ${(widget.person as Owner).dogBreed}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Color(0xFFEF4444),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(widget.person as Owner).likes} likes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Hourly Rate Badge - Premium positioning
          if (widget.person is Walker)
            Positioned(
              top: _headerHeight - 40,
              right: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSystem.space2,
                          vertical: DesignSystem.space1 + 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha((0.4 * 255).round()),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha((0.2 * 255).round()),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withAlpha((0.3 * 255).round()),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.25 * 255).round()),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.attach_money_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedService ?? 'Service',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withAlpha((0.85 * 255).round()),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      '${_selectedService != null ? (widget.person as Walker).getServicePrice(_selectedService!) : (widget.person as Walker).hourlyRate}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const Text(
                                      '/hr',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Restart animation for pulse effect
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
                ),
              ),
            ),

          // App Bar with Back Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.3 * 255).round()),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.3 * 255).round()),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white, size: 22),
                        onPressed: () {},
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Action Bar with Glassmorphism
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(DesignSystem.space3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E293B).withAlpha((0.95 * 255).round()),
                              const Color(0xFF0F172A).withAlpha((0.90 * 255).round()),
                            ]
                          : [
                              Colors.white.withAlpha((0.95 * 255).round()),
                              Colors.white.withAlpha((0.85 * 255).round()),
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha((0.1 * 255).round())
                            : Colors.black.withAlpha((0.08 * 255).round()),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.15 * 255).round()),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Message Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Messaging ${widget.person.name}...'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF6366F1),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: DesignSystem.space2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF334155),
                                            const Color(0xFF1E293B),
                                          ]
                                        : [
                                            const Color(0xFFF8FAFC),
                                            const Color(0xFFF1F5F9),
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withAlpha((0.1 * 255).round())
                                        : Colors.black.withAlpha((0.08 * 255).round()),
                                    width: 1,
                                  ),
                                  boxShadow: DesignSystem.shadowSubtle(Colors.black),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.message_rounded,
                                      size: 18,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                    const SizedBox(width: DesignSystem.space1),
                                    Text(
                                      'Message',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: DesignSystem.caption,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: DesignSystem.space2),

                        // Book Walk Button
                        Expanded(
                          flex: 1,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final currentUser = FirebaseAuth.instance.currentUser;

                                // Check if user is authenticated using Firebase Auth directly
                                if (currentUser != null) {
                                  // User is logged in - check if they're trying to book a walker
                                  if (isWalker) {
                                    // They're viewing a walker, navigate to booking page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingPage(
                                          walker: widget.person as Walker,
                                        ),
                                      ),
                                    );
                                  } else {
                                    // They're viewing an owner - show message that booking isn't available
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('You can book pet walkers, not pet owners'),
                                        backgroundColor: Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                } else {
                                  // User not logged in - go to authentication page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingAuthenticationPage(
                                        personName: isWalker
                                            ? widget.person.name
                                            : (widget.person as Owner).dogName,
                                        isWalker: false, // They want to book, so they'll sign up as owner
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: DesignSystem.space2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isWalker
                                        ? [
                                            const Color(0xFF10B981),
                                            const Color(0xFF059669),
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
                                      color: (isWalker
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEC4899))
                                          .withAlpha((0.4 * 255).round()),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: DesignSystem.space1),
                                    Text(
                                      isWalker ? 'Book Walk' : 'Add Your Pet',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: DesignSystem.caption,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard({
    required Animation<double> animation,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * animation.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignSystem.space2,
                  horizontal: DesignSystem.space1,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                ),
                child: Column(
                  children: [
                    // Icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(DesignSystem.space1 + 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withAlpha((0.2 * 255).round()),
                            color.withAlpha((0.1 * 255).round()),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha((0.25 * 255).round()),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(height: DesignSystem.space1),
                    // Value
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Label
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildCompactBio(Person person, bool isDark, bool isWalker) {
    // Primary color based on user type
    final primaryColor = isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899);

    return Container(
      padding: const EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  primaryColor.withAlpha((0.15 * 255).round()),
                  primaryColor.withAlpha((0.08 * 255).round()),
                ]
              : [
                  primaryColor.withAlpha((0.08 * 255).round()),
                  primaryColor.withAlpha((0.04 * 255).round()),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: primaryColor.withAlpha((0.2 * 255).round()),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSystem.space1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                          .withAlpha((0.2 * 255).round()),
                      (isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                          .withAlpha((0.1 * 255).round()),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                  size: 18,
                ),
              ),
              const SizedBox(width: DesignSystem.space2),
              Text(
                isWalker ? 'About Me' : 'About ${(person as Owner).dogName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.space2),
          Text(
            person.bio,
            style: TextStyle(
              fontSize: DesignSystem.caption,
              height: 1.6,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAvailability(bool isDark) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withAlpha((0.5 * 255).round()),
                  const Color(0xFF0F172A).withAlpha((0.3 * 255).round()),
                ]
              : [
                  const Color(0xFFFAFAFA),
                  const Color(0xFFF5F5F5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha((0.08 * 255).round())
              : Colors.black.withAlpha((0.04 * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSystem.space1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withAlpha((0.2 * 255).round()),
                      const Color(0xFF10B981).withAlpha((0.1 * 255).round()),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: DesignSystem.space2),
              Text(
                (widget.person is Owner) ? 'Mostly Walks On' : 'Availability',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.space2),
          Wrap(
            spacing: DesignSystem.space1,
            runSpacing: DesignSystem.space1,
            children: days.map((day) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.space2,
                  vertical: DesignSystem.space1,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withAlpha((0.15 * 255).round()),
                      const Color(0xFF10B981).withAlpha((0.08 * 255).round()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                  border: Border.all(
                    color: const Color(0xFF10B981).withAlpha((0.3 * 255).round()),
                    width: 1,
                  ),
                ),
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: DesignSystem.small,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                    letterSpacing: 0.3,
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.person is Walker) ...[
            const SizedBox(height: DesignSystem.space2),
            Container(
              padding: const EdgeInsets.all(DesignSystem.space2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                    : Colors.white.withAlpha((0.5 * 255).round()),
                borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: DesignSystem.space1),
                  Expanded(
                    child: Text(
                      'Last Minute: Yes • Cancellation: 2-days Notice',
                      style: TextStyle(
                        fontSize: DesignSystem.small,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildServicesSection(bool isDark, List<String> services) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF6366F1).withAlpha((0.15 * 255).round()),
                  const Color(0xFF6366F1).withAlpha((0.08 * 255).round()),
                ]
              : [
                  const Color(0xFF6366F1).withAlpha((0.08 * 255).round()),
                  const Color(0xFF6366F1).withAlpha((0.04 * 255).round()),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSystem.space1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
                      const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ),
              const SizedBox(width: DesignSystem.space2),
              Text(
                'Services Offered',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.space2),
          Wrap(
            spacing: DesignSystem.space1 + 4,
            runSpacing: DesignSystem.space1 + 4,
            children: services.map((service) {
              IconData serviceIcon;
              Color serviceColor;
              String serviceDescription;

              switch (service) {
                case 'Walking':
                  serviceIcon = Icons.directions_walk_rounded;
                  serviceColor = const Color(0xFF6366F1);
                  serviceDescription = 'Professional dog walking';
                  break;
                case 'Grooming':
                  serviceIcon = Icons.cleaning_services_rounded;
                  serviceColor = const Color(0xFF8B5CF6);
                  serviceDescription = 'Full grooming services';
                  break;
                case 'Sitting':
                  serviceIcon = Icons.home_work_rounded;
                  serviceColor = const Color(0xFFF59E0B);
                  serviceDescription = 'In-home pet sitting';
                  break;
                default:
                  serviceIcon = Icons.pets_rounded;
                  serviceColor = const Color(0xFF6366F1);
                  serviceDescription = service;
              }

              final isSelected = _selectedService == service;
              final walker = widget.person as Walker;
              final price = walker.getServicePrice(service);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedService = service;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.space2,
                    vertical: DesignSystem.space1 + 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [
                              serviceColor,
                              serviceColor.withAlpha((0.8 * 255).round()),
                            ]
                          : [
                              serviceColor.withAlpha((0.15 * 255).round()),
                              serviceColor.withAlpha((0.08 * 255).round()),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                    border: Border.all(
                      color: isSelected
                          ? serviceColor
                          : serviceColor.withAlpha((0.3 * 255).round()),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: serviceColor.withAlpha(((isSelected ? 0.3 : 0.15) * 255).round()),
                        blurRadius: isSelected ? 12 : 8,
                        offset: Offset(0, isSelected ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        serviceIcon,
                        color: isSelected ? Colors.white : serviceColor,
                        size: 24,
                      ),
                      const SizedBox(height: DesignSystem.space1),
                      Text(
                        service,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : serviceColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceDescription,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withAlpha((0.9 * 255).round())
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignSystem.space1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withAlpha((0.2 * 255).round())
                              : const Color(0xFF10B981).withAlpha((0.15 * 255).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$$price/hr',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}