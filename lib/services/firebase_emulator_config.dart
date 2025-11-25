import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Configure Firebase to use local emulators in debug mode
class FirebaseEmulatorConfig {
  static const bool _useEmulators = false; // Disabled - using production Firebase

  // Emulator hosts and ports
  // Use 10.0.2.2 for Android emulators to access host machine's localhost
  // Use localhost or 127.0.0.1 for desktop/web
  static const String _emulatorHost = 'localhost';
  static const int _authEmulatorPort = 9099;
  static const int _firestoreEmulatorPort = 8080;
  static const int _storageEmulatorPort = 9199;

  /// Call this after Firebase.initializeApp() to connect to emulators
  static Future<void> connectToEmulators() async {
    if (!_useEmulators) {
      return;
    }

    try {

      // Connect Firebase Auth to emulator
      await FirebaseAuth.instance.useAuthEmulator(
        _emulatorHost,
        _authEmulatorPort,
      );

      // Connect Firestore to emulator
      FirebaseFirestore.instance.useFirestoreEmulator(
        _emulatorHost,
        _firestoreEmulatorPort,
      );

      // Connect Storage to emulator
      await FirebaseStorage.instance.useStorageEmulator(
        _emulatorHost,
        _storageEmulatorPort,
      );

    } catch (e) {
        // Error handled silently
    }
  }

  /// Check if emulators are being used
  static bool get useEmulators => _useEmulators;
}
