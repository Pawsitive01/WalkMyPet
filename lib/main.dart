import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/detail_page.dart';
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

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('About Us Page'),
    );
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Register Page'),
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFF6366F1).withAlpha((0.15 * 255).round())
                  : Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: _isHovered ? 10 : 6,
              spreadRadius: 0,
              offset: Offset(0, _isHovered ? 3 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar, Name & Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'image_${widget.walker.imageUrl}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withAlpha((0.25 * 255).round()),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: AssetImage(widget.walker.imageUrl),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.walker.name,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.walker.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                      const SizedBox(width: 10),
                      // Price Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha((0.3 * 255).round()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '\$',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                Text(
                                  '${widget.walker.hourlyRate}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'per hour',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha((0.85 * 255).round()),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Stats Row with Rating
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withAlpha((0.08 * 255).round())
                                  : Colors.black.withAlpha((0.06 * 255).round()),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.walker.rating}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.walker.reviews})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_walk_rounded,
                              color: Color(0xFF6366F1),
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.walker.completedWalks}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Badges
                  if (widget.walker.hasPoliceClearance) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactBadge(
                          icon: Icons.verified_rounded,
                          label: 'Verified',
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                        ),
                        if (widget.walker.hasPoliceClearance)
                          _buildCompactBadge(
                            icon: Icons.shield_rounded,
                            label: 'Police Check',
                            color: const Color(0xFF8B5CF6),
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Bar at Bottom
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1E293B).withAlpha((0.5 * 255).round()),
                          const Color(0xFF0F172A).withAlpha((0.8 * 255).round()),
                        ]
                      : [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFF1F5F9),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha((0.1 * 255).round())
                        : Colors.black.withAlpha((0.06 * 255).round()),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withAlpha((0.05 * 255).round())
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withAlpha((0.3 * 255).round()),
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF6366F1),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Book Now Button
                  Expanded(
                    flex: 1,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking ${widget.walker.name}...'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withAlpha((0.3 * 255).round()),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: 14,
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
    );
  }

  Widget _buildCompactBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha((0.25 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFFEC4899).withAlpha((0.15 * 255).round())
                  : Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: _isHovered ? 10 : 6,
              spreadRadius: 0,
              offset: Offset(0, _isHovered ? 3 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar, Owner Name & Dog Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'image_${widget.owner.imageUrl}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withAlpha((0.25 * 255).round()),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: AssetImage(widget.owner.imageUrl),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.owner.name,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.pets,
                                  size: 14,
                                  color: Color(0xFFEC4899),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${widget.owner.dogName}, ${widget.owner.dogAge} years old',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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

                  // Dog Breed Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withAlpha((0.3 * 255).round()),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.owner.dogBreed,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Stats Row with Rating
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withAlpha((0.5 * 255).round())
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withAlpha((0.08 * 255).round())
                                  : Colors.black.withAlpha((0.06 * 255).round()),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.owner.rating}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.owner.reviews})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_walk_rounded,
                              color: Color(0xFF6366F1),
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.owner.completedWalks}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Police Clearance Badge
                  if (widget.owner.hasPoliceClearance) ...[
                    const SizedBox(height: 10),
                    _buildCompactBadge(
                      icon: Icons.shield_rounded,
                      label: 'Police Check',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),

            // Action Bar at Bottom
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1E293B).withAlpha((0.5 * 255).round()),
                          const Color(0xFF0F172A).withAlpha((0.8 * 255).round()),
                        ]
                      : [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFF1F5F9),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha((0.1 * 255).round())
                        : Colors.black.withAlpha((0.06 * 255).round()),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withAlpha((0.05 * 255).round())
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEC4899).withAlpha((0.3 * 255).round()),
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFEC4899),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEC4899),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Book Now Button
                  Expanded(
                    flex: 1,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking walk for ${widget.owner.dogName}...'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFEC4899),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withAlpha((0.3 * 255).round()),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: 14,
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
    );
  }

  Widget _buildCompactBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha((0.25 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}