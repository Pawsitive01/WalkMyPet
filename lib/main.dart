import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:walkmypet/models.dart';
import 'package:walkmypet/detail_page.dart';
import 'package:walkmypet/booking_authentication_page.dart';
import 'package:walkmypet/booking/booking_page.dart';
import 'package:walkmypet/about_us_page.dart';
import 'package:walkmypet/user_type_selection_page.dart' as user_type;
import 'package:walkmypet/services/firebase_emulator_config.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/providers/auth_provider.dart' as app_auth;
import 'package:walkmypet/profile/redesigned_owner_profile_page.dart';
import 'package:walkmypet/profile/redesigned_walker_profile_page.dart';
import 'package:walkmypet/services/notification_service.dart';
import 'package:walkmypet/services/stripe_service.dart';
import 'package:flutter/services.dart';
import 'package:walkmypet/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/walker/walker_notifications_page.dart';
import 'package:walkmypet/owner/owner_notifications_page.dart';
import 'package:walkmypet/booking/my_bookings_page_v3.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  String? firebaseError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timeout');
      },
    );
    firebaseInitialized = true;

    // Connect to Firebase Emulators in debug mode
    await FirebaseEmulatorConfig.connectToEmulators();

    // Initialize Stripe SDK
    try {
      final stripeService = StripeService();
      await stripeService.initialize();
    } catch (e) {
      print('Warning: Stripe SDK initialization failed: $e');
      // Don't block app startup if Stripe fails to initialize
    }
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        if (firebaseInitialized)
          ChangeNotifierProvider(create: (context) => app_auth.AuthProvider()),
      ],
      child: MyApp(
        firebaseInitialized: firebaseInitialized,
        firebaseError: firebaseError,
      ),
    ),
  );
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
          navigatorKey: NotificationService.navigatorKey,
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
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize NotificationService if Firebase is initialized
    if (widget.firebaseInitialized) {
      try {
        await NotificationService().initialize();
        debugPrint('NotificationService initialized successfully');
      } catch (e) {
        debugPrint('Error initializing NotificationService: $e');
      }
    }

    // Small delay to ensure everything is settled
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isReady = true;
      });
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets,
                  size: 80,
                  color: Colors.white,
                ),
                SizedBox(height: 24),
                Text(
                  'Walk My Pet',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 48),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
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

    // Show error banner if Firebase failed to initialize and not dismissed
    if (widget.firebaseError != null && !_bannerDismissed) {
      return Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _bannerDismissed ? 0 : null,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Offline Mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Limited functionality available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _bannerDismissed = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
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
      );
    }

    return widget.child;
  }
}

class MyHomePage extends StatefulWidget {
  final int initialIndex;

  const MyHomePage({super.key, this.initialIndex = 0});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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

  List<Widget> _getWidgetOptions(app_auth.AuthProvider? authProvider) {
    final Widget fourthTab;

    if (authProvider != null && authProvider.isAuthenticated) {
      debugPrint('📱 MyHomePage: User authenticated - loading: ${authProvider.isLoading}, profile: ${authProvider.userProfile != null}');

      // Show profile page for all authenticated users
      // If user type is not set yet, default to owner profile
      if (authProvider.userProfile != null) {
        fourthTab = authProvider.isWalker
            ? const RedesignedWalkerProfilePage()
            : const RedesignedOwnerProfilePage();
      } else {
        // User is authenticated but profile not loaded yet
        debugPrint('⏳ MyHomePage: Waiting for profile to load...');
        fourthTab = const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        );
      }
    } else if (authProvider != null && authProvider.isLoading) {
      // AuthProvider is still loading - show loading indicator
      debugPrint('⏳ MyHomePage: AuthProvider loading...');
      fourthTab = const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    } else {
      // Show register page for unauthenticated users
      debugPrint('🚫 MyHomePage: User not authenticated - showing register page');
      fourthTab = const user_type.RegisterPage();
    }

    return <Widget>[
      const WalkerList(),
      const OwnerList(),
      const AboutUsPage(),
      fourthTab,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<app_auth.AuthProvider?>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final widgetOptions = _getWidgetOptions(authProvider);

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
              // Hide main app bar for profile tab (both walker and owner profiles have their own headers)
              // Show it for all other tabs (walkers, owners, about)
              if (_selectedIndex != 3)
                _buildModernAppBar(context, themeProvider, authProvider, isDark),
              Expanded(
                child: FadeTransition(
                  opacity: _animController,
                  child: widgetOptions.elementAt(_selectedIndex),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildModernNavBar(context, authProvider, isDark),
    );
  }

  Widget _buildModernAppBar(BuildContext context, ThemeProvider themeProvider, app_auth.AuthProvider? authProvider, bool isDark) {
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
                        padding: const EdgeInsets.all(DesignSystem.space1_5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
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
                            authProvider != null && authProvider.isAuthenticated && authProvider.userProfile != null
                                ? 'Welcome, ${authProvider.userProfile!.displayName ?? "User"}!'
                                : 'Find your perfect match',
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
                  Row(
                    children: [
                      // Notification bell for all authenticated users
                      if (authProvider != null && authProvider.isAuthenticated) ...[
                        _buildNotificationBellButton(authProvider, isDark),
                        const SizedBox(width: 8),
                      ],
                      // Menu button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Menu',
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          offset: const Offset(0, 50),
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white : const Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'theme',
                              child: Row(
                                children: [
                                  Icon(
                                    themeProvider.themeMode == ThemeMode.light
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white : const Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    themeProvider.themeMode == ThemeMode.light
                                        ? 'Dark Mode'
                                        : 'Light Mode',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // My Bookings - only for authenticated owners
                            if (authProvider != null && authProvider.isAuthenticated && authProvider.isOwner)
                              PopupMenuItem<String>(
                                value: 'my_bookings',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 20,
                                      color: isDark ? Colors.white : const Color(0xFFEC4899),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'My Bookings',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            PopupMenuItem<String>(
                              value: (authProvider != null && authProvider.isAuthenticated) ? 'signout' : 'signin',
                              child: Row(
                                children: [
                                  Icon(
                                    (authProvider != null && authProvider.isAuthenticated)
                                        ? Icons.logout_rounded
                                        : Icons.login_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white : const Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    (authProvider != null && authProvider.isAuthenticated) ? 'Sign Out' : 'Sign In',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (String value) async {
                            if (value == 'theme') {
                              themeProvider.toggleTheme();
                            } else if (value == 'profile') {
                              // Navigate to profile tab
                              setState(() {
                                _selectedIndex = 3;
                              });
                            } else if (value == 'my_bookings') {
                              // Navigate to My Bookings page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyBookingsPageV3(),
                                ),
                              );
                            } else if (value == 'signout') {
                              // Sign out the user
                              if (authProvider == null) return;
                              try {
                                await authProvider.signOut();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Signed out successfully'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                  // Navigate to home tab
                                  setState(() {
                                    _selectedIndex = 0;
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error signing out: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else if (value == 'signin') {
                              // Navigate to register/sign in tab
                              setState(() {
                                _selectedIndex = 3;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBellButton(app_auth.AuthProvider? authProvider, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading notification count: ${snapshot.error}');
        }
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        // Only show the bell if there are notifications
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // Navigate to appropriate notifications page based on user type
              final isWalker = authProvider?.isWalker ?? false;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isWalker
                      ? const WalkerNotificationsPage()
                      : const OwnerNotificationsPage(),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
        );
      },
    );
  }

  Widget _buildModernNavBar(BuildContext context, app_auth.AuthProvider? authProvider, bool isDark) {
    // Determine the icon and label for the fourth nav item
    final bool isAuthenticated = authProvider != null && authProvider.isAuthenticated;
    final IconData fourthIcon = isAuthenticated ? Icons.person_rounded : Icons.person_add_rounded;
    final String fourthLabel = isAuthenticated ? 'Profile' : 'Register';

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
              _buildNavItem(3, fourthIcon, fourthLabel, isDark),
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
  final UserService _userService = UserService();
  List<Walker> _walkers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadWalkers();
  }

  Future<void> _loadWalkers() async {
    try {
      final users = await _userService.getPetWalkers();

      // Filter for walkers who completed onboarding and map to Walker model
      final loadedWalkers = users.where((user) {
        final data = user.toFirestore();
        return data['onboardingComplete'] == true;
      }).map((user) {
        final data = user.toFirestore();

        // Convert servicePrices from Map<String, dynamic> with doubles to Map<String, int>
        final rawServicePrices = data['servicePrices'] as Map<String, dynamic>? ?? {};
        final servicePrices = <String, int>{};
        rawServicePrices.forEach((key, value) {
          servicePrices[key] = (value is int) ? value : (value as num).toInt();
        });

        return Walker(
          userId: user.id,
          name: data['displayName'] ?? 'Unknown',
          rating: (data['rating'] ?? 5.0).toDouble(),
          reviews: data['reviews'] ?? 0,
          hourlyRate: (data['hourlyRate'] ?? 25) is int
              ? data['hourlyRate'] ?? 25
              : (data['hourlyRate'] as num?)?.toInt() ?? 25,
          location: data['location'] ?? 'Unknown',
          completedWalks: data['completedWalks'] ?? 0,
          imageUrl: data['photoURL'] ?? 'assets/images/default_walker.jpg',
          bio: data['bio'] ?? 'No bio available',
          hasPoliceClearance: data['hasPoliceClearance'] ?? false,
          services: List<String>.from(data['services'] ?? ['Walking']),
          servicePrices: servicePrices,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _walkers = loadedWalkers;
          _isLoading = false;
          _errorMessage = null;
        });

        // Create staggered animations for each item
        if (_walkers.isNotEmpty) {
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
      }
    } catch (e) {
      debugPrint('Error loading walkers: $e');
      if (mounted) {
        setState(() {
          _walkers = [];
          _isLoading = false;
          _errorMessage = 'Failed to load pet walkers: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadWalkers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state
    if (_walkers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_walk_outlined,
                size: 80,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No Pet Walkers Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pet walkers will appear here once they complete their profile setup.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadWalkers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show walkers list
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
  final UserService _userService = UserService();
  List<Owner> _owners = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadOwners();
  }

  Future<void> _loadOwners() async {
    try {
      final users = await _userService.getPetOwners();

      final loadedOwners = users.map((user) {
        final data = user.toFirestore();
        return Owner(
          userId: user.id,
          name: data['displayName'] ?? 'Unknown',
          dogName: data['dogName'] ?? 'Pet',
          dogAge: int.tryParse((data['dogAge'] ?? '0').toString()) ?? 0,
          dogBreed: data['dogBreed'] ?? 'Unknown Breed',
          rating: (data['rating'] ?? 5.0).toDouble(),
          reviews: data['reviews'] ?? 0,
          completedWalks: data['completedWalks'] ?? 0,
          imageUrl: data['photoURL'] ?? 'assets/images/default_owner.jpg',
          bio: data['bio'] ?? 'No bio available',
          hasPoliceClearance: data['hasPoliceClearance'] ?? false,
          likes: data['likes'] ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _owners = loadedOwners;
          _isLoading = false;
          _errorMessage = null;
        });

        // Create staggered animations for each item
        if (_owners.isNotEmpty) {
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
      }
    } catch (e) {
      debugPrint('Error loading owners: $e');
      if (mounted) {
        setState(() {
          _owners = [];
          _isLoading = false;
          _errorMessage = 'Failed to load pet owners: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFEC4899)),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadOwners();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state
    if (_owners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets_outlined,
                size: 80,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No Pet Owners Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pet owners will appear here once they complete their profile setup.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadOwners();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show owners list
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
                            child: ClipOval(
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: widget.walker.imageUrl.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: widget.walker.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF6366F1),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                                          child: const Icon(
                                            Icons.person,
                                            color: Color(0xFF6366F1),
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF6366F1),
                                          size: 28,
                                        ),
                                      ),
                              ),
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
                        // Police Clearance (NEW - replaces rate)
                        Expanded(
                          child: widget.walker.hasPoliceClearance
                              ? _buildInfoChip(
                                  icon: Icons.shield_outlined,
                                  label: 'Verified',
                                  sublabel: 'Police Check',
                                  color: const Color(0xFF10B981),
                                  isDark: isDark,
                                )
                              : _buildInfoChip(
                                  icon: Icons.info_outline,
                                  label: 'Standard',
                                  sublabel: 'Verified',
                                  color: const Color(0xFF64748B),
                                  isDark: isDark,
                                ),
                        ),
                      ],
                    ),

                    // Services (without prices - cleaner)
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
                          return _buildSimpleServiceBadge(
                            icon: serviceIcon,
                            label: service,
                            isDark: isDark,
                          );
                        }).toList(),
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
                          onTap: () async {
                            final authProvider = Provider.of<app_auth.AuthProvider?>(context, listen: false);
                            final currentUser = authProvider != null ? FirebaseAuth.instance.currentUser : null;

                            // Check if user is authenticated using Firebase Auth directly
                            if (currentUser != null) {
                              // Check if user is a walker
                              if (authProvider?.isWalker == true) {
                                // Show message that walkers can't book other walkers
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.info_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'You are signed in as a Pet Walker. Please register as a Pet Owner to book a walker.',
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
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: 'Register',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const BookingAuthenticationPage(
                                              personName: 'Pet Owner',
                                              isWalker: false,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                                return;
                              }
                              // User is logged in as owner - go directly to booking page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    walker: widget.walker,
                                  ),
                                ),
                              );
                            } else {
                              // User not logged in - go to authentication page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingAuthenticationPage(
                                    personName: widget.walker.name,
                                    isWalker: false,
                                  ),
                                ),
                              );
                            }
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Book from \$${widget.walker.hourlyRate}/hr',
                                  style: const TextStyle(
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

  // Simplified service badge without price (mobile-first redesign)
  Widget _buildSimpleServiceBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withAlpha((0.12 * 255).round()),
            const Color(0xFF6366F1).withAlpha((0.06 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha((0.25 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
              letterSpacing: 0.2,
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
                            child: ClipOval(
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: widget.owner.imageUrl.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: widget.owner.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: const Color(0xFFEC4899).withAlpha((0.1 * 255).round()),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFEC4899),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: const Color(0xFFEC4899).withAlpha((0.1 * 255).round()),
                                          child: const Icon(
                                            Icons.pets,
                                            color: Color(0xFFEC4899),
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFEC4899).withAlpha((0.1 * 255).round()),
                                        child: const Icon(
                                          Icons.pets,
                                          color: Color(0xFFEC4899),
                                          size: 28,
                                        ),
                                      ),
                              ),
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
                    // Add Pet Button
                    Expanded(
                      flex: 2,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final authProvider = Provider.of<app_auth.AuthProvider?>(context, listen: false);
                            final currentUser = authProvider != null ? FirebaseAuth.instance.currentUser : null;

                            // Check if user is authenticated using Firebase Auth directly
                            if (currentUser != null) {
                              // User is logged in - go to their profile page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RedesignedOwnerProfilePage(),
                                ),
                              );
                            } else {
                              // User not logged in - go to authentication page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingAuthenticationPage(
                                    personName: widget.owner.dogName,
                                    isWalker: false,
                                  ),
                                ),
                              );
                            }
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