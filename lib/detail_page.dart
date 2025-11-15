import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/booking_login_page.dart';

// Modern Design System Constants
class DesignSystem {
  // Typography Scale (SF Pro / Inter inspired)
  static const double displayLarge = 40.0;
  static const double h1 = 32.0;
  static const double h2 = 24.0;
  static const double h3 = 20.0;
  static const double body = 16.0;
  static const double caption = 14.0;
  static const double small = 12.0;

  // 8pt Grid Spacing System
  static const double space1 = 8.0;
  static const double space2 = 16.0;
  static const double space3 = 24.0;
  static const double space4 = 32.0;
  static const double space5 = 40.0;
  static const double space6 = 48.0;

  // Border Radius
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // Modern Shadow System
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

  @override
  void initState() {
    super.initState();
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

  // Calculate dynamic values based on scroll
  double get _headerHeight {
    const maxHeight = 200.0;
    const minHeight = 80.0;
    final height = maxHeight - _scrollOffset;
    return height.clamp(minHeight, maxHeight);
  }

  double get _imageSize {
    const maxSize = 150.0;
    const minSize = 50.0;
    final size = maxSize - (_scrollOffset * 0.5);
    return size.clamp(minSize, maxSize);
  }

  double get _imageTopPosition {
    const maxTop = 100.0;
    const minTop = 15.0;
    final top = maxTop - (_scrollOffset * 0.5);
    return top.clamp(minTop, maxTop);
  }

  double get _titleOpacity {
    // Fade out title when scrolling
    return (1.0 - (_scrollOffset / 100)).clamp(0.0, 1.0);
  }

  double get _appBarIconSize {
    const maxSize = 48.0;
    const minSize = 40.0;
    final size = maxSize - (_scrollOffset * 0.04);
    return size.clamp(minSize, maxSize);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWalker = widget.person is Walker;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated Header with Enhanced Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: _headerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWalker
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
          ),
          
          // Main Content with ScrollView
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Space for header and image
              SliverToBoxAdapter(
                child: SizedBox(height: _headerHeight + (_imageSize / 2) - 20),
              ),
              
              // Content Section
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(DesignSystem.space3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Location (fade in as you scroll)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: 1.0 - _titleOpacity,
                          child: Column(
                            children: [
                              Text(
                                widget.person.name,
                                style: TextStyle(
                                  fontSize: DesignSystem.h1,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -1.0,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: DesignSystem.space1),
                              if (widget.person is Walker)
                                Text(
                                  (widget.person as Walker).location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                )
                              else if (widget.person is Owner)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        (isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                                            .withAlpha((0.12 * 255).round()),
                                        (isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                                            .withAlpha((0.06 * 255).round()),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: (isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                                          .withAlpha((0.25 * 255).round()),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.pets_rounded,
                                        color: isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${(widget.person as Owner).dogName}, ${(widget.person as Owner).dogAge}y • ${(widget.person as Owner).dogBreed}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: DesignSystem.space3),

                        // Bio Section
                        _buildCompactBio(widget.person, isDark, isWalker),

                        const SizedBox(height: DesignSystem.space3),

                        // Price Card for Walker
                        if (widget.person is Walker) ...[
                          _buildCompactPriceCard(widget.person as Walker, isDark),
                          const SizedBox(height: DesignSystem.space3),
                        ],

                        // Animated Stats Row with Modern Design
                        Container(
                          padding: const EdgeInsets.all(DesignSystem.space3),
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
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.05),
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

                        // Availability
                        _buildCompactAvailability(isDark),

                        const SizedBox(height: DesignSystem.space3),

                        // Reviews Section
                        _buildCompactReviews(widget.person, isDark, isWalker),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Animated Profile Image
          Positioned(
            left: 0,
            right: 0,
            top: _imageTopPosition,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              child: Hero(
                tag: 'image_${widget.person.imageUrl}',
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: _imageSize > 80 ? 5 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).round()),
                          blurRadius: _imageSize > 80 ? 24 : 12,
                          spreadRadius: 0,
                          offset: Offset(0, _imageSize > 80 ? 4 : 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: _imageSize / 2,
                      backgroundImage: AssetImage(widget.person.imageUrl),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Animated AppBar with title that appears on scroll
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: _appBarIconSize,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.25 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    
                    // Title that appears when scrolled
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: 1.0 - _titleOpacity,
                      child: Text(
                        widget.person.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.25 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
                        onPressed: () {},
                        padding: const EdgeInsets.all(10),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingLoginPage(
                                      personName: isWalker
                                          ? widget.person.name
                                          : (widget.person as Owner).dogName,
                                      isWalker: isWalker,
                                    ),
                                  ),
                                );
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
                                  children: const [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: DesignSystem.space1),
                                    Text(
                                      'Book Walk',
                                      style: TextStyle(
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
                      padding: const EdgeInsets.all(DesignSystem.space2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: DesignSystem.space1),
                    // Value
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: DesignSystem.h3,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Label
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: DesignSystem.small,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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

  Widget _buildCompactPriceCard(Walker walker, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(DesignSystem.space2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOURLY RATE',
                        style: TextStyle(
                          fontSize: DesignSystem.small,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: DesignSystem.space1),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.attach_money_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          Text(
                            '${walker.hourlyRate}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4, left: 2),
                            child: Text(
                              '/hr',
                              style: TextStyle(
                                fontSize: DesignSystem.body,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(DesignSystem.space2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBio(Person person, bool isDark, bool isWalker) {
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
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
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
                'Availability',
                style: TextStyle(
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
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
      ),
    );
  }

  Widget _buildCompactReviews(Person person, bool isDark, bool isWalker) {
    // Sample reviews data - in production, this would come from API
    final reviews = [
      {
        'name': 'John Doe',
        'initials': 'JD',
        'rating': 5,
        'time': '2d ago',
        'text': 'Excellent service & very punctual. Highly recommend!',
        'verified': true,
      },
      {
        'name': 'Sarah Smith',
        'initials': 'SS',
        'rating': 5,
        'time': '1w ago',
        'text': 'Amazing experience! My dog absolutely loved the walk.',
        'verified': true,
      },
      {
        'name': 'Mike Johnson',
        'initials': 'MJ',
        'rating': 4,
        'time': '2w ago',
        'text': 'Great walker, very professional and caring.',
        'verified': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                fontSize: DesignSystem.h3,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: DesignSystem.caption,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignSystem.space2),

        // Horizontal scrollable reviews
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            padding: const EdgeInsets.only(right: DesignSystem.space2),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  right: index < reviews.length - 1 ? DesignSystem.space2 : 0,
                ),
                padding: const EdgeInsets.all(DesignSystem.space3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B),
                            const Color(0xFF0F172A),
                          ]
                        : [
                            const Color(0xFFFFFFFF),
                            const Color(0xFFF8FAFC),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha((0.1 * 255).round())
                        : Colors.black.withAlpha((0.05 * 255).round()),
                    width: 1,
                  ),
                  boxShadow: DesignSystem.shadowCard(Colors.black),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isWalker
                                  ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                  : [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isWalker ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                                    .withAlpha((0.3 * 255).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              review['initials'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: DesignSystem.caption,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignSystem.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      review['name'] as String,
                                      style: TextStyle(
                                        fontSize: DesignSystem.caption,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (review['verified'] as bool) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: Color(0xFF10B981),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(
                                  5,
                                  (starIndex) => Icon(
                                    starIndex < (review['rating'] as int)
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: const Color(0xFFFBBF24),
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          review['time'] as String,
                          style: TextStyle(
                            fontSize: DesignSystem.small,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignSystem.space2),
                    Expanded(
                      child: Text(
                        '"${review['text']}"',
                        style: TextStyle(
                          fontSize: DesignSystem.caption,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}