import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  /// Check if running on desktop platform
  bool get isDesktop {
    return !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  }

  /// Pick an image from the camera
  Future<File?> pickImageFromCamera() async {
    try {
      // Camera is not available on desktop platforms
      if (isDesktop) {
        throw 'Camera is not available on desktop. Please choose from files.';
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      throw 'Failed to access camera: ${e.toString()}';
    }
  }

  /// Pick an image from the gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // Use file_picker for desktop platforms, image_picker for mobile
      if (isDesktop) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final filePath = result.files.first.path;
          if (filePath != null) {
            return File(filePath);
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
          return File(image.path);
        }
        return null;
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      throw 'Failed to access gallery: ${e.toString()}';
    }
  }

  /// Upload image to Firebase Storage and return the download URL
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Verify file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      print('Starting upload for user: ${user.uid}');
      print('File path: ${imageFile.path}');
      print('File size: ${await imageFile.length()} bytes');

      // Create a reference to the storage location
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('profile_images/$fileName');

      print('Storage path: profile_images/$fileName');

      // Read file as bytes (fixes desktop platform issues with putFile)
      final bytes = await imageFile.readAsBytes();
      print('Read ${bytes.length} bytes from file');

      // Upload the file using putData for desktop compatibility
      final UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      print('Upload completed successfully');

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error uploading image: ${e.code} - ${e.message}');

      // Provide specific error messages
      if (e.code == 'unauthorized') {
        throw Exception('Permission denied. Please check Firebase Storage rules.');
      } else if (e.code == 'canceled') {
        throw Exception('Upload canceled');
      } else if (e.code == 'unknown') {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Firebase error: ${e.message}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
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
      print('Error deleting image: $e');
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
