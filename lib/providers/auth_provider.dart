import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

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
    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;

    if (user != null) {
      try {
        // Load user profile from Firestore
        _userProfile = await _userService.getUser(user.uid);
      } catch (e) {
        print('Error loading user profile: $e');
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
      print('Error refreshing user profile: $e');
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
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
