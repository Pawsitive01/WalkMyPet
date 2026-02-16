import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/services/notification_service.dart';
import 'package:walkmypet/services/database_migration_service.dart';

class AuthProvider with ChangeNotifier {
  late final FirebaseAuth _auth;
  late final UserService _userService;
  late final NotificationService _notificationService;
  late final DatabaseMigrationService _migrationService;

  User? _user;
  AppUser? _userProfile;
  bool _isLoading = true;

  User? get user => _user;
  AppUser? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get hasCompletedOnboarding => _userProfile?.toFirestore()['onboardingComplete'] == true;

  AuthProvider() {
    _init();
  }

  void _init() {
    try {
      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _userService = UserService();
      _notificationService = NotificationService();
      _migrationService = DatabaseMigrationService();

      // Listen to auth state changes
      _auth.authStateChanges().listen(_onAuthStateChanged);
    } catch (e) {
      // Error handled silently
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;

    if (user != null) {
      try {
        // Migrate user from old 'users' collection if needed
        await _migrationService.migrateCurrentUserIfNeeded();

        // Load user profile from Firestore
        _userProfile = await _userService.getUser(user.uid);

        // Initialize notifications and save FCM token
        await _notificationService.initialize();
        await _notificationService.saveTokenToFirestore(user.uid);
      } catch (e) {
        // Error handled silently
      }
    } else {
      _userProfile = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUserProfile() async {
    if (_user == null) return;

    try {
      _userProfile = await _userService.getUser(_user!.uid);
      notifyListeners();
    } catch (e) {
      // Silent error handling
    }
  }

  String? get userType {
    if (_userProfile == null) return null;
    final data = _userProfile!.toFirestore();
    return data['userType'];
  }

  bool get isWalker => userType == 'petWalker';
  bool get isOwner => userType == 'petOwner';

  Future<void> signOut() async {
    // Remove FCM token before signing out
    if (_user != null) {
      await _notificationService.removeTokenFromFirestore(_user!.uid);
    }
    await _auth.signOut();
  }
}
