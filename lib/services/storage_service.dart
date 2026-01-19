
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Filename must start with userId to match storage rules
      String filePath = 'profile_images/${userId}_${DateTime.now().millisecondsSinceEpoch}.png';
      UploadTask uploadTask = _storage.ref().child(filePath).putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}
