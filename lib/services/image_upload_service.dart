import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUploadService {
  late final FirebaseStorage _storage;
  late final FirebaseAuth _auth;
  final ImagePicker _picker = ImagePicker();

  ImageUploadService() {
    _storage = FirebaseStorage.instance;
    _auth = FirebaseAuth.instance;
  }

  /// Check if running on desktop platform
  bool get isDesktop {
    return !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  }

  /// Pick an image from the camera
  /// Returns a map with 'bytes' and 'name' for cross-platform compatibility
  Future<Map<String, dynamic>?> pickImageFromCamera() async {
    try {
      // Camera is not available on desktop or web platforms
      if (isDesktop || kIsWeb) {
        throw 'Camera is not available on desktop/web. Please choose from files.';
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        return {
          'bytes': bytes,
          'name': image.name,
        };
      }
      return null;
    } catch (e) {
      throw 'Failed to access camera: ${e.toString()}';
    }
  }

  /// Pick an image from the gallery
  /// Returns a map with 'bytes' and 'name' for cross-platform compatibility
  Future<Map<String, dynamic>?> pickImageFromGallery() async {
    try {
      // Use file_picker for desktop and web platforms
      if (isDesktop || kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true, // Important: Get bytes directly for web/desktop
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;

          // On web, bytes are always available and path is NOT available
          // On desktop, bytes might be available or we need to read from path
          if (file.bytes != null) {
            // Web and some desktop: bytes are directly available
            return {
              'bytes': file.bytes!,
              'name': file.name,
              // Don't access path on web - it throws exception
            };
          } else if (!kIsWeb && file.path != null) {
            // Desktop only (not web): read bytes from file path
            final fileObj = File(file.path!);
            final bytes = await fileObj.readAsBytes();
            return {
              'bytes': bytes,
              'name': file.name,
            };
          }
        }
        return null;
      } else {
        // Use image_picker for mobile platforms
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          final bytes = await image.readAsBytes();
          return {
            'bytes': bytes,
            'name': image.name,
          };
        }
        return null;
      }
    } catch (e) {
      throw 'Failed to access gallery: ${e.toString()}';
    }
  }

  /// Upload image to Firebase Storage and return the download URL
  /// Takes a Map with 'bytes', 'name', and optional 'path' from picker methods
  Future<String> uploadProfileImage(Map<String, dynamic> imageData) async {
    try {

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get bytes from the image data
      final Uint8List bytes = imageData['bytes'] as Uint8List;
      final String? imageName = imageData['name'] as String?;


      // Check Firebase Storage instance

      // Create a reference to the storage location
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageRef = _storage.ref().child('profile_images/$fileName');

      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'platform': kIsWeb ? 'web' : (isDesktop ? 'desktop' : 'mobile'),
          'originalName': imageName ?? 'unknown',
        },
      );


      // Upload using putData() with Uint8List - universal cross-platform method
      UploadTask uploadTask;
      try {
        uploadTask = storageRef.putData(bytes, metadata);
      } catch (e) {
        rethrow;
      }

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {

      // Provide specific error messages
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception('Permission denied. Firebase Storage may not be enabled or rules are blocking upload.');
      } else if (e.code == 'canceled') {
        throw Exception('Upload canceled');
      } else if (e.code == 'unknown') {
        throw Exception('Network error or Firebase Storage not configured. Please check your connection and Firebase Console.');
      } else if (e.code == 'storage/object-not-found') {
        throw Exception('Storage bucket not found. Please enable Firebase Storage in Firebase Console.');
      } else {
        throw Exception('Firebase error [${e.code}]: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Delete an image from Firebase Storage given its URL
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('firebase')) {
        return; // Not a Firebase Storage URL
      }

      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      // Don't throw error - deletion failure shouldn't block user flow
    }
  }

  /// Show bottom sheet to choose between camera and gallery
  static Future<File?> showImageSourceBottomSheet({
    required Function() onCamera,
    required Function() onGallery,
  }) async {
    // This will be called from the UI layer
    // Return type is for documentation purposes
    return null;
  }
}
