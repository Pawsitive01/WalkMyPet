import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Configure Firebase to use local emulators in debug mode
class FirebaseEmulatorConfig {
  static const bool _useEmulators = false; // Disabled - using production Firebase

  // Emulator hosts and ports
  // Use 10.0.2.2 for Android emulators to access host machine's localhost
  static const String _emulatorHost = '10.0.2.2';
  static const int _authEmulatorPort = 9099;
  static const int _firestoreEmulatorPort = 8080;

  /// Call this after Firebase.initializeApp() to connect to emulators
  static Future<void> connectToEmulators() async {
    if (!_useEmulators) {
      print('🔥 Using production Firebase');
      return;
    }

    try {
      print('🧪 Connecting to Firebase Emulators...');

      // Connect Firebase Auth to emulator
      await FirebaseAuth.instance.useAuthEmulator(
        _emulatorHost,
        _authEmulatorPort,
      );
      print('✅ Auth Emulator connected: $_emulatorHost:$_authEmulatorPort');

      // Connect Firestore to emulator
      FirebaseFirestore.instance.useFirestoreEmulator(
        _emulatorHost,
        _firestoreEmulatorPort,
      );
      print('✅ Firestore Emulator connected: $_emulatorHost:$_firestoreEmulatorPort');

      print('✅ All Firebase Emulators connected successfully!');
      print('📊 Emulator UI available at: http://$_emulatorHost:4000');
    } catch (e) {
      print('⚠️ Error connecting to emulators: $e');
      print('⚠️ Make sure emulators are running: firebase emulators:start');
    }
  }

  /// Check if emulators are being used
  static bool get useEmulators => _useEmulators;
}
