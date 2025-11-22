
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setUserProfile(String uid, UserProfile userProfile) {
    return _db.collection('users').doc(uid).set(userProfile.toFirestore());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    } else {
      return null;
    }
  }

  Future<List<UserProfile>> getWalkers() async {
    QuerySnapshot snapshot = await _db.collection('users').where('userType', isEqualTo: 'walker').get();
    return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }

  Future<List<UserProfile>> getOwners() async {
    QuerySnapshot snapshot = await _db.collection('users').where('userType', isEqualTo: 'owner').get();
    return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }
}
