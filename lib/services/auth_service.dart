import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _auth = FirebaseAuth.instance;

    // Ensure auth persistence is set to LOCAL (persists across app restarts)
    _auth.setPersistence(Persistence.LOCAL).catchError((error) {
      // Error handled silently
    });

    _googleSignIn = GoogleSignIn();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Send email verification (non-blocking — failure should not abort signup)
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        userCredential.user!.sendEmailVerification().catchError((_) {});
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        await user.reload();
      }
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Delete account and all associated Firestore data
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final db = FirebaseFirestore.instance;

      // Delete user documents from all collections
      await Future.wait([
        db.collection('owners').doc(uid).delete().catchError((_) => null),
        db.collection('walkers').doc(uid).delete().catchError((_) => null),
        db.collection('users').doc(uid).delete().catchError((_) => null),
      ]);

      // Delete notifications
      final notifications = await db
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in notifications.docs) {
        await doc.reference.delete();
      }

      // Delete reviews written by or about this user
      final reviewsBy = await db
          .collection('reviews')
          .where('reviewerId', isEqualTo: uid)
          .get();
      final reviewsAbout = await db
          .collection('reviews')
          .where('reviewedId', isEqualTo: uid)
          .get();
      for (final doc in [...reviewsBy.docs, ...reviewsAbout.docs]) {
        await doc.reference.delete();
      }

      // Sign out from Google if applicable
      await _googleSignIn.signOut().catchError((_) => null);

      // Delete Firebase Auth account (must be last)
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions with professional messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password must be at least 6 characters with a mix of letters and numbers.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in or use forgot password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up to create an account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or use forgot password.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently unavailable. Please try another method.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please wait a few minutes and try again.';
      case 'requires-recent-login':
        return 'For security reasons, please sign in again to complete this action.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet and try again.';
      default:
        return e.message ?? 'Unable to complete authentication. Please try again.';
    }
  }
}
