import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/detail_page.dart';
import 'package:walkmypet/login_page.dart';
import 'package:walkmypet/about_us_page.dart';
import 'package:walkmypet/register_page.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

void main() async {
  print('🚀 App starting...');

  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialized');

  bool firebaseInitialized = false;
  String? firebaseError;

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ Firebase initialization timeout - continuing without Firebase');
        throw Exception('Firebase initialization timeout');
      },
    );
    firebaseInitialized = true;
    print('✅ Firebase initialized successfully');
  } catch (e) {
    firebaseError = e.toString();
    print('❌ Firebase initialization error: $e');
    print('⚠️ App will continue without Firebase');
  }

  print('🎨 Starting app UI...');
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(
        firebaseInitialized: firebaseInitialized,
        firebaseError: firebaseError,
      ),
    ),
  );
  print('✅ App started successfully');
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? firebaseError;

  const MyApp({
    super.key,
    this.firebaseInitialized = false,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Color(0xFF6366F1);

    const TextTheme appTextTheme =  TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -1,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
        surface: const Color(0xFFF8FAFC),
      ),
      textTheme: appTextTheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF0F172A),
      ),
      textTheme: appTextTheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF818CF8),
        foregroundColor: Colors.white,
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Walk My Pet',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: InitializationWrapper(
            firebaseInitialized: firebaseInitialized,
            firebaseError: firebaseError,
            child: const MyHomePage(),
          ),
        );
      },
    );
  }
}

class InitializationWrapper extends StatefulWidget {
  final Widget child;
  final bool firebaseInitialized;
  final String? firebaseError;

  const InitializationWrapper({
    super.key,
    required this.child,
    required this.firebaseInitialized,
    this.firebaseError,
  });

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    print('📱 Initializing app UI...');

    // Small delay to ensure everything is settled
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isReady = true;
      });
      print('✅ App UI ready');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pets,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Walk My Pet',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error banner if Firebase failed to initialize
    if (widget.firebaseError != null) {
      return Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Material(
                color: Colors.orange.shade700,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Running in offline mode',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () {
                          // Hide banner by rebuilding without it
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;

  static const List<Widget> _widgetOptions = <Widget>[
    WalkerList(),
    OwnerList(),
    AboutUsPage(),
    RegisterPage(),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                      ]
                    : [
                        const Color(0xFFF8FAFC),
                        const Color(0xFFE0E7FF),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              _buildModernAppBar(context, themeProvider, isDark),
              Expanded(
                child: FadeTransition(
                  opacity: _animController,
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildModernNavBar(context, isDark),
    );
  }

  Widget _buildModernAppBar(BuildContext context, ThemeProvider themeProvider, bool isDark) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ]
              : [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.elliptical(60, 30),
          bottomRight: Radius.elliptical(60, 30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha((0.25 * 255).round()),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.25 * 255).round()),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.3 * 255).round()),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.pets, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Walk My Pet',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Find your perfect match',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha((0.85 * 255).round()),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.25 * 255).round()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.3 * 255).round()),
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        themeProvider.themeMode == ThemeMode.light
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                      tooltip: 'Toggle Theme',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.directions_walk_rounded, 'Walkers', isDark),
              _buildNavItem(1, Icons.pets_rounded, 'Owners', isDark),
              _buildNavItem(2, Icons.info_rounded, 'About', isDark),
              _buildNavItem(3, Icons.person_add_rounded, 'Register', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withAlpha((0.1 * 255).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class WalkerList extends StatefulWidget {
  const WalkerList({super.key});

  @override
  State<WalkerList> createState() => _WalkerListState();
}

class _WalkerListState extends State<WalkerList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _itemAnimations;

  static const _walkers = [
    Walker(
      name: 'John Doe',
      rating: 4.5,
      reviews: 120,
      hourlyRate: 25,
      location: 'Adelaide, Australia',
      completedWalks: 150,
      imageUrl: 'assets/images/walker1.jpg',
      bio: 'I am a dog lover and I have been walking dogs for 5 years. I am very responsible and I will take good care of your dog.',
      hasPoliceClearance: true,
      services: ['Walking', 'Sitting'],
      servicePrices: {
        'Walking': 25,
        'Sitting': 35,
      },
    ),
    Walker(
      name: 'Jane Smith',
      rating: 5.0,
      reviews: 200,
      hourlyRate: 30,
      location: 'Los Angeles, CA',
      completedWalks: 250,
      imageUrl: 'assets/images/walker2.jpg',
      bio: 'I am a certified dog walker and I have been working with dogs for over 10 years. I am also a certified dog trainer.',
      hasPoliceClearance: false,
      services: ['Walking', 'Grooming', 'Sitting'],
      servicePrices: {
        'Walking': 30,
        'Grooming': 45,
        'Sitting': 40,
      },
    ),
    Walker(
      name: 'Sam Wilson',
      rating: 4.2,
      reviews: 90,
      hourlyRate: 22,
      location: 'Adelaide, Australia',
      completedWalks: 120,
      imageUrl: 'assets/images/walker3.jpg',
      bio: 'I am a student and I love dogs. I am available for walks in the afternoon and on weekends.',
      hasPoliceClearance: true,
      services: ['Walking'],
      servicePrices: {
        'Walking': 22,
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Create staggered animations for each item
    _itemAnimations = List.generate(
      _walkers.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      itemCount: _walkers.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _itemAnimations[index],
          builder: (context, child) {
            final value = _itemAnimations[index].value;
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: RepaintBoundary(
            child: WalkerCard(walker: _walkers[index]),
          ),
        );
      },
    );
  }
}

class OwnerList extends StatefulWidget {
  const OwnerList({super.key});

  @override
  State<OwnerList> createState() => _OwnerListState();
}

class _OwnerListState extends State<OwnerList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _itemAnimations;

  static const _owners = [
    Owner(
      name: 'Richard Roe',
      dogName: 'Max',
      dogAge: 3,
      dogBreed: 'Golden Retriever',
      rating: 4.8,
      reviews: 80,
      completedWalks: 100,
      imageUrl: 'assets/images/owner1.jpg',
      bio: 'Max is a very friendly and energetic Golden Retriever. He loves to play fetch and go for long walks.',
      hasPoliceClearance: true,
      likes: 245,
    ),
    Owner(
      name: 'Mary Major',
      dogName: 'Bella',
      dogAge: 2,
      dogBreed: 'French Bulldog',
      rating: 4.9,
      reviews: 95,
      completedWalks: 120,
      imageUrl: 'assets/images/owner2.jpg',
      bio: 'Bella is a sweet and playful French Bulldog. She is very good with other dogs and loves to cuddle.',
      hasPoliceClearance: false,
      likes: 312,
    ),
    Owner(
      name: 'Peter Jones',
      dogName: 'Buddy',
      dogAge: 5,
      dogBreed: 'Labrador',
      rating: 4.2,
      reviews: 60,
      completedWalks: 80,
      imageUrl: 'assets/images/owner3.jpg',
      bio: 'Buddy is a calm and gentle Labrador. He is very well-behaved and loves to go for walks in the park.',
      hasPoliceClearance: true,
      likes: 178,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _itemAnimations = List.generate(
      _owners.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      itemCount: _owners.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _itemAnimations[index],
          builder: (context, child) {
            final value = _itemAnimations[index].value;
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: RepaintBoundary(
            child: OwnerCard(owner: _owners[index]),
          ),
        );
      },
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  const StarRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16);
        } else if (index < rating) {
          return const Icon(Icons.star_half_rounded, color: Color(0xFFFBBF24), size: 16);
        } else {
          return Icon(Icons.star_outline_rounded, color: Colors.grey[400], size: 16);
        }
      }),
    );
  }
}

class WalkerCard extends StatefulWidget {
  final Walker walker;

  const WalkerCard({super.key, required this.walker});

  @override
  State<WalkerCard> createState() => _WalkerCardState();
}

class _WalkerCardState extends State<WalkerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(person: widget.walker),
            ),
          );
        },
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            maxWidth: screenWidth > 500 ? 420 : double.infinity,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth > 500 ? 0 : 24,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFF6366F1).withAlpha((0.12 * 255).round())
                    : Colors.black.withAlpha((0.04 * 255).round()),
                blurRadius: _isHovered ? 12 : 8,
                spreadRadius: 0,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact Header with Avatar & Name
                    Row(
                      children: [
                        Hero(
                          tag: 'image_${widget.walker.imageUrl}',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6366F1).withAlpha((0.3 * 255).round()),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: AssetImage(widget.walker.imageUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.walker.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 13,
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      widget.walker.location,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Compact Info Grid
                    Row(
                      children: [
                        // Rating
                        Expanded(
                          child: _buildInfoChip(
                            icon: Icons.star,
                            label: '${widget.walker.rating}',
                            sublabel: '${widget.walker.reviews} reviews',
                            color: const Color(0xFFFBBF24),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Walks
                        Expanded(
                          child: _buildInfoChip(
                            icon: Icons.pets,
                            label: '${widget.walker.completedWalks}',
                            sublabel: 'walks',
                            color: const Color(0xFF6366F1),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Price
                        Expanded(
                          child: _buildInfoChip(
                            icon: Icons.payments,
                            label: '\$${widget.walker.hourlyRate}',
                            sublabel: 'per hour',
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    // Services
                    if (widget.walker.services.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.walker.services.map((service) {
                          final IconData serviceIcon = service == 'Walking'
                              ? Icons.directions_walk_rounded
                              : service == 'Grooming'
                                  ? Icons.cleaning_services_rounded
                                  : Icons.home_work_rounded;
                          final int price = widget.walker.getServicePrice(service);
                          return _buildServiceBadge(
                            icon: serviceIcon,
                            label: service,
                            price: price,
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ],

                    // Compact Badges
                    if (widget.walker.hasPoliceClearance) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildMicroBadge(
                            icon: Icons.verified,
                            label: 'Verified',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          if (widget.walker.hasPoliceClearance)
                            _buildPoliceClearanceBadge(
                              icon: Icons.shield,
                              label: 'Police Clearance',
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withAlpha((0.08 * 255).round())
                    : Colors.black.withAlpha((0.06 * 255).round()),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // About Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(person: widget.walker),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha((0.05 * 255).round())
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withAlpha((0.15 * 255).round())
                                    : Colors.black.withAlpha((0.1 * 255).round()),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Book Button
                    Expanded(
                      flex: 2,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(
                                  personName: widget.walker.name,
                                  isWalker: true,
                                  rating: widget.walker.rating,
                                  personImage: widget.walker.imageUrl,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withAlpha((0.3 * 255).round()),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Book Walker',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha((0.03 * 255).round())
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha((0.08 * 255).round())
              : Colors.black.withAlpha((0.06 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMicroBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF10B981).withAlpha((0.15 * 255).round())
            : const Color(0xFF10B981).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBadge({
    required IconData icon,
    required String label,
    required int price,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withAlpha((0.15 * 255).round()),
            const Color(0xFF6366F1).withAlpha((0.08 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6366F1),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '\$$price/hr',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliceClearanceBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF6366F1).withAlpha((0.15 * 255).round())
            : const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

}

class OwnerCard extends StatefulWidget {
  final Owner owner;

  const OwnerCard({super.key, required this.owner});

  @override
  State<OwnerCard> createState() => _OwnerCardState();
}

class _OwnerCardState extends State<OwnerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(person: widget.owner),
            ),
          );
        },
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            maxWidth: screenWidth > 500 ? 420 : double.infinity,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth > 500 ? 0 : 24,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFFEC4899).withAlpha((0.12 * 255).round())
                    : Colors.black.withAlpha((0.04 * 255).round()),
                blurRadius: _isHovered ? 12 : 8,
                spreadRadius: 0,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact Header with Avatar & Owner Name
                    Row(
                      children: [
                        Hero(
                          tag: 'image_${widget.owner.imageUrl}',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEC4899).withAlpha((0.3 * 255).round()),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: AssetImage(widget.owner.imageUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.owner.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.pets,
                                    size: 13,
                                    color: Color(0xFFEC4899),
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      '${widget.owner.dogName}, ${widget.owner.dogAge}y • ${widget.owner.dogBreed}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Compact Info Grid
                    Row(
                      children: [
                        // Rating
                        Expanded(
                          flex: 2,
                          child: _buildInfoChip(
                            icon: Icons.star,
                            label: '${widget.owner.rating}',
                            sublabel: '${widget.owner.reviews} reviews',
                            color: const Color(0xFFFBBF24),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Walks
                        Expanded(
                          flex: 2,
                          child: _buildInfoChip(
                            icon: Icons.pets,
                            label: '${widget.owner.completedWalks}',
                            sublabel: 'walks done',
                            color: const Color(0xFFEC4899),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    // Compact Badge
                    if (widget.owner.hasPoliceClearance) ...[
                      const SizedBox(height: 10),
                      _buildPoliceClearanceBadge(
                        icon: Icons.shield,
                        label: 'Police Clearance',
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withAlpha((0.08 * 255).round())
                    : Colors.black.withAlpha((0.06 * 255).round()),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // About Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(person: widget.owner),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha((0.05 * 255).round())
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withAlpha((0.15 * 255).round())
                                    : Colors.black.withAlpha((0.1 * 255).round()),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Book Button
                    Expanded(
                      flex: 2,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(
                                  personName: widget.owner.dogName,
                                  isWalker: false,
                                  rating: widget.owner.rating,
                                  personImage: widget.owner.imageUrl,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withAlpha((0.3 * 255).round()),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Add your Pet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha((0.03 * 255).round())
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha((0.08 * 255).round())
              : Colors.black.withAlpha((0.06 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMicroBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF10B981).withAlpha((0.15 * 255).round())
            : const Color(0xFF10B981).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliceClearanceBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF6366F1).withAlpha((0.15 * 255).round())
            : const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }
}